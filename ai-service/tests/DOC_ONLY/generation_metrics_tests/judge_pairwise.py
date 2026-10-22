"""Giai doan 3b: LLM-as-a-Judge pairwise (2 luot dao vi tri).

- Judge = key MOI (OLLAMA_JUDGE_API_KEY), RAG tra loi = key cu -> tach biet.
  Model van cung weights gemma4:31b nen con self-bias: giam bang dao A/B +
  cho hoa (TIE) + bat giai thich bang chung truoc.
- Moi cau 2 calls: run1 (A=ground truth, B=generated), run2 (dao lai).
  Hop nhat: dong thuan -> final; thang+hoa -> thang (yeu); nguoc nhau -> disputed.
- Do dai chi canh bao (lech >3x), khong quyet thang thua.

Env:
    OLLAMA_JUDGE_API_KEY   (bat buoc key moi; fallback key cu + canh bao)
    OLLAMA_JUDGE_MODEL     (fallback OLLAMA_MODEL)

Chay tu ai-service (chia batch vi 120 cau x 2 calls):
    python tests/DOC_ONLY/generation_metrics_tests/judge_pairwise.py --limit 30
    ... lap lai den khi xong (resume tu dong)
Output: tests/DOC_ONLY/generation_metrics_tests/judge.json
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

HERE = Path(__file__).resolve().parent
ANSWERS = HERE / "answers.json"
DATASET = HERE.parent / "datasets" / "doc_only_120.json"
OUT = HERE / "judge.json"

JUDGE_PROMPT = """Ban la giam khao danh gia chat luong tra loi RAG (tieng Viet).
Du lieu: CAU HOI, DAP AN MAU (ground truth), DAP AN HE THONG, NGU CAN CU (trich tai lieu), NGUON TRICH DAN cua he thong.

Nhiem vu (tra JSON thuan, khong markdown):
1. "evidence": lieu ke NGAN GON cac y trong dap an mau; voi moi y, y nao he thong co/thieu/sai (trich cum tu ngan lam bang chung).
2. "correctness": "A" | "B" | "TIE" — dap an nao dung va day du hon theo NGU CAN CU (dien dat khac nhung du y dung thi van duoc TIE hoac thang, khong tru diem van phong).
3. "relevance": 1-5 — dap an he thong co giai quyet dung cau hoi khong.
4. "hallucination": true/false — he thong co thong tin nao SAI hoac khong duoc ngu can cu ho tro khong; neu true, "hallucination_quote" trich cum tu do.
5. "citations_ok": true/false — cac nguon trich dan co thuc su chung minh noi dung tra loi khong.

