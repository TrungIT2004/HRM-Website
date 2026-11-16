"""End-to-end HYBRID evaluation: DB_ONLY + DOC_ONLY trong 1 cau hoi.

Truy van can ca du lieu ca nhan (DB) va quy dinh chung (DOC).
VD: "Toi co bao nhieu ngay phep con lai theo quy dinh?" -> can so ngay tu DB + quy dinh tu DOC.

Khong co gold SQL cho HYBRID (chi co needs_columns) -> chi do chat luong
dap an bang fact extraction tu citations va answer.

Chay: python test_v2/hybrid/eval_hybrid.py --n 30
Output: test_v2/outputs/hybrid_eval.json
"""
import argparse
import json
import re
import sys
import time
from pathlib import Path

from test_v2.common import setup_test_env, DB_ONLY_HYBRID_QUESTIONS_WITH_ANSWERS, TEST_UID, get_output_path
from src.sql.executor import generate_personal_rows, summarize_result, scoped_tables_in, directory_lines
from src.chat.chat_service import ChatService

setup_test_env()

THRESHOLDS = {
    "sql_ok": (">", 0.85),
    "fact_recall": (">", 0.75),
    "answer_ok": (">", 0.70),
    "has_db_facts": (">", 0.50),  # it nhat 50% cau co fact DB
    "has_doc_facts": (">", 0.50),  # it nhat 50% cau co fact DOC
}

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE)
_REFUSAL_RES = [
    "chưa có dữ liệu", "chua co du lieu", "không có", "khong co",
    "liên hệ", "lien he", "nhân sự", "nhan su",
]
_DASHES = str.maketrans({"‐": "-", "‑": "-", "‒": "-", "–": "-", "—": "-", "−": "-"})


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
    "1": ["thứ hai", "thu 2"], "2": ["thứ ba", "thu 3"],
    "3": ["thứ tư", "thu 4"], "4": ["thứ năm", "thu 5"],
    "5": ["thứ sáu", "thu 6"], "6": ["thứ bảy", "thu 7"],
    "7": ["chủ nhật", "chu nhat"],
}
_SEED_TAG_RE = re.compile(r"\[seed-eval\]\s*", re.IGNORECASE)
_ZERO_WORDS = ("chưa", "không")


def norm_date(s: str) -> str:
    s = s.strip().translate(_DASHES)
    m = re.match(r"^(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4})$", s)
    if m:
        d, mo, y = (int(x) for x in m.groups())
        return f"{y:04d}-{mo:02d}-{d:02d}"
    return ""


def facts_from_rows(rows, source_tag: str):
    """Tach facts, danh dau nguon: 'db' hoac 'doc'."""
    facts = []
    for r in rows or []:
        vals = r.values() if isinstance(r, dict) else r
        for v in vals:
            if v is None:
                continue
            if isinstance(v, bool):
                facts.append((source_tag, "text", "true" if v else "false"))
                continue
            s = _SEED_TAG_RE.sub("", str(v)).strip()
            if not s or _UUID_RE.match(s):
                continue
            m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
            if m and len(s) > 10:
                facts.append((source_tag, "text", m.group(1)))
                continue
            if re.fullmatch(r"[A-Z]{2,}-?\d+", s):
                continue
            if s.lower() == "false":
                continue
            n = norm_num(s)
            if n:
                facts.append((source_tag, "num", n))
                continue
            m = re.match(r"^(\d{4}-\d{2}-\d{2})", s)
            if m and len(s) > 10:
                facts.append((source_tag, "date", m.group(1)))
                continue
            if re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
                facts.append((source_tag, "date", s))
            elif len(s) >= 2:
                facts.append((source_tag, "text", norm_text(s)))
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
        return any(abs(float(n) - want) <= max(0.011, 1e-6 * abs(want)) for n in nums)
    if kind == "date":
        dates = set()
        for m in re.finditer(r"\d{1,2}\s*[/\-.‐‑–—]\s*\d{1,2}\s*[/\-.‐‑–—]\s*\d{4}", answer):
            d = norm_date(m.group(0))
            if d:
                dates.add(d)
        dates.update(re.findall(r"\d{4}-\d{2}-\d{2}", answer))
        return fact in dates
    if fact in low:
        return True
    if fact == "true":
        return any(w in low for w in N(("đang hoạt động", "đang hiệu lực", "có hiệu lực", "đang làm việc")))
    if fact == "false":
        return any(w in low for w in N(("không", "nghỉ", "không có", "không làm việc")))
    syns = list(N(_STATUS_VI.get(fact, [])))
    if fact in _DAY_VI:
        syns += N(_DAY_VI[fact])
    if syns and any(syn in low for syn in syns):
        return True
    noparen = re.sub(r"\s*\(.*?\)\s*", " ", fact).strip()
    return bool(noparen) and noparen != fact and noparen in low


