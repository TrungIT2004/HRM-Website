"""
Backfill questions_vector cho toàn bộ chunk đã có trong DB.

Lý do: LocalEmbedder cũ gán questions_vector = content_vector, nên cột
questions_vector trùng 100% content_vector và kênh "hypothetical questions"
(Reverse HyDE) chưa từng chạy. Script này chỉ tính LẠI questions_vector,
không đụng content_vector.

Chạy:  python scripts/backfill_questions_vector.py [--dry-run]
"""
import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
from src.embeddings.local_embedder import LocalEmbedder
from src.db.session import get_db_connection

DIM = 768


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="chỉ báo cáo, không ghi DB")
    args = ap.parse_args()

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute(
        "SELECT c.id, c.hypothetical_questions FROM document_chunks c "
        "JOIN knowledge_documents d ON d.id = c.document_id "
        "WHERE d.status = 'COMPLETED' AND array_length(c.hypothetical_questions, 1) > 0"
    )
    rows = cur.fetchall()
    if not rows:
        print("Không có chunk nào cần backfill.")
        cur.close(); conn.close()
        return 0

    flat = [q for (_, qs) in rows for q in qs]
    print(f"Backfill {len(rows)} chunk, tổng {len(flat)} câu hỏi...")

    embedder = LocalEmbedder()
    vectors = np.asarray(embedder.generate_embeddings_batch(flat), dtype=np.float32)
    assert vectors.shape[1] == DIM, f"Cần {DIM} chiều, model trả {vectors.shape[1]}"

    updates, pos = [], 0
    for chunk_id, questions in rows:
        n = len(questions)
        mean = vectors[pos:pos + n].mean(axis=0)
        pos += n
        norm = float(np.linalg.norm(mean))
        if norm == 0:
            continue
        updates.append(([float(x) for x in (mean / norm)], chunk_id))

    print(f"Chuẩn bị cập nhật {len(updates)} chunk.")
    if args.dry_run:
        cur.close(); conn.close()
        return 0

    for vec, chunk_id in updates:
        cur.execute(
            "UPDATE document_chunks SET questions_vector = %s::vector WHERE id = %s",
            (vec, chunk_id),
        )
    conn.commit()

    cur.execute(
        "SELECT count(*) AS total, "
        "count(*) FILTER (WHERE content_vector::text = questions_vector::text) AS still_equal "
        "FROM document_chunks"
    )
    total, still_equal = cur.fetchone()
    print(f"Xong. Tổng chunk: {total} | còn trùng content_vector: {still_equal}")

    cur.close(); conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
