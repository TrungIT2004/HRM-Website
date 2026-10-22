"""Ingest EVALRET corpus với OCR cải tiến (commit永久)."""
import sys
import uuid
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from dotenv import load_dotenv
load_dotenv()

from src.db.session import get_db_connection
from src.embeddings.local_embedder import LocalEmbedder
from src.pipeline import IngestionPipeline
from psycopg2.extras import execute_values

DOCS_DIR = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế")
EVAL_PREFIX = "EVALRET|"

def wipe_existing(cur):
    like = EVAL_PREFIX + "%"
    cur.execute("DELETE FROM document_chunks WHERE document_id IN (SELECT id FROM knowledge_documents WHERE file_name LIKE %s)", (like,))
    cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE %s", (like,))

def main():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        if sys.platform == "win32":
            try:
                sys.stdout.reconfigure(encoding="utf-8")
            except Exception:
                pass
        
        wipe_existing(cur)
        conn.commit()
        
        pipeline = IngestionPipeline(enrich_with_llm=True)
        embedder = LocalEmbedder()
        files = sorted(f for ext in ("*.pdf", "*.docx") for f in DOCS_DIR.glob(ext))
        
        for f in files:
            safe_name = f.name.encode('ascii', 'replace').decode('ascii')
            print(f"[ingest] {safe_name}", flush=True)
            chunks = embedder.embed_chunks(pipeline.process_file(f), batch_size=32)
            did = str(uuid.uuid4())
            cur.execute(
                "INSERT INTO knowledge_documents (id,file_name,file_type,status,file_path,allowed_departments) VALUES (%s,%s,%s,'COMPLETED',%s,ARRAY['ALL'])",
                (did, EVAL_PREFIX + f.name, f.suffix.lstrip("."), str(f)),
            )
            execute_values(cur, """
                INSERT INTO document_chunks (document_id, chunk_index, chunk_type, breadcrumb, content, page_number, summary, keywords, hypothetical_questions, allowed_jobs, allowed_departments, content_vector, questions_vector) VALUES %s;""", [
                (did, i + 1, c.chunk_type, c.breadcrumb, c.content, c.page_number, c.summary, c.keywords, c.hypothetical_questions, c.allowed_jobs, c.allowed_departments, c.content_vector, c.questions_vector) for i, c in enumerate(chunks)
            ])
            conn.commit()
            print(f"[ingest] -> {len(chunks)} chunks", flush=True)
        
        print("[DONE] EVALRET corpus ingested permanently.")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    main()