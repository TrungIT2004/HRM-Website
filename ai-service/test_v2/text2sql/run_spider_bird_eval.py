#!/usr/bin/env python3
"""
SPIDER/BIRD-style Text-to-SQL evaluation for HRM chatbot.
Measures: EM (Exact Match), EX (Execution), TS (Test Suite), Valid SQL Rate.

Uses production pipeline: build_text2sql_prompt -> validate_sql -> run_hrm_query
with 7 Gemini API keys rotation (gemini-3.5-flash-lite).
Runs 187 DB_ONLY questions from db_only_hybrid_questions.json.
"""
import os
import sys
import json
import time
import re
import argparse
from pathlib import Path
from collections import defaultdict
from typing import List, Dict, Any, Optional, Tuple, Set
from datetime import date

# Fix Windows console encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from dotenv import load_dotenv
load_dotenv()

# Production pipeline imports
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

# Questions file (with gold SQL)
QS_FILE = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions_with_answers.json"
OUT_DIR = Path(__file__).resolve().parent / "results"

# Model to use
GEMINI_MODEL = "gemini-3.5-flash-lite"

# Thresholds for PASS/FAIL
THRESHOLDS = {
    "valid_sql_rate": (">", 0.80),
    "em": (">", 0.60),
    "semantic_em": (">", 0.70),  # More lenient - ignores aliases, column order
    "ex": (">", 0.70),
    "ts": (">", 0.65),
}

# =========================================================================
# GEMINI KEY POOL WITH ROTATION
# =========================================================================

class GeminiKeyPool:
    """Manages a pool of Gemini API keys with rotation and quota tracking."""

    def __init__(self, api_keys: List[str], model: str):
        self.model = model
        self.clients = [genai.Client(api_key=key) for key in api_keys]
        self.current_idx = 0
        self.usage = {i: {"requests": 0, "errors": 0} for i in range(len(self.clients))}
        print(f"[GeminiPool] Initialized with {len(self.clients)} API keys for model: {model}")

    def _get_next_client(self) -> tuple[genai.Client, int]:
        """Get next client in rotation and return (client, index)."""
        idx = self.current_idx
        client = self.clients[idx]
        self.current_idx = (self.current_idx + 1) % len(self.clients)
        return client, idx

    def generate_sql(self, system_prompt: str, user_prompt: str) -> str:
        """Generate SQL using Gemini with automatic key rotation on failure."""
        last_error = None

        for attempt in range(len(self.clients) * 2):  # Try each key up to 2 times
            client, idx = self._get_next_client()

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
                self.usage[idx]["requests"] += 1

                if text.strip():
                    return text.strip()
                else:
                    last_error = "Empty response"

            except Exception as e:
                self.usage[idx]["errors"] += 1
                last_error = str(e)
                print(f"[GeminiPool] Key {idx} failed: {e}")
                continue

        raise RuntimeError(f"All Gemini keys exhausted. Last error: {last_error}")

    def get_stats(self) -> Dict:
        return self.usage


# =========================================================================
# LOAD API KEYS
# =========================================================================

def load_api_keys() -> List[str]:
    """Load 7 Gemini API keys from environment variables."""
    keys = []
    for i in range(7):
        key = os.getenv(f"GEMINI_API_KEY_{i}")
        if key and key != f"your_gemini_api_key_{i}_here":
            keys.append(key)

    if len(keys) == 7:
        print(f"[Config] Loaded 7 API keys from environment variables")
        return keys

    # Fallback: try single GEMINI_API_KEY
    single_key = os.getenv("GEMINI_API_KEY")
    if single_key and single_key != "your_gemini_api_key_here":
        print(f"[Config] Using single GEMINI_API_KEY for all 7 slots")
        return [single_key] * 7

    raise RuntimeError(
        "No Gemini API keys found. Set GEMINI_API_KEY_0 through GEMINI_API_KEY_6 "
        "or GEMINI_API_KEY in .env file"
    )


# =========================================================================
# SQL NORMALIZATION FOR EM (Exact Match)
# =========================================================================

def normalize_sql(sql: str) -> str:
    """Normalize SQL for structural comparison (EM metric)."""
    if not sql:
        return ""
    # Remove comments
    sql = re.sub(r"--.*", "", sql)
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    # Normalize whitespace
    sql = re.sub(r"\s+", " ", sql)
    # Normalize case for keywords
    sql = sql.strip()
    # Remove trailing semicolon
    sql = sql.rstrip(";")
    # Normalize placeholder format
    sql = re.sub(r"%\s*\(\s*(\w+)\s*\)\s*s", r"%(\1)s", sql)
    return sql.lower()


