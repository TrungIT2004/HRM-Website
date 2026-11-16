"""Test full LLM router (rewrite_and_route) trên tất cả câu DOC_ONLY + DB_ONLY/HYBRID."""
import json
import csv
import time
import argparse
from typing import Optional
from pathlib import Path

from test_v2.common import setup_test_env, DB_ONLY_HYBRID_QUESTIONS, DOC_ONLY_DATASET, get_output_path
from test_v2.common.checkpoint import create_checkpoint, ROUTER_CHECKPOINT

setup_test_env()

# Import router function
from src.sql.router import rewrite_and_route, build_router_prompt
from src.utils.llm_completion import complete_router


def load_doc_only():
    """120 câu DOC_ONLY từ doc_only_120.csv"""
    rows = []
    with open(DOC_ONLY_DATASET, encoding="utf-8-sig") as f:
        for r in csv.DictReader(f):
            if "THIEU THONG TIN" in (r.get("answer_draft") or ""):
                continue
            rows.append({
                "question": r["question"],
                "expected_route": "DOC_ONLY",
                "source": "doc",
                "id": f"doc_{len(rows)}"
            })
    return rows


def load_db_hybrid():
    """180 câu DB_ONLY/HYBRID từ db_only_hybrid_questions.json"""
    data = json.loads(DB_ONLY_HYBRID_QUESTIONS.read_text(encoding="utf-8"))
    gold = []
    for table in data.get("tables", []):
        for q in table.get("questions", []):
            gold.append({
                "question": q["question"],
                "expected_route": q["expected_route"],
                "source": "db",
                "id": q["id"]
            })
    return gold


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--reset", action="store_true", help="Clear checkpoint and start fresh")
    parser.add_argument("--limit", type=int, default=0, help="Limit questions to test (0 = all)")
    args = parser.parse_args()

    cp = create_checkpoint(ROUTER_CHECKPOINT)
    if args.reset:
        cp.reset()

    doc_qs = load_doc_only()
    db_qs = load_db_hybrid()
    all_qs = doc_qs + db_qs

    if args.limit:
        all_qs = all_qs[:args.limit]

    # Filter out already-completed
    all_ids = [q["id"] for q in all_qs]
    remaining_ids = cp.get_remaining(all_ids)
    remaining_qs = [q for q in all_qs if q["id"] in remaining_ids]

    print(f"Total questions: {len(all_qs)} (DOC={len(doc_qs)}, DB/HYB={len(db_qs)})")
    print(f"Already done: {len(all_ids) - len(remaining_ids)} | Remaining: {len(remaining_qs)}")

    def llm_complete(system_content: str, user_content: str, tag: str = "rewrite_route",
                     model: Optional[str] = None) -> str:
        return complete_router(system_content, user_content, temperature=0.0)

    correct_route = 0
    start = time.time()

    for i, item in enumerate(remaining_qs, 1):
        q = item["question"]
        exp = item["expected_route"]
        qid = item["id"]

        try:
            t0 = time.time()
            rewritten, route = rewrite_and_route(q, history=[], context_summary=None, llm_complete=llm_complete)
            dt = (time.time() - t0) * 1000

            ok = (route == exp)
            if ok:
                correct_route += 1

            result = {
                "id": qid,
                "question": q,
                "expected": exp,
                "predicted": route,
                "rewritten": rewritten,
                "correct": ok,
                "latency_ms": round(dt, 1)
            }

            # Log to JSONL + checkpoint
            cp.log_result(qid, result)
            cp.mark_done(qid)

            status = "✅" if ok else "❌"
            print(f"[{i}/{len(remaining_qs)}] {status} [{route}] {q[:60]}... ({dt:.0f}ms)")

        except Exception as e:
            print(f"[{i}] ERROR: {e}")
            result = {
                "id": qid, "question": q, "expected": exp,
                "error": str(e), "correct": False
            }
            cp.log_result(qid, result)
            cp.mark_done(qid)

    # Compute overall stats from ALL results (including previously done)
    all_results = cp.load_results()
    total = len(all_results)
    correct_all = sum(1 for r in all_results if r.get("correct"))
    acc = correct_all / total if total else 0
    avg_lat = sum(r.get("latency_ms", 0) for r in all_results) / total if total else 0

    print(f"\n=== ROUTER ACCURACY (cumulative): {correct_all}/{total} = {acc:.1%} ===")
    print(f"Avg latency: {avg_lat:.0f}ms | Total time: {(time.time()-start):.1f}s")

    # Per-route breakdown
    from collections import defaultdict
    by_exp = defaultdict(lambda: {"total": 0, "correct": 0})
    for r in all_results:
        if "error" not in r:
            by_exp[r["expected"]]["total"] += 1
            if r["correct"]:
                by_exp[r["expected"]]["correct"] += 1

    print("\n=== PER-ROUTE ACCURACY ===")
    for exp, stats in sorted(by_exp.items()):
        print(f"  {exp}: {stats['correct']}/{stats['total']} = {stats['correct']/stats['total']:.1%}")

    # Save summary JSON
    out = get_output_path("llm_router_test.json")
    out.write_text(json.dumps({
        "total": total,
        "accuracy": round(acc, 4),
        "avg_latency_ms": round(avg_lat, 1),
        "per_route": {k: {"acc": v["correct"]/v["total"], "total": v["total"]} for k, v in by_exp.items()},
        "details": all_results
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nSaved: {out}")
    print(f"JSONL log: {cp.jsonl_file}")


if __name__ == "__main__":
    main()