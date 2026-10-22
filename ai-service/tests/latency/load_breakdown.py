"""Tim khoa serial: 3 cau DOC giong het, chay tuan tu vs 3 threads (1 ChatService
chung nhu prod singleton). Stage nao phong len duoi tai = khoa do.
Chay: py tests/latency/load_breakdown.py
"""
import functools
import sys
import threading
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from fastapi.testclient import TestClient  # noqa: E402

from main import app, INTERNAL_API_SECRET  # noqa: E402
from src.cache.semantic_cache import SemanticCache  # noqa: E402
from src.retrievers.hybrid_retriever import HybridRetriever  # noqa: E402
from src.embeddings.local_embedder import LocalEmbedder  # noqa: E402
from src.rerankers.cross_encoder_reranker import CrossEncoderReranker  # noqa: E402
import src.chat.chat_service as cs  # noqa: E402

TLS = threading.local()
PHASE = defaultdict(float)  # TestClient chay app tren thread rieng -> TLS caller khong thay; gop theo phase


def span(name):
    def deco(fn):
        @functools.wraps(fn)
        def w(*a, **k):
            t0 = time.time()
            out = fn(*a, **k)
            PHASE[name] += time.time() - t0
            return out
        return w
    return deco


cs.ChatService._llm_complete = span("llm")(cs.ChatService._llm_complete)
cs.ChatService._generate_llm_answer = span("llm_answer")(cs.ChatService._generate_llm_answer)
cs.ChatService.rewrite_and_route_step = span("rewrite")(cs.ChatService.rewrite_and_route_step)
SemanticCache.check_cache = span("cache")(SemanticCache.check_cache)
HybridRetriever.retrieve = span("retrieve")(HybridRetriever.retrieve)
if hasattr(CrossEncoderReranker, "rerank"):
    CrossEncoderReranker.rerank = span("rerank")(CrossEncoderReranker.rerank)
LocalEmbedder.generate_embedding = span("embed")(LocalEmbedder.generate_embedding)

client = TestClient(app)
H = {"X-Internal-Secret": INTERNAL_API_SECRET}
QS = [
    "Người lao động được nghỉ lễ nào hưởng nguyên lương?",
    "Tuổi nghỉ hưu của lao động nam là bao nhiêu?",
    "Làm thế nào để yêu cầu cấp văn phòng phẩm?",
]


def wipe():
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id LIKE 'LOAD%');")
    cur.execute("DELETE FROM chat_conversations WHERE user_id LIKE 'LOAD%';")
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()


def one(i_q):
    i, q = i_q
    t0 = time.time()
    r = client.post("/api/v1/chat/query", headers=H, json={
        "question": q, "user_id": f"LOAD{i}", "user_jobs": ["ALL"],
        "department": "ALL", "top_k": 3})
    r.raise_for_status()
    return time.time() - t0


def show(tag, res):
    print(f"== {tag} wall_sum={sum(res):.1f}s ==")
    for i, dt in enumerate(res):
        print(f"  q{i}: total={dt:.1f}s")
    print("  STAGES: " + " ".join(f"{k}={v:.1f}" for k, v in sorted(PHASE.items())))
    PHASE.clear()


def main():
    wipe()
    seq = [one((i, q)) for i, q in enumerate(QS)]
    show("SEQUENTIAL", seq)
    wipe()
    with ThreadPoolExecutor(max_workers=3) as ex:
        par = list(ex.map(one, list(enumerate(QS))))
    show("PARALLELx3", par)
    wipe()
    print("done")


if __name__ == "__main__":
    main()
