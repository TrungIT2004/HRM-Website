"""DOC_ONLY LLM-as-a-Judge using Gemini Flash Lite 3.5 (google-genai library).

Evaluates generated answers against ground truth using pairwise comparison (2 calls, swapped).

Uses 7-key rotation with token bucket rate limiting (same as ChatService).

Requires:
    GEMINI_API_KEY_0..6 in .env (or GEMINI_API_KEY for single key)
    GEMINI_MODEL_JUDGE=gemini-3.5-flash-lite (default)

Run from ai-service/:
    python test_v2/doc_only/judge_gemini.py --limit 120

Output: test_v2/doc_only/results/judge_gemini.json (resumable)
"""

import argparse
import json
import os
import re
import sys
import time
import threading
from pathlib import Path
from typing import List, Dict, Optional

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from dotenv import load_dotenv
load_dotenv()

from google import genai
from google.genai import types


HERE = Path(__file__).resolve().parent
ANSWERS = HERE / "results" / "latest" / "answers.json"
DATASET = HERE / "dataset" / "doc_only_120.json"
OUT = HERE / "results" / "judge_gemini.json"

JUDGE_PROMPT = """Bạn là giám khảo đánh giá chất lượng trả lời RAG (tiếng Việt).
Dữ liệu: CÂU HỎI, ĐÁP ÁN MẪU (ground truth), ĐÁP ÁN HỆ THỐNG, NGỮ CẢN CỨ (trích tài liệu), NGUỒN TRÍCH DẪN của hệ thống.

Nhiệm vụ (trả JSON thuần, không markdown):
1. "evidence": liệt kê NGẮN GỌN các ý trong đáp án mẫu; với mỗi ý, ý nào hệ thống có/thiếu/sai (trích cụm từ ngắn làm bằng chứng).
2. "correctness": "A" | "B" | "TIE" — đáp án nào đúng và đầy đủ hơn theo NGỮ CẢN CỨ (điền đắt không những đúng ý đúng thì vẫn được TIE hoặc thắng, không trừ điểm văn phong).
3. "relevance": 1-5 — đáp án hệ thống có giải quyết đúng câu hỏi không.
4. "hallucination": true/false — hệ thống có thông tin nào SAI hoặc không được ngữ cảnh hỗ trợ không; nếu true, "hallucination_quote" trích cụm từ đó.
5. "citations_ok": true/false — các nguồn trích dẫn có thực sự chứng minh nội dung trả lời không.

--- CÂU HỎI ---
{question}
--- ĐÁP ÁN A ---
{a}
--- ĐÁP ÁN B ---
{b}
--- NGỮ CẢN CỨ ---
{contexts}
--- NGUỒN TRÍCH DẪN CỦA HỆ THỐNG ---
{cites}
--- HẾT ---"""


class TokenBucket:
    """Token bucket rate limiter for API key quota management."""

    def __init__(self, rpm: int, cost_per_call: int = 6):
        self.rpm = rpm
        self.capacity = rpm
        self.cost_per_call = cost_per_call
        self._tokens = float(rpm)
        self._last_refill = time.time()
        self._lock = threading.Lock()

    def _refill(self) -> None:
        now = time.time()
        elapsed = now - self._last_refill
        refill_amount = elapsed * (self.rpm / 60.0)
        self._tokens = min(self.capacity, self._tokens + refill_amount)
        self._last_refill = now

    def available(self) -> float:
        with self._lock:
            self._refill()
            return self._tokens

    def try_take(self, cost: Optional[int] = None) -> bool:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                self._tokens -= cost
                return True
            return False

    def take(self, cost: Optional[int] = None) -> float:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                self._tokens -= cost
                return 0.0
            deficit = cost - self._tokens
            wait_time = deficit / (self.rpm / 60.0)
        if wait_time > 0:
            time.sleep(wait_time)
        with self._lock:
            self._refill()
            self._tokens = max(0.0, self._tokens - cost)
        return wait_time

    def time_until_ready(self, cost: Optional[int] = None) -> float:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                return 0.0
            deficit = cost - self._tokens
            return deficit / (self.rpm / 60.0)


