"""Do CHANH XAC + TOC DO retrieval (khong goi LLM sinh dap an).

Do 13/17 thong so retrieval. Bo 5,6 (RAGAS context_precision/recall - can judge
LLM) va 16,17 (token/gia cua condense_question - can LLM): ton token, khong
thuoc nhanh retrieve.

Metrics (nhanh A + B + C + D cua bo dac ta):
  Hit@1/3/5, MRR@5, top1_mean, fallback_rate,
  content_similarity, question_similarity, vector_score, text_rank,
  rerank_gain (top1 va gold-rank co/khong rerank), retrieve_time, rerank_time,
  embed_time, error_rate, rerank_fallback_rate.

Chay tu ai-service:
    python tests/retrieval_doc_only/eval_retrieval.py --n 30      # 30 cau DOC_ONLY
    python tests/retrieval_doc_only/eval_retrieval.py --n 239     # het dataset
Output: tests/retrieval_doc_only/retrieval_eval.json ( tung cau + summary)
"""
import argparse
import csv
import json
import os
import re
import sys
import time
import unicodedata
import uuid
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

TESTSET = Path(__file__).resolve().parent.parent / "generated_testset.csv"
OUT_DIR = Path(__file__).resolve().parent
DOCS_DIR = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế")
EVAL_PREFIX = "EVALRET|"
# ponytail: ten bang backup duy nhat theo PID — 2 lan eval chay chong se khong
# ghi de backup cua nhau (da tung mat ca corpus vi dung chung ten). Ceiling:
# van khong chay song song duoc vi chung prefix EVALRET| (guard ben duoi chan).
import os as _os

BACKUP = f"_eval_backup_{_os.getpid()}"

# Nguong dat trong yeu cau de ket luan PASS/FAIL, khong phai de calibrate.
THRESHOLDS = {
    "hit_at_5": (">", 0.60),
    "mrr_at_5": (">", 0.45),
    "top1_mean": (">", 0.20),
    "fallback_rate": ("<", 0.20),
}


def _fold(text: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", text or "")
                   if unicodedata.category(c) != "Mn").lower()


def _norm(text: str) -> str:
    # ponytail: chunker noi cell/dong bang ' | ' nhung preview trong CSV khong co
    # -> phai chuan hoa separator truoc khi so, neu khong gold-match hut hang
    # loat va Hit@k do thap oan. Ceiling: chi chuan hoa whitespace/separator,
    # khong fold dau (giua nguyen phan biet noi dung).
    t = (text or "").replace("|", " ")
    return re.sub(r"\s+", " ", t).strip().lower()


def load_rows(n: int) -> list:
    """DOC_ONLY theo keyword_fallback cua router (khong ton LLM token)."""
    from src.sql.router import keyword_fallback

    rows = []
    with open(TESTSET, encoding="utf-8-sig") as fh:
        for r in csv.DictReader(fh):
            if "THIEU THONG TIN" in (r.get("answer_draft") or ""):
                continue
            if keyword_fallback(r["question"]) != "DOC_ONLY":
                continue
            rows.append(r)
            if len(rows) >= n:
                break
    return rows


def gold_rank(gold_preview: str, got: list, question: str = "") -> int | None:
    """Rank (1-based) cua chunk dung.
    Thử match needle từ content_preview; nếu fail, fallback match keyword từ câu hỏi."""
    needle = _norm(gold_preview)[:120]
    # Fallback keywords từ câu hỏi (bỏ stopwords đơn giản)
    stop = {"làm", "sao", "để", "cho", "và", "của", "cái", "này", "kia", "có", "không", "được", "là", "gì", "ai", "nào", "trong", "ngoài", "về", "theo", "the"}
    q_words = [w for w in _norm(question).split() if w not in stop and len(w) > 2]
    
    for i, c in enumerate(got):
        hay = _norm(c.get("content"))
        # 1. Thử match preview (ưu tiên)
        if needle and needle in hay:
            return i + 1
        # 2. Fallback: match ≥2 từ khóa câu hỏi
        if q_words:
            hits = sum(1 for w in q_words if w in hay)
            if hits >= 2:
                return i + 1
    return None


# ---------------------------------------------------------------- corpus


def _backup(cur) -> None:
    """Copy corpus cu sang bang tam de do tren corpus SACH, tra lai nguyen
    trang sau khi xong (DB la data dev, khong duoc xoa mat)."""
    cur.execute(f"DROP TABLE IF EXISTS {BACKUP}_chunks, {BACKUP}_docs")
    cur.execute(f"CREATE TABLE {BACKUP}_chunks AS SELECT * FROM document_chunks")
    cur.execute(f"CREATE TABLE {BACKUP}_docs AS SELECT * FROM knowledge_documents")
    cur.execute("DELETE FROM document_chunks")
    cur.execute("DELETE FROM knowledge_documents")


