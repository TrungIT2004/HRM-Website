"""Embed lai TOAN BO vectors khi doi embedding model (one-shot/ops).

Dung chinh LocalEmbedder + logic questions_vector nhu ingest (embed_chunks)
nen vector nhat quan voi du lieu ingest moi. Xoa semantic_cache (vector cu
khong tuong thich). Kiem tra 768 chieu truoc khi ghi.

Chay (cwd=ai-service): py -X utf8 scripts/reembed_vectors.py [--dry-run]
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()
from src.db.session import get_db_connection  # noqa: E402
from src.embeddings.local_embedder import LocalEmbedder  # noqa: E402
from src.models.schema import ProcessedChunk  # noqa: E402

DIM = 768


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    embedder = LocalEmbedder()
    print("model:", embedder.model_name)
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, breadcrumb, content, hypothetical_questions FROM document_chunks;")
    rows = cur.fetchall()
    print(f"[reembed] {len(rows)} chunks")
    if a.dry_run:
        return 0
    chunks = [ProcessedChunk(document_name="", breadcrumb=b or "", content=c or "",
                             hypothetical_questions=list(q or []))
              for _, b, c, q in rows]
    chunks = embedder.embed_chunks(chunks, batch_size=32)
    assert all(len(c.content_vector or []) == DIM and len(c.questions_vector or []) == DIM
               for c in chunks), "sai chieu vector!"
    cur.executemany(
        "UPDATE document_chunks SET content_vector = %s::vector, questions_vector = %s::vector WHERE id = %s;",
        [(c.content_vector, c.questions_vector, str(cid)) for c, (cid, _, _, _) in zip(chunks, rows)])
    cur.execute("TRUNCATE semantic_cache;")
    conn.commit()
    print(f"[reembed] xong {len(rows)} chunks + clear semantic_cache")
    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
