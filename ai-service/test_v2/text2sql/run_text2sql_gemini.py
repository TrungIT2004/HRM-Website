#!/usr/bin/env python3
"""
Text-to-SQL test runner using Gemini 3.5 Flash Lite with token bucket + sticky key assignment.
Runs the 187 DB_ONLY questions from db_only_hybrid_questions.json
"""
import os
import sys
import json
import time
import re
import threading
from pathlib import Path
from collections import defaultdict
from typing import List, Dict, Any, Optional, Tuple

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from dotenv import load_dotenv
load_dotenv()

# Import existing validation and prompt building
from src.sql.executor import validate_sql, run_hrm_query, generate_personal_rows
from src.sql.text2sql import build_text2sql_prompt, extract_sql
from src.sql.router import keyword_fallback
from src.db.session import get_hrm_connection

# Google GenAI SDK
from google import genai
from google.genai import types

# =========================================================================
# CONFIGURATION
# =========================================================================

# Test user (Dang Thanh Khai)
TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"

# Questions file
QS = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions.json"
OUT = Path(__file__).resolve().parent / "db_retrieval_eval_gemini.json"

# Thresholds
THRESHOLDS = {"route_acc": (">", 0.85), "sql_ok": (">", 0.80), "non_empty": (">", 0.70)}

# Model to use
GEMINI_MODEL = "gemini-3.5-flash-lite"  # Updated from deprecated gemini-2.5-flash-lite

# RPM limits from env (free tier defaults)
GEMINI_RPM = int(os.getenv("GEMINI_RPM_SQL", "15"))

# =========================================================================
# TOKEN BUCKET FOR RATE LIMITING
# =========================================================================

class TokenBucket:
    """Token bucket rate limiter for API key quota management.

    Each key has a bucket with capacity = RPM (requests per minute).
    Each LLM call consumes ~6 requests (based on typical multi-call pipeline).
    Thread-safe for concurrent access.
    """

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
        """Try to consume tokens. Returns True if successful."""
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                self._tokens -= cost
                return True
            return False

    def take(self, cost: Optional[int] = None) -> float:
        """Consume tokens, blocking until available. Returns wait time."""
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
            self._tokens -= cost
        return wait_time

    def time_until_ready(self, cost: Optional[int] = None) -> float:
        """Seconds until bucket has enough tokens for cost."""
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                return 0.0
            deficit = cost - self._tokens
            return deficit / (self.rpm / 60.0)


# =========================================================================
# GEMINI CLIENT POOL WITH TOKEN BUCKET + STICKY ASSIGNMENT
# =========================================================================

class GeminiKeyPool:
    """Manages a pool of Gemini API keys with token bucket rate limiting and sticky assignment."""

    def __init__(self, api_keys: List[str], model: str, rpm: int = GEMINI_RPM):
        self.model = model
        self.clients = [genai.Client(api_key=key) for key in api_keys]
        self.buckets = [TokenBucket(rpm=rpm, cost_per_call=6) for _ in api_keys]
        self.usage = {i: {"requests": 0, "errors": 0} for i in range(len(self.clients))}
        self._affinity: Dict[str, int] = {}  # question_id -> key_index
        self._affinity_lock = threading.Lock()
        print(f"[GeminiPool] Initialized with {len(self.clients)} API keys for model: {model} (RPM={rpm})")

    def _pick_key(self, question_id: Optional[str] = None) -> int:
        """Pick the best key using token bucket + sticky affinity."""
        if not self.clients:
            return 0

        # Try sticky key first
        if question_id:
            with self._affinity_lock:
                sticky_idx = self._affinity.get(question_id)
            if sticky_idx is not None and sticky_idx < len(self.buckets):
                if self.buckets[sticky_idx].try_take():
                    return sticky_idx

        # Find key with most headroom
        best_idx = -1
        best_available = -1.0
        for idx, bucket in enumerate(self.buckets):
            available = bucket.available()
            if available > best_available:
                best_available = available
                best_idx = idx

        # Try best key
        if best_idx >= 0 and self.buckets[best_idx].try_take():
            if question_id:
                with self._affinity_lock:
                    self._affinity[question_id] = best_idx
            return best_idx

        # All buckets low - wait for the one that will be ready soonest
        wait_idx = min(
            range(len(self.buckets)),
            key=lambda i: self.buckets[i].time_until_ready()
        )
        wait_time = self.buckets[wait_idx].take()
        if wait_time > 0:
            print(f"[GeminiPool] Rate limit: waited {wait_time:.1f}s for key {wait_idx}")
        if question_id:
            with self._affinity_lock:
                self._affinity[question_id] = wait_idx
        return wait_idx

    def generate_sql(self, system_prompt: str, user_prompt: str, question_id: Optional[str] = None) -> str:
        """Generate SQL using Gemini with token bucket + sticky key assignment."""
        last_error = None

        # Try each key at most once (token bucket prevents 429)
        for attempt in range(len(self.clients)):
            key_idx = self._pick_key(question_id)
            client = self.clients[key_idx]

            try:
                response = client.models.generate_content(
                    model=self.model,
                    contents=[
                        types.Content(role="user", parts=[types.Part(text=system_prompt)]),
                        types.Content(role="user", parts=[types.Part(text=user_prompt)]),
                    ],
                    config=types.GenerateContentConfig(
                        temperature=0.0,
                        max_output_tokens=2048,
                    )
                )

                text = response.text or ""
                self.usage[key_idx]["requests"] += 1

                if text.strip():
                    return text.strip()
                else:
                    last_error = "Empty response"

            except Exception as e:
                self.usage[key_idx]["errors"] += 1
                last_error = str(e)
                err_str = str(e)
                print(f"[GeminiPool] Key {key_idx} failed: {e}")
                # On quota/auth errors, drain the bucket so it won't be picked next time
                if ("429" in err_str or "401" in err_str or
                    "quota" in err_str.lower() or "rate limit" in err_str.lower() or
                    "unauthenticated" in err_str.lower()):
                    with self.buckets[key_idx]._lock:
                        self.buckets[key_idx]._tokens = 0
                        self.buckets[key_idx]._last_refill = time.time()
                continue

        raise RuntimeError(f"All Gemini keys exhausted. Last error: {last_error}")

    def get_stats(self) -> Dict:
        return self.usage


