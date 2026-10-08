"""Test full LLM router (rewrite_and_route) trên tất cả câu DOC_ONLY + DB_ONLY/HYBRID."""
import sys, json, csv, time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Import router function
from src.sql.router import rewrite_and_route, build_router_prompt
from src.chat.chat_service import ChatService

DOC_CSV = Path(__file__).resolve().parent.parent / "generated_testset.csv"
DB_JSON = Path(__file__).resolve().parent.parent / "db_only_hybrid_questions.json"

def load_doc_only():
    """146 câu DOC_ONLY từ generated_testset.csv"""
    rows = []
    with open(DOC_CSV, encoding="utf-8-sig") as f:
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
    data = json.loads((Path(__file__).resolve().parent.parent / "db_only_hybrid_questions.json").read_text(encoding="utf-8"))
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
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
            sys.stderr.reconfigure(encoding="utf-8")
        except Exception:
            pass

    doc_qs = load_doc_only()
    db_qs = load_db_hybrid()
    all_qs = doc_qs + db_qs
    print(f"Total questions: {len(all_qs)} (DOC={len([q for q in doc_qs])}, DB/HYB={len([q for q in db_qs])})")

    # Initialize ChatService to get LLM completion callback
    svc = ChatService()
    
    def llm_complete(system_content: str, user_content: str, tag: str = "rewrite_route") -> str:
        return svc._llm_complete(system_content, user_content, tag=tag)

    results = []
    correct_route = 0
    start = time.time()

    for i, item in enumerate(all_qs, 1):
        q = item["question"]
        exp = item["expected_route"]
        
        try:
            t0 = time.time()
            rewritten, route = rewrite_and_route(q, history=[], context_summary=None, llm_complete=llm_complete)
            dt = (time.time() - t0) * 1000
            
            ok = (route == exp)
            if ok:
                correct_route += 1
            
            results.append({
                "id": item["id"],
                "question": q,
                "expected": exp,
                "predicted": route,
                "rewritten": rewritten,
                "correct": ok,
                "latency_ms": round(dt, 1)
            })
            
            status = "✅" if ok else "❌"
            print(f"[{i}/{len(all_qs)}] {status} [{route}] {q[:60]}... ({dt:.0f}ms)")
            
        except Exception as e:
            print(f"[{i}] ERROR: {e}")
            results.append({
                "id": item["id"], "question": q, "expected": exp,
                "error": str(e), "correct": False
            })

    total = len(all_qs)
    acc = correct_route / total
    avg_lat = sum(r.get("latency_ms", 0) for r in results) / total
    
    print(f"\n=== ROUTER ACCURACY: {correct_route}/{total} = {acc:.1%} ===")
    print(f"Avg latency: {avg_lat:.0f}ms | Total time: {(time.time()-start):.1f}s")

    # Per-route breakdown
    from collections import defaultdict
    by_exp = defaultdict(lambda: {"total": 0, "correct": 0})
    for r in results:
        if "error" not in r:
            by_exp[r["expected"]]["total"] += 1
            if r["correct"]:
                by_exp[r["expected"]]["correct"] += 1
    
    print("\n=== PER-ROUTE ACCURACY ===")
    for exp, stats in sorted(by_exp.items()):
        print(f"  {exp}: {stats['correct']}/{stats['total']} = {stats['correct']/stats['total']:.1%}")

    # Save results
    out = Path(__file__).resolve().parent / "llm_router_test.json"
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps({
        "total": total,
        "accuracy": round(acc, 4),
        "avg_latency_ms": round(avg_lat, 1),
        "per_route": {k: {"acc": v["correct"]/v["total"], "total": v["total"]} for k, v in by_exp.items()},
        "details": results
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nSaved: {out}")

if __name__ == "__main__":
    main()