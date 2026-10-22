"""Breakdown latency + tokens theo stage, khong sua prod code (monkeypatch spy).
10 cau (6 DOC + 2 DB + 1 refused + 1 stream TTFT) + 1 cache-hit. User that cho DB.
Chay: py TEMP/breakdown.py
"""
import functools
import sys
import time
from collections import defaultdict
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(r"C:\Users\ad\Desktop\HRM\ai-service")))
from dotenv import load_dotenv

load_dotenv()
from fastapi.testclient import TestClient
from main import app, INTERNAL_API_SECRET
import src.chat.chat_service as cs
from src.cache.semantic_cache import SemanticCache
from src.retrievers.hybrid_retriever import HybridRetriever
from src.embeddings.local_embedder import LocalEmbedder
from src.rerankers.cross_encoder_reranker import CrossEncoderReranker

STAGE = defaultdict(float)
USAGE = {"in": 0, "out": 0, "calls": 0}


def span(name):
    def deco(fn):
        @functools.wraps(fn)
        def w(*a, **k):
            t0 = time.time()
            out = fn(*a, **k)
            STAGE[name] += time.time() - t0
            return out
        return w
    return deco


def bump_usage(res, provider, tag):
    try:
        u = getattr(res, "usage", None) or getattr(res, "usage_metadata", None)
        if u is None:
            return
        USAGE["in"] += int(getattr(u, "prompt_tokens", getattr(u, "prompt_token_count", 0)) or 0)
        USAGE["out"] += int(getattr(u, "completion_tokens", getattr(u, "candidates_token_count", 0)) or 0)
        USAGE["calls"] += 1
    except Exception:
        pass


_orig_complete = cs.ChatService._llm_complete
_orig_answer = cs.ChatService._generate_llm_answer
_orig_text2sql = cs.ChatService._run_text2sql


@functools.wraps(_orig_complete)
def complete_spy(self, system_content, user_content, tag="", model=None):
    if self.ollama_client:
        try:
            res = self.ollama_client.chat.completions.create(
                model=self.ollama_model,
                messages=[{"role": "system", "content": system_content},
                          {"role": "user", "content": user_content}], temperature=0.0)
            bump_usage(res, "ollama", tag)
            text = res.choices[0].message.content.strip()
            if text:
                return text
        except Exception:
            pass
    if self.gemini_client:
        try:
            res = self.gemini_client.generate_content(
                f"{system_content}\n\n{user_content}", request_options={"timeout": 60})
            bump_usage(res, "gemini", tag)
            text = res.text.strip()
            if text:
                return text
        except Exception:
            pass
    return ""


@functools.wraps(_orig_answer)
def answer_spy(self, prompt, system_prompt=None):
    system = system_prompt or cs.SYSTEM_PROMPT
    if self.ollama_client:
        try:
            res = self.ollama_client.chat.completions.create(
                model=self.ollama_model,
                messages=[{"role": "system", "content": system},
                          {"role": "user", "content": prompt}], temperature=0.2)
            bump_usage(res, "ollama", "answer")
            return res.choices[0].message.content.strip()
        except Exception:
            pass
    if self.gemini_client:
        try:
            res = self.gemini_client.generate_content(
                f"{system}\n\n{prompt}", request_options={"timeout": 60})
            bump_usage(res, "gemini", "answer")
            return res.text.strip()
        except Exception:
            pass
    return "Hệ thống AI hiện đang bận hoặc gặp sự cố kết nối. Bạn vui lòng thử lại sau giây lát."


# ponytail: spy copy TAM logic ham goc de moc usage object (return chi co text).
# Chi dung do 1 lan, khong thay prod; timing la wall bao gom nested call
# (rerank nam trong retrieve) — doc waterfall thi tru ra.
cs.ChatService._llm_complete = span("llm_all")(complete_spy)
cs.ChatService._generate_llm_answer = span("llm_answer")(answer_spy)
cs.ChatService._run_text2sql = span("text2sql")(cs.ChatService._run_text2sql)
cs.ChatService.rewrite_and_route_step = span("rewrite_route")(cs.ChatService.rewrite_and_route_step)
SemanticCache.check_cache = span("cache_check")(SemanticCache.check_cache)
HybridRetriever.retrieve = span("retrieve_total")(HybridRetriever.retrieve)
if hasattr(CrossEncoderReranker, "rerank"):
    CrossEncoderReranker.rerank = span("rerank")(CrossEncoderReranker.rerank)
