"""Do Retrieval DOC_ONLY tren dataset golden (match chinh xac chunk-id).

Metrics @K=1/3/5/10: HitRate (=Recall khi 1 gold/question), Precision, MRR,
latency mean/p50/p95. Sweep: vw 0.5/0.7/0.9 x rerank on/off (6 cau hinh),
moi cau hinh retrieve top-10 roi cat @K (khong goi lap).
Khong sweep chunk size/overlap/embedding: doi chunking la doi chunk-id,
phai relabel dataset — de rieng khi co corpus moi.

Chay tu ai-service:
    python tests/DOC_ONLY/retrieval_metrics_tests/eval_retrieval.py
    python tests/DOC_ONLY/retrieval_metrics_tests/eval_retrieval.py --n 10  # thu nhanh
Output: tests/DOC_ONLY/retrieval_metrics_tests/retrieval_eval.json
"""
import argparse
import json
import statistics
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

DATASET = Path(__file__).resolve().parent.parent / "datasets" / "doc_only_120.json"
OUT = Path(__file__).resolve().parent / "retrieval_eval.json"
KS = (1, 3, 5, 10)
VWS = (0.5, 0.7, 0.9)


def rank_of(gold: str, got: list) -> int | None:
    for i, c in enumerate(got):
        if str(c.get("chunk_id")) == gold:
            return i + 1
    return None


def summarize(ranks: list, lats: list, top1s: list) -> dict:
    n = len(ranks) or 1
    s = {}
    for k in KS:
        hits = [1 if r and r <= k else 0 for r in ranks]
        s[f"hit@{k}"] = round(sum(hits) / n, 4)
        s[f"recall@{k}"] = s[f"hit@{k}"]  # 1 gold/cau -> recall == hit
        s[f"precision@{k}"] = round(sum(h / k for h in hits) / n, 4)
        s[f"mrr@{k}"] = round(sum((1.0 / r) if r and r <= k else 0.0 for r in ranks) / n, 4)
    s |= {"lat_mean_ms": round(statistics.mean(lats), 1) if lats else 0.0,
          "lat_p50_ms": round(statistics.median(lats), 1) if lats else 0.0,
          "lat_p95_ms": round(sorted(lats)[max(0, int(len(lats) * 0.95) - 1)], 1) if lats else 0.0,
          "top1_mean": round(statistics.mean(top1s), 4) if top1s else 0.0}
    return s


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=0, help="Thu nhanh N cau dau (0=het).")
    ap.add_argument("--top-k", type=int, default=10, help="top_k retrieve (prod=5).")
    args = ap.parse_args()

    rows = json.loads(DATASET.read_text(encoding="utf-8"))
    rows = [r for r in rows if "THIEU THONG TIN" not in (r.get("ground_truth") or "")]
    if args.n:
        rows = rows[: args.n]
    print(f"[eval] {len(rows)} cau")

    from src.retrievers.hybrid_retriever import HybridRetriever
    ret = HybridRetriever()  # 1 instance, toggle use_reranker theo call

    results, all_rows = {}, []
    for vw in VWS:
        for rerank in (False, True):
            tag = f"vw={vw}_rerank={'on' if rerank else 'off'}"
            ranks, lats, top1s = [], [], []
            for i, r in enumerate(rows):
                gold = (r.get("relevant_chunk_ids") or [None])[0]
                t = time.perf_counter()
                try:
                    got = ret.retrieve(query=r["question"], jobs=["ALL"],
                                       departments=["ALL"], top_k=args.top_k,
                                       use_reranker=rerank, vw=vw, lw=1.0 - vw)
                except Exception as e:
                    print(f"  [{tag}] loi cau {r['id']}: {e}"[:150])
                    ranks.append(None)
                    lats.append(0.0)
                    top1s.append(0.0)
                    continue
                lats.append((time.perf_counter() - t) * 1000)
                rk = rank_of(gold, got)
                ranks.append(rk)
                top1s.append(got[0]["relevance_score"] if got else 0.0)
                all_rows.append({"id": r["id"], "config": tag,
                                 "gold_rank": rk,
                                 "top5_ids": [str(c.get("chunk_id")) for c in got[:5]],
                                 "top1_score": round(top1s[-1], 4),
                                 "lat_ms": round(lats[-1], 1)})
                if (i + 1) % 30 == 0:
                    print(f"  [{tag}] {i + 1}/{len(rows)}", flush=True)
            results[tag] = summarize(ranks, lats, top1s) | {"n": len(rows)}
            print(f"[{tag}] " + " ".join(
                f"{k}={v}" for k, v in results[tag].items() if "5" in k or "lat" in k))

    OUT.write_text(json.dumps({"configs": results, "rows": all_rows},
                              ensure_ascii=False, indent=2), encoding="utf-8")
    best = max(results, key=lambda t: results[t]["mrr@5"])
    print(f"\n-> {OUT}\nBEST mrr@5: {best} = {results[best]}")


if __name__ == "__main__":
    main()
