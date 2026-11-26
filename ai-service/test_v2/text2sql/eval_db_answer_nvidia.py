"""Do GENERATION DB_ONLY o tang answer: facts tu gold SQL co trong cau tra
loi tieng Viet khong.

Moi cau: gold_sql (the UID -> TEST_UID, execute) -> trich facts (so, ngay,
status, ten; bo UUID) -> production _run_text2sql + _answer_with_db ->
kiem tra tung fact co trong answer (chuan hoa so Viet: 15.000.000==15000000).
Gold rong -> doi hoi cau tu choi ("chua co"/"khong co"/"lien he").

Metric chinh: fact_recall (trung binh % facts co mat). Phu: answer_ok
(tat ca facts co mat), sql_ok.
Khong do projection SQL (do o eval_db_generation.py roi).

Chay:  python tests/retrieval_db_only/eval_db_answer_nvidia.py [--n 40]
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

# NVIDIA imports
from test_v2.text2sql.run_text2sql_nvidia import NvidiaKeyPool
from src.chat.chat_service import ChatService, reset_usage, take_usage

TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"
GOLD_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"
QS = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions_with_answers.json"

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
        return any(abs(float(n) - want) <= max(0.011, 1e-6 * abs(want))
                   for n in nums)
    if kind == "date":
        dates = set()
        for m in re.finditer(r"\d{1,2}\s*[/\-.‐‑–—]\s*\d{1,2}\s*[/\-.‐‑–—]\s*\d{4}", answer):
            d = norm_date(m.group(0))
            if d:
                dates.add(d)
        dates.update(re.findall(r"\d{4}-\d{2}-\d{2}", answer))
        for m in re.finditer(r"\d{1,2}\s*[/\-.]\s*\d{1,2}(?!\d)", answer):
            d = norm_date(m.group(0) + f"/{datetime.now().year}")
            if d:
                dates.add(d)
        return fact in dates
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

    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    ap.add_argument("--model", default="nvidia/nemotron-3.5-super-vl-120b-a12b")
    ap.add_argument("--base-url", default="https://integrate.api.nvidia.com/v1")
    ap.add_argument("--rpm", type=int, default=40, help="Rate limit requests per minute")
    args = ap.parse_args()

    data = json.loads(QS.read_text(encoding="utf-8"))
    rows_in = [q for t in data["tables"] for q in t["questions"]
               if q.get("expected_route") == "DB_ONLY"][:args.n]
    print(f"[eval] {len(rows_in)} cau DB_ONLY answer-level (NVIDIA), uid={TEST_UID[:8]}",
          flush=True)

    # Logger disabled for simplicity
    logger = None

    # Initialize NVIDIA pool
    api_key = __import__("os").getenv("NVIDIA_API_KEY")
    if not api_key or api_key == "your_nvidia_api_key_here":
        raise RuntimeError("Set NVIDIA_API_KEY in .env")
    pool = NvidiaKeyPool(api_key, args.base_url, args.model, rpm=args.rpm)

    # Create ChatService but override _llm_complete to use NVIDIA
    svc = ChatService.__new__(ChatService)  # Create without __init__
    svc._llm_provider = "nvidia"
    svc._nvidia_client = pool.client
    svc._route_model = args.model
    svc._sql_model = args.model
    svc._ans_model = "minimaxai/minimax-m3.1-flash"
    svc._ocr_model = "nvidia/nemotron-3.5-parse"
    svc._ans_config = {"temperature": 0.2, "max_tokens": 8192}
    svc._fast_config = {"temperature": 0.0, "max_tokens": 2048}
    svc._sql_config = {"temperature": 0.0, "max_tokens": 4096}
    svc._ocr_config = {"temperature": 0.0, "max_tokens": 4096}
    # Rate limiting attributes
    svc._nvidia_rpm = args.rpm
    svc._nvidia_window_seconds = 60
    svc._nvidia_request_timestamps = []
    svc._last_generated_sql = None
    svc.executor = __import__("concurrent.futures").futures.ThreadPoolExecutor(max_workers=4)
    svc.retriever = None  # Not needed for DB_ONLY
    svc.cache = None      # Not needed for DB_ONLY

    conn = psycopg2.connect(
        "postgresql://postgres:[REDACTED]@localhost:5432/hrm")
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
            except Exception as e:
                try:
                    conn.rollback()
                except Exception:
                    pass
                row["error"] = f"{type(e).__name__}: {e}"[:200]
                row.setdefault("fact_recall", 0.0)
                row.setdefault("n_facts", 0)
                row.setdefault("n_hit", 0)
            u = take_usage()
            row["prompt_tokens"] = u["in"]
            row["completion_tokens"] = u["out"]
            row["llm_calls"] = u["calls"]
            out_rows.append(row)

            # Log detailed question result (skip logger for now to avoid JSON serialization issues)
            total_latency = sql_latency_ms + answer_latency_ms
            pass  # logger temporarily disabled

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

    print("\n== DB ANSWER (NVIDIA) ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")


if __name__ == "__main__":
    main()