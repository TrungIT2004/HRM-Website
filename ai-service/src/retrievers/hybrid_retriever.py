from typing import List, Dict, Any, Optional
from pathlib import Path
import re

from src.embeddings.local_embedder import LocalEmbedder
from src.rerankers.cross_encoder_reranker import CrossEncoderReranker
from src.db.session import get_db_connection

# Token xuat hien trong qua nhieu % corpus -> thong tin ~ 0, bo khoi query.
# Do: 'simple' khong lo stop-word, 'hop' (69% corpus) cung an diem nhu 'phat' (2%).
DF_STOP_RATIO = 0.5

# B1. Tokenize query -> do df -> gan trong so IDF, bo token pho bien (>50% corpus).
# IDF = ln((N - df + 0.5) / (df + 0.5) + 1)  [BM25]. Tu hiem -> idf cao.
# ponytail: bo ts_rank_cd (het IDF nen 'hop' [69% corpus] an cung diem 'phat' [2%],
# keo chunk hop dong lao dong len top va giat cau hoi).
LEXICAL_WEIGHTS_SQL = """
    WITH q AS (
        SELECT w AS term FROM unnest(ARRAY(
            SELECT w FROM unnest(regexp_split_to_array(
                lower(regexp_replace(%(query)s, '[^[:alnum:]]', ' ', 'g')), '\\s+'
            )) w WHERE w <> ''
        )) w
    ),
    total AS (SELECT count(*) AS n FROM document_chunks),
    df AS (
        -- Tan suat tren TOAN BO corpus, khong gioi han theo user.
        -- c.tsv: tsvector da tinh san luc ingest (co GIN index). Tinh lai to_tsvector
        -- + unaccent trong query = 4.0s/248 chunk; dung c.tsv = 177ms (23x).
        -- unaccent() ca 2 phia: query "hop le" khop duoc chunk viet "hop phap".
        SELECT q.term, count(c.id) AS n
        FROM q
        JOIN document_chunks c
          ON c.tsv @@ to_tsquery('simple', unaccent(q.term))
        GROUP BY q.term
    ),
    weights AS (
        SELECT d.term, ln(((t.n - d.n + 0.5) / (d.n + 0.5)) + 1.0) AS idf
        FROM df d, total t
        WHERE d.n::float / t.n < %(df_stop)s
    )
"""


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
        use_reranker: bool = True,
        alt_queries: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """alt_queries: them cac bien the cau hoi (vd ban goc chua LLM-rewrite).

        Retry nhieu bien the chu khong phu thuoc LLM co dung khong: LLM rewrite
        lam reranker cham doi thuong (do voi cau goc, cau sau LLM dat 0.51 vs 0.05),
        nhung neu LLM fail/treo thi cau goc van phai ra ket qua dung.
        Stage 1 chay N cau, gop theo chunk_id giu diem cao nhat, rerank MOT LAN.
        """
        queries = [query] + [q for q in (alt_queries or []) if q and q.strip() and q != query]
        if not query or not query.strip():
            return []

        user_jobs = jobs or roles or ["ALL"]
        user_depts = departments or ["ALL"]

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            results = self._candidates(cursor, queries, user_jobs, user_depts, top_k, use_reranker)
        finally:
            cursor.close()
            conn.close()

        # Stage 2: Cross-Encoder Reranking on CUDA
        if self.reranker and use_reranker and len(results) > 1:
            return self.reranker.rerank(query=query, chunks=results, top_k=top_k)

        results.sort(key=lambda x: x["relevance_score"], reverse=True)
        return results[:top_k]

    def _candidates(
        self,
        cursor,
        queries: List[str],
        user_jobs: List[str],
        user_depts: List[str],
        top_k: int,
        use_reranker: bool
    ) -> List[Dict[str, Any]]:
        """Stage 1 cho nhieu bien the cau hoi, gop theo chunk_id giu diem cao nhat."""
        # Stage 1: phai lay DU nhan hon top_k vi lexical thuong diem thap
        # (nhieu chunk khong chua tu nao con lai) -> vector thuong thang
        # nen can noi rong de con candidate cho reranker.
        per_query_limit = max(40, top_k * 12) if (self.reranker and use_reranker) else top_k
        candidate_limit = per_query_limit * len(queries)

        sql = LEXICAL_WEIGHTS_SQL + """
            , scored AS (
                SELECT
                    c.id, c.document_id, c.chunk_index, c.chunk_type, c.breadcrumb,
                    c.content, c.page_number, c.summary, c.keywords,
                    c.hypothetical_questions, c.allowed_jobs, c.allowed_departments,
                    d.file_name, d.file_path,
                    COALESCE(1 - (c.content_vector <=> %(qv)s::vector), 0.0) AS content_similarity,
                    COALESCE(1 - (c.questions_vector <=> %(qv)s::vector), 0.0) AS question_similarity,
                    GREATEST(
                        COALESCE(1 - (c.content_vector <=> %(qv)s::vector), 0.0),
                        COALESCE(1 - (c.questions_vector <=> %(qv)s::vector), 0.0)
                    ) AS vector_score,
                    COALESCE((
                        SELECT sum(w.idf * ts_rank(c.tsv, to_tsquery('simple', unaccent(w.term))) * 10.0)
                        FROM weights w
                    ), 0.0) AS lex_raw
                FROM document_chunks c
                JOIN knowledge_documents d ON c.document_id = d.id
                WHERE d.status = 'COMPLETED'
                  AND (c.allowed_jobs && %(jobs)s::varchar[] OR 'ALL' = ANY(c.allowed_jobs))
                  AND (c.allowed_departments && %(depts)s::varchar[] OR 'ALL' = ANY(c.allowed_departments))
            )
            SELECT
                id, document_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                summary, keywords, hypothetical_questions, allowed_jobs, allowed_departments,
                file_name, file_path, content_similarity, question_similarity, vector_score,
                -- x/(1+x): luon < 1 -> 0.3 la trong so THAT va giu duoc thu tu
                (lex_raw / (1.0 + lex_raw)) AS text_rank
            FROM scored
            ORDER BY (vector_score * 0.7 + (lex_raw / (1.0 + lex_raw)) * 0.3) DESC
            LIMIT %(limit)s;
        """

        # Gop theo chunk_id, giu diem cao nhat. Diem luon cung thang 0-1 nen
        # "cao nhat" nghia la bien the nao khop chunk do tot hon.
        merged: Dict[str, Dict[str, Any]] = {}
        for q in queries:
            query_vector = self.embedder.generate_embedding(q, task_type="retrieval_query")
            words = re.findall(r'\b[A-Za-zÀ-ỹ0-9_/%-]{2,}\b', q.lower())
            query_keywords = list(dict.fromkeys(words))

            cursor.execute(
                sql,
                {
                    "query": q,
                    "df_stop": DF_STOP_RATIO,
                    "qv": str(query_vector),
                    "jobs": user_jobs,
                    "depts": user_depts,
                    "limit": per_query_limit,
                },
            )

            for r in cursor.fetchall():
                (
                    chunk_id, doc_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                    summary, keywords, questions, allowed_jobs, allowed_depts,
                    file_name, file_path, content_sim, question_sim, vector_score, text_rank
                ) = r

                final_score = float(vector_score or 0.0) * 0.7 + float(text_rank or 0.0) * 0.3
                prev = merged.get(str(chunk_id))
                if prev is not None and prev["relevance_score"] >= final_score:
                    continue

                merged[str(chunk_id)] = {
                    "chunk_id": str(chunk_id),
                    "document_id": str(doc_id),
                    "document_name": file_name,
                    "file_url": f"/api/ai/documents/{doc_id}/download" if doc_id else None,
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
                    "vector_score": float(vector_score or 0.0),
                    "text_rank": float(text_rank or 0.0),
                    "relevance_score": round(final_score, 4),
                    "matched_query": q,
                }

        return sorted(merged.values(), key=lambda x: -x["relevance_score"])[:candidate_limit]
