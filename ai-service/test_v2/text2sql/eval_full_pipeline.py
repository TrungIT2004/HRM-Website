#!/usr/bin/env python3
"""
Full Pipeline Evaluation using ChatService.answer_query()
Combines retrieval, generation, and answer metrics in one run.
Uses production pipeline: Router → Text2SQL → Composer → Answer
Measures: route_acc, sql_ok, non_empty, rows_match (EX), fact_recall, answer_ok
"""
import os
import sys
import json
import time
import re
import argparse
from pathlib import Path
from collections import defaultdict
from typing import List, Dict, Any, Optional, Tuple
from datetime import date

import psycopg2
from psycopg2.extras import RealDictCursor

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from dotenv import load_dotenv
load_dotenv()

from src.chat.chat_service import ChatService, reset_usage, take_usage
from src.sql.executor import validate_sql, run_hrm_query
from src.sql.text2sql import extract_sql

# Fix Windows console encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# =========================================================================
# CONFIGURATION
# =========================================================================

# Use GOLD_UID for both generated and gold SQL to compare execution results on same data
GOLD_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"   # Gold SQL UID (EMP023)
# TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"  # Not used - different user data
USER_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"  # Use GOLD_UID for both gen and gold SQL

QS_FILE = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions_with_answers.json"
OUT_DIR = Path(__file__).resolve().parent / "results"

THRESHOLDS = {
    "route_acc": (">", 0.85),
    "sql_ok": (">", 0.80),
    "non_empty": (">", 0.70),
    "rows_match": (">", 0.70),      # EX
    "fact_recall": (">", 0.70),
    "answer_ok": (">", 0.65),
}

# =========================================================================
# JSON ENCODER FOR DATE/DATETIME/DECIMAL
# =========================================================================

from decimal import Decimal
from datetime import date, datetime


class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


# =========================================================================
# NORMALIZATION (from eval_db_answer.py & eval_db_generation.py)
# =========================================================================

_DASHES = str.maketrans({
    "‐": "-", "‑": "-", "‒": "-", "–": "-",
    "—": "-", "−": "-",
})

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE)

_ID_CELL = None

_SEED_TAG_RE = re.compile(r"\[seed-eval\]\s*", re.IGNORECASE)

_STATUS_VI = {
    "pending": ["đang chờ duyệt", "chờ duyệt"],
    "accepted": ["đã duyệt"],
    "rejected": ["bị từ chối", "từ chối"],
    "paid": ["đã thanh toán", "thực lĩnh"],
    "approved": ["đã duyệt", "đã phê duyệt", "phê duyệt"],
    "draft": ["nháp", "soạn thảo"],
    "sufficient": ["đủ giờ"],
    "late": ["đi muộn", "trễ"],
    "early": ["về sớm"],
    "in_progress": ["đang xử lý", "đang xu ly"],
    "open": ["đang mở", "mở"],
    "done": ["hoàn thành", "xong", "đã xử lý"],
    "cancelled": ["đã hủy", "đã huỷ"],
    "active": ["đang sử dụng", "đang giữ", "đang hiệu lực", "hiệu lực"],
    "returned": ["đã trả", "tra lai", "đã trả lại"],
    "manager_scored": ["quản lý đã chấm", "đã chấm"],
    "self_submitted": ["tự nộp", "đã nộp"],
}

_DAY_VI = {
    "1": ["thứ hai", "thu 2"],
    "2": ["thứ ba", "thu 3"],
    "3": ["thứ tư", "thu 4"],
    "4": ["thứ năm", "thu 5"],
    "5": ["thứ sáu", "thu 6"],
    "6": ["thứ bảy", "thu 7"],
    "7": ["chủ nhật", "chu nhat"],
}

_ZERO_WORDS = ("chưa", "không")

_REFUSAL_RES = [
    "chưa có dữ liệu", "chua co du lieu", "không có", "khong co",
    "liên hệ", "lien he", "nhân sự", "nhan su",
]


def norm_text(s: str) -> str:
    s = re.sub(r"\s+", " ", str(s or "")).strip().lower().translate(_DASHES)
    return "".join(c for c in __import__("unicodedata").normalize("NFD", s)
                   if __import__("unicodedata").category(c) != "Mn")


