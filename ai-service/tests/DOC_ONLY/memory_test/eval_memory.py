"""Giai doan 4: do Memory tren 20 hoi thoai x 12 turns (doc_only_memory_20x12).

- Chay hoi thoai THAT noi chuoi (cung conversation_id): history, summary,
  rewrite, retrieval, answer nhu prod.
- Stage A (key RAG cu): rewrite accuracy (cosine vs rewrite_expected) +
  carryover (thuc the lich su giu lai) + retrieval truoc/sau rewrite.
- Stage B (key judge moi): multi-turn correctness pairwise 2 luot (tai dung
  judge_pairwise). Bo 20 turn THIEU THONG TIN (chi cham 220).
- Resume + batch. Don conversations EVAL_MEM khi xong.

Chay tu ai-service:
    python tests/DOC_ONLY/memory_test/eval_memory.py --stage a            # ~30p
    python tests/DOC_ONLY/memory_test/eval_memory.py --stage b --limit 30 # lap lai
Output: memory_test/answers_memory.json + judge_memory.json
"""
import argparse
import json
import re
import sys
import time
import unicodedata
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
DATASET = HERE.parent / "datasets" / "doc_only_memory_20x12.json"
ANS = HERE / "answers_memory.json"
JUDGE = HERE / "judge_memory.json"
EVAL_USER = "EVAL_MEM"
STOP = {"lam", "sao", "de", "cho", "va", "cua", "cai", "nay", "kia", "co", "khong",
        "duoc", "la", "gi", "ai", "nao", "trong", "ngoai", "ve", "theo", "voi",
        "nhu", "thi", "khi", "neu", "cac", "nhung", "mot", "nhat"}


def fold(t: str) -> str:
    t = unicodedata.normalize("NFD", t or "")
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", t.lower()).strip()


def rank_of(gold: str, got: list) -> int | None:
    for i, c in enumerate(got):
        if str(c.get("chunk_id")) == gold:
            return i + 1
    return None


def stage_a(limit: int) -> None:
    rows = json.loads(DATASET.read_text(encoding="utf-8"))
    done = {}
    if ANS.exists():
        for r in json.loads(ANS.read_text(encoding="utf-8")):
            done[r["id"]] = r

    from src.chat.chat_service import ChatService, reset_usage, take_usage
    from src.embeddings.local_embedder import LocalEmbedder
    from src.retrievers.hybrid_retriever import HybridRetriever

    svc, emb, ret = ChatService(), LocalEmbedder(), HybridRetriever(use_reranker=False)
    convs: dict = {}
    todo = [r for r in rows if r["id"] not in done][: limit or None]
    print(f"[mem-A] {len(rows)} turns ({len(todo)} can chay)", flush=True)
    for k, r in enumerate(todo):
        cid = convs.get(r["conversation_id"])
        t0 = time.perf_counter()
        reset_usage()
        try:
            out = svc.answer_query(r["question"], conversation_id=cid, user_id=EVAL_USER,
                                   jobs=["ALL"], departments=["ALL"], top_k=5)
        except Exception as e:
            out = {"answer": f"[LOI GEN: {e}]", "rewritten_query": r["question"],
                   "citations": [], "confidence": "LOW", "dropped_claims": -1}
        u = take_usage()
        convs[r["conversation_id"]] = out.get("conversation_id", cid)
        sys_rw, exp_rw = out.get("rewritten_query", ""), r.get("rewrite_expected", "")
        try:
            v1, v2 = emb.generate_embedding(sys_rw, task_type="retrieval_query"), \
                emb.generate_embedding(exp_rw, task_type="retrieval_query")
            cos = round(sum(a * b for a, b in zip(v1, v2)), 4)
        except Exception:
            cos = 0.0
        need = [w for w in fold(exp_rw).split()
                if w not in fold(r["question"]).split() and len(w) > 2 and w not in STOP]
        carry = (round(sum(1 for w in need if w in fold(sys_rw)) / len(need), 4)
                 if need else None)
        gold = (r.get("relevant_chunk_ids") or [None])[0]
        try:
            rb = rank_of(gold, ret.retrieve(query=r["question"], jobs=["ALL"],
                                            departments=["ALL"], top_k=5, use_reranker=True))
            ra = rank_of(gold, ret.retrieve(query=sys_rw or r["question"], jobs=["ALL"],
                                            departments=["ALL"], top_k=5, use_reranker=True))
        except Exception:
            rb, ra = None, None
        done[r["id"]] = {
            "id": r["id"], "conversation_id": r["conversation_id"], "turn_index": r["turn_index"],
            "question": r["question"], "ground_truth": r.get("ground_truth", ""),
            "answerable": "THIEU THONG TIN" not in (r.get("ground_truth") or ""),
            "answer": out.get("answer", ""), "rewritten_query": sys_rw,
            "rewrite_expected": exp_rw, "rewrite_cosine": cos, "carryover": carry,
            "rank_before": rb, "rank_after": ra,
            "citations": out.get("citations", []) or [], "confidence": out.get("confidence", "?"),
            "elapsed_s": round(time.perf_counter() - t0, 2),
            "prompt_tokens": u["in"], "completion_tokens": u["out"],
        }
        if (k + 1) % 10 == 0 or k + 1 == len(todo):
            ANS.write_text(json.dumps(list(done.values()), ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[{k + 1}/{len(todo)}] {r['id']} cos={cos} carry={carry} "
                  f"rank {rb}->{ra} conf={done[r['id']]['confidence']}", flush=True)
    ANS.write_text(json.dumps(list(done.values()), ensure_ascii=False, indent=2), encoding="utf-8")

    scored = list(done.values())
    rec = [r for r in scored if r["rewrite_cosine"] is not None]
    car = [r for r in scored if r["carryover"] is not None]
    n5 = lambda rs, k: sum(1 for r in rs if r[k] and r[k] <= 5) / max(1, len(rs))  # noqa: E731
    print(f"[mem-A] rewrite_cosine mean={sum(r['rewrite_cosine'] for r in rec) / max(1, len(rec)):.4f} n={len(rec)}")
    print(f"[mem-A] carryover mean={sum(r['carryover'] for r in car) / max(1, len(car)):.4f} n={len(car)}")
    print(f"[mem-A] hit@5 truoc={n5(scored, 'rank_before'):.4f} sau={n5(scored, 'rank_after'):.4f}")

    if not limit:
        from src.db.session import get_db_connection
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                        "(SELECT id FROM chat_conversations WHERE user_id = %s);", (EVAL_USER,))
            cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (EVAL_USER,))
            conn.commit()
            print("[mem-A] da xoa conversations EVAL_MEM", flush=True)
        finally:
            cur.close()
            conn.close()
    print(f"-> {ANS}")


