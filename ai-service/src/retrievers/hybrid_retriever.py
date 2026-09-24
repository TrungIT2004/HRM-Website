from typing import List, Dict, Any, Optional
from pathlib import Path
import re

from src.embeddings.local_embedder import LocalEmbedder
from src.rerankers.cross_encoder_reranker import CrossEncoderReranker
from src.db.session import get_db_connection


class HybridRetriever:
    """
    Two-Stage Hybrid Search combining:
    1. Stage 1 (Coarse): Multi-Vector Dense Search (768d) + Sparse BM25 + RBAC
    2. Stage 2 (Fine): Cross-Encoder Reranking (BAAI/bge-reranker-base on CUDA)
    """

    def __init__(self, use_reranker: bool = True):
        self.embedder = LocalEmbedder()
        self.reranker = CrossEncoderReranker() if use_reranker else None

    def retrieve(
        self,
        query: str,
        jobs: Optional[List[str]] = None,
        departments: Optional[List[str]] = None,
        roles: Optional[List[str]] = None,
        top_k: int = 4,
        use_reranker: bool = True
    ) -> List[Dict[str, Any]]:
        if not query or not query.strip():
            return []

        user_jobs = jobs or roles or ["ALL"]
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
            # - Dense Vector: GREATEST(content_sim, question_sim)
            # - Sparse BM25: ts_rank_cd on content + breadcrumb
            # - Combined score: 0.7 * vector + 0.3 * text_rank
            sql = """
                SELECT 
                    c.id, c.document_id, c.chunk_index, c.chunk_type, c.breadcrumb, c.content, c.page_number,
                    c.summary, c.keywords, c.hypothetical_questions, c.allowed_jobs, c.allowed_departments,
                    d.file_name, d.file_path,
                    COALESCE(1 - (c.content_vector <=> %s::vector), 0.0) AS content_similarity,
                    COALESCE(1 - (c.questions_vector <=> %s::vector), 0.0) AS question_similarity,
                    GREATEST(
                        COALESCE(1 - (c.content_vector <=> %s::vector), 0.0),
                        COALESCE(1 - (c.questions_vector <=> %s::vector), 0.0)
                    ) AS vector_score,
                    COALESCE(ts_rank_cd(to_tsvector('simple', c.content || ' ' || c.breadcrumb), plainto_tsquery('simple', %s)), 0.0) AS text_rank
                FROM document_chunks c
                JOIN knowledge_documents d ON c.document_id = d.id
                WHERE d.status = 'COMPLETED'
                  AND (c.allowed_jobs && %s::varchar[] OR 'ALL' = ANY(c.allowed_jobs))
                  AND (c.allowed_departments && %s::varchar[] OR 'ALL' = ANY(c.allowed_departments))
                ORDER BY (
                    GREATEST(
                        COALESCE(1 - (c.content_vector <=> %s::vector), 0.0),
                        COALESCE(1 - (c.questions_vector <=> %s::vector), 0.0)
                    ) * 0.7 +
                    LEAST(COALESCE(ts_rank_cd(to_tsvector('simple', c.content || ' ' || c.breadcrumb), plainto_tsquery('simple', %s)), 0.0), 1.0) * 0.3
                ) DESC
                LIMIT %s;
            """

            # Stage 1: Coarse retrieval limit (fetch 10-12 candidate chunks for Cross-Encoder)
            candidate_limit = max(10, top_k * 3) if (self.reranker and use_reranker) else top_k

            cursor.execute(
                sql,
                (
                    query_vector, query_vector, query_vector, query_vector,
                    query,
                    user_jobs, user_depts,
                    query_vector, query_vector,
                    query,
                    candidate_limit
                )
            )

            rows = cursor.fetchall()
            results = []

            for r in rows:
                (
                    chunk_id, doc_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                    summary, keywords, questions, allowed_jobs, allowed_depts,
                    file_name, file_path, content_sim, question_sim, vector_score, text_rank
                ) = r

                # Calculate initial hybrid score with keyword overlap bonus
                keyword_bonus = 0.0
                if keywords and query_keywords:
                    overlap = set(k.lower() for k in keywords).intersection(set(query_keywords))
                    if overlap:
                        keyword_bonus = min(0.08, len(overlap) * 0.02)

                final_score = float(vector_score or 0.0) * 0.7 + float(text_rank or 0.0) * 0.3 + keyword_bonus
                file_url = f"/api/ai/documents/{doc_id}/download" if doc_id else None

                results.append({
                    "chunk_id": str(chunk_id),
                    "document_id": str(doc_id),
                    "document_name": file_name,
                    "file_url": file_url,
                    "chunk_index": chunk_index,
                    "chunk_type": chunk_type,
                    "breadcrumb": re.sub(r'^[a-fA-F0-9]{8,64}_', '', breadcrumb) if breadcrumb else "",
                    "page_number": page_number,
                    "content": content,
                    "summary": summary,
                    "keywords": keywords,
                    "hypothetical_questions": questions,
                    "allowed_jobs": allowed_jobs,
                    "content_similarity": float(content_sim or 0.0),
                    "question_similarity": float(question_sim or 0.0),
                    "relevance_score": round(final_score, 4)
                })

        finally:
            cursor.close()
            conn.close()

        # Stage 2: Cross-Encoder Reranking on CUDA
        if self.reranker and use_reranker and len(results) > 1:
            return self.reranker.rerank(query=query, chunks=results, top_k=top_k)

        # Fallback to Stage 1 score sorting
        results.sort(key=lambda x: x["relevance_score"], reverse=True)
        return results[:top_k]