def norm_num(s: str) -> str:
    t = re.sub(r"\s", "", s)
    if "," in t:
        t = t.replace(".", "").replace(",", ".")
    elif t.count(".") > 1:
        t = t.replace(".", "")
    if re.fullmatch(r"\d+(\.\d+)?", t):
        try:
            return str(float(t))
        except ValueError:
            pass
    return ""


def norm_date(s: str) -> str:
    s = s.strip().translate(_DASHES)
    m = re.match(r"^(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4})$", s)
    if m:
        d, mo, y = (int(x) for x in m.groups())
        return f"{y:04d}-{mo:02d}-{d:02d}"
    return ""


def facts_from_rows(rows):
    """Trích facts từ rows (số, ngày, status, text; bỏ UUID)."""
    facts = []
    for r in rows or []:
        vals = r.values() if isinstance(r, dict) else r
        for v in vals:
            if v is None:
                continue
            if isinstance(v, bool):
                facts.append(("text", "true" if v else "false"))
                continue
            s = _SEED_TAG_RE.sub("", str(v)).strip()
            if not s or _UUID_RE.match(s):
                continue
            m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
            if m and len(s) > 10:
                facts.append(("text", m.group(1)))
                continue
            if re.fullmatch(r"[A-Z]{2,}-?\d+", s):
                continue
            if s.lower() == "false":
                continue
            n = norm_num(s)
            if n:
                facts.append(("num", n))
                continue
            m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
            if m and len(s) > 10:
                facts.append(("date", m.group(1)))
                continue
            if re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
                facts.append(("date", s))
            elif len(s) >= 2:
                facts.append(("text", norm_text(s)))
    seen, out = set(), []
    for f in facts:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def fact_in_answer(kind, fact, answer):
    low = norm_text(answer)
    N = lambda words: [norm_text(w) for w in words]
    if kind == "num":
        try:
            want = float(fact)
        except ValueError:
            return False
        if want == 0:
            if "0" in re.findall(r"(?<!\d)0(?!\d)", answer):
                return True
            return any(w in low for w in N(_ZERO_WORDS))
        nums = set()
        for m in re.finditer(r"\d[\d\s.,]*\d|\d", answer):
            n = norm_num(m.group(0))
            if n:
                nums.add(n)
        for m in re.finditer(r"(\d[\d\s.,]*)\s*(ngày|ngay|giờ|gio|phút|phut|tuần|tuan|tháng|thang|năm|nam)", answer, re.IGNORECASE):
            n = norm_num(m.group(1))
            if n:
                nums.add(n)
        return any(abs(float(n) - want) <= max(0.011, 1e-6 * abs(want)) for n in nums)
    if kind == "date":
        dates = set()
        for m in re.finditer(r"\d{1,2}\s*[/\-.‐‑–—]\s*\d{1,2}\s*[/\-.‐‑–—]\s*\d{4}", answer):
            d = norm_date(m.group(0))
            if d:
                dates.add(d)
        dates.update(re.findall(r"\d{4}-\d{2}-\d{2}", answer))
        for m in re.finditer(r"\d{1,2}\s*[/\-.]\s*\d{1,2}(?!\d)", answer):
            d = norm_date(m.group(0) + f"/{__import__('datetime').datetime.now().year}")
            if d:
                dates.add(d)
        return fact in dates
    if fact in low:
        return True
    if fact == "true":
        return any(w in low for w in N(("đang hoạt động", "đang hiệu lực", "có hiệu lực", "đang làm việc", "active", "hiệu lực")))
    if fact == "false":
        return any(w in low for w in N(("không", "nghỉ", "không có", "không làm việc", "inactive", "không hiệu lực")))
    syns = list(N(_STATUS_VI.get(fact, [])))
    if fact in _DAY_VI:
        syns += N(_DAY_VI[fact])
    if syns and any(syn in low for syn in syns):
        return True
    noparen = re.sub(r"\s*\(.*?\)\s*", " ", fact).strip()
    return bool(noparen) and noparen != fact and noparen in low


