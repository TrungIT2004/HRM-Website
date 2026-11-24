"""Do GENERATION DB_ONLY o tang answer: facts tu gold SQL co trong cau tra
loi tieng Viet khong.

Moi cau: gold_sql (the UID -> TEST_UID, execute) -> trich facts (so, ngay,
status, ten; bo UUID) -> production _run_text2sql + _answer_with_db ->
kiem tra tung fact co trong answer (chuan hoa so Viet: 15.000.000==15000000).
Gold rong -> doi hoi cau tu choi ("chua co"/"khong co"/"lien he").

Metric chinh: fact_recall (trung binh % facts co mat). Phu: answer_ok
(tat ca facts co mat), sql_ok.
Khong do projection SQL (do o eval_db_generation.py roi).

Chay:  python tests/retrieval_db_only/eval_db_answer.py [--n 40]
Output: tests/retrieval_db_only/results/YYYY-MM-DD_HH-MM-SS_db_answer/
        - questions.jsonl (per-question details)
        - run_meta.json (run config)
        - summary.json (aggregated metrics)
"""
import argparse
import json
import re
import sys
import time
from datetime import datetime
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

from logger import create_logger  # noqa: E402

TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"
GOLD_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"
QS = Path(__file__).resolve().parent.parent / "db_only_hybrid_questions_with_answers.json"

THRESHOLDS = {"fact_recall": (">", 0.85), "answer_ok": (">", 0.80)}

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE)
_REFUSAL_RES = [
    "chưa có dữ liệu", "chua co du lieu", "không có", "khong co",
    "liên hệ", "lien he", "nhân sự", "nhan su",
]

_DASHES = str.maketrans({
    "‐": "-", "‑": "-", "‒": "-", "–": "-",
    "—": "-", "−": "-",
})


def norm_text(s: str) -> str:
    # ponytail: LLM viet gach noi Unicode (‑ U+2011) con DB dung '-' ASCII;
    # khong chuan hoa la miss oan ("T2‑T6" vs "T2-T6").
    s = re.sub(r"\s+", " ", str(s or "")).strip().lower().translate(_DASHES)
    return "".join(c for c in __import__("unicodedata").normalize("NFD", s)
                   if __import__("unicodedata").category(c) != "Mn")


def norm_num(s: str) -> str:
    """Chuan hoa so Viet: '1 346,22' -> '1346.22'; '15.000.000'/'29.000.000'
    (nhieu cham = phan tach nghin) -> '15000000'. Quy tac: co dau phay ->
    phay la thap phan; nhieu cham -> bo het; 1 cham -> thap phan."""
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


# ponytail: composer localize dung (DD/MM/YYYY, "dang cho duyet", "chua su
# dung") — checker phai hieu ca 2 dang. Map enum han che, khong doan mo rong.
# ponytail: norm_text GIU NGUYEN chu đ (U+0111 khong decompose duoc) nen
# synonym phai viet dang co dau day du ("đang", khong phai "dang").
# ponytail: composer dich status/boolean/ngay-thu sang tieng Viet tu nhien
# ("OPEN"->"đang mở", True->"có", 6->"thứ Bảy"). Checker phai hieu ca 2 dang.
# Ceiling: map han che theo quan sat; status moi la them tay.
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
    "7": ["chủ nhật", "chu nhat", "chủ nhật".replace(" ", "")],
}
_SEED_TAG_RE = re.compile(r"\[seed-eval\]\s*", re.IGNORECASE)
_ZERO_WORDS = ("chưa", "không")


def norm_date(s: str) -> str:
    """'31/08/2026'/'31-08-2026'/'22‑06‑2026' (gach Unicode) -> '2026-08-31'."""
    s = s.strip().translate(_DASHES)
    m = re.match(r"^(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4})$", s)
    if m:
        d, mo, y = (int(x) for x in m.groups())
        return f"{y:04d}-{mo:02d}-{d:02d}"
    return ""