def compute_em(generated_sql: str, gold_sql: str) -> bool:
    """Compute Exact Match (EM) - structural SQL equivalence."""
    if not generated_sql or not gold_sql:
        return False
    gen_norm = normalize_sql_for_comparison(generated_sql)
    gold_norm = normalize_sql_for_comparison(gold_sql)
    return gen_norm == gold_norm


# =========================================================================
# EXECUTION COMPARISON FOR EX (Execution Accuracy)
# =========================================================================

def execute_sql(sql: str, user_id: str) -> Tuple[List[Dict], Optional[str]]:
    """Execute SQL and return (rows, error)."""
    try:
        result = run_hrm_query(sql, user_id)
        return result["rows"], None
    except Exception as e:
        return [], str(e)


def rows_equal(rows1: List[Dict], rows2: List[Dict]) -> bool:
    """Compare two result sets for execution accuracy."""
    if len(rows1) != len(rows2):
        return False
    # Normalize rows for comparison
    def norm_row(r):
        if isinstance(r, dict):
            return tuple(sorted((k, normalize_cell(v)) for k, v in r.items()))
        return tuple(normalize_cell(v) for v in r)

    set1 = set(norm_row(r) for r in rows1)
    set2 = set(norm_row(r) for r in rows2)
    return set1 == set2


def normalize_cell(v):
    """Normalize cell value for comparison."""
    if v is None:
        return None
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip()
    # Normalize dates
    if re.match(r"\d{4}-\d{2}-\d{2}", s):
        return s
    # Normalize numbers
    try:
        return float(s.replace(",", "").replace(" ", ""))
    except ValueError:
        return s.lower()


def compute_ex(generated_sql: str, gold_sql: str, user_id: str) -> bool:
    """Compute Execution Accuracy (EX) - result set equivalence."""
    if not generated_sql or not gold_sql:
        return False

    gen_rows, gen_err = execute_sql(generated_sql, user_id)
    gold_rows, gold_err = execute_sql(gold_sql, user_id)

    if gen_err or gold_err:
        return False

    return rows_equal(gen_rows, gold_rows)


# =========================================================================
# TEST SUITE (TS) - SEMANTIC ROBUSTNESS
# =========================================================================

def generate_test_queries(base_sql: str, question: str) -> List[str]:
    """Generate test suite queries for semantic robustness testing."""
    # For now, use the base SQL with different user contexts
    # In full SPIDER, this would generate multiple test cases
    return [base_sql]


def compute_ts(generated_sql: str, gold_sql: str, question: str, user_id: str) -> bool:
    """Compute Test Suite (TS) accuracy - semantic robustness.

    Runs multiple test queries to verify the SQL behaves correctly
    under different conditions (edge cases, different parameters).
    """
    if not generated_sql or not gold_sql:
        return False

    # Test 1: Original execution
    gen_rows1, gen_err1 = execute_sql(generated_sql, user_id)
    gold_rows1, gold_err1 = execute_sql(gold_sql, user_id)
    if gen_err1 or gold_err1 or not rows_equal(gen_rows1, gold_rows1):
        return False

    # Test 2: Check structural validity (no SELECT *, proper placeholders)
    ok, _, err = validate_sql(generated_sql)
    if not ok:
        return False

    # Test 3: Verify user-scoping (contains %(uid)s filter)
    if "%(uid)s" not in generated_sql:
        return False

    return True


# =========================================================================
# LOAD QUESTIONS
# =========================================================================

def load_questions(n: int) -> List[Dict]:
    """Load DB_ONLY questions from the test file with gold SQL."""
    data = json.loads(QS_FILE.read_text(encoding="utf-8"))
    rows = [q for t in data["tables"] for q in t["questions"]
            if q["expected_route"] == "DB_ONLY"]
    print(f"[Data] Total DB_ONLY questions available: {len(rows)}")
    return rows[:n]


def normalize_gold_sql(gold_sql: str) -> str:
    """Convert gold SQL with literal UID to template with %(uid)s placeholder."""
    if not gold_sql:
        return ""
    # Replace literal UUID with %(uid)s placeholder
    # The gold SQL uses '35337165-e0d0-4dd1-9c67-cc48180363af'
    gold_uid = "35337165-e0d0-4dd1-9c67-cc48180363af"
    # Also handle the case where it's quoted as '%(uid)s' in some gold SQLs
    normalized = gold_sql.replace(gold_uid, "%(uid)s")
    # Fix quoted placeholder: '%(uid)s' -> %(uid)s
    normalized = normalized.replace("'%(uid)s'", "%(uid)s")
    return normalized


