"""Giai doan 3a: sinh dap an RAG cho 120 cau golden + 10 cau negatives.

- Dung key hien tai (RAG = Ollama account 1). Judge chay script rieng + key moi.
- Context freeze: top_k=5, cau hinh retrieval production (vw=0.7 + rerank).
- Truoc khi chay: purge semantic_cache gan giong cau test (>=0.90) de dap an tuoi.
- Resume: bo qua id da co trong answers.json (chay lai an toan).
- Don dep: xoa conversations EVAL_GEN sau khi xong (giu corpus + cache).

Chay tu ai-service:
    python tests/DOC_ONLY/generation_metrics_tests/run_answers.py --n 2  # thu
    python tests/DOC_ONLY/generation_metrics_tests/run_answers.py         # full (~1h)
Output: tests/DOC_ONLY/generation_metrics_tests/answers.json
"""
import argparse
import json
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

HERE = Path(__file__).resolve().parent
DATASET = HERE.parent / "datasets" / "doc_only_120.json"
NEGATIVES = HERE / "negatives.json"
OUT = HERE / "answers.json"
EVAL_USER = "EVAL_GEN"


def purge_cache(questions: list) -> int:
    """Xoa cache rows gan giong cau test de moi answer sinh tuoi."""
    from src.db.session import get_db_connection
    from src.embeddings.local_embedder import LocalEmbedder

    embedder = LocalEmbedder()
    vecs = embedder.generate_embeddings_batch(questions, batch_size=32)
    conn = get_db_connection()
    cur = conn.cursor()
    doomed = set()
    try:
        for v in vecs:
            cur.execute("SELECT id FROM semantic_cache "
                        "WHERE 1 - (query_vector <=> %s::vector) >= 0.90", (str(v),))
            doomed.update(r[0] for r in cur.fetchall())
        if doomed:
            cur.execute("DELETE FROM semantic_cache WHERE id = ANY(%s::uuid[])",
                        (list(doomed),))
        conn.commit()
    finally:
        cur.close()
        conn.close()
    return len(doomed)


def cleanup_conversations() -> None:
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                    "(SELECT id FROM chat_conversations WHERE user_id = %s);", (EVAL_USER,))
        cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (EVAL_USER,))
        conn.commit()
    finally:
        cur.close()
        conn.close()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=0, help="Thu nhanh N cau dau (0=het).")
    ap.add_argument("--no-purge", action="store_true")
    ap.add_argument("--no-cleanup", action="store_true")
    args = ap.parse_args()

    rows = json.loads(DATASET.read_text(encoding="utf-8"))
    rows = [r for r in rows if "THIEU THONG TIN" not in (r.get("ground_truth") or "")]
    items = [{"id": r["id"], "question": r["question"], "expected_abstain": False} for r in rows]
    negs = json.loads(NEGATIVES.read_text(encoding="utf-8"))
    items += [{"id": n["id"], "question": n["question"], "expected_abstain": True} for n in negs]
    if args.n:
        items = items[: args.n]

    done = {}
    if OUT.exists():
        for r in json.loads(OUT.read_text(encoding="utf-8")):
            done[r["id"]] = r
    todo = [it for it in items if it["id"] not in done]
    print(f"[gen] {len(items)} cau ({len(todo)} can chay, {len(done)} resume)", flush=True)

    if todo and not args.no_purge:
        print(f"[gen] purged {purge_cache([t['question'] for t in todo])} cache rows", flush=True)

    from src.chat.chat_service import ChatService, reset_usage, take_usage
    from src.sql.router import keyword_fallback

    svc = ChatService()
    for i, it in enumerate(todo):
        t0 = time.perf_counter()
        reset_usage()
        try:
            out = svc.answer_query(it["question"], user_id=EVAL_USER,
                                   jobs=["ALL"], departments=["ALL"], top_k=5)
        except Exception as e:
            out = {"answer": f"[LOI GEN: {e}]", "rewritten_query": it["question"],
                   "citations": [], "confidence": "LOW",
                   "retrieved_chunks_count": 0, "dropped_claims": -1}
        u = take_usage()
        try:
            expected_route = keyword_fallback(it["question"])
        except Exception:
            expected_route = "?"
        done[it["id"]] = {
            "id": it["id"], "question": it["question"],
            "expected_abstain": it["expected_abstain"],
            "expected_route": expected_route,
            "answer": out.get("answer", ""),
            "rewritten_query": out.get("rewritten_query", ""),
            "citations": out.get("citations", []) or [],
            "confidence": out.get("confidence", "?"),
            "retrieved_chunks_count": out.get("retrieved_chunks_count", 0),
            "dropped_claims": out.get("dropped_claims", -1),
            "elapsed_s": round(time.perf_counter() - t0, 2),
            "prompt_tokens": u["in"], "completion_tokens": u["out"],
            "llm_calls": u["calls"],
        }
        OUT.write_text(json.dumps(list(done.values()), ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[{i + 1}/{len(todo)}] {it['id']} conf={done[it['id']]['confidence']} "
              f"drop={done[it['id']]['dropped_claims']} "
              f"t={done[it['id']]['elapsed_s']}s n_cite={len(done[it['id']]['citations'])}", flush=True)

    if not args.no_cleanup and not args.n:
        cleanup_conversations()
        print("[gen] da xoa conversations EVAL_GEN", flush=True)
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()