--- CAU HOI ---
{question}
--- DAP AN A ---
{a}
--- DAP AN B ---
{b}
--- NGU CAN CU ---
{contexts}
--- NGUON TRICH DAN CUA HE THONG ---
{cites}
--- HET ---"""


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


def judge_once(client, model: str, **kw) -> dict | None:
    for _ in range(2):
        try:
            res = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": JUDGE_PROMPT.format(**kw)}],
                temperature=0.0, timeout=180)
            d = parse_verdict(res.choices[0].message.content)
            if d:
                return d
        except Exception as e:
            print(f"  [judge loi] {type(e).__name__}: {e}"[:150], flush=True)
            time.sleep(3)
    return None


def aggregate(v1: str, v2: str) -> str:
    """v1/v2 da map ve frame GT-vs-GEN: 'GT' | 'GEN' | 'TIE'."""
    if v1 == v2:
        return v1
    if "TIE" in (v1, v2):
        return v1 if v2 == "TIE" else v2  # thang (yeu)
    return "DISPUTED"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=30)
    ap.add_argument("--ids", type=str, default=None,
                    help="Chi cham lai cac id (vd D005,D011) — xoa row cu, force re-judge.")
    ap.add_argument("--full-context", action="store_true",
                    help="Dung FULL chunk (khong cat 600 ky tu) — chong oan hallucination.")
    args = ap.parse_args()

    key = os.getenv("OLLAMA_JUDGE_API_KEY") or os.getenv("OLLAMA_API_KEY", "")
    if not os.getenv("OLLAMA_JUDGE_API_KEY"):
        print("[WARN] chua co OLLAMA_JUDGE_API_KEY — dung key cu, judge mat tinh doc lap!", flush=True)
    from openai import OpenAI
    client = OpenAI(
        base_url=os.getenv("OLLAMA_JUDGE_BASE_URL") or os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
        api_key=key)
    model = os.getenv("OLLAMA_JUDGE_MODEL") or os.getenv("OLLAMA_MODEL", "gemma4:31b")
    print(f"[judge] model={model} key=...{key[-4:]}")

    answers = {r["id"]: r for r in json.loads(ANSWERS.read_text(encoding="utf-8"))
               if not r.get("expected_abstain") and "LOI GEN" not in r.get("answer", "")}
    gold = {r["id"]: r for r in json.loads(DATASET.read_text(encoding="utf-8"))}
    ids = sorted(set(answers) & set(gold))

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
    print(f"[judge] {len(ids)} cau ({len(todo)} can chay, {len(have)} resume)", flush=True)

    by_id = {r["id"]: r for r in out["rows"]}
    from src.retrievers.hybrid_retriever import HybridRetriever
    ret = HybridRetriever(use_reranker=False)
    for k, i in enumerate(todo):
        a, g = answers[i], gold[i]
        # ponytail: faithfulness phai cham tren top-5 dap an DA THAY (retrieve lai
        # bang rewritten_query), khong phai 1 gold chunk — neu khong, chi tiet dung
        # tu chunk 2..5 bi xu oan hallucination (vd D001).
        try:
            got = ret.retrieve(query=a.get("rewritten_query") or a["question"],
                               jobs=["ALL"], departments=["ALL"], top_k=5,
                               use_reranker=True, vw=0.7, lw=0.3)
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
        kw = {"question": a["question"], "contexts": ctx or "(khong co)", "cites": cites or "[]"}
        print(f"[{k + 1}/{len(todo)}] {i} run1 (A=GT,B=GEN)", flush=True)
        r1 = judge_once(client, model, a=g["ground_truth"], b=a["answer"], **kw)
        print(f"[{k + 1}/{len(todo)}] {i} run2 (A=GEN,B=GT)", flush=True)
        r2 = judge_once(client, model, a=a["answer"], b=g["ground_truth"], **kw)
        time.sleep(1)
        if not r1 or not r2:
            print(f"  [{i}] judge fail, bo qua (chay lai se resume)", flush=True)
            continue
        m1 = {"A": "GT", "B": "GEN", "TIE": "TIE"}[r1["correctness"]]
        m2 = {"A": "GEN", "B": "GT", "TIE": "TIE"}[r2["correctness"]]
        lg, la = len(g["ground_truth"]), len(a["answer"])
        cited_docs = [c.get("document_name") for c in (a.get("citations") or [])]
        row = {"id": i, "run1": {"verdict": m1, "relevance": r1.get("relevance"),
                                 "hallucination": r1.get("hallucination"),
                                 "hallucination_quote": r1.get("hallucination_quote", ""),
                                 "citations_ok": r1.get("citations_ok"),
                                 "evidence": (r1.get("evidence") or "")[:800]},
               "run2": {"verdict": m2, "relevance": r2.get("relevance"),
                        "hallucination": r2.get("hallucination"),
                        "hallucination_quote": r2.get("hallucination_quote", ""),
                        "citations_ok": r2.get("citations_ok"),
                        "evidence": (r2.get("evidence") or "")[:800]},
               "final": aggregate(m1, m2),
               "len_gt": lg, "len_gen": la,
               "len_warn": (max(lg, la) / max(1, min(lg, la))) > 3,
               # citation deterministic: trich dan co nam trong top-5 da thay?
               "cite_in_context": (sum(1 for d in cited_docs if d in ret_docs)
                                   / max(1, len(cited_docs))) if cited_docs else 0.0}
        by_id[i] = row
        out["rows"] = [by_id[j] for j in sorted(by_id)]
        out["summary"] = summarize(out["rows"])
        OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  [{i}] {m1}/{m2} -> {row['final']}", flush=True)

    print("\n== JUDGE ==\n " + json.dumps(out["summary"], ensure_ascii=False))
    print(f"-> {OUT}")


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


if __name__ == "__main__":
    main()
