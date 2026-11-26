#!/usr/bin/env python3
"""
Text-to-SQL test runner using NVIDIA NIM (OpenAI-compatible) with nemotron-3.5-super-vl-120b-a12b.
Runs the 187 DB_ONLY questions from db_only_hybrid_questions.json
"""
import os
import sys
import json
import time
import re
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

# OpenAI SDK (NVIDIA NIM is OpenAI-compatible)
from openai import OpenAI

# =========================================================================
# CONFIGURATION
# =========================================================================

# Test user (Dang Thanh Khai)
TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"

# Questions file
QS = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions.json"
OUT = Path(__file__).resolve().parent / "db_retrieval_eval_nvidia.json"

# Thresholds
THRESHOLDS = {"route_acc": (">", 0.85), "sql_ok": (">", 0.80), "non_empty": (">", 0.70)}

# Model to use (NVIDIA NIM)
NVIDIA_MODEL = "nvidia/nemotron-3.5-super-vl-120b-a12b"

# =========================================================================
# NVIDIA CLIENT POOL (Single client - no key rotation needed for free tier)
# =========================================================================

class NvidiaKeyPool:
    """Manages NVIDIA NIM client for Text2SQL with sliding window rate limiting (40 req/min free tier)."""

    def __init__(self, api_key: str, base_url: str, model: str, rpm: int = 40):
        self.model = model
        self.client = OpenAI(api_key=api_key, base_url=base_url)
        self.usage = {"requests": 0, "errors": 0, "prompt_tokens": 0, "completion_tokens": 0}
        self._rpm = rpm
        self._window_seconds = 60  # 1-minute rolling window
        self._request_timestamps = []  # track request times for sliding window
        print(f"[NVIDIAPool] Initialized with model: {model}, rate limit: {rpm} req/min")

    def _wait_for_slot(self):
        """Wait until we have a slot in the rolling window."""
        import time
        now = time.time()
        # Remove timestamps older than the window
        self._request_timestamps = [t for t in self._request_timestamps if now - t < self._window_seconds]

        if len(self._request_timestamps) >= self._rpm:
            # Wait until oldest request expires
            oldest = self._request_timestamps[0]
            wait_time = self._window_seconds - (now - oldest) + 0.1  # small buffer
            if wait_time > 0:
                print(f"[NVIDIAPool] Rate limit: waiting {wait_time:.1f}s (window: {len(self._request_timestamps)}/{self._rpm})")
                time.sleep(wait_time)
            now = time.time()
            self._request_timestamps = [t for t in self._request_timestamps if now - t < self._window_seconds]

        self._request_timestamps.append(now)

    def generate_sql(self, system_prompt: str, user_prompt: str) -> str:
        """Generate SQL using NVIDIA NIM with sliding window rate limiting and retry on 429/empty."""
        import time
        self._wait_for_slot()
        max_retries = 5  # more retries for rate limits
        base_delay = 2.0

        for attempt in range(max_retries):
            try:
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    temperature=0.0,
                    max_tokens=8192,
                )

                print(f"[NVIDIAPool] Response: finish_reason={response.choices[0].finish_reason}, "
                      f"content_len={len(response.choices[0].message.content or '')}")

                text = response.choices[0].message.content or ""
                self.usage["requests"] += 1

                if response.usage:
                    self.usage["prompt_tokens"] += response.usage.prompt_tokens
                    self.usage["completion_tokens"] += response.usage.completion_tokens

                if text.strip():
                    return text.strip()
                else:
                    finish_reason = response.choices[0].finish_reason
                    if finish_reason == "content_filter":
                        raise RuntimeError("Content filtered by safety system")
                    elif finish_reason == "length":
                        raise RuntimeError("Response truncated (max_tokens)")
                    raise RuntimeError(f"Empty response (finish_reason={finish_reason})")

            except Exception as e:
                self.usage["errors"] += 1
                err_str = str(e)
                print(f"[NVIDIAPool] Attempt {attempt+1}/{max_retries} failed: {err_str}")

                # Check for rate limit (429) or empty response
                is_rate_limit = "429" in err_str or "rate limit" in err_str.lower()
                is_empty = "Empty response" in err_str

                if is_rate_limit or is_empty:
                    if attempt < max_retries - 1:
                        # For rate limits, use longer backoff and wait for window to clear
                        if is_rate_limit:
                            delay = base_delay * (2 ** attempt) * 2  # longer for rate limits
                            print(f"[NVIDIAPool] Rate limited - waiting {delay:.1f}s before retry...")
                            time.sleep(delay)
                            # Clear our tracking to force re-sync with server
                            self._request_timestamps = []
                        else:
                            delay = base_delay * (2 ** attempt)
                            print(f"[NVIDIAPool] Waiting {delay:.1f}s before retry...")
                            time.sleep(delay)
                        continue

                # Non-retryable error
                raise

        raise RuntimeError(f"All {max_retries} attempts failed")

    def get_stats(self) -> Dict:
        return self.usage