def _restore(cur) -> None:
    cur.execute(f"DELETE FROM document_chunks")
    cur.execute(f"DELETE FROM knowledge_documents")
    # FK: document_chunks.document_id -> knowledge_documents.id, phai insert docs truoc.
    cur.execute(f"INSERT INTO knowledge_documents SELECT * FROM {BACKUP}_docs")
    cur.execute(f"INSERT INTO document_chunks SELECT * FROM {BACKUP}_chunks")
    cur.execute(f"DROP TABLE {BACKUP}_chunks, {BACKUP}_docs")


def _wipe(cur) -> None:
    # ponytail: LIKE can wildcard '%'; ban cu thieu nen chua tung xoa duoc gi,
    # corpus do bi nhiem tu lan chay truoc. Ceiling: prefix EVALRET| la duy nhat.
    like = EVAL_PREFIX + "%"
    cur.execute("DELETE FROM document_chunks WHERE document_id IN "
                "(SELECT id FROM knowledge_documents WHERE file_name LIKE %s)", (like,))
    cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE %s", (like,))


def ingest_corpus(cur):
    """Nap 5 file test (4 PDF scan + 1 docx) vao corpus sach."""
    from psycopg2.extras import execute_values

    from src.embeddings.local_embedder import LocalEmbedder
    from src.pipeline import IngestionPipeline

    _wipe(cur)
    pipeline = IngestionPipeline(enrich_with_llm=True)
    embedder = LocalEmbedder()
    files = sorted(f for ext in ("*.pdf", "*.docx") for f in DOCS_DIR.glob(ext))
    doc_ids = []
    for f in files:
        print(f"[ingest] {f.name}", flush=True)
        chunks = embedder.embed_chunks(pipeline.process_file(f), batch_size=32)
        did = str(uuid.uuid4())
        cur.execute(
            "INSERT INTO knowledge_documents "
            "(id,file_name,file_type,status,file_path,allowed_departments) "
            "VALUES (%s,%s,%s,'COMPLETED',%s,ARRAY['ALL'])",
            (did, EVAL_PREFIX + f.name, f.suffix.lstrip("."), str(f)),
        )
        execute_values(cur, """
            INSERT INTO document_chunks (
                document_id, chunk_index, chunk_type, breadcrumb, content,
                page_number, summary, keywords, hypothetical_questions,
                allowed_jobs, allowed_departments, content_vector, questions_vector
            ) VALUES %s;""", [
            (did, i + 1, c.chunk_type, c.breadcrumb, c.content, c.page_number,
             c.summary, c.keywords, c.hypothetical_questions,
             c.allowed_jobs, c.allowed_departments, c.content_vector, c.questions_vector)
            for i, c in enumerate(chunks)
        ])
        doc_ids.append(did)
        print(f"[ingest] -> {len(chunks)} chunks", flush=True)
    return doc_ids


# ---------------------------------------------------------------- metrics


