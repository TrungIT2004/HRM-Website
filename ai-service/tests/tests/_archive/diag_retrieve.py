"""Debug: chay HybridRetriever voi cau hoi that, in diem tung chang."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.retrievers.hybrid_retriever import HybridRetriever

QUERY = sys.argv[1] if len(sys.argv) > 1 else "Lương của Phạm Thị Cúc"
RERANK = "--rerank" in sys.argv

r = HybridRetriever()
res = r.retrieve(query=QUERY, top_k=4, use_reranker=RERANK)

print(f"query: {QUERY!r}  reranker={RERANK}  -> {len(res)} chunks")
for c in res:
    print(f"  {c['document_name']} #{c['chunk_index']} {c['chunk_type']}")
    print(f"     relevance={c['relevance_score']} "
          f"content_sim={c['content_similarity']} question_sim={c['question_similarity']}")
    print(f"     {c['content'][:120]!r}")
