"""Eval chuẩn BEIR cho HRM RAG: Hit@k / MRR@5 / latency, trực tiếp qua HybridRetriever (ko cần uvicorn).
Chuẩn: BEIR protocol (corpus + queries + qrels mini) + SQuAD EM/F1 proxy cho ViQuAD.
Chạy: pip install datasets && python tests/test_standard_eval.py
# ponytail: 1 file, reuse HybridRetriever/LocalEmbedder, tag EVAL_ + cleanup. Ceiling: mini-corpus 100q (lên full BEIR khi Hit@5>70%).
"""
import sys, time, uuid, json, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
if sys.stdout.encoding != 'utf-8':
    try: sys.stdout.reconfigure(encoding='utf-8')
    except Exception: pass

N, TOPK = (int(sys.argv[1]) if len(sys.argv) > 1 else 100), 5
TAG = "EVAL_STD"
OUT = Path(__file__).parent / "viquad_eval_results.json"

def norm(s): return re.sub(r"\s+", " ", (s or "").lower().strip())

def metrics(results):
    # results: list of (rank_of_first_gold_or_None, latency)
    h1 = sum(1 for r, _ in results if r == 1) / len(results)
    h3 = sum(1 for r, _ in results if r and r <= 3) / len(results)
    h5 = sum(1 for r, _ in results if r and r <= 5) / len(results)
    mrr = sum(1 / r for r, _ in results if r) / len(results)
    lat = sorted(l for _, l in results)
    print(f"Hit@1={h1:.0%} Hit@3={h3:.0%} Hit@5={h5:.0%} MRR@5={mrr:.3f} p50={lat[len(lat)//2]:.2f}s max={max(lat):.2f}s")
    print("DAT neu: Hit@5>=60% (mini-corpus), MRR>=0.45. Retriever miss -> them chunk/kw; rerank sai -> check CrossEncoder.")
    return h1, h3, h5, mrr

def run_eval(name, queries, gold_of, doc_of, retriever, answers=None):
    """queries: [q], gold_of: q_idx -> {gold_keys}, doc_of: key -> text. Insert mini-corpus tag EVAL, retrieve, cleanup."""
    from src.db.session import get_db_connection
    from src.embeddings.local_embedder import LocalEmbedder
    conn = get_db_connection(); cur = conn.cursor()
    did = str(uuid.uuid4())
    try:
        cur.execute("INSERT INTO knowledge_documents (id,file_name,file_type,status,file_path,allowed_departments) VALUES (%s,%s,'eval','COMPLETED','eval',ARRAY['ALL'])", (did, TAG + name))
        keys = list(doc_of)
        vecs = LocalEmbedder().generate_embeddings_batch([doc_of[k] for k in keys])
        for i, k in enumerate(keys):
            cur.execute("INSERT INTO document_chunks (id,document_id,chunk_index,chunk_type,breadcrumb,content,allowed_jobs,allowed_departments,content_vector,questions_vector) VALUES (%s,%s,%s,'EVAL',%s,%s,ARRAY['ALL'],ARRAY['ALL'],%s::vector,%s::vector)",
                        (str(uuid.uuid4()), did, i, f"{TAG}|{k}", doc_of[k], vecs[i], vecs[i]))
        conn.commit()
        print(f"\n[eval] {name}: inserted {len(keys)} docs, retrieving {len(queries)} queries...", flush=True)
        res, rows = [], []
        for qi, q in enumerate(queries):
            t0 = time.time()
            got = retriever.retrieve(query=q, jobs=["ALL"], departments=["ALL"], top_k=TOPK)
            dt = time.time() - t0
            if qi < 3 or (qi + 1) % 10 == 0:
                print(f"[eval] q{qi+1}/{len(queries)} {dt:.1f}s top1={got[0]['relevance_score'] if got else 0:.3f}", flush=True)
            rank = next((i + 1 for i, c in enumerate(got) if c["breadcrumb"].replace(TAG + "|", "") in gold_of[qi]), None)
            res.append((rank, dt))
            top1_ctx = next((c["content"] for c in got if c["breadcrumb"].replace(TAG + "|", "") in gold_of[qi]), "")
            rows.append({
                "idx": qi, "question": q, "rank": rank, "latency_s": round(dt, 3),
                "top1_score": got[0]["relevance_score"] if got else 0.0,
                "top1_breadcrumb": got[0]["breadcrumb"].replace(TAG + "|", "") if got else None,
                "gold_keys": sorted(gold_of[qi]),
                "retrieved": [{"rank": i + 1, "breadcrumb": c["breadcrumb"].replace(TAG + "|", ""), "score": c["relevance_score"]} for i, c in enumerate(got)],
                # proxy reader: cau tra loi co nam trong context cua chunk dau tien co gold khong
                "answer_in_gold_chunk": bool(answers and answers[qi] and norm(answers[qi]) in norm(top1_ctx)),
                "gold_answer": answers[qi] if answers else None,
            })
        print(f"\n== {name} (n={len(queries)}) ==")
        agg = metrics(res)
        OUT.write_text(json.dumps({
            "name": name, "n": len(queries), "top_k": TOPK, "n_docs": len(keys),
            "hit@1": agg[0], "hit@3": agg[1], "hit@5": agg[2], "mrr@5": agg[3],
            "p50_latency_s": round(sorted(l for _, l in res)[len(res) // 2], 3),
            "max_latency_s": round(max(l for _, l in res), 3),
            "reranker": retriever.reranker is not None,
            "rows": rows,
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"[eval] -> {OUT}")
        return agg
    finally:
        cur.execute("DELETE FROM document_chunks WHERE breadcrumb LIKE %s", (TAG + "|%",))
        cur.execute("DELETE FROM knowledge_documents WHERE id=%s", (did,))
        conn.commit(); cur.close(); conn.close()

if __name__ == "__main__":
    from src.retrievers.hybrid_retriever import HybridRetriever
    no_rr = len(sys.argv) > 2 and sys.argv[2] == "no-rerank"
    R = HybridRetriever(use_reranker=not no_rr)  # production path: hybrid 0.7/0.3 + CrossEncoder rerank
    print(f"[eval] reranker={'OFF' if no_rr else 'ON'}", flush=True)
    # --- ViQuAD (TV, dung nghia nhat). Tai 1 file SQuAD-JSON tu Kaggle nguyendolikeyou/uit-viquad -> tests/data/viquad.json ---
    p = Path(__file__).parent / "data" / "viquad.json"
    if not p.exists():
        print(f"\n[ViQuAD] bo qua (thieu {p}). Tai train_formatted.json tu kaggle.com/datasets/nguyendolikeyou/uit-viquad -> luu vao {p} roi chay lai.")
        sys.exit(1)
    vq = json.loads(p.read_text(encoding="utf-8"))
    Q2, G2, D2, A2 = [], [], {}, []
    for art in vq["data"][:N]:
        for para in art["paragraphs"]:
            D2.setdefault(para["context"][:60], para["context"])
            for qa in para["qas"]:
                if qa.get("answers"):
                    Q2.append(qa["question"]); G2.append({para["context"][:60]}); A2.append(norm(qa["answers"][0]["text"]))
                    if len(Q2) >= N: break
            if len(Q2) >= N: break
        if len(Q2) >= N: break
    run_eval("viquad", Q2, G2, D2, R, answers=A2)
    print("(proxy reader: answer_in_gold_chunk = cau tra loi co nam trong context chunk co gold; EM/F1 day du can LLM server)")
