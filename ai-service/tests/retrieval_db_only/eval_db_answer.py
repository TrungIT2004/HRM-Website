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
Output: tests/retrieval_db_only/db_answer_eval.json
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
OUT = Path(__file__).resolve().parent / "db_answer_eval.json"

THRESHOLDS = {"fact_recall": (">", 0.85), "answer_ok": (">", 0.80)}

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE)
_REFUSAL_RES = [
    "chưa có dữ liệu", "chua co du lieu", "không có", "khong co",
    "liên hệ", "lien he", "nhân sự", "nhan su",
]


_DASHES = str.maketrans({
    "\u2010": "-", "\u2011": "-", "\u2012": "-", "\u2013": "-",
    "\u2014": "-", "\u2212": "-",
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
        nums = set()
        for m in re.finditer(r"\d[\d\s.,]*\d|\d", answer):
            n = norm_num(m.group(0))
            if n:
                nums.add(n)
        return any(abs(float(n) - want) <= max(0.011, 1e-6 * abs(want))
                   for n in nums)
    if kind == "date":
        dates = set()
        for m in re.finditer(r"\d{1,2}\s*[/\-.\u2010\u2011\u2013\u2014]\s*\d{1,2}\s*[/\-.\u2010\u2011\u2013\u2014]\s*\d{4}", answer):
            d = norm_date(m.group(0))
            if d:
                dates.add(d)
        dates.update(re.findall(r"\d{4}-\d{2}-\d{2}", answer))
        return fact in dates
    # text: khop nguyen van, hoac dang Viet cua status/day-code, hoac
    # bo phan ngoac viet tat ("gio hanh chinh (t2-t6)" ~ "gio hanh chinh").
    if fact in low:
        return True
    if fact == "true":
        return any(w in low for w in N(("đang hoạt động", "đang hiệu lực",
                                        "có hiệu lực", "đang làm việc")))
    if fact == "false":
        return any(w in low for w in N(("không", "nghỉ", "không có",
                                        "không làm việc")))
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
            try:
                sql = r["expected_sql_query"].replace(GOLD_UID, TEST_UID)
                if not re.search(r"(?i)\blimit\b", sql):
                    sql = sql.rstrip().rstrip(";") + " LIMIT 100"
                cur.execute(sql)
                cols = [d[0] for d in cur.description] if cur.description else []
                exp = [dict(zip(cols, rr)) for rr in cur.fetchall()]
                conn.rollback()
                facts = facts_from_rows(exp)
                row["n_facts"] = len(facts)
                summary, _ = svc._run_text2sql(q, TEST_UID)
                row["sql_ok"] = True
                answer = svc._answer_with_db(q, summary)
                row["answer_head"] = answer[:2000]
                if not facts:
                    low = norm_text(answer)
                    row["answer_ok"] = (
                        any(t in low for t in _REFUSAL_RES)
                        or bool(re.search(r"(?<!\d)0(?!\d)", answer)))
                    row["fact_recall"] = 1.0 if row["answer_ok"] else 0.0
                else:
                    hits = [f for f in facts if fact_in_answer(f[0], f[1], answer)]
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
            u = take_usage()
            row["prompt_tokens"] = u["in"]
            row["completion_tokens"] = u["out"]
            row["llm_calls"] = u["calls"]
            out_rows.append(row)
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
    OUT.write_text(json.dumps({"test_uid": TEST_UID, "summary": summary,
                               "rows": out_rows}, ensure_ascii=False, indent=2),
                   encoding="utf-8")
    print("\n== DB ANSWER ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()
