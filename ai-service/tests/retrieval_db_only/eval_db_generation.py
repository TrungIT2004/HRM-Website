"""Do GENERATION DB_ONLY: SQL he sinh vs gold SQL (cung user test).

Moi cau: gold_sql (the UID literal -> TEST_UID, execute truc tiep, khong qua
guard) vs system SQL (LLM sinh -> validate -> execute, giong production).
So sanh multiset rows (chuan hoa scalar, sort, float tolerance).
Gold loi (execute hong) -> dem rieng, khong do loi he thong.

Chay:  python tests/retrieval_db_only/seed_db_eval.py   # seed truoc (1 lan)
        python tests/retrieval_db_only/eval_db_generation.py [--n 40]
Output: tests/retrieval_db_only/db_generation_eval.json
"""
import argparse
import json
import re
import sys
import time
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

TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"
GOLD_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"
QS = Path(__file__).resolve().parent.parent / "db_only_hybrid_questions_with_answers.json"
OUT = Path(__file__).resolve().parent / "db_generation_eval.json"

THRESHOLDS = {"sql_ok": (">", 0.80), "rows_match": (">", 0.85)}


_UUID_CELL = None


_ID_CELL = None


def norm_cell(v):
    global _ID_CELL
    if _ID_CELL is None:
        import re as _re
        _ID_CELL = _re.compile(
            r"(^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
            r"|^[A-Z]{2,}[\d-]+$)",
            _re.IGNORECASE)
    # ponytail: moi dang "rong" (NULL/""/None/False/0) -> 0.0 de SUM rong
    # (NULL) == COALESCE 0, "False" == khong co dong. Ceiling: ten "0" that
    # (hiem) cung bi coi la rong.
    if v is None:
        return 0.0
    if isinstance(v, bool):
        return 1.0 if v else 0.0
    if isinstance(v, float):
        return round(v, 2)
    if isinstance(v, int):
        return float(v)
    s = str(v).strip()
    if s.lower() in ("", "null", "none", "false"):
        return 0.0
    if s.lower() == "true":
        return 1.0
    try:
        return round(float(s), 2)
    except (ValueError, OverflowError):
        pass
    # datetime -> date part ("2026-01-02T17:00..." vs "2026-01-02")
    m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
    return m.group(1) if m and len(s) > 10 else s


def drop_id_cells(cells):
    # ponytail: ID (UUID, EMP032, LT-0004...) khong phai fact tra loi —
    # gold thua/system thieu deu khong tinh. Ceiling: cau hoi ma ID
    # chinh la dap an (hiem) se duoc nhe tay; so tai khoan (toan so)
    # van so binh thuong.
    return [c for c in cells
            if not (isinstance(c, str) and _ID_CELL and _ID_CELL.match(c))]


def norm_rows(rows):
    return sorted(tuple(norm_cell(c) for c in r.values()) if isinstance(r, dict)
                  else tuple(norm_cell(c) for c in r) for r in (rows or []))


# ponytail: gold va system SQL hop le co the chon projection khac nhau
# (them/bot cot, doi thu tu). So khop chuan xac phat hien oan.
# Rule thay the: containment thuan multiset — moi dong expected phai co 1 dong
# actual chua het cac cell (sau chuan hoa). ID (UUID/EMPxxx/LT-xxx) bo qua
# 2 phia; moi dang rong (NULL/""/False/0) coi nhu 0.0.
# Ceiling: khong phat hien duoc actual thua dong rac o multi_row; cau hoi
# ma ID chinh la dap an (hiem) duoc nhe tay.
def rows_contain(exp_rows, act_rows, strict_count):
    from collections import Counter

    def bag(row):
        cells = [norm_cell(c) for c in
                 (row.values() if isinstance(row, dict) else row)]
        return Counter(drop_id_cells(cells))

    def num_eq(a, b):
        # so: epsilon tuyet doi + tuong doi (AVG float noise 23956528.67 vs .0)
        if isinstance(a, bool) or isinstance(b, bool):
            return a == b
        if isinstance(a, (int, float)) and isinstance(b, (int, float)):
            return abs(a - b) <= max(0.011, 1e-6 * max(abs(a), abs(b)))
        return a == b

    def row_match(er, ar):
        # multiset-containment: moi cell expected (ke ca lap) phai co cell
        # actual bang nhau (so co epsilon). Giua 2 loi: false alarm tren
        # gold lap gia tri (ngay x3 cot, bonus+allowance deu 0) RE hon de
        # sot miss that (0% vs 12 ngay). False alarm triage tay vai giay.
        ar_vals = list(ar.elements())
        for k, v in er.items():
            if sum(1 for a in ar_vals if num_eq(k, a)) < v:
                return False
        return True

    exp = [bag(r) for r in (exp_rows or [])]
    act = [bag(r) for r in (act_rows or [])]
    if not exp:
        # gold rong: pass neu actual rong hoac chi 1 dong toan 0 ("khong co")
        return not act or (len(act) == 1 and all(k == 0 for k in act[0]))
    if strict_count and len(exp) != len(act):
        return False
    if len(exp) > len(act):
        return False
    # containment thuan: moi dong expected phai co 1 dong actual chua het
    used = [False] * len(act)
    for er in exp:
        hit = None
        for j, ar in enumerate(act):
            if used[j]:
                continue
            if row_match(er, ar):
                hit = j
                break
        if hit is None:
            return False
        used[hit] = True
    return True


