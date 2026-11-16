"""Batch digest tai lieu doanh nghiep thuc te vao DB, chi Gemini 3.5 Flash Lite OCR anh.

Chay (cwd=ai-service):
  py -X utf8 scripts/ingest_gemini_batch.py [--src "C:/Users/ad/Desktop/RAG-Test-Docs/Tai lieu..."] [--dry-run]

- Quet *.pdf + *.docx, bo .doc/.bak.
- OCR_ONLY_GEMINI=1: tat EasyOCR fallback, chi Gemini OCR anh.
- VISION_MIN_GAP=5: ~12 req/phut, duoi tran 15 RPM. ~141 page ~= 12 phut.
- Fresh: xoa ban ghi cu theo file_name truoc khi ingest (user chon).
- Xuat JSON chunk/file vao out/ de xem.
"""
import argparse
import hashlib
import os
import shutil
import sys
import time
from pathlib import Path

# ponytail: set env truoc import parser (model/gap doc o import-time/call-time).
os.environ.setdefault("OCR_ONLY_GEMINI", "1")
os.environ.setdefault("VISION_MIN_GAP", "5")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()
load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from src.chunkers.legal_chunker import LegalChunker  # noqa: E402
from src.db.session import get_db_connection  # noqa: E402
from src.embeddings.local_embedder import LocalEmbedder  # noqa: E402
from src.metadata.metadata_enricher import MetadataEnricher  # noqa: E402
from src.parsers.docx_parser import DOCXParser  # noqa: E402
from src.parsers.pdf_parser import PDFParser  # noqa: E402
from src.pipeline import IngestionPipeline  # noqa: E402 (chi dung export_to_json)