class GeminiKeyPool:
    """Manages a pool of Gemini API keys with token bucket rate limiting."""

    def __init__(self, api_keys: List[str], model: str, rpm: int = 15):
        self.model = model
        self.clients = [genai.Client(api_key=key) for key in api_keys]
        self.buckets = [TokenBucket(rpm=rpm, cost_per_call=1) for _ in api_keys]
        self.usage = {i: {"requests": 0, "errors": 0} for i in range(len(self.clients))}
        self._invalid_keys: set[int] = set()
        print(f"[JudgePool] Initialized with {len(self.clients)} API keys for model: {model} (RPM={rpm})")

    def _pick_key(self) -> int:
        """Pick the best key using token bucket."""
        if not self.clients:
            return 0

        # Find key with most headroom (skip invalid)
        best_idx = -1
        best_available = -1.0
        for idx, bucket in enumerate(self.buckets):
            if idx in self._invalid_keys:
                continue
            available = bucket.available()
            if available > best_available:
                best_available = available
                best_idx = idx

        # Try best key
        if best_idx >= 0 and self.buckets[best_idx].try_take():
            return best_idx

        # All buckets low - wait for the one that will be ready soonest (skip invalid)
        valid_indices = [i for i in range(len(self.buckets)) if i not in self._invalid_keys]
        if not valid_indices:
            print(f"[JudgePool] All {len(self.buckets)} keys invalid!")
            return 0
        wait_idx = min(
            valid_indices,
            key=lambda i: self.buckets[i].time_until_ready()
        )
        wait_time = self.buckets[wait_idx].take()
        if wait_time > 0:
            print(f"[JudgePool] Rate limit: waited {wait_time:.1f}s for key {wait_idx}")
        return wait_idx

    def generate(self, prompt: str) -> str:
        """Generate content using best available key."""
        last_error = None

        for attempt in range(len(self.clients)):
            key_idx = self._pick_key()
            client = self.clients[key_idx]

            try:
                res = client.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        temperature=0.0,
                        max_output_tokens=2048,
                    ),
                )

                text = (res.text or "").strip()
                self.usage[key_idx]["requests"] += 1

                if text:
                    return text
                else:
                    last_error = "Empty response"

            except Exception as e:
                self.usage[key_idx]["errors"] += 1
                last_error = str(e)
                err_str = str(e)
                print(f"[JudgePool] Key {key_idx} failed: {e}")
                if "401" in err_str or "unauthenticated" in err_str.lower():
                    self._invalid_keys.add(key_idx)
                    print(f"[JudgePool] Key {key_idx} marked INVALID (401/unauth)")
                elif ("429" in err_str or "quota" in err_str.lower()
                      or "rate limit" in err_str.lower()):
                    with self.buckets[key_idx]._lock:
                        self.buckets[key_idx]._tokens = 0
                        self.buckets[key_idx]._last_refill = time.time()
                continue

        raise RuntimeError(f"All judge keys exhausted. Last error: {last_error}")


def parse_verdict(text: str) -> dict | None:
    t = (text or "").strip()
    t = re.sub(r"^```(?:json)?\s*|\s*```$", "", t, flags=re.S).strip()
    cands = [t]
    m = re.search(r"\{.*\}", t, flags=re.S)
    if m:
        cands.append(m.group(0))
    for c in cands:
        try:
            d = json.loads(c)
            if d.get("correctness") in ("A", "B", "TIE"):
                return d
        except Exception:
            continue
    return None


def aggregate(v1: str, v2: str) -> str:
    """v1/v2 đã map về frame GT-vs-GEN: 'GT' | 'GEN' | 'TIE'."""
    if v1 == v2:
        return v1
    if "TIE" in (v1, v2):
        return v1 if v2 == "TIE" else v2
    return "DISPUTED"


