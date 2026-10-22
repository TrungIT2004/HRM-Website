import json
from typing import List, Dict, Any, Optional
from src.embeddings.local_embedder import LocalEmbedder
from src.db.session import get_db_connection


class SemanticCache:
    """
    Semantic Caching for AI RAG Service using PostgreSQL + pgvector (768d).
    - Checks if incoming user query has >= 95% cosine similarity with existing cached questions.
    - If HIT: Responds in ~30ms without invoking heavy LLMs (Ollama 120B).
    - If MISS: Stores the generated response and citations for subsequent users.
    - Enforces RBAC & Department security so employees cannot view restricted executive answers.
    """

    def __init__(self, embedder: Optional[LocalEmbedder] = None):
        self.embedder = embedder or LocalEmbedder()

    def check_cache(
        self,
        query: str,
        jobs: Optional[List[str]] = None,
        departments: Optional[List[str]] = None,
        roles: Optional[List[str]] = None,
        similarity_threshold: float = 0.95
    ) -> Optional[Dict[str, Any]]:
        """
        Looks up semantic cache in PostgreSQL for a matching question.
        Returns cached response and citations if similarity >= threshold.
        """
        if not query or not query.strip():
            return None

        user_jobs = jobs or roles or ["ALL"]
        user_depts = departments or ["ALL"]

        # Generate 768d vector on CUDA
        query_vector = self.embedder.generate_embedding(query)

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            sql = """
                SELECT 
                    id, query_text, response_text, citations,
                    (1 - (query_vector <=> %s::vector)) AS similarity
                FROM semantic_cache
                WHERE (allowed_jobs && %s::varchar[] OR 'ALL' = ANY(allowed_jobs))
                  AND (allowed_departments && %s::varchar[] OR 'ALL' = ANY(allowed_departments))
                  AND (1 - (query_vector <=> %s::vector)) >= %s
                ORDER BY similarity DESC
                LIMIT 1;
            """
            cursor.execute(
                sql,
                (query_vector, user_jobs, user_depts, query_vector, similarity_threshold)
            )
            row = cursor.fetchone()

            if row:
                cache_id, cached_query, response_text, citations_json, similarity = row
                
                # Increment hit count asynchronously in DB
                cursor.execute(
                    "UPDATE semantic_cache SET hit_count = hit_count + 1, updated_at = NOW() WHERE id = %s;",
                    (cache_id,)
                )
                conn.commit()

                citations = citations_json if isinstance(citations_json, list) else json.loads(citations_json or "[]")
                print(f"[SemanticCache] ⚡ CACHE HIT ({similarity*100:.1f}%) for query: '{query}' (Matched: '{cached_query}')")
                
                return {
                    "cached": True,
                    "answer": response_text,
                    "citations": citations,
                    "similarity": round(float(similarity), 4),
                    "matched_query": cached_query
                }

            return None

        except Exception as e:
            print(f"[SemanticCache] Warning: Cache check error: {e}")
            return None
        finally:
            cursor.close()
            conn.close()

    def add_to_cache(
        self,
        query: str,
        response: str,
        citations: List[Dict[str, Any]],
        jobs: Optional[List[str]] = None,
        departments: Optional[List[str]] = None,
        roles: Optional[List[str]] = None
    ) -> None:
        """Saves a query-answer pair to semantic cache in PostgreSQL."""
        if not query or not response or not query.strip() or not response.strip():
            return

        user_jobs = jobs or roles or ["ALL"]
        user_depts = departments or ["ALL"]

        query_vector = self.embedder.generate_embedding(query)

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            sql = """
                INSERT INTO semantic_cache (
                    query_text, query_vector, response_text, citations, allowed_jobs, allowed_departments
                ) VALUES (%s, %s, %s, %s, %s, %s);
            """
            cursor.execute(
                sql,
                (
                    query.strip(),
                    query_vector,
                    response.strip(),
                    json.dumps(citations, ensure_ascii=False),
                    user_jobs,
                    user_depts
                )
            )
            conn.commit()
            print(f"[SemanticCache] Cached new question-answer pair: '{query[:60]}...'")

        except Exception as e:
            conn.rollback()
            print(f"[SemanticCache] Warning: Could not save to cache: {e}")
        finally:
            cursor.close()
            conn.close()
