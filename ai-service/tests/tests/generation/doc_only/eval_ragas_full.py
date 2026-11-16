"""Do full bo RAGAS (faithfulness / answer_relevancy / context_precision / context_recall)
tren 80 cau hoi thuc te tu tests/generated_testset.json.

Pipeline: ingest 3 PDF vao document_chunks (tag EVAL_RAG, cleanup sau khi chay)
  -> ChatService.answer_query lay answer
  -> HybridRetriever.retrieve lay contexts
  -> ragas.evaluate cham diem (judge: LLM_PROVIDER trong .env).

Chay tu thu muc ai-service:
    python tests/eval_ragas_full.py --n 10        # chay thu 10 cau
    python tests/eval_ragas_full.py --n 80        # chay het
Output: tests/ragas_eval_results.json

LUU Y TRUNG THUC:
- reference hien tai = ground_truth_hint (LLM tom tat, chua review tay).
  faithfulness / answer_relevancy / context_precision van tin duoc (khong phu
  thuoc reference). context_recall phu thuoc reference -> chi tham khao cho
  den khi ban sua CSV thanh dap an chuan.
- Khong do answer_correctness (doi hoi ground truth chuan tuyet doi).
"""
import sys
import types

# ragas 0.4.3 import duong vertexai cu khong con ton tai trong langchain-community
# 0.4.x; stub de qua mat import (khong dung VertexAI o day).
_stub = types.ModuleType("langchain_community.chat_models.vertexai")
_stub.ChatVertexAI = type("ChatVertexAI", (object,), {})
sys.modules["langchain_community.chat_models.vertexai"] = _stub

import argparse
import json
import os
import re
import time
import uuid
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

DOCS_DIR = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế")
TESTSET = Path(__file__).parent.parent.parent / "generated_testset.json"
OUT = Path(__file__).parent / "ragas_eval_results.json"
EVAL_USER = "EVAL_RAGAS"


def ingest_eval_corpus():
    """Nap 3 PDF vao DB, tra ve [document_id]."""
    from psycopg2.extras import execute_values
    from src.db.session import get_db_connection
    from src.embeddings.local_embedder import LocalEmbedder
    from src.pipeline import IngestionPipeline

    conn = get_db_connection()
    cur = conn.cursor()
    # ponytail: corpus EVALRET| giu lai tu test retrieval la CUNG 7 file ->
    # trung noi dung, lam top-k dinh chunk doi. Xoa truoc khi nap EVAL_RAG|.
    cur.execute("DELETE FROM document_chunks WHERE document_id IN "
                "(SELECT id FROM knowledge_documents WHERE file_name LIKE 'EVALRET|%')")
    cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE 'EVALRET|%'")
    conn.commit()
    pipeline = IngestionPipeline(enrich_with_llm=True)
    embedder = LocalEmbedder()
    doc_ids = []
    try:
        files = sorted(f for ext in ("*.pdf", "*.docx") for f in DOCS_DIR.glob(ext))
        for f in files:
            print(f"[ingest] {f.name}", flush=True)
            chunks = pipeline.process_file(f)
            chunks = embedder.embed_chunks(chunks, batch_size=32)
            did = str(uuid.uuid4())
            cur.execute(
                "INSERT INTO knowledge_documents "
                "(id,file_name,file_type,status,file_path,allowed_departments) "
                "VALUES (%s,%s,'pdf','COMPLETED',%s,ARRAY['ALL'])",
                (did, "EVAL_RAG|" + f.name, str(f)),
            )
            execute_values(
                cur,
                """INSERT INTO document_chunks (
                    document_id, chunk_index, chunk_type, breadcrumb, content,
                    page_number, summary, keywords, hypothetical_questions,
                    allowed_jobs, allowed_departments,
                    content_vector, questions_vector
                ) VALUES %s;""",
                [
                    (
                        did, i + 1, c.chunk_type, c.breadcrumb, c.content,
                        c.page_number, c.summary, c.keywords,
                        c.hypothetical_questions,
                        c.allowed_jobs, c.allowed_departments,
                        c.content_vector, c.questions_vector,
                    )
                    for i, c in enumerate(chunks)
                ],
            )
            conn.commit()
            print(f"[ingest] -> {len(chunks)} chunks (doc {did[:8]})", flush=True)
            doc_ids.append(did)
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
    return doc_ids