# =========================================================================
# LOAD API KEYS
# =========================================================================

def load_api_keys() -> List[str]:
    """Load 7 Gemini API keys from environment or quota_state.json."""
    # First try environment variables GEMINI_API_KEY_0 through GEMINI_API_KEY_6
    keys = []
    for i in range(7):
        key = os.getenv(f"GEMINI_API_KEY_{i}")
        if key and key != f"your_gemini_api_key_{i}_here":
            keys.append(key)

    if len(keys) == 7:
        print(f"[Config] Loaded 7 API keys from environment variables")
        return keys

    # Fallback: try single GEMINI_API_KEY (will use same key for all)
    single_key = os.getenv("GEMINI_API_KEY")
    if single_key and single_key != "your_gemini_api_key_here":
        print(f"[Config] Using single GEMINI_API_KEY for all 7 slots")
        return [single_key] * 7

    # Last resort: extract from quota_state.json (keys are masked there though)
    quota_file = Path(__file__).resolve().parent / "quota_state.json"
    if quota_file.exists():
        with open(quota_file) as f:
            quota = json.load(f)
        # Keys in quota_state are masked (key0_AQ.Ab8RN...) - can't use directly
        print(f"[Config] WARNING: quota_state.json has masked keys, cannot extract real keys")

    raise RuntimeError(
        "No Gemini API keys found. Set GEMINI_API_KEY_0 through GEMINI_API_KEY_6 "
        "or GEMINI_API_KEY in .env file"
    )


# =========================================================================
# TEXT2SQL GENERATION USING GEMINI
# =========================================================================

def generate_sql_with_gemini(pool: GeminiKeyPool, question: str, question_id: Optional[str] = None) -> str:
    """Generate SQL using Gemini via the key pool."""
    system_prompt = "Trả về duy nhất 1 khối ```sql ... ```."
    user_prompt = build_text2sql_prompt(question)

    raw_response = pool.generate_sql(system_prompt, user_prompt, question_id=question_id)
    sql = extract_sql(raw_response)
    return sql