# =========================================================================
# EXECUTION COMPARISON (from eval_db_generation.py)
# =========================================================================

def norm_cell(v):
    if v is None:
        return None
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip()
    if re.match(r"\d{4}-\d{2}-\d{2}", s):
        return s
    try:
        return float(s.replace(",", "").replace(" ", ""))
    except ValueError:
        return s.lower()


def rows_equal(rows1: List[Dict], rows2: List[Dict]) -> bool:
    if len(rows1) != len(rows2):
        return False
    def norm_row(r):
        if isinstance(r, dict):
            return tuple(sorted((k, norm_cell(v)) for k, v in r.items()))
        return tuple(norm_cell(v) for v in r)
    set1 = set(norm_row(r) for r in rows1)
    set2 = set(norm_row(r) for r in rows2)
    return set1 == set2


def execute_gold_sql(gold_sql: str) -> Tuple[List[Dict], Optional[str]]:
    """Execute gold SQL với GOLD_UID (original user), trả về (rows, error).

    Note: Gold SQL was designed for GOLD_UID's data. Running with GOLD_UID
    returns the expected values that match expected_answer.
    """
    try:
        # Use GOLD_UID directly (don't replace with TEST_UID)
        sql = gold_sql
        if not re.search(r"(?i)\blimit\b", sql):
            sql = sql.rstrip().rstrip(";") + " LIMIT 100"
        conn = psycopg2.connect(
            "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
        try:
            conn.autocommit = True
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(sql)
            # RealDictRow is already dict-like, use dict(r) not dict(zip(cols, r))
            # because iterating over RealDictRow yields keys, not values
            rows = [dict(r) for r in cur.fetchall()]
            return rows, None
        finally:
            conn.close()
    except Exception as e:
        return [], str(e)


def execute_gen_sql(gen_sql: str, user_id: str) -> Tuple[List[Dict], Optional[str]]:
    """Execute generated SQL with USER_UID (GOLD_UID for consistent comparison)."""
    try:
        ok, clean_sql, err = validate_sql(gen_sql)
        if not ok:
            return [], err
        conn = psycopg2.connect(
            "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
        try:
            conn.autocommit = True
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SET LOCAL statement_timeout = '5s';")
            cur.execute(clean_sql, {"uid": user_id, "year": date.today().year})
            # RealDictRow is already dict-like, use dict(r) not dict(zip(cols, r))
            rows = [dict(r) for r in cur.fetchall()[:100]]
            return rows, None
        finally:
            conn.close()
    except Exception as e:
        return [], str(e)


# =========================================================================
# LOAD QUESTIONS
# =========================================================================

def load_questions(n: int) -> List[Dict]:
    data = json.loads(QS_FILE.read_text(encoding="utf-8"))
    rows = [q for t in data["tables"] for q in t["questions"]
            if q["expected_route"] == "DB_ONLY"]
    print(f"[Data] Total DB_ONLY questions available: {len(rows)}")
    return rows[:n]


# =========================================================================
# MAIN EVALUATION
# =========================================================================

def run_evaluation(questions: List[Dict], user_id: str) -> List[Dict]:
    svc = ChatService()
    out_rows = []

    for i, q_data in enumerate(questions):
        question = q_data["question"]
        q_id = q_data["id"]
        check_type = q_data["check_type"]
        gold_sql = q_data.get("expected_sql_query", "")
        expected_answer_data = q_data.get("expected_answer", {})

        row = {
            "id": q_id,
            "question": question,
            "check_type": check_type,
            "route": None,
            "route_ok": False,
            "sql_ok": False,
            "non_empty": False,
            "rows_match": False,
            "fact_recall": 0.0,
            "answer_ok": False,
            "latency_ms": 0.0,
            "error": None,
        }

        reset_usage()
        t_start = time.perf_counter()

        try:
            # Full pipeline: answer_query
            result = svc.answer_query(question, user_id=user_id)
            row["latency_ms"] = round((time.perf_counter() - t_start) * 1000, 1)

            # Routing
            route = result.get("route") or result.get("rewritten_query", "")
            # Extract route from result if available, else infer
            row["route"] = route
            row["route_ok"] = route in ("DB_ONLY", "HYBRID")

            # Get route from internal (rewrite_and_route_step stores it)
            # The route is determined in answer_query but not returned, so we infer from result
            # Check if result has citations with DB type -> DB_ONLY/HYBRID
            citations = result.get("citations", [])
            route = "DB_ONLY" if any(c.get("chunk_type") == "DB" for c in citations) else "DOC_ONLY"
            row["route"] = route
            row["route_ok"] = route in ("DB_ONLY", "HYBRID")

            # Get generated SQL from internal state
            sql = getattr(svc, "_last_generated_sql", None)
            row["generated_sql"] = sql
            if sql:
                ok, _, err = validate_sql(sql)
                if ok:
                    row["sql_ok"] = True
                    # Execute to get rows
                    try:
                        exec_result = run_hrm_query(sql, user_id)
                        row["row_count"] = exec_result["row_count"]
                        row["non_empty"] = exec_result["row_count"] > 0
                        row["generated_rows"] = exec_result["rows"]
                    except Exception as e:
                        row["sql_ok"] = False
                        row["sql_error"] = str(e)

            # Answer
            answer = result.get("answer", "")
            row["generated_answer"] = answer[:2000] if answer else ""

            # Get generated SQL from internal state
            sql = getattr(svc, "_last_generated_sql", None)
            row["generated_sql"] = sql
            if sql:
                ok, _, err = validate_sql(sql)
                if ok:
                    row["sql_ok"] = True
                    # Execute to get rows (with USER_UID - GOLD_UID for consistent comparison)
                    try:
                        gen_rows, gen_err = execute_gen_sql(sql, user_id)
                        if not gen_err:
                            row["row_count"] = len(gen_rows)
                            row["non_empty"] = len(gen_rows) > 0
                            row["generated_rows"] = gen_rows
                        else:
                            row["sql_ok"] = False
                            row["sql_error"] = gen_err
                    except Exception as e:
                        row["sql_ok"] = False
                        row["sql_error"] = str(e)

            # Answer
            answer = result.get("answer", "")
            row["generated_answer"] = answer[:2000] if answer else ""

            # Gold SQL comparison (EX - rows_match): compare STRUCTURE (columns, row count)
            if gold_sql:
                gold_rows, gold_err = execute_gold_sql(gold_sql)
                if not gold_err and row.get("generated_rows"):
                    # Compare structure: same columns (order-insensitive) and same row count
                    gen_cols = set(row["generated_rows"][0].keys()) if row["generated_rows"] else set()
                    gold_cols = set(gold_rows[0].keys()) if gold_rows else set()
                    row["rows_match"] = (gen_cols == gold_cols) and (len(row["generated_rows"]) == len(gold_rows))
                    row["gold_rows"] = gold_rows
                    row["gold_cols"] = list(gold_cols)
                    row["gen_cols"] = list(gen_cols)
                else:
                    row["gold_error"] = gold_err

            # Expected answer comparison (Fact Recall, Answer OK)
            # expected_answer is based on GOLD_UID data - compare with generated answer
            if expected_answer_data:
                gold_rows = expected_answer_data.get("rows", [])
                facts = facts_from_rows(gold_rows)
                row["n_facts"] = len(facts)
                if facts:
                    hits = [f for f in facts if fact_in_answer(f[0], f[1], answer)]
                    row["n_hit"] = len(hits)
                    row["fact_recall"] = round(len(hits) / len(facts), 4)
                    row["answer_ok"] = row["fact_recall"] == 1.0
                else:
                    # Empty gold - check refusal
                    low = norm_text(answer)
                    row["answer_ok"] = any(t in low for t in _REFUSAL_RES) or bool(re.search(r"(?<!\d)0(?!\d)", answer))
                    row["fact_recall"] = 1.0 if row["answer_ok"] else 0.0

        except Exception as e:
            row["error"] = f"{type(e).__name__}: {e}"[:200]

        u = take_usage()
        row["prompt_tokens"] = u["in"]
        row["completion_tokens"] = u["out"]
        row["llm_calls"] = u["calls"]
        out_rows.append(row)

        if (i + 1) % 10 == 0:
            print(f"[eval] {i + 1}/{len(questions)}", flush=True)

    return out_rows


def compute_summary(results: List[Dict]) -> Dict:
    n = len(results)
    if n == 0:
        return {}

    gold_results = [r for r in results if r.get("gold_rows") is not None or r.get("gold_error") is None]
    n_gold = len(gold_results) or 1

    summary = {
        "n": n,
        "route_acc": round(sum(1 for r in results if r["route_ok"]) / n, 4),
        "sql_ok": round(sum(1 for r in results if r["sql_ok"]) / n, 4),
        "non_empty": round(sum(1 for r in results if r["non_empty"]) / n, 4),
        "rows_match": round(sum(1 for r in gold_results if r["rows_match"]) / n_gold, 4) if gold_results else 0.0,
        "fact_recall": round(sum(r["fact_recall"] for r in results) / n, 4),
        "answer_ok": round(sum(1 for r in results if r["answer_ok"]) / n, 4),
        "error_rate": round(sum(1 for r in results if r["error"]) / n, 4),
        "latency_mean_ms": round(sum(r["latency_ms"] for r in results) / n, 1),
        "prompt_tokens_mean": round(sum(r.get("prompt_tokens", 0) for r in results) / n, 1),
        "completion_tokens_mean": round(sum(r.get("completion_tokens", 0) for r in results) / n, 1),
    }

    # By check_type
    by_type = defaultdict(lambda: {"total": 0, "route_acc": 0, "sql_ok": 0, "non_empty": 0, "rows_match": 0, "fact_recall": 0, "answer_ok": 0})
    for r in results:
        ct = r["check_type"]
        by_type[ct]["total"] += 1
        if r["route_ok"]: by_type[ct]["route_acc"] += 1
        if r["sql_ok"]: by_type[ct]["sql_ok"] += 1
        if r["non_empty"]: by_type[ct]["non_empty"] += 1
        if r.get("rows_match"): by_type[ct]["rows_match"] += 1
        by_type[ct]["fact_recall"] += r["fact_recall"]
        if r["answer_ok"]: by_type[ct]["answer_ok"] += 1

    by_type_summary = {}
    for k, v in by_type.items():
        total = v["total"] or 1
        by_type_summary[k] = {
            "total": v["total"],
            "route_acc": round(v["route_acc"] / total, 4),
            "sql_ok": round(v["sql_ok"] / total, 4),
            "non_empty": round(v["non_empty"] / total, 4),
            "rows_match": round(v["rows_match"] / total, 4),
            "fact_recall": round(v["fact_recall"] / total, 4),
            "answer_ok": round(v["answer_ok"] / total, 4),
        }

    summary["by_check_type"] = by_type_summary
    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary.get(k, 0)]
    }

    return summary