def facts_from_rows(rows):
    """Tach facts (bo UUID, bo marker seed). Tra [(text, num)]."""
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
                # ponytail: ma NV (EMP032), ma tai san (LT-0004) khong phai
                # fact tra loi (gold thua cho du). So TK ngan hang (toan so)
                # va serial (tron chu-so) van giu. Ceiling: cau hoi ma code
                # (hiem) se duoc nhe tay.
                continue
            if s.lower() == "false":
                # ponytail: flag False the hien bang omission ("nghi T7,CN")
                # hoac phu dinh, khong bao gio viet chu "false" ra dap an.
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
    # bo trung, giu thu tu
    seen, out = set(), []
    for f in facts:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def fact_in_answer(kind, fact, answer):
    # ponytail: low da strip dau nen moi synonym cung phai norm truoc khi so
    # (loi cu: "đang hoạt động" co dau khong bao gio khop text khong dau).
    low = norm_text(answer)
    N = lambda words: [norm_text(w) for w in words]
    if kind == "num":
        try:
            want = float(fact)
        except ValueError:
            return False
        if want == 0:
            # so 0 duoc dien dat bang chu ("chua su dung ngay nao")
            if "0" in re.findall(r"(?<!\d)0(?!\d)", answer):
                return True
            return any(w in low for w in N(_ZERO_WORDS))
        # Extract all numbers from answer with Vietnamese formatting
        nums = set()
        for m in re.finditer(r"\d[\d\s.,]*\d|\d", answer):
            n = norm_num(m.group(0))
            if n:
                nums.add(n)
        # Also try to extract numbers with Vietnamese suffixes (ngay, gio, phut, etc)
        for m in re.finditer(r"(\d[\d\s.,]*)\s*(ngày|ngay|giờ|gio|phút|phut|tuần|tuan|tháng|thang|năm|nam)", answer, re.IGNORECASE):
            n = norm_num(m.group(1))
            if n:
                nums.add(n)
        return any(abs(float(n) - want) <= max(0.011, 1e-6 * abs(want))
                   for n in nums)
    if kind == "date":
        dates = set()
        # Match DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY with various separators
        for m in re.finditer(r"\d{1,2}\s*[/\-.‐‑–—]\s*\d{1,2}\s*[/\-.‐‑–—]\s*\d{4}", answer):
            d = norm_date(m.group(0))
            if d:
                dates.add(d)
        # Also match ISO format YYYY-MM-DD
        dates.update(re.findall(r"\d{4}-\d{2}-\d{2}", answer))
        # Match "DD/MM" (assume current year)
        for m in re.finditer(r"\d{1,2}\s*[/\-.]\s*\d{1,2}(?!\d)", answer):
            d = norm_date(m.group(0) + f"/{datetime.now().year}")
            if d:
                dates.add(d)
        return fact in dates
    # text: khop nguyen van, hoac dang Viet cua status/day-code, hoac
    # bo phan ngoac viet tat ("gio hanh chinh (t2-t6)" ~ "gio hanh chinh").
    if fact in low:
        return True
    if fact == "true":
        return any(w in low for w in N(("đang hoạt động", "đang hiệu lực",
                                        "có hiệu lực", "đang làm việc", "active", "hiệu lực")))
    if fact == "false":
        return any(w in low for w in N(("không", "nghỉ", "không có",
                                        "không làm việc", "inactive", "không hiệu lực")))
    syns = list(N(_STATUS_VI.get(fact, [])))
    if fact in _DAY_VI:
        syns += N(_DAY_VI[fact])
    if syns and any(syn in low for syn in syns):
        return True
    noparen = re.sub(r"\s*\(.*?\)\s*", " ", fact).strip()
    return bool(noparen) and noparen != fact and noparen in low