BASE = Path(__file__).resolve().parent.parent
DOCS_DIR = BASE / "uploads" / "documents"
OUT_DIR = BASE / "out" / "gemini_batch"
DEFAULT_SRC = "C:/Users/ad/Desktop/RAG-Test-Docs/T\u00e0i li\u1ec7u doanh nghi\u1ec7p th\u1ef1c t\u1ebf"


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(8 << 20), b""):
            h.update(b)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=DEFAULT_SRC)
    ap.add_argument("--dry-run", action="store_true", help="chi liet ke file, khong goi Gemini/DB")
    a = ap.parse_args()

    assert "3.5-flash-lite" in os.getenv("GEMINI_OCR_MODEL", ""), "GEMINI_OCR_MODEL phai la gemini-3.5-flash-lite"
    assert os.getenv("GEMINI_API_KEY"), "thieu GEMINI_API_KEY"

    src = Path(a.src)
    files = sorted([p for p in src.iterdir() if p.suffix.lower() in (".pdf", ".docx") and p.is_file()])
    print(f"[batch] {len(files)} file (.pdf/.docx), bo .doc/.bak. uoc tinh ~141 req OCR.")
    for p in files:
        print(f"  - {p.stat().st_size // 1024}KB :: {p.name[:60]}")
    if a.dry_run or not files:
        return 0

    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    chunker = LegalChunker()
    enricher = MetadataEnricher()
    embedder = LocalEmbedder()
    conn = get_db_connection()
    cur = conn.cursor()
    stats = []  # dict/file: parse/chunk/enrich/embed/db/total
    try:
        for src_file in files:
            name = src_file.name
            print(f"\n[batch] === {name} ===", flush=True)
            # ponytail: dem page bang stdlib+pymupdf san co, khong thu vien moi.
            pages, ocr_pages = 0, 0
            try:
                import pymupdf

                if src_file.suffix.lower() == ".pdf":
                    with pymupdf.open(src_file) as d:
                        pages = len(d)
                        ocr_pages = sum(1 for i in range(pages) if d[i].get_images())
            except Exception:
                pass
            print(f"[batch] pages={pages} ocr_pages={ocr_pages}", flush=True)
            t0 = time.perf_counter()
            dst = DOCS_DIR / name
            shutil.copy2(src_file, dst)  # ponytail: overwrite cung ten (fresh), khong _v2 nhu API.
            digest, size = sha256(dst), dst.stat().st_size
            cur.execute("DELETE FROM knowledge_documents WHERE file_name = %s;", (name,))
            cur.execute(
                "INSERT INTO knowledge_documents (file_name, file_type, file_hash, file_path,"
                " file_size, uploaded_by, status, allowed_departments)"
                " VALUES (%s,%s,%s,%s,%s,'ADMIN','PROCESSING',%s) RETURNING id;",
                (name, dst.suffix.lower().lstrip("."), digest, str(dst), size, ["ALL"]),
            )
            doc_id = str(cur.fetchone()[0])
            conn.commit()
            try:
                # 5 chang do gio rieng: parse(OCR) / chunk / enrich(meta) / embed / db-insert.
                t = time.perf_counter()
                parser = PDFParser() if dst.suffix.lower() == ".pdf" else DOCXParser()
                parsed = parser.parse(dst)
                t_parse = time.perf_counter() - t
                t = time.perf_counter()
                chunks = chunker.chunk(parsed)
                for c in chunks:
                    c.allowed_jobs, c.allowed_departments = ["ALL"], ["ALL"]
                t_chunk = time.perf_counter() - t
                t = time.perf_counter()
                chunks = enricher.enrich_all(chunks)
                t_enrich = time.perf_counter() - t
                t = time.perf_counter()
                chunks = embedder.embed_chunks(chunks, batch_size=32)
                t_embed = time.perf_counter() - t
                from psycopg2.extras import execute_values

                t = time.perf_counter()
                execute_values(
                    cur,
                    "INSERT INTO document_chunks (document_id, chunk_index, chunk_type, breadcrumb,"
                    " content, page_number, summary, keywords, hypothetical_questions,"
                    " allowed_jobs, allowed_departments, content_vector, questions_vector)"
                    " VALUES %s;",
                    [(doc_id, i + 1, c.chunk_type, c.breadcrumb, c.content, c.page_number,
                      c.summary, c.keywords, c.hypothetical_questions,
                      c.allowed_jobs, c.allowed_departments, c.content_vector, c.questions_vector)
                     for i, c in enumerate(chunks)],
                )
                cur.execute("UPDATE knowledge_documents SET status='COMPLETED', updated_at=NOW() WHERE id=%s;", (doc_id,))
                conn.commit()
                t_db = time.perf_counter() - t
                IngestionPipeline.export_to_json(chunks, OUT_DIR / f"{dst.stem}.chunks.json")
                dt = t_parse + t_chunk + t_enrich + t_embed + t_db
                stats.append({"name": name, "pages": pages, "ocr": ocr_pages, "n": len(chunks),
                              "parse": t_parse, "chunk": t_chunk, "enrich": t_enrich,
                              "embed": t_embed, "db": t_db, "total": dt})
                print(f"[batch] OK {len(chunks)} chunks in {dt:.1f}s"
                      f" (parse/OCR {t_parse:.1f} | chunk {t_chunk:.1f} | enrich {t_enrich:.1f}"
                      f" | embed {t_embed:.1f} | db {t_db:.1f}) -> {dst.stem}.chunks.json", flush=True)
            except Exception as e:  # noqa: BLE001
                conn.rollback()
                cur.execute("UPDATE knowledge_documents SET status='FAILED', error_message=%s WHERE id=%s;", (str(e)[:2000], doc_id))
                conn.commit()
                stats.append({"name": name, "pages": pages, "ocr": ocr_pages, "n": 0,
                              "parse": 0, "chunk": 0, "enrich": 0, "embed": 0, "db": 0,
                              "total": time.perf_counter() - t0})
                print(f"[batch] FAIL {name}: {e}", flush=True)
    finally:
        cur.close()
        conn.close()
    if stats:
        print("\n[batch] ===== SO LIEU (giay) =====")
        print("  file | trang (OCR) | chunks | parse/OCR | chunk | enrich | embed | db | tong | avg/trangOCR")
        for s in stats:
            avg = s["total"] / s["ocr"] if s["ocr"] else 0
            print(f"  {s['n']:4d} chunks | {s['pages']:3d} ({s['ocr']:3d}) | {s['parse']:7.1f} | {s['chunk']:5.1f}"
                  f" | {s['enrich']:6.1f} | {s['embed']:5.1f} | {s['db']:4.1f} | {s['total']:7.1f}"
                  f" | {avg:5.1f}s | {s['name'][:44]}")
        to, tp = sum(s["total"] for s in stats), sum(s["ocr"] for s in stats)
        print(f"  TONG {tp} ocr-pages / {to:.1f}s = {to / tp:.1f}s/trang (tb), parse/OCR rieng:"
              f" {sum(s['parse'] for s in stats) / tp:.1f}s/trang" if tp else "  (khong co ocr-page)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