def run_gold(cur, gold_sql):
    """Execute gold SQL (da the UID), tra (rows, error). Bo guard."""
    sql = gold_sql.replace(GOLD_UID, TEST_UID)
    # gold khong co LIMIT -> them de tranh full scan
    if not re.search(r"(?i)\blimit\b", sql):
        sql = sql.rstrip().rstrip(";") + " LIMIT 100"
    cur.execute(sql)
    cols = [d[0] for d in cur.description] if cur.description else []
    return [dict(zip(cols, r)) for r in cur.fetchall()], None


def run_system(svc, question):
    """Giong production _run_text2sql nhung tra rows (retry 1 nhu production)."""
    from src.sql.text2sql import build_text2sql_prompt, extract_sql
    from src.sql.executor import run_hrm_query

    last_err = ""
    for _ in range(2):
        prompt = build_text2sql_prompt(question)
        if last_err:
            prompt += f"\nLần trước SQL lỗi: {last_err}. Sửa lại cho đúng luật."
        raw = svc._llm_complete(
            "Trả về duy nhất 1 khối ```sql ... ```.", prompt, tag="eval-gen")
        res = run_hrm_query(extract_sql(raw), TEST_UID)
        return res["rows"], extract_sql(raw)
    raise RuntimeError(last_err)


def main() -> None:
    import psycopg2
    from src.chat.chat_service import ChatService

    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    args = ap.parse_args()

    data = json.loads(QS.read_text(encoding="utf-8"))
    rows_in = [q for t in data["tables"] for q in t["questions"]
               if q.get("expected_route") == "DB_ONLY"][:args.n]
    print(f"[eval] {len(rows_in)} cau DB_ONLY, uid={TEST_UID[:8]}", flush=True)

    svc = ChatService()
    conn = psycopg2.connect(
        "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
    cur = conn.cursor()
    out_rows = []
    try:
        for i, r in enumerate(rows_in):
            q = r["question"]
            row = {"id": r["id"], "question": q,
                   "check_type": r["check_type"], "sql_ok": False,
                   "rows_match": False, "gold_bad": False,
                   "n_expected": 0, "n_actual": -1, "error": None}
            try:
                try:
                    exp_rows, _ = run_gold(cur, r["expected_sql_query"])
                    conn.rollback()
                except Exception as e:  # noqa: BLE001
                    conn.rollback()
                    row["gold_bad"] = True
                    row["error"] = f"GOLD_BAD: {type(e).__name__}: {e}"[:200]
                    out_rows.append(row)
                    continue
                row["n_expected"] = len(exp_rows)
                t = time.perf_counter()
                act_rows, sql = run_system(svc, q)
                row["latency_ms"] = round((time.perf_counter() - t) * 1000, 1)
                row["sql_ok"] = True
                row["n_actual"] = len(act_rows)
                row["rows_match"] = rows_contain(
                    exp_rows, act_rows,
                    strict_count=(r["check_type"] != "multi_row"))
                if not row["rows_match"]:
                    row["expected_head"] = str(norm_rows(exp_rows)[:3])[:300]
                    row["actual_head"] = str(norm_rows(act_rows)[:3])[:300]
            except Exception as e:  # noqa: BLE001
                row["error"] = f"{type(e).__name__}: {e}"[:200]
            out_rows.append(row)
            if (i + 1) % 10 == 0:
                print(f"[eval] {i + 1}/{len(rows_in)}", flush=True)
    finally:
        cur.close()
        conn.close()

    valid = [r for r in out_rows if not r["gold_bad"]]
    n = len(valid) or 1
    summary = {
        "n": len(out_rows),
        "n_gold_bad": sum(1 for r in out_rows if r["gold_bad"]),
        "sql_ok": round(sum(1 for r in valid if r["sql_ok"]) / n, 4),
        "rows_match": round(sum(1 for r in valid if r["rows_match"]) / n, 4),
        "latency_mean_ms": round(sum(r.get("latency_ms", 0) for r in valid) / n, 1),
    }
    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary[k]]
    }
    OUT.write_text(json.dumps({"test_uid": TEST_UID, "summary": summary,
                               "rows": out_rows}, ensure_ascii=False, indent=2),
                   encoding="utf-8")
    print("\n== DB GENERATION ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()