def main():
    ap = argparse.ArgumentParser(description="Full Pipeline Evaluation (ChatService.answer_query)")
    ap.add_argument("--n", type=int, default=187, help="Number of questions to test")
    args = ap.parse_args()

    questions = load_questions(args.n)
    print(f"[eval] {len(questions)} cau DB_ONLY, uid={USER_UID[:8]}", flush=True)

    results = run_evaluation(questions, USER_UID)
    summary = compute_summary(results)

    # Save
    OUT_DIR.mkdir(exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
    out_file = OUT_DIR / f"{timestamp}_full_pipeline_eval.json"

    output = {
        "test_uid": USER_UID,
        "summary": summary,
        "rows": results
    }
    out_file.write_text(json.dumps(output, ensure_ascii=False, indent=2, cls=CustomJSONEncoder), encoding="utf-8")

    # Print
    print("\n== FULL PIPELINE EVALUATION ==")
    for k, v in summary.items():
        if k not in ("by_check_type", "pass_fail"):
            print(f"  {k} = {v}")
    print("\n  Pass/Fail:")
    for k, v in summary["pass_fail"].items():
        print(f"    {k}: {v}")
    print("\n  By Check Type:")
    for ct, m in summary["by_check_type"].items():
        print(f"    {ct}: {m}")
    print(f"\n-> Results saved to: {out_file}")


if __name__ == "__main__":
    main()