def cleanup_eval_corpus(doc_ids, keep_corpus=False):
    from src.db.session import get_db_connection

    conn = get_db_connection()
    cur = conn.cursor()
    if not keep_corpus:
        cur.execute("DELETE FROM document_chunks WHERE document_id = ANY(%s::uuid[]);",
                    (doc_ids,))
        cur.execute("DELETE FROM knowledge_documents WHERE id = ANY(%s::uuid[]);",
                    (doc_ids,))
    cur.execute(
        "DELETE FROM chat_messages WHERE conversation_id IN "
        "(SELECT id FROM chat_conversations WHERE user_id = %s);",
        (EVAL_USER,),
    )
    cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (EVAL_USER,))
    conn.commit()
    cur.close()
    conn.close()
    print("[cleanup] da xoa corpus + conversation EVAL_RAGAS", flush=True)


def _purge_eval_cache(questions) -> None:
    """Xoa cache rows gan giong cau test de moi answer sinh tuoi (test rule
    generation moi). Nguong 0.90 duoi nguong hit 0.95: chi nhung row KIEU
    GI quote test moi bi xoa; cache prod khac biet khong anh huong."""
    from src.db.session import get_db_connection
    from src.embeddings.local_embedder import LocalEmbedder

    embedder = LocalEmbedder()
    vecs = embedder.generate_embeddings_batch(questions, batch_size=32)
    conn = get_db_connection()
    cur = conn.cursor()
    doomed = set()
    for v in vecs:
        cur.execute(
            "SELECT id FROM semantic_cache "
            "WHERE 1 - (query_vector <=> %s::vector) >= 0.90", (str(v),))
        doomed.update(r[0] for r in cur.fetchall())
    if doomed:
        cur.execute("DELETE FROM semantic_cache WHERE id = ANY(%s::uuid[])",
                    (list(doomed),))
    conn.commit()
    cur.close()
    conn.close()
    print(f"[eval] purged {len(doomed)} cache rows ~ cau test", flush=True)


