"""Do RETRIEVAL nhanh DB_ONLY: Text-to-SQL -> guard -> execute.

Scope: chi DB_ONLY (HYBRID can them doc corpus + judge cau tra loi, do rieng).
Moi cau: route (keyword, free) + _run_text2sql production (LLM sinh SQL, retry 1).
Metrics: route_acc, sql_ok (sinh + execute duoc), non_empty (co dong),
phan ra theo check_type. Khong goi LLM sinh dap an.

Chay:  python tests/retrieval_db_only/seed_db_eval.py            # seed truoc (1 lan)
        python tests/retrieval_db_only/eval_db_retrieval.py [--n 30]
Output: tests/retrieval_db_only/db_retrieval_eval.json
"""
import argparse
import json
import sys
import time
from collections import defaultdict
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"  # Dang Thanh Khai, joined 2026-01-02
QS = Path(__file__).resolve().parent.parent / "db_only_hybrid_questions.json"
OUT = Path(__file__).resolve().parent / "db_retrieval_eval.json"

# Nguong dat de PASS (de xuat lan dau theo data seed 1 user Jan-Sep 2026;
# hieu chinh sau khi co baseline that).
THRESHOLDS = {"route_acc": (">", 0.85), "sql_ok": (">", 0.80), "non_empty": (">", 0.70)}


def load_rows(n: int) -> list:
    data = json.loads(QS.read_text(encoding="utf-8"))
    rows = [q for t in data["tables"] for q in t["questions"]
            if q["expected_route"] == "DB_ONLY"]
    return rows[:n]


def main() -> None:
    from src.chat.chat_service import ChatService
    from src.sql.router import keyword_fallback

    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    args = ap.parse_args()

    rows_in = load_rows(args.n)
    print(f"[eval] {len(rows_in)} cau DB_ONLY, uid={TEST_UID[:8]}", flush=True)
    svc = ChatService()
    out_rows = []

    for i, r in enumerate(rows_in):
        q = r["question"]
        row = {"id": r["id"], "question": q, "check_type": r["check_type"],
               "route": None, "route_ok": False, "sql_ok": False,
               "row_count": 0, "non_empty": False, "latency_ms": 0.0,
               "error": None}
        try:
            route = keyword_fallback(q)
            row["route"] = route
            row["route_ok"] = route in ("DB_ONLY", "HYBRID")
            t = time.perf_counter()
            summary, _cites = svc._run_text2sql(q, TEST_UID)
            row["latency_ms"] = round((time.perf_counter() - t) * 1000, 1)
            row["sql_ok"] = True
            # summary dang "so dong: N" -> lay N (regex cu tim so TRUOC
            # chu "dong" nen khong bao gio khop, non_empty luon True oan)
            import re
            m = re.search(r"số dòng:\s*(\d+)", summary)
            row["row_count"] = int(m.group(1)) if m else -1
            row["non_empty"] = (row["row_count"] or 0) > 0
            row["summary_head"] = summary[:150]
            row["summary_tail"] = summary[-300:]
        except Exception as e:  # metric loi: SQL sinh hong / execute hong
            row["error"] = f"{type(e).__name__}: {e}"[:200]
        out_rows.append(row)
        if (i + 1) % 10 == 0:
            print(f"[eval] {i + 1}/{len(rows_in)}", flush=True)

    n = len(out_rows) or 1
    by_type = defaultdict(lambda: [0, 0])  # [ok, total] theo check_type
    for r in out_rows:
        ok = r["sql_ok"] and r["non_empty"]
        by_type[r["check_type"]][1] += 1
        by_type[r["check_type"]][0] += ok

    summary = {
        "n": len(out_rows),
        "route_acc": round(sum(1 for r in out_rows if r["route_ok"]) / n, 4),
        "sql_ok": round(sum(1 for r in out_rows if r["sql_ok"]) / n, 4),
        "non_empty": round(sum(1 for r in out_rows if r["non_empty"]) / n, 4),
        "error_rate": round(sum(1 for r in out_rows if r["error"]) / n, 4),
        "latency_mean_ms": round(sum(r["latency_ms"] for r in out_rows) / n, 1),
        "by_check_type": {k: {"pass": v[0], "total": v[1]} for k, v in by_type.items()},
    }
    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary[k]]
    }

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps({"test_uid": TEST_UID, "summary": summary,
                               "rows": out_rows}, ensure_ascii=False, indent=2),
                   encoding="utf-8")
    print("\n== DB RETRIEVAL ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()
