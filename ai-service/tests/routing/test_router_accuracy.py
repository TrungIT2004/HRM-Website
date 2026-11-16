"""Test keyword_fallback accuracy trên dataset 200 câu DB_ONLY/HYBRID."""
import sys, json
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from src.sql.router import keyword_fallback

DATA_FILE = Path(__file__).resolve().parent.parent / "db_only_hybrid_questions.json"

def load_gold():
    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    gold = []
    for table in data.get("tables", []):
        for q in table.get("questions", []):
            gold.append({
                "question": q["question"],
                "expected": q["expected_route"],
                "table": table["table"],
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
    
    gold = load_gold()
    print(f"Loaded {len(gold)} test cases")

    correct = 0
    confusion = {}
    per_route = {}

    for item in gold:
        pred = keyword_fallback(item["question"])
        exp = item["expected"]
        ok = pred == exp
        if ok:
            correct += 1
        else:
            confusion.setdefault((exp, pred), []).append(item["question"])

        per_route.setdefault(exp, {"total": 0, "correct": 0})
        per_route[exp]["total"] += 1
        if ok:
            per_route[exp]["correct"] += 1

    print(f"\n=== OVERALL ACCURACY: {correct}/{len(gold)} = {correct/len(gold):.1%} ===")
    
    print("\n=== PER-ROUTE ===")
    for route, stats in per_route.items():
        acc = stats["correct"] / stats["total"] if stats["total"] else 0
        print(f"  {route}: {stats['correct']}/{stats['total']} = {acc:.1%}")

    if confusion:
        print("\n=== TOP CONFUSIONS ===")
        for (exp, pred), items in sorted(confusion.items(), key=lambda x: -len(x[1])):
            print(f"  {exp} -> {pred}: {len(items)} cases")
            for q in items[:3]:
                safe = q.encode('ascii', 'replace').decode('ascii')
                print(f"    - {safe[:80]}")

if __name__ == "__main__":
    main()