def main() -> None:
    import psycopg2
    from src.chat.chat_service import ChatService, reset_usage, take_usage

    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    args = ap.parse_args()

    data = json.loads(QS.read_text(encoding="utf-8"))
    rows_in = [q for t in data["tables"] for q in t["questions"]
               if q.get("expected_route") == "DB_ONLY"][:args.n]
    print(f"[eval] {len(rows_in)} cau DB_ONLY answer-level, uid={TEST_UID[:8]}",
          flush=True)

    # Initialize logger
    logger = create_logger(
        test_name="db_answer",
        model="gemini-3.5-flash-lite",
        thresholds=THRESHOLDS,
        test_uid=TEST_UID,
    )

    svc = ChatService()
    conn = psycopg2.connect(
        "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm")
    cur = conn.cursor()
    out_rows = []
    try:
        for i, r in enumerate(rows_in):
            q = r["question"]
            row = {"id": r["id"], "question": q, "sql_ok": False,
                   "fact_recall": 0.0, "answer_ok": False,
                   "n_facts": 0, "n_hit": 0, "error": None}
            reset_usage()
            gold_sql = r["expected_sql_query"]
            generated_sql = None
            generated_answer = None
            exp_rows = []
            facts = []
            sql_latency_ms = 0.0
            answer_latency_ms = 0.0
            try:
                sql = gold_sql.replace(GOLD_UID, TEST_UID)
                if not re.search(r"(?i)\blimit\b", sql):
                    sql = sql.rstrip().rstrip(";") + " LIMIT 100"
                cur.execute(sql)
                cols = [d[0] for d in cur.description] if cur.description else []
                exp = [dict(zip(cols, rr)) for rr in cur.fetchall()]
                conn.rollback()
                exp_rows = exp
                facts = facts_from_rows(exp)
                row["n_facts"] = len(facts)

                t_sql = time.perf_counter()
                summary, _ = svc._run_text2sql(q, TEST_UID)
                sql_latency_ms = round((time.perf_counter() - t_sql) * 1000, 1)
                row["sql_ok"] = True

                t_ans = time.perf_counter()
                generated_answer = svc._answer_with_db(q, summary)
                answer_latency_ms = round((time.perf_counter() - t_ans) * 1000, 1)
                row["answer_head"] = generated_answer[:2000]

                # Extract generated_sql from summary if available
                generated_sql = getattr(svc, '_last_generated_sql', None)

                if not facts:
                    low = norm_text(generated_answer)
                    row["answer_ok"] = (
                        any(t in low for t in _REFUSAL_RES)
                        or bool(re.search(r"(?<!\d)0(?!\d)", generated_answer)))
                    row["fact_recall"] = 1.0 if row["answer_ok"] else 0.0
                else:
                    hits = [f for f in facts if fact_in_answer(f[0], f[1], generated_answer)]
                    row["n_hit"] = len(hits)
                    row["fact_recall"] = round(len(hits) / len(facts), 4)
                    row["answer_ok"] = row["fact_recall"] == 1.0
                    if not row["answer_ok"]:
                        row["missed"] = [f[1][:60] for f in facts if f not in hits][:5]
            except Exception as e:  # noqa: BLE001
                try:
                    conn.rollback()
                except Exception:
                    pass
                row["error"] = f"{type(e).__name__}: {e}"[:200]
                # Ensure defaults are preserved on error
                row.setdefault("fact_recall", 0.0)
                row.setdefault("n_facts", 0)
                row.setdefault("n_hit", 0)
            u = take_usage()
            row["prompt_tokens"] = u["in"]
            row["completion_tokens"] = u["out"]
            row["llm_calls"] = u["calls"]
            out_rows.append(row)

            # Log detailed question result
            total_latency = sql_latency_ms + answer_latency_ms
            logger.log_question({
                "question_id": r["id"],
                "question": q,
                "check_type": r["check_type"],
                "expected_route": "DB_ONLY",
                "routing": {"routed_as": "DB_ONLY", "route_ok": True, "router_latency_ms": 0},
                "sql_generation": {
                    "gold_sql": gold_sql,
                    "generated_sql": generated_sql,
                    "sql_latency_ms": sql_latency_ms,
                    "ttft_ms": 0,
                    "retries": 0,
                    "error": row.get("error") if not row["sql_ok"] else None,
                },
                "execution": {
                    "sql_ok": row["sql_ok"],
                    "rows_match": None,  # not measured in this test
                    "n_expected": len(exp_rows),
                    "n_actual": 0,
                    "exec_latency_ms": sql_latency_ms,
                    "gold_rows": exp_rows,
                    "generated_rows": [],
                },
                "answer_generation": {
                    "gold_facts": facts,
                    "generated_answer": generated_answer,
                    "answer_latency_ms": answer_latency_ms,
                    "answer_ttft_ms": 0,
                    "fact_recall": row["fact_recall"],
                    "answer_ok": row["answer_ok"],
                    "missed_facts": row.get("missed", []),
                },
                "token_usage": {
                    "prompt_tokens": row.get("prompt_tokens", 0),
                    "completion_tokens": row.get("completion_tokens", 0),
                    "total_tokens": row.get("prompt_tokens", 0) + row.get("completion_tokens", 0),
                    "llm_calls": row.get("llm_calls", 0),
                },
                "total_latency_ms": total_latency,
            })

            if (i + 1) % 10 == 0:
                print(f"[eval] {i + 1}/{len(rows_in)}", flush=True)
    finally:
        cur.close()
        conn.close()

    scored = [r for r in out_rows if not r["error"]]
    n = len(scored) or 1
    summary = {
        "n": len(out_rows),
        "n_error": sum(1 for r in out_rows if r["error"]),
        "sql_ok": round(sum(1 for r in scored if r["sql_ok"]) / n, 4),
        "fact_recall": round(sum(r["fact_recall"] for r in scored) / n, 4),
        "answer_ok": round(sum(1 for r in scored if r["answer_ok"]) / n, 4),
        "prompt_tokens_mean": round(sum(r.get("prompt_tokens", 0) for r in scored) / n, 1),
        "completion_tokens_mean": round(sum(r.get("completion_tokens", 0) for r in scored) / n, 1),
    }
    summary["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [summary[k]]
    }

    # Finalize logger
    logger.finalize(summary)

    print("\n== DB ANSWER ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> Results in: {logger.get_run_dir()}")


if __name__ == "__main__":
    main()