def run_text2sql_gemini(pool: GeminiKeyPool, question: str, user_id: str, question_id: Optional[str] = None) -> Tuple[List[Dict], str]:
    """Run text2sql with Gemini: generate -> validate -> execute (with retry)."""
    last_err = ""
    pending_hint = ""

    for attempt in range(2):
        sql = generate_sql_with_gemini(pool, question, question_id=question_id)

        if last_err:
            # Re-build prompt with error hint
            user_prompt = build_text2sql_prompt(question) + f"\nLần trước SQL lỗi: {last_err}. Sửa lại cho đúng luật."
            raw_response = pool.generate_sql("Trả về duy nhất 1 khối ```sql ... ```.", user_prompt, question_id=question_id)
            sql = extract_sql(raw_response)
        elif pending_hint:
            user_prompt = build_text2sql_prompt(question) + pending_hint
            raw_response = pool.generate_sql("Trả về duy nhất 1 khối ```sql ... ```.", user_prompt, question_id=question_id)
            sql = extract_sql(raw_response)

        try:
            result = run_hrm_query(sql, user_id)
        except (ValueError, RuntimeError) as e:
            last_err = str(e)
            print(f"[Text2SQL-Gemini] attempt {attempt} failed: {e}")
            continue

        last_err = ""
        if attempt == 1:
            return result["rows"], sql

        if not result["rows"]:
            pending_hint = (
                "\nLần trước SQL chạy được nhưng trả về 0 dòng. Thử lại: bỏ lọc "
                "tháng/năm hiện tại, lấy kỳ MỚI NHẤT (ORDER BY ... DESC LIMIT 1); "
                "quan hệ có-thể-trống thì LEFT JOIN; đếm/tổng/max thì COUNT/COALESCE/MAX."
            )
            print("[Text2SQL-Gemini] attempt 0 empty, retry once with latest-period hint")
            continue

        # Shape check for listing queries
        from src.sql.executor import _shape_ok
        if not _shape_ok(question, result["columns"]):
            pending_hint = (
                "\nLần trước SQL chạy được nhưng thiếu cột ngữ cảnh (chỉ có: "
                + ", ".join(result["columns"]) + "). Viết lại GIỮ NGUYÊN các "
                "cột đã có và THÊM cột ngày/tháng/lý do/trạng thái còn thiếu "
                "theo câu hỏi."
            )
            print(f"[Text2SQL-Gemini] attempt 0 shape-bad {result['columns']}, retry once")
            continue

        return result["rows"], sql

    raise RuntimeError(last_err or "Không sinh được SQL hợp lệ")


# =========================================================================
# MAIN TEST RUNNER
# =========================================================================

def load_questions(n: int) -> List[Dict]:
    """Load DB_ONLY questions from the test file."""
    data = json.loads(QS.read_text(encoding="utf-8"))
    rows = [q for t in data["tables"] for q in t["questions"]
            if q["expected_route"] == "DB_ONLY"]
    return rows[:n]


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=187, help="Number of questions to test")
    ap.add_argument("--model", default=GEMINI_MODEL, help="Gemini model to use")
    args = ap.parse_args()

    # Load API keys
    api_keys = load_api_keys()
    pool = GeminiKeyPool(api_keys, args.model)

    # Load questions
    rows_in = load_questions(args.n)
    print(f"[eval] {len(rows_in)} cau DB_ONLY, uid={TEST_UID[:8]}, model={args.model}", flush=True)

    out_rows = []

    for i, r in enumerate(rows_in):
        q = r["question"]
        row = {"id": r["id"], "question": q, "check_type": r["check_type"],
               "route": None, "route_ok": False, "sql_ok": False,
               "row_count": 0, "non_empty": False, "latency_ms": 0.0,
               "error": None}

        try:
            # Keyword routing (doesn't use LLM)
            route = keyword_fallback(q)
            row["route"] = route
            row["route_ok"] = route in ("DB_ONLY", "HYBRID")

            t = time.perf_counter()
            rows, sql = run_text2sql_gemini(pool, q, TEST_UID)
            row["latency_ms"] = round((time.perf_counter() - t) * 1000, 1)
            row["sql_ok"] = True

            m = re.search(r"số dòng:\s*(\d+)", str(len(rows)))
            row["row_count"] = len(rows)
            row["non_empty"] = len(rows) > 0
            row["sql"] = sql[:200]

        except Exception as e:
            row["error"] = f"{type(e).__name__}: {e}"[:200]

        out_rows.append(row)

        if (i + 1) % 10 == 0:
            print(f"[eval] {i + 1}/{len(rows_in)}", flush=True)

    # Summary
    n = len(out_rows) or 1
    by_type = defaultdict(lambda: [0, 0])
    for r in out_rows:
        ok = r["sql_ok"] and r["non_empty"]
        by_type[r["check_type"]][1] += 1
        by_type[r["check_type"]][0] += ok

    summary = {
        "n": len(out_rows),
        "model": args.model,
        "route_acc": round(sum(1 for r in out_rows if r["route_ok"]) / n, 4),
        "sql_ok": round(sum(1 for r in out_rows if r["sql_ok"]) / n, 4),
        "non_empty": round(sum(1 for r in out_rows if r["non_empty"]) / n, 4),
        "error_rate": round(sum(1 for r in out_rows if r["error"]) / n, 4),
        "latency_mean_ms": round(sum(r["latency_ms"] for r in out_rows) / n, 1),
        "by_check_type": {k: {"pass": v[0], "total": v[1]} for k, v in by_type.items()},
        "key_usage": pool.get_stats(),
    }
    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary[k]]
    }

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps({
        "test_uid": TEST_UID,
        "summary": summary,
        "rows": out_rows
    }, ensure_ascii=False, indent=2), encoding="utf-8")

    print("\n== DB RETRIEVAL (Gemini) ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()