def summarize(rows: list) -> dict:
    n = len(rows) or 1
    c = {"n": len(rows)}
    for k in ("GT", "GEN", "TIE", "DISPUTED"):
        c[k] = sum(1 for r in rows if r["final"] == k)
    c["correctness_rate"] = round((c["GEN"] + c["TIE"]) / n, 4)
    rel = [r["run1"]["relevance"] for r in rows if isinstance(r["run1"].get("relevance"), (int, float))]
    c["relevance_mean"] = round(sum(rel) / len(rel), 2) if rel else 0.0
    c["hallucination_rate"] = round(sum(1 for r in rows
        if r["run1"].get("hallucination") or r["run2"].get("hallucination")) / n, 4)
    oks = [r for r in rows if r["run1"].get("citations_ok") is not None]
    c["citations_ok_rate"] = round(sum(1 for r in oks if r["run1"]["citations_ok"]) / len(oks), 4) if oks else 0.0
    c["len_warn"] = sum(1 for r in rows if r["len_warn"])
    cc = [r.get("cite_in_context", 0.0) for r in rows]
    c["cite_in_context_mean"] = round(sum(cc) / len(cc), 4) if cc else 0.0
    return c


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=30, help="Số câu hỏi tối đa mỗi lần chạy")
    ap.add_argument("--answers", type=str, default=None, help="Đường dẫn file answers.json từ benchmark")
    ap.add_argument("--ids", type=str, default=None,
                    help="Chỉ chấm lại các id (vd D005,D011) — xoá row cũ, force re-judge")
    ap.add_argument("--full-context", action="store_true",
                    help="Dùng FULL chunk (không cắt 600 ký tự) — chống oan hallucination")
    args = ap.parse_args()

    # Load API keys (GEMINI_API_KEY_0..6 or single GEMINI_API_KEY)
    api_keys = []
    for i in range(7):
        key = os.getenv(f"GEMINI_API_KEY_{i}")
        if key and key != f"your_gemini_api_key_{i}_here":
            api_keys.append(key)

    if len(api_keys) == 0:
        single_key = os.getenv("GEMINI_API_KEY")
        if single_key and single_key != "your_gemini_api_key_here":
            api_keys = [single_key] * 7
            print("[JudgePool] Using single GEMINI_API_KEY replicated 7x")
        else:
            print("[ERROR] No GEMINI_API_KEY found in .env", flush=True)
            sys.exit(1)
    else:
        print(f"[JudgePool] Loaded {len(api_keys)} API keys")

    pool = GeminiKeyPool(api_keys, model=os.getenv("GEMINI_MODEL_JUDGE", "gemini-3.5-flash-lite"), rpm=15)

    # Load answers (from benchmark)
    if args.answers:
        answers_path = Path(args.answers)
    else:
        results_dir = HERE / "results"
        if results_dir.exists():
            subdirs = sorted([d for d in results_dir.iterdir() if d.is_dir()], reverse=True)
            if subdirs:
                answers_path = subdirs[0] / "answers.json"
            else:
                answers_path = ANSWERS
        else:
            answers_path = ANSWERS

    if not answers_path.exists():
        print(f"[ERROR] Answers file not found: {answers_path}", flush=True)
        print("Run the benchmark first, or specify --answers path", flush=True)
        sys.exit(1)

    answers = {r["id"]: r for r in json.loads(answers_path.read_text(encoding="utf-8"))
               if not r.get("expected_abstain") and "LOI GEN" not in r.get("generated_answer", "")}
    gold = {r["id"]: r for r in json.loads(DATASET.read_text(encoding="utf-8"))}
    ids = sorted(set(answers) & set(gold))

    # Load existing results for resume
    out = {"rows": [], "summary": {}}
    if OUT.exists():
        out = json.loads(OUT.read_text(encoding="utf-8"))
    if args.ids:
        want = {x.strip() for x in args.ids.split(",") if x.strip()}
        out["rows"] = [r for r in out["rows"] if r["id"] not in want]
        ids = [i for i in ids if i in want]
        args.limit = len(ids)
    have = {r["id"] for r in out["rows"] if r.get("run1") and r.get("run2")}
    todo = [i for i in ids if i not in have][: args.limit]
    print(f"[judge] {len(ids)} câu ({len(todo)} cần chạy, {len(have)} resume)", flush=True)

    # Initialize retriever for context
    from src.retrievers.hybrid_retriever import HybridRetriever
    ret = HybridRetriever(use_reranker=False)

    by_id = {r["id"]: r for r in out["rows"]}
    for k, i in enumerate(todo):
        a, g = answers[i], gold[i]
        try:
            got = ret.retrieve(
                query=a.get("rewritten_query") or a["question"],
                jobs=["ALL"], departments=["ALL"], top_k=5,
                use_reranker=True, vw=0.7, lw=0.3
            )
        except Exception:
            got = []
        seen = {str(c.get("chunk_id")) for c in got}
        per = None if args.full_context else 600
        cap = 12000 if args.full_context else 4000
        parts = [(c.get("content") or "")[:per] for c in got]
        for gid in (g.get("relevant_chunk_ids") or []):
            if gid not in seen:
                parts += g.get("reference_contexts", [])
                break
        ctx = "\n---\n".join(parts)[:cap]
        ret_docs = [c.get("document_name") for c in got]
        cites = json.dumps([{"document_name": c.get("document_name"),
                              "breadcrumb": c.get("breadcrumb")} for c in a.get("citations", [])],
                           ensure_ascii=False)[:1000]
        kw = {"question": a["question"], "contexts": ctx or "(không có)", "cites": cites or "[]"}
        print(f"[{k + 1}/{len(todo)}] {i} run1 (A=GT,B=GEN)", flush=True)
        r1 = parse_verdict(pool.generate(JUDGE_PROMPT.format(a=g["ground_truth"], b=a["generated_answer"], **kw)))
        print(f"[{k + 1}/{len(todo)}] {i} run2 (A=GEN,B=GT)", flush=True)
        r2 = parse_verdict(pool.generate(JUDGE_PROMPT.format(a=a["generated_answer"], b=g["ground_truth"], **kw)))
        time.sleep(1)
        if not r1 or not r2:
            print(f"  [{i}] judge fail, bỏ qua (chạy lại sẽ resume)", flush=True)
            continue
        m1 = {"A": "GT", "B": "GEN", "TIE": "TIE"}[r1["correctness"]]
        m2 = {"A": "GEN", "B": "GT", "TIE": "TIE"}[r2["correctness"]]
        lg, la = len(g["ground_truth"]), len(a["generated_answer"])
        cited_docs = [c.get("document_name") for c in (a.get("citations") or [])]
        row = {"id": i, "run1": {"verdict": m1, "relevance": r1.get("relevance"),
                                  "hallucination": r1.get("hallucination"),
                                  "hallucination_quote": r1.get("hallucination_quote", ""),
                                  "citations_ok": r1.get("citations_ok"),
                                  "evidence": str(r1.get("evidence") or "")[:800]},
               "run2": {"verdict": m2, "relevance": r2.get("relevance"),
                        "hallucination": r2.get("hallucination"),
                        "hallucination_quote": r2.get("hallucination_quote", ""),
                        "citations_ok": r2.get("citations_ok"),
                        "evidence": str(r2.get("evidence") or "")[:800]},
               "final": aggregate(m1, m2),
               "len_gt": lg, "len_gen": la,
               "len_warn": (max(lg, la) / max(1, min(lg, la))) > 3,
               "cite_in_context": (sum(1 for d in cited_docs if d in ret_docs)
                                   / max(1, len(cited_docs))) if cited_docs else 0.0}
        by_id[i] = row
        out["rows"] = [by_id[j] for j in sorted(by_id)]
        out["summary"] = summarize(out["rows"])
        OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  [{i}] {m1}/{m2} -> {row['final']}", flush=True)

    print("\n== JUDGE ==")
    print(json.dumps(out["summary"], ensure_ascii=False, indent=2))
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()