# =========================================================================
# LOAD API KEY
# =========================================================================

def load_api_key() -> str:
    """Load NVIDIA API key from environment."""
    # Primary: NVIDIA_API_KEY
    key = os.getenv("NVIDIA_API_KEY")
    if key and key != "your_nvidia_api_key_here":
        print(f"[Config] Loaded NVIDIA_API_KEY from environment")
        return key

    # Fallback: try to find in other common locations
    raise RuntimeError(
        "No NVIDIA API key found. Set NVIDIA_API_KEY in .env file"
    )


# =========================================================================
# TEXT2SQL GENERATION USING NVIDIA
# =========================================================================

def generate_sql_with_nvidia(pool: NvidiaKeyPool, question: str) -> str:
    """Generate SQL using NVIDIA via the client pool."""
    system_prompt = "Trả về duy nhất 1 khối ```sql ... ```."
    user_prompt = build_text2sql_prompt(question)

    raw_response = pool.generate_sql(system_prompt, user_prompt)
    sql = extract_sql(raw_response)
    return sql


def run_text2sql_nvidia(pool: NvidiaKeyPool, question: str, user_id: str) -> Tuple[List[Dict], str]:
    """Run text2sql with NVIDIA: generate -> validate -> execute (with retry)."""
    last_err = ""
    pending_hint = ""

    for attempt in range(2):
        sql = generate_sql_with_nvidia(pool, question)

        if last_err:
            # Re-build prompt with error hint
            user_prompt = build_text2sql_prompt(question) + f"\nLần trước SQL lỗi: {last_err}. Sửa lại cho đúng luật."
            raw_response = pool.generate_sql("Trả về duy nhất 1 khối ```sql ... ```.", user_prompt)
            sql = extract_sql(raw_response)
        elif pending_hint:
            user_prompt = build_text2sql_prompt(question) + pending_hint
            raw_response = pool.generate_sql("Trả về duy nhất 1 khối ```sql ... ```.", user_prompt)
            sql = extract_sql(raw_response)

        try:
            result = run_hrm_query(sql, user_id)
        except (ValueError, RuntimeError) as e:
            last_err = str(e)
            print(f"[Text2SQL-NVIDIA] attempt {attempt} failed: {e}")
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
            print("[Text2SQL-NVIDIA] attempt 0 empty, retry once with latest-period hint")
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
            print(f"[Text2SQL-NVIDIA] attempt 0 shape-bad {result['columns']}, retry once")
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
    ap.add_argument("--model", default=NVIDIA_MODEL, help="NVIDIA model to use")
    ap.add_argument("--base-url", default=os.getenv("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1"),
                    help="NVIDIA NIM base URL")
    ap.add_argument("--rpm", type=int, default=40, help="Rate limit requests per minute")
    args = ap.parse_args()

    # Load API key
    api_key = load_api_key()
    pool = NvidiaKeyPool(api_key, args.base_url, args.model, rpm=args.rpm)

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
            rows, sql = run_text2sql_nvidia(pool, q, TEST_UID)
            row["latency_ms"] = round((time.perf_counter() - t) * 1000, 1)
            row["sql_ok"] = True

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

    print("\n== DB RETRIEVAL (NVIDIA) ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()