def summarize(rows: list) -> dict:
    n = len(rows) or 1
    scored = [r for r in rows if not r["error"]]
    top1 = [r["top1_score"] for r in scored]

    def hits(k):
        return sum(1 for r in scored if r["gold_rank"] and r["gold_rank"] <= k) / n

    def mean(key):
        return round(sum(r[key] for r in scored) / len(scored), 4) if scored else 0.0

    s = {
        "n": len(rows),
        "n_scored": len(scored),
        "hit_at_1": round(hits(1), 4),
        "hit_at_3": round(hits(3), 4),
        "hit_at_5": round(hits(5), 4),
        "mrr_at_5": round(sum(1.0 / r["gold_rank"] for r in scored
                              if r["gold_rank"] and r["gold_rank"] <= 5) / n, 4),
        "top1_mean": round(sum(top1) / len(top1), 4) if top1 else 0.0,
        "fallback_rate": round(sum(1 for r in scored if r["fallback"]) / n, 4),
        "content_similarity": mean("content_similarity"),
        "question_similarity": mean("question_similarity"),
        "vector_score": mean("vector_score"),
        "text_rank": mean("text_rank"),
        "rerank_gain_hit@5": round(
            sum(1 for r in scored if r["gold_rank_norerank"] and r["gold_rank_norerank"] <= 5) / n, 4),
        "rerank_gain_top1": round(
            sum(r["top1_score"] - r["top1_score_norerank"] for r in scored) / n, 4),
        "retrieve_time": mean("retrieve_time"),
        "rerank_time": mean("rerank_time"),
        "embed_time": mean("embed_time"),
        "error_rate": round(sum(1 for r in rows if r["error"]) / n, 4),
        "rerank_fallback_rate": round(
            sum(1 for r in rows if r["rerank_fallback"]) / n, 4),
    }
    s["pass_fail"] = {
        k: ("PASS" if (v > t if op == ">" else v < t) else "FAIL")
        for k, (op, t) in THRESHOLDS.items()
        for v in [s[k]]
    }
    return s


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=30)
    ap.add_argument("--top-k", type=int, default=5)
    ap.add_argument("--reuse", action="store_true",
                    help="Dung corpus EVALRET san co, bo qua backup+ingest+restore.")
    ap.add_argument("--keep", action="store_true",
                    help="Giu corpus EVALRET sau khi xong (de lan sau --reuse).")
    args = ap.parse_args()

    from src.chat.chat_service import RELEVANCE_THRESHOLD
    from src.db.session import get_db_connection
    from src.retrievers.hybrid_retriever import HybridRetriever

    rows_in = load_rows(args.n)
    print(f"[eval] {len(rows_in)} cau DOC_ONLY | threshold={RELEVANCE_THRESHOLD}", flush=True)

    ret = HybridRetriever()
    rerank_off = ret.reranker is None or ret.reranker.model is None

    conn = get_db_connection()
    cur = conn.cursor()
    out_rows = []
    reuse = False
    try:
        if args.reuse:
            cur.execute("SELECT count(*) FROM knowledge_documents WHERE file_name LIKE %s",
                        (EVAL_PREFIX + "%",))
            reuse = (cur.fetchone() or [0])[0] > 0
            if reuse:
                print("[eval] reuse corpus EVALRET san co", flush=True)
        if not reuse:
            # Chong 2 lan eval chay chong len nhau (cung prefix EVALRET + bang
            # backup): thay corpus giua chung -> mat du lieu nhu da tung xay ra.
            cur.execute("SELECT count(*) FROM knowledge_documents WHERE file_name LIKE %s",
                        (EVAL_PREFIX + "%",))
            if (cur.fetchone() or [0])[0]:
                raise RuntimeError(
                    "Corpus EVALRET dang ton tai (co the do lan chay khac). "
                    "Dung --reuse hoac doi lan kia xong.")
            _backup(cur)
            conn.commit()
            ingest_corpus(cur)
            conn.commit()

        for i, r in enumerate(rows_in):
            q = r["question"]
            row = {
                "question": q,
                "source_file": r.get("source_file"),
                "error": None,
                "rerank_fallback": rerank_off,
            }
            try:
                t = time.perf_counter()
                ret.embedder.generate_embedding(q, task_type="retrieval_query")
                row["embed_time"] = (time.perf_counter() - t) * 1000

                t = time.perf_counter()
                got = ret.retrieve(query=q, jobs=["ALL"], departments=["ALL"],
                                   top_k=args.top_k)
                row["retrieve_time"] = (time.perf_counter() - t) * 1000

                t = time.perf_counter()
                raw = ret.retrieve(query=q, jobs=["ALL"], departments=["ALL"],
                                   top_k=args.top_k, use_reranker=False)
                row["retrieve_time_norerank"] = (time.perf_counter() - t) * 1000
                # rerank chi them giua 2 lan -> tach ra de khong lan SQL.
                row["rerank_time"] = row["retrieve_time"] - row["retrieve_time_norerank"]

                top = got[0] if got else {}
                row.update({
                    "top1_score": top.get("relevance_score", 0.0),
                    "fallback": (not got) or top.get("relevance_score", 0.0) < RELEVANCE_THRESHOLD,
                    "content_similarity": top.get("content_similarity", 0.0),
                    "question_similarity": top.get("question_similarity", 0.0),
                    "vector_score": top.get("vector_score", 0.0),
                    "text_rank": top.get("text_rank", 0.0),
                    "gold_rank": gold_rank(r.get("content_preview", ""), got, q),
                    "top1_score_norerank": raw[0]["relevance_score"] if raw else 0.0,
                    "gold_rank_norerank": gold_rank(r.get("content_preview", ""), raw, q),
                    "top1_breadcrumb": top.get("breadcrumb", "")[:120],
                })
            except Exception as e:  # loi SQL/embedding -> metric 14
                row["error"] = f"{type(e).__name__}: {e}"[:200]
            out_rows.append(row)
            if (i + 1) % 10 == 0:
                print(f"[eval] {i + 1}/{len(rows_in)}", flush=True)

        summary = summarize(out_rows)
    finally:
        if not reuse and not args.keep:
            _wipe(cur)
            conn.commit()
            _restore(cur)
            conn.commit()
        else:
            print("[eval] giu corpus EVALRET cho lan chay sau", flush=True)
        cur.close()
        conn.close()

    OUT_DIR.mkdir(exist_ok=True)
    (OUT_DIR / "retrieval_eval.json").write_text(
        json.dumps({"threshold": RELEVANCE_THRESHOLD, "top_k": args.top_k,
                    "summary": summary, "rows": out_rows}, ensure_ascii=False, indent=2),
        encoding="utf-8")

    print("\n== RETRIEVAL ==")
    for k, v in summary.items():
        print(f"  {k} = {v}")
    print(f"\n-> tests/retrieval_doc_only/retrieval_eval.json")


if __name__ == "__main__":
    main()