def stage_b(limit: int, ids_filter: set | None = None) -> None:
    import os
    key = os.getenv("OLLAMA_JUDGE_API_KEY") or os.getenv("OLLAMA_API_KEY", "")
    from openai import OpenAI
    from tests.DOC_ONLY.generation_metrics_tests.judge_pairwise import (
        JUDGE_PROMPT, aggregate, judge_once, parse_verdict, summarize)
    client = OpenAI(
        base_url=os.getenv("OLLAMA_JUDGE_BASE_URL") or os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
        api_key=key)
    model = os.getenv("OLLAMA_JUDGE_MODEL") or os.getenv("OLLAMA_MODEL", "gemma4:31b")

    ans = {r["id"]: r for r in json.loads(ANS.read_text(encoding="utf-8"))
           if r.get("answerable") and "LOI GEN" not in r.get("answer", "")}
    gold = {r["id"]: r for r in json.loads(DATASET.read_text(encoding="utf-8"))}
    ids = sorted(set(ans) & set(gold))
    out = {"rows": [], "summary": {}}
    if JUDGE.exists():
        out = json.loads(JUDGE.read_text(encoding="utf-8"))
    if ids_filter:
        out["rows"] = [r for r in out["rows"] if r["id"] not in ids_filter]
        ids = [i for i in ids if i in ids_filter]
        limit = len(ids)
    have = {r["id"] for r in out["rows"] if r.get("run1") and r.get("run2")}
    todo = [i for i in ids if i not in have][: limit or None]
    print(f"[mem-B] {len(ids)} turns cham duoc ({len(todo)} can chay) model={model}", flush=True)

    from src.retrievers.hybrid_retriever import HybridRetriever
    ret = HybridRetriever(use_reranker=False)
    by_id = {r["id"]: r for r in out["rows"]}
    for k, i in enumerate(todo):
        a, g = ans[i], gold[i]
        try:
            got = ret.retrieve(query=a.get("rewritten_query") or a["question"], jobs=["ALL"],
                               departments=["ALL"], top_k=5, use_reranker=True, vw=0.7, lw=0.3)
        except Exception:
            got = []
        ctx = "\n---\n".join((c.get("content") or "") for c in got)[:12000]
        cites = json.dumps([c.get("document_name") for c in a.get("citations", [])],
                           ensure_ascii=False)[:800]
        kw = {"question": f"[Hoi thoai {a['conversation_id']}, luot {a['turn_index']}] {a['question']}",
              "contexts": ctx or "(khong co)", "cites": cites or "[]"}
        r1 = judge_once(client, model, a=g["ground_truth"], b=a["answer"], **kw)
        time.sleep(1)
        r2 = judge_once(client, model, a=a["answer"], b=g["ground_truth"], **kw)
        time.sleep(1)
        if not r1 or not r2:
            print(f"  [{i}] judge fail, resume sau", flush=True)
            continue
        m1 = {"A": "GT", "B": "GEN", "TIE": "TIE"}[r1["correctness"]]
        m2 = {"A": "GEN", "B": "GT", "TIE": "TIE"}[r2["correctness"]]
        lg, la = len(g["ground_truth"]), len(a["answer"])
        by_id[i] = {"id": i, "conversation_id": a["conversation_id"], "turn_index": a["turn_index"],
                    "run1": {"verdict": m1, "relevance": r1.get("relevance"),
                             "hallucination": r1.get("hallucination")},
                    "run2": {"verdict": m2, "relevance": r2.get("relevance"),
                             "hallucination": r2.get("hallucination")},
                    "final": aggregate(m1, m2), "len_gt": lg, "len_gen": la,
                    "len_warn": (max(lg, la) / max(1, min(lg, la))) > 3}
        out["rows"] = [by_id[j] for j in sorted(by_id)]
        out["summary"] = summarize(out["rows"])
        JUDGE.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[{k + 1}/{len(todo)}] {i} {m1}/{m2} -> {by_id[i]['final']}", flush=True)
    print("\n== MEM-B ==\n " + json.dumps(out["summary"], ensure_ascii=False))
    print(f"-> {JUDGE}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=["a", "b"], required=True)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--ids", type=str, default=None,
                    help="Cham lai cac id (xoa row cu, force re-judge).")
    args = ap.parse_args()
    if args.stage == "a":
        stage_a(args.limit)
    else:
        ids_filter = ({x.strip() for x in args.ids.split(",") if x.strip()}
                      if args.ids else None)
        stage_b(args.limit, ids_filter)


if __name__ == "__main__":
    main()