def _gold_hit(gold_preview: str, got) -> int | None:
    """Tra ve rank (1-based) cua chunk vang trong retrieved, None neu rot top-k."""
    needle = re.sub(r"\s+", " ", (gold_preview or "")[:150]).strip().lower()
    if not needle:
        return None
    for i, c in enumerate(got):
        hay = re.sub(r"\s+", " ", (c.get("content") or "")).lower()
        if needle in hay:
            return i + 1
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=10, help="So cau chay (mac dinh 10)")
    ap.add_argument("--review", type=str, default=None,
                    help="JSON review tay (review_30_manual.json): dung thay cho sampling, gold tay lam reference")
    ap.add_argument("--retrieve-only", action="store_true",
                    help="Chi do retrieval (top1/fallback/Hit@k): mien phi, khong goi judge")
    ap.add_argument("--reuse", action="store_true",
                    help="Dung corpus EVAL_RAG san co trong DB, khong ingest lai (0 Vision call, 0 cho)")
    ap.add_argument("--no-judge", action="store_true",
                    help="Chi sinh dap an + contexts, khong cham RAGAS (0 judge call, so sanh tay voi gold)")
    ap.add_argument("--ids", type=str, default=None,
                    help="Chi chay cac id trong review file, vd --ids 3,6,9,20,26")
    ap.add_argument("--top-k", type=int, default=3)
    args = ap.parse_args()
    global OUT
    if args.ids:
        OUT = OUT.with_name("ragas_eval_rerun.json")

    from src.chat.chat_service import ChatService, reset_usage, take_usage
    from src.retrievers.hybrid_retriever import HybridRetriever

    all_rows = json.loads(TESTSET.read_text(encoding="utf-8"))
    if args.review:
        # ponytail: review tay la source of truth duy nhat — khong resample, gold tay lam
        # reference (thay hint nhap). Ceiling: schema review file phai co question/answer.
        rev = json.loads(Path(args.review).read_text(encoding="utf-8"))
        if args.ids:
            want = {int(x) for x in args.ids.split(",") if x.strip().isdigit()}
            rev = [r for r in rev if r.get("id") in want]
        rows = [{
            "question": r["question"],
            "ground_truth_hint": r.get("answer") or r.get("reference") or "",
            "content_preview": r.get("content_preview") or "",
            "source_file": r.get("source_file"),
        } for r in (rev if args.ids else rev[:args.n])]
        print(f"[eval] {len(rows)} cau review tay tu {args.review}", flush=True)
    else:
        # Bo cau chunk thieu thong tin (LLM da danh dau, khong do duoc)
        usable = [r for r in all_rows
                  if "THIEU THONG TIN" not in (r.get("answer_draft") or "")]
        # ponytail: lay mau dan theo file thay vi N dong dau (30 dong dau toan
        # 214/917). Ceiling: chua can bang theo do kho cau.
        by_file: dict = {}
        for r in usable:
            by_file.setdefault(r.get("source_file", "?"), []).append(r)
        rows = []
        i = 0
        while len(rows) < args.n and any(by_file.values()):
            for k in sorted(by_file):
                if by_file[k] and len(rows) < args.n:
                    rows.append(by_file[k].pop(0))
            i += 1
            if i > args.n + 5:
                break
        print(f"[eval] {len(rows)}/{len(all_rows)} cau hoi (dan theo file, "
              f"{len(by_file)} file)", flush=True)

    if args.reuse:
        # ponytail: corpus EVAL_RAG trong DB da dung noi dung can test (cung code ingest +
        # cung fallback khi Vision 429) thi ingest lai chi dot quota/cho vo ich. Khong thay
        # gi thi khong nap lai. Ceiling: doi code parser thi phai ingest lai.
        from src.db.session import get_db_connection as _g
        _c = _g(); _cur = _c.cursor()
        _cur.execute("SELECT id FROM knowledge_documents WHERE file_name LIKE 'EVAL_RAG|%'")
        doc_ids = [str(r[0]) for r in _cur.fetchall()]
        _cur.close(); _c.close()
        if not doc_ids:
            raise SystemExit("[reuse] DB khong co corpus EVAL_RAG — chay khong --reuse de ingest.")
        print(f"[eval] reuse {len(doc_ids)} docs EVAL_RAG san co, bo qua ingest", flush=True)
    else:
        doc_ids = ingest_eval_corpus()
    try:
        _purge_eval_cache([r["question"] for r in rows])
        ret = HybridRetriever()
        if args.retrieve_only:
            from src.chat.chat_service import RELEVANCE_THRESHOLD
            out_rows, top1s, hits = [], [], 0
            for i, r in enumerate(rows):
                got = ret.retrieve(query=r["question"], jobs=["ALL"],
                                     departments=["ALL"], top_k=args.top_k)
                top1 = got[0]["relevance_score"] if got else 0.0
                rank = _gold_hit(r.get("content_preview", ""), got)
                top1s.append(top1)
                hits += 1 if rank else 0
                out_rows.append({
                    "question": r["question"][:120],
                    "source_file": r.get("source_file"),
                    "top1_score": round(top1, 4),
                    "gold_rank": rank,
                    "fallback": top1 < RELEVANCE_THRESHOLD,
                })
                if (i + 1) % 20 == 0:
                    print(f"[eval] {i + 1}/{len(rows)}", flush=True)
            top1s_sorted = sorted(top1s)
            summary = {
                "n": len(rows),
                "threshold": RELEVANCE_THRESHOLD,
                "fallback_rate": round(
                    sum(1 for t in top1s if t < RELEVANCE_THRESHOLD) / len(rows), 4),
                "hit_at_k": round(hits / len(rows), 4),
                "top1_mean": round(sum(top1s) / len(top1s), 4),
                "top1_p50": round(top1s_sorted[len(top1s_sorted) // 2], 4),
            }
            print("\n== RETRIEVAL ==")
            for k, v in summary.items():
                print(f"  {k} = {v}")
            OUT.write_text(json.dumps(
                {"mode": "retrieve-only", "top_k": args.top_k,
                 "summary": summary, "rows": out_rows},
                ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[eval] -> {OUT}")
            return

        svc = ChatService()
        samples = []
        for i, r in enumerate(rows):
            q = r["question"]
            t0 = time.time()  # latency/turn: tong tu hoi den co dap an
            reset_usage()  # token/turn: gom tu moi LLM call trong cau nay
            out = svc.answer_query(
                q, user_id=EVAL_USER,
                jobs=["ALL"], departments=["ALL"], top_k=7,
            )
            # ponytail: contexts dem cham PHAI la chunks dap an da dung.
            # answer path retrieve bang cau rewrite (+ cau goc lam alt);
            # retrieve lai bang cau goc cho chunks khac -> faithfulness 0 oan.
            rq = out.get("rewritten_query") or q
            got = ret.retrieve(query=rq, jobs=["ALL"], departments=["ALL"],
                               top_k=3, alt_queries=[q])
            ctx = [c["content"] for c in got if c.get("content")]
            u = take_usage()
            # Chi cau DOC thanh cong (confidence HIGH/MEDIUM) moi vao RAGAS:
            # cau rot DB/OUT_OF_SCOPE/fallback co answer la thong bao loi,
            # cham chung chi lam nhieu metric oan.
            ok = out.get("confidence") in ("HIGH", "MEDIUM")
            samples.append({
                "user_input": q,
                "retrieved_contexts": ctx,
                "response": out["answer"],
                "reference": r.get("ground_truth_hint") or "",
                "confidence": out.get("confidence"),
                "judged": ok,
                "dropped_claims": out.get("dropped_claims", 0),
                "elapsed": round(time.time() - t0, 2),
                "prompt_tokens": u["in"],
                "completion_tokens": u["out"],
                "llm_calls": u["calls"],
            })
            print(f"[eval] {i + 1}/{len(rows)} ctx={len(ctx)} "
                  f"ans={len(out['answer'])} chars conf={out.get('confidence')} "
                  f"{'JUDGE' if ok else 'SKIP'}", flush=True)

        if args.no_judge:
            # ponytail: ghi dap an + contexts de so tay voi gold review,
            # khong dot ~120 judge calls (tien + gio). Chay trong try nen
            # finally van don EVAL_RAGAS nhu cu.
            OUT.write_text(json.dumps({
                "mode": "no-judge",
                "n": len(rows),
                "rows": [
                {
                    "question": s["user_input"],
                    "answer": s["response"],
                    "reference": s["reference"],
                    "contexts": s["retrieved_contexts"],
                    "confidence": s["confidence"],
                    "judged": s["judged"],
                    "dropped_claims": s.get("dropped_claims", 0),
                    "elapsed": s.get("elapsed"),
                    "prompt_tokens": s.get("prompt_tokens"),
                    "completion_tokens": s.get("completion_tokens"),
                    "llm_calls": s.get("llm_calls"),
                }
                    for s in samples
                ],
            }, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[eval] -> {OUT} (no-judge: so tay voi review_30_manual.json)")
            return

        import warnings
        warnings.filterwarnings("ignore")
        from openai import OpenAI
        from datasets import Dataset as HFDataset
        from langchain_huggingface import HuggingFaceEmbeddings
        from ragas import evaluate
        from ragas.embeddings import LangchainEmbeddingsWrapper
        from ragas.llms import llm_factory
        # ragas 0.4.x: evaluate() cu chi nhan metric v1 (singleton), khong nhan
        # collections v2 (chi dung voi @experiment moi).
        from ragas.metrics._answer_relevance import answer_relevancy
        from ragas.metrics._context_precision import context_precision
        from ragas.metrics._context_recall import context_recall
        from ragas.metrics._faithfulness import faithfulness

        # ponytail: max_tokens lon + temperature 0 — judge tra JSON dai,
        # thieu la bi cat giua chung (IncompleteOutputException hang loat).
        judge = llm_factory(
            os.getenv("OLLAMA_MODEL", "gemma4:31b"),
            provider="openai",
            client=OpenAI(
                base_url=os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1"),
                api_key=os.getenv("OLLAMA_API_KEY", "ollama"),
            ),
            max_tokens=4096,
            temperature=0,
        )
        emb = LangchainEmbeddingsWrapper(HuggingFaceEmbeddings(
            model_name=os.getenv(
                "LOCAL_EMBEDDING_MODEL",
                "bkai-foundation-models/vietnamese-bi-encoder",
            )
        ))

        judged = [s for s in samples if s["judged"]]
        print(f"[eval] {len(judged)}/{len(samples)} cau DOC thanh cong vao judge",
              flush=True)
        ds = HFDataset.from_dict({
            "question": [s["user_input"] for s in judged],
            "answer": [s["response"] for s in judged],
            "contexts": [s["retrieved_contexts"] for s in judged],
            "ground_truths": [[s["reference"]] for s in judged],
            "reference": [s["reference"] for s in judged],
        })
        metrics = [faithfulness, answer_relevancy, context_precision, context_recall]
        result = evaluate(ds, metrics=metrics, llm=judge, embeddings=emb)
        df = result.to_pandas()
        summary = {m.name: round(float(df[m.name].mean()), 4) for m in metrics}
        print("\n== RAGAS ==")
        for k, v in summary.items():
            print(f"  {k} = {v}")
        scored = {
            s["user_input"]: {
                m.name: (None if df[m.name].iloc[j] != df[m.name].iloc[j]
                         else float(df[m.name].iloc[j]))
                for m in metrics
            }
            for j, s in enumerate(judged)
        }

        OUT.write_text(json.dumps({
            "n": len(rows),
            "n_judged": len(judged),
            "summary": summary,
            "rows": [
                {
                    "question": s["user_input"],
                    "answer": s["response"][:500],
                    "reference": s["reference"],
                    "n_contexts": len(s["retrieved_contexts"]),
                    "confidence": s["confidence"],
                    "judged": s["judged"],
                    "dropped_claims": s.get("dropped_claims", 0),
                    "elapsed": s.get("elapsed"),
                    "prompt_tokens": s.get("prompt_tokens"),
                    "completion_tokens": s.get("completion_tokens"),
                    "llm_calls": s.get("llm_calls"),
                    **scored.get(s["user_input"], {m.name: None for m in metrics}),
                }
                for s in samples
            ],
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[eval] -> {OUT}")
    finally:
        # ponytail: --reuse thi corpus la do chung, khong duoc xoa; chi don conversations.
        cleanup_eval_corpus(doc_ids, keep_corpus=args.reuse)


if __name__ == "__main__":
    main()