LocalEmbedder.generate_embedding = span("embed")(LocalEmbedder.generate_embedding)

client = TestClient(app)
H = {"X-Internal-Secret": INTERNAL_API_SECRET}
DOC_USER = "PERF"
DB_USER = "35337165-e0d0-4dd1-9c67-cc48180363af"

DOC_QS = [
    "Người lao động được nghỉ lễ nào hưởng nguyên lương?",
    "Tuổi nghỉ hưu của lao động nam là bao nhiêu?",
    "Làm thế nào để yêu cầu cấp văn phòng phẩm?",
    "Ai duyệt đăng ký xe công tác?",
    "Quy chế MWG áp dụng cho ai?",
    "Mức phạt đi muộn 15 phút là bao nhiêu?",
]
DB_QS = ["Tôi còn bao nhiêu ngày phép?", "Hợp đồng của tôi loại gì?"]
REFUSED_Q = "Thủ đô của Úc là thành phố nào?"


def ask(q, uid):
    STAGE.clear()
    t0 = time.time()
    r = client.post("/api/v1/chat/query", headers=H, json={
        "question": q, "user_id": uid, "user_jobs": ["ALL"],
        "department": "ALL", "top_k": 3})
    dt = time.time() - t0
    b = r.json()
    stages = dict(STAGE)
    return {"q": q[:50], "total": round(dt, 2), "stages": {k: round(v, 2) for k, v in stages.items()},
            "answer_chars": len(b.get("answer", "")), "cits": len(b.get("citations") or [])}


def main():
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()

    rows = []
    for q in DOC_QS:
        rows.append(("DOC", ask(q, DOC_USER)))
    for q in DB_QS:
        rows.append(("DB", ask(q, DB_USER)))
    rows.append(("REFUSED", ask(REFUSED_Q, DOC_USER)))
    # stream TTFT: time-to-first-token ~= prefill, con lai ~= decode
    t0 = time.time()
    first_at, chars, n_tok = None, 0, 0
    with client.stream("POST", "/api/v1/chat/stream", headers=H, json={
            "question": DOC_QS[1], "user_id": DOC_USER, "user_jobs": ["ALL"],
            "department": "ALL", "top_k": 3}) as resp:
        for line in resp.iter_lines():
            s = line.strip() if isinstance(line, str) else line.decode().strip()
            if s.startswith("data: ") and first_at is None and "token" in s:
                first_at = time.time() - t0
            if s.startswith("data: "):
                n_tok += 1
                chars += len(s)
    stream_total = time.time() - t0
    # cache hit: hoi lai cau dau
    rows.append(("CACHE_HIT", ask(DOC_QS[0], DOC_USER)))

    out = ["KIND | total | stages (s) | ans_chars cits"]
    for kind, r in rows:
        out.append(f"{kind:9} | {r['total']:5} | {r['stages']} | {r['answer_chars']} {r['cits']}")
    out.append(f"STREAM total={stream_total:.1f}s TTFT~={first_at:.1f}s chunks={n_tok} chars={chars}")
    out.append(f"TOKENS total in={USAGE['in']} out={USAGE['out']} (gemini-decode est rieng, xem file)")
    open(r"C:\Users\ad\AppData\Local\Temp\opencode\break.txt", "w", encoding="utf-8").write("\n".join(out))

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id IN ('PERF', %s));", (DB_USER,))
    cur.execute("DELETE FROM chat_conversations WHERE user_id IN ('PERF', %s);", (DB_USER,))
    cur.execute("DELETE FROM semantic_cache;")
    conn.commit()
    cur.close()
    conn.close()
    print("ok")


if __name__ == "__main__":
    main()