def classify_fact_kind(fact_text: str) -> str:
    """Phan loai fact thuoc ve DB hay DOC dua vao noi dung."""
    # So lieu ca nhan (so ngay, so tien, ngay thang ca nhan) -> DB
    db_keywords = ["ngày phép", "ngay phep", "lương", "luong", "thu nhập", "thu nhap",
                   "tiền", "tien", "ngày công", "ngay cong", "giờ", "gio",
                   "overtime", "ot", "phép", "phep", "nghỉ", "nghi",
                   "ngày làm", "ngay lam", "ca làm", "ca lam"]
    # Quy dinh chung, ten quy che, dieu luat -> DOC
    doc_keywords = ["quy định", "quy dinh", "luật", "luat", "điều", "dieu",
                    "chính sách", "chinh sach", "quy chế", "quy che",
                    "thâm niên", "tham nien", "nghỉ cưới", "nghi cuoi",
                    "nghỉ thai sản", "nghi thai san", "nghỉ ốm", "nghi om",
                    "bảo hiểm", "bao hiem", "bhxh", "bhyt", "bhtn",
                    "hợp đồng", "hop dong", "thử việc", "thu viec"]
    low = norm_text(fact_text)
    for kw in db_keywords:
        if kw in low:
            return "db"
    for kw in doc_keywords:
        if kw in low:
            return "doc"
    return "unknown"


def extract_facts_from_citations(citations: list) -> list:
    """Extract facts from DOC citations (chunk content)."""
    doc_facts = []
    for c in citations or []:
        content = c.get("content") or c.get("chunk_content", "")
        if content:
            for sent in re.split(r"[.!?]", content):
                sent = sent.strip()
                if len(sent) >= 10:
                    doc_facts.append(("doc", "text", norm_text(sent)))
    return doc_facts


