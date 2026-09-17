from typing import List, Dict, Any, Optional
from pathlib import Path
import re

from src.embeddings.gemini_embedder import GeminiEmbedder
from src.db.session import get_db_connection


class HybridRetriever:
    """
    Hybrid Search combining:
    1. Multi-Vector Dense Search (Content Vector + Hypothetical Questions Vector)
    2. Keyword overlap boost (BM25-style signal)
    3. RBAC & Department security filters
    """

    def __init__(self):
        self.embedder = GeminiEmbedder()

    def retrieve(
        self,
        query: str,
        roles: Optional[List[str]] = None,
        departments: Optional[List[str]] = None,
        top_k: int = 4
    ) -> List[Dict[str, Any]]:
        if not query or not query.strip():
            return []

        user_roles = roles or ["ROLE_EMPLOYEE"]
        user_depts = departments or ["ALL"]

        # 1. Embed query with Gemini (task_type=retrieval_query)
        query_vector = self.embedder.generate_embedding(query, task_type="retrieval_query")

        # 2. Extract significant query words for keyword matching
        words = re.findall(r'\b[A-Za-zÀ-ỹ0-9_/%-]{2,}\b', query.lower())
        query_keywords = list(dict.fromkeys(words))

        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            # Hybrid search query:
            # - Multi-Vector: GREATEST(content_sim, question_sim)
            # - Keyword boost: +0.03 if any keyword in document matches
            sql = """
                SELECT 
                    c.id, c.document_id, c.chunk_index, c.chunk_type, c.breadcrumb, c.content, c.page_number,
                    c.summary, c.keywords, c.hypothetical_questions, c.allowed_roles, c.allowed_departments,
                    d.file_name, d.file_path,
                    (1 - (c.content_vector <=> %s::vector)) AS content_similarity,
                    (1 - (c.questions_vector <=> %s::vector)) AS question_similarity,
                    GREATEST(
                        (1 - (c.content_vector <=> %s::vector)),
                        (1 - (c.questions_vector <=> %s::vector))
                    ) AS vector_score
                FROM document_chunks c
                JOIN knowledge_documents d ON c.document_id = d.id
                WHERE d.status = 'COMPLETED'
                  AND (c.allowed_roles && %s::varchar[] OR 'ALL' = ANY(c.allowed_roles))
                  AND (c.allowed_departments && %s::varchar[] OR 'ALL' = ANY(c.allowed_departments))
                ORDER BY vector_score DESC
                LIMIT %s;
            """

            cursor.execute(
                sql,
                (
                    query_vector, query_vector, query_vector, query_vector,
                    user_roles, user_depts, top_k
                )
            )

            rows = cursor.fetchall()
            results = []

            for r in rows:
                (
                    chunk_id, doc_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                    summary, keywords, questions, allowed_roles, allowed_depts,
                    file_name, file_path, content_sim, question_sim, vector_score
                ) = r

                # Calculate final hybrid score with keyword overlap bonus
                keyword_bonus = 0.0
                if keywords and query_keywords:
                    overlap = set(k.lower() for k in keywords).intersection(set(query_keywords))
                    if overlap:
                        keyword_bonus = min(0.08, len(overlap) * 0.02)

                final_score = float(vector_score or 0.0) + keyword_bonus
                file_url = f"/static/documents/{Path(file_path).name}" if file_path else None

                results.append({
                    "chunk_id": str(chunk_id),
                    "document_id": str(doc_id),
                    "document_name": file_name,
                    "file_url": file_url,
                    "chunk_index": chunk_index,
                    "chunk_type": chunk_type,
                    "breadcrumb": breadcrumb,
                    "page_number": page_number,
                    "content": content,
                    "summary": summary,
                    "keywords": keywords,
                    "hypothetical_questions": questions,
                    "content_similarity": float(content_sim or 0.0),
                    "question_similarity": float(question_sim or 0.0),
                    "relevance_score": round(final_score, 4)
                })

            # Sort by final score descending
            results.sort(key=lambda x: x["relevance_score"], reverse=True)
            return results[:top_k]

        finally:
            cursor.close()
            conn.close()