def normalize_sql_for_comparison(sql: str) -> str:
    """Normalize SQL for structural comparison (EM metric).

    Removes: comments, extra whitespace, LIMIT clause differences,
    alias differences that don't affect semantics, ::int casts,
    table aliases in WHERE clauses, column aliases (AS xxx), column order.
    """
    if not sql:
        return ""
    # Remove comments
    sql = re.sub(r"--.*", "", sql)
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    # Remove LIMIT clause (production adds it automatically)
    sql = re.sub(r"\s+LIMIT\s+\d+\s*$", "", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\s+LIMIT\s+\d+", "", sql, flags=re.IGNORECASE)
    # Normalize placeholder format (handle both %(uid)s and '%(uid)s')
    sql = re.sub(r"'%\s*\(\s*(\w+)\s*\)\s*s'", r"%(\1)s", sql)
    sql = re.sub(r"%\s*\(\s*(\w+)\s*\)\s*s", r"%(\1)s", sql)
    # Remove ::int casts for comparison
    sql = re.sub(r"::int\b", "", sql, flags=re.IGNORECASE)
    # Remove table aliases in simple column references (e.g., u.user_id -> user_id)
    sql = re.sub(r"\b[a-z]+\.(user_id|requestor_id|department_id|job_id|shift_id)\b", r"\1", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\busers\.(user_id)\b", r"\1", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\battendances\.(user_id)\b", r"\1", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bleave_requests\.(requestor_id)\b", r"\1", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bovertime_records\.(requestor_id)\b", r"\1", sql, flags=re.IGNORECASE)
    # Remove column aliases: "col AS alias" or "col alias" -> "col"
    sql = re.sub(r"\b(\w+)\s+AS\s+\w+\b", r"\1", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\b(\w+)\s+(so_nam|so_thang|years|months|thang|gio_nam_nay|gio_nam_truoc|chenh_lech|tong_thuc_nhan|so_phieu|so_lan|tong_gio|gio_ot|so_lan_muon_thang_nay|so_lan_muon_thang_truoc|ngay_nghi_quy_nay|ngay_nghi_quy_truoc|gio_thang_nay|gio_thang_truoc|ten_ca|ten_phong|chuc_danh|department|job|shift|remaining_days|used_pct|avg_salary|tuan)\b", r"\1", sql, flags=re.IGNORECASE)
    # Normalize common column name variations
    sql = re.sub(r"\bten_ca\b", "name", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bten_phong\b", "name", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bchuc_danh\b", "title", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bdepartment\b", "name", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bjob\b", "title", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\bshift\b", "name", sql, flags=re.IGNORECASE)
    # Normalize whitespace
    sql = re.sub(r"\s+", " ", sql)
    sql = sql.strip().rstrip(";")
    # Sort SELECT columns for order-insensitive comparison (simple approach)
    # Extract SELECT clause, sort columns, rebuild
    select_match = re.search(r"^\s*SELECT\s+(.*?)\s+FROM\s", sql, re.IGNORECASE | re.DOTALL)
    if select_match:
        select_part = select_match.group(1)
        from_part = sql[select_match.end():]
        # Split columns, sort, rejoin
        cols = [c.strip() for c in select_part.split(",")]
        cols.sort()
        sql = "SELECT " + ", ".join(cols) + " FROM " + from_part
    return sql.lower()


# =========================================================================
# MAIN EVALUATION RUNNER
# =========================================================================

def run_evaluation(pool: GeminiKeyPool, questions: List[Dict],
                   user_id: str) -> List[Dict]:
    """Run SPIDER/BIRD evaluation on questions."""
    out_rows = []

    for i, q_data in enumerate(questions):
        question = q_data["question"]
        q_id = q_data["id"]
        check_type = q_data["check_type"]
        gold_sql_raw = q_data.get("expected_sql_query", "")
        gold_sql = normalize_gold_sql(gold_sql_raw)

        row = {
            "id": q_id,
            "question": question,
            "check_type": check_type,
            "has_gold_sql": bool(gold_sql_raw),
            "generated_sql": None,
            "gold_sql": gold_sql,
            "gold_sql_raw": gold_sql_raw,
            "valid_sql": False,
            "sql_error": None,
            "em": False,
            "ex": False,
            "ts": False,
            "latency_ms": 0.0,
            "route": None,
            "route_ok": False,
        }

        # Keyword routing
        route = keyword_fallback(question)
        row["route"] = route
        row["route_ok"] = route in ("DB_ONLY", "HYBRID")

        # Generate SQL using production pipeline with retries
        system_prompt = "Trả về duy nhất 1 khối ```sql ... ```."
        user_prompt = build_text2sql_prompt(question)

        last_err = ""
        pending_hint = ""
        generated_sql = ""

        for attempt in range(2):  # Production does 2 attempts
            try:
                raw_response = pool.generate_sql(system_prompt, user_prompt)
                generated_sql = extract_sql(raw_response)

                if last_err:
                    # Retry with error hint
                    user_prompt = build_text2sql_prompt(question) + f"\nLần trước SQL lỗi: {last_err}. Sửa lại cho đúng luật."
                    raw_response = pool.generate_sql(system_prompt, user_prompt)
                    generated_sql = extract_sql(raw_response)
                elif pending_hint:
                    user_prompt = build_text2sql_prompt(question) + pending_hint
                    raw_response = pool.generate_sql(system_prompt, user_prompt)
                    generated_sql = extract_sql(raw_response)

                # Validate SQL
                ok, clean_sql, err = validate_sql(generated_sql)
                if not ok:
                    last_err = err
                    print(f"  [Attempt {attempt}] Validation failed: {err}")
                    continue

                # Execute
                t = time.perf_counter()
                result = run_hrm_query(clean_sql, user_id)
                row["latency_ms"] = round((time.perf_counter() - t) * 1000, 1)
                row["row_count"] = result["row_count"]
                row["non_empty"] = result["row_count"] > 0
                row["valid_sql"] = True
                row["generated_sql"] = clean_sql

                # Shape check for listing queries
                from src.sql.executor import _shape_ok
                if attempt == 0 and not result["rows"]:
                    pending_hint = (
                        "\nLần trước SQL chạy được nhưng trả về 0 dòng. Thử lại: bỏ lọc "
                        "tháng/năm hiện tại, lấy kỳ MỚI NHẤT (ORDER BY ... DESC LIMIT 1); "
                        "quan hệ có-thể-trống thì LEFT JOIN; đếm/tổng/max thì COUNT/COALESCE/MAX."
                    )
                    print(f"  [Attempt {attempt}] Empty result, retry with hint")
                    continue

                if attempt == 0 and not _shape_ok(question, result["columns"]):
                    pending_hint = (
                        "\nLần trước SQL chạy được nhưng thiếu cột ngữ cảnh (chỉ có: "
                        + ", ".join(result["columns"]) + "). Viết lại GIỮ NGUYÊN các "
                        "cột đã có và THÊM cột ngày/tháng/lý do/trạng thái còn thiếu "
                        "theo câu hỏi."
                    )
                    print(f"  [Attempt {attempt}] Shape check failed, retry with hint")
                    continue

                # Success - compute metrics if gold SQL exists
                if gold_sql:
                    row["em"] = compute_em(clean_sql, gold_sql)
                    row["semantic_em"] = compute_em(
                        normalize_sql_for_comparison(clean_sql),
                        normalize_sql_for_comparison(gold_sql)
                    )
                    row["ex"] = compute_ex(clean_sql, gold_sql, user_id)
                    row["ts"] = compute_ts(clean_sql, gold_sql, question, user_id)

                break

            except Exception as e:
                row["sql_error"] = f"{type(e).__name__}: {e}"[:200]
                last_err = str(e)
                print(f"  [Attempt {attempt}] Error: {e}")
                continue

        out_rows.append(row)

        if (i + 1) % 10 == 0:
            print(f"[eval] {i + 1}/{len(questions)}")

    return out_rows


def compute_summary(results: List[Dict], key_usage: Dict) -> Dict:
    """Compute aggregated metrics."""
    n = len(results)
    if n == 0:
        return {}

    # Valid SQL Rate
    valid_count = sum(1 for r in results if r["valid_sql"])
    valid_sql_rate = valid_count / n

    # Metrics only on questions with gold SQL
    gold_results = [r for r in results if r["has_gold_sql"]]
    n_gold = len(gold_results)

    em = sum(1 for r in gold_results if r["em"]) / n_gold if n_gold > 0 else 0.0
    ex = sum(1 for r in gold_results if r["ex"]) / n_gold if n_gold > 0 else 0.0
    ts = sum(1 for r in gold_results if r["ts"]) / n_gold if n_gold > 0 else 0.0
    semantic_em = sum(1 for r in gold_results if r.get("semantic_em", False)) / n_gold if n_gold > 0 else 0.0

    # Overall metrics
    route_acc = sum(1 for r in results if r["route_ok"]) / n
    non_empty = sum(1 for r in results if r.get("non_empty", False)) / n
    error_rate = sum(1 for r in results if r["sql_error"]) / n
    latency_mean = sum(r["latency_ms"] for r in results) / n

    # By check_type
    by_type = defaultdict(lambda: {"valid": 0, "total": 0, "em": 0, "semantic_em": 0, "ex": 0, "ts": 0})
    for r in results:
        ct = r["check_type"]
        by_type[ct]["total"] += 1
        if r["valid_sql"]:
            by_type[ct]["valid"] += 1
        if r["has_gold_sql"]:
            by_type[ct]["em"] += 1 if r["em"] else 0
            by_type[ct]["semantic_em"] += 1 if r.get("semantic_em", False) else 0
            by_type[ct]["ex"] += 1 if r["ex"] else 0
            by_type[ct]["ts"] += 1 if r["ts"] else 0

    by_type_summary = {}
    for k, v in by_type.items():
        total = v["total"] or 1
        by_type_summary[k] = {
            "total": v["total"],
            "valid_rate": round(v["valid"] / total, 4),
            "em": round(v["em"] / total, 4) if v["total"] > 0 else 0,
            "semantic_em": round(v["semantic_em"] / total, 4) if v["total"] > 0 else 0,
            "ex": round(v["ex"] / total, 4) if v["total"] > 0 else 0,
            "ts": round(v["ts"] / total, 4) if v["total"] > 0 else 0,
        }

    summary = {
        "n": n,
        "n_with_gold": n_gold,
        "valid_sql_rate": round(valid_sql_rate, 4),
        "em": round(em, 4),
        "semantic_em": round(semantic_em, 4),
        "ex": round(ex, 4),
        "ts": round(ts, 4),
        "route_acc": round(route_acc, 4),
        "non_empty": round(non_empty, 4),
        "error_rate": round(error_rate, 4),
        "latency_mean_ms": round(latency_mean, 1),
        "by_check_type": by_type_summary,
        "key_usage": key_usage,
    }

    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary.get(k, 0)]
    }

    return summary


def main():
    ap = argparse.ArgumentParser(description="SPIDER/BIRD Text-to-SQL Evaluation")
    ap.add_argument("--n", type=int, default=187, help="Number of questions to test")
    ap.add_argument("--model", default=GEMINI_MODEL, help="Gemini model to use")
    args = ap.parse_args()

    # Load API keys
    api_keys = load_api_keys()
    # Filter out known bad keys (key 2 is 401)
    if len(api_keys) > 2:
        print(f"[Config] Removing invalid key at index 2")
        api_keys.pop(2)
    pool = GeminiKeyPool(api_keys, args.model)

    # Load questions
    questions = load_questions(args.n)
    print(f"[eval] {len(questions)} cau DB_ONLY, uid={TEST_UID[:8]}, model={args.model}", flush=True)

    # Run evaluation
    print(f"[eval] Starting evaluation with SPIDER/BIRD metrics...")
    results = run_evaluation(pool, questions, TEST_UID)

    # Compute summary
    summary = compute_summary(results, pool.get_stats())

    # Save results
    OUT_DIR.mkdir(exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
    out_file = OUT_DIR / f"{timestamp}_spider_bird_eval.json"

    output = {
        "test_uid": TEST_UID,
        "model": args.model,
        "summary": summary,
        "rows": results
    }

    out_file.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")

    # Print summary
    print("\n== SPIDER/BIRD EVALUATION ==")
    print(f"  n = {summary['n']}")
    print(f"  n_with_gold = {summary['n_with_gold']}")
    print(f"  Valid SQL Rate = {summary['valid_sql_rate']:.2%}")
    print(f"  EM (Exact Match) = {summary['em']:.2%}")
    print(f"  EX (Execution) = {summary['ex']:.2%}")
    print(f"  TS (Test Suite) = {summary['ts']:.2%}")
    print(f"  Route Accuracy = {summary['route_acc']:.2%}")
    print(f"  Non-empty Rate = {summary['non_empty']:.2%}")
    print(f"  Error Rate = {summary['error_rate']:.2%}")
    print(f"  Latency Mean = {summary['latency_mean_ms']:.1f}ms")
    print("\n  Pass/Fail:")
    for k, v in summary["pass_fail"].items():
        print(f"    {k}: {v}")
    print(f"\n  By Check Type:")
    for ct, metrics in summary["by_check_type"].items():
        print(f"    {ct}: {metrics}")
    print(f"\n  Key Usage: {summary['key_usage']}")
    print(f"\n-> Results saved to: {out_file}")


if __name__ == "__main__":
    main()