def main() -> None:
    import psycopg2
    from src.chat.chat_service import ChatService, reset_usage, take_usage

    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=30)
    args = ap.parse_args()

    OUT = get_output_path("hybrid_eval.json")

    data = json.loads(DB_ONLY_HYBRID_QUESTIONS_WITH_ANSWERS.read_text(encoding="utf-8"))
    # Lay cac cau co expected_route la HYBRID
    rows_in = [q for t in data["tables"] for q in t["questions"]
               if q.get("expected_route") == "HYBRID"][:args.n]
    print(f"[eval] {len(rows_in)} cau HYBRID end-to-end, uid={TEST_UID[:8]}", flush=True)

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
                   "has_db_facts": False, "has_doc_facts": False,
                   "n_db_facts": 0, "n_doc_facts": 0,
                   "n_db_hit": 0, "n_doc_hit": 0, "error": None}
            reset_usage()
            try:
                # 1. Chay production pipeline (generate_personal_rows -> summary -> _answer_with_hybrid with DOC retrieval)
                from src.utils.llm_completion import complete_sql
                rows, sql = generate_personal_rows(complete_sql, q, TEST_UID)
                row["sql_ok"] = True

                tables = scoped_tables_in(sql)
                summary = summarize_result({"rows": rows, "row_count": len(rows)}, tables)
                people = directory_lines(rows)
                if people:
                    summary += "\nNgười liên quan:\n" + "\n".join(people)
                db_citations = [{
                    "document_name": "Dữ liệu cá nhân HRM",
                    "breadcrumb": t,
                    "page_number": None,
                    "file_url": None,
                    "chunk_type": "DB",
                    "relevance_score": 1.0,
                } for t in tables]

                # 2. Retrieve DOC chunks via HybridRetriever
                doc_chunks = svc.retriever.retrieve(
                    query=q, jobs=["ALL"], departments=["ALL"], top_k=4, use_reranker=True
                )

                # 3. Call new _answer_with_hybrid method
                answer = svc._answer_with_hybrid(q, summary, doc_chunks)

                # 4. Build citations from both DB and DOC
                doc_citations_for_eval = []
                for c in doc_chunks:
                    doc_citations_for_eval.append({
                        "document_name": c["document_name"],
                        "breadcrumb": c["breadcrumb"],
                        "page_number": c["page_number"],
                        "file_url": c["file_url"],
                        "chunk_type": c["chunk_type"],
                        "relevance_score": c["relevance_score"],
                        "content": c.get("content", "")
                    })
                all_citations = doc_citations_for_eval + db_citations

                # 5. Extract facts
                db_facts = facts_from_rows(rows, "db")
                doc_facts = extract_facts_from_citations(all_citations)

                all_facts = db_facts + doc_facts
                row["n_db_facts"] = len(db_facts)
                row["n_doc_facts"] = len(doc_facts)

                # Phan loai fact
                db_facts_final = []
                doc_facts_final = []
                for src, kind, val in all_facts:
                    if src == "db":
                        db_facts_final.append((kind, val))
                    else:
                        cls = classify_fact_kind(val)
                        if cls == "doc":
                            doc_facts_final.append((kind, val))
                        elif cls == "db":
                            db_facts_final.append((kind, val))
                        else:
                            doc_facts_final.append((kind, val))  # default DOC

                row["n_db_facts"] = len(db_facts_final)
                row["n_doc_facts"] = len(doc_facts_final)
                row["has_db_facts"] = len(db_facts_final) > 0
                row["has_doc_facts"] = len(doc_facts_final) > 0

                if not db_facts_final and not doc_facts_final:
                    low = norm_text(answer)
                    row["answer_ok"] = (
                        any(t in low for t in _REFUSAL_RES)
                        or bool(re.search(r"(?<!\d)0(?!\d)", answer)))
                    row["fact_recall"] = 1.0 if row["answer_ok"] else 0.0
                else:
                    db_hits = [f for f in db_facts_final if fact_in_answer(f[0], f[1], answer)]
                    doc_hits = [f for f in doc_facts_final if fact_in_answer(f[0], f[1], answer)]
                    row["n_db_hit"] = len(db_hits)
                    row["n_doc_hit"] = len(doc_hits)
                    total_facts = len(db_facts_final) + len(doc_facts_final)
                    total_hits = len(db_hits) + len(doc_hits)
                    row["fact_recall"] = round(total_hits / total_facts, 4) if total_facts > 0 else 1.0
                    row["answer_ok"] = row["fact_recall"] == 1.0
                    if not row["answer_ok"]:
                        missed = []
                        for f in db_facts_final:
                            if f not in db_hits:
                                missed.append(f"DB:{f[1][:60]}")
                        for f in doc_facts_final:
                            if f not in doc_hits:
                                missed.append(f"DOC:{f[1][:60]}")
                        row["missed"] = missed[:5]

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
        "has_db_facts": round(sum(1 for r in scored if r["has_db_facts"]) / n, 4),
        "has_doc_facts": round(sum(1 for r in scored if r["has_doc_facts"]) / n, 4),
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
    print("\n== HYBRID END-TO-END ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()