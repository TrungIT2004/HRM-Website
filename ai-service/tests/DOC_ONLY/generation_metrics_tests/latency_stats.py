"""Thong ke latency + tokens theo tung cau va tong hop (doc answers.json)."""
import json
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
rows = json.loads((HERE / "answers.json").read_text(encoding="utf-8"))

gold = [r for r in rows if not r.get("expected_abstain")]
neg = [r for r in rows if r.get("expected_abstain")]


def stats(rs: list, key: str) -> dict:
    v = sorted(r[key] for r in rs)
    return {"n": len(v), "mean": round(statistics.mean(v), 2),
            "p50": round(statistics.median(v), 2),
            "p95": round(v[max(0, int(len(v) * 0.95) - 1)], 2),
            "max": round(v[-1], 2)}


print("== ELAPSED (end-to-end, giay) ==")
print(" golden:", stats(gold, "elapsed_s"))
print(" negatives:", stats(neg, "elapsed_s"))
print("== TOKENS (in/out tren cau golden, dem tu moi LLM call) ==")
print(" prompt_in:", stats(gold, "prompt_tokens"))
print(" completion_out:", stats(gold, "completion_tokens"))
print(" llm_calls:", stats(gold, "llm_calls"))
print("== CONFIDENCE (golden) ==",
      {k: sum(1 for r in gold if r["confidence"] == k) for k in ("HIGH", "MEDIUM", "LOW")})
print("== CONFIDENCE (negatives, ky vong LOW/tu choi) ==",
      {k: sum(1 for r in neg if r["confidence"] == k) for k in ("HIGH", "MEDIUM", "LOW")})

if "--csv" in sys.argv:
    with open(HERE / "latency_per_question.csv", "w", encoding="utf-8-sig") as fh:
        fh.write("id,expected_abstain,confidence,elapsed_s,prompt_tokens,"
                 "completion_tokens,llm_calls,dropped_claims,n_cite\n")
        for r in rows:
            fh.write(f"{r['id']},{int(r['expected_abstain'])},{r['confidence']},"
                     f"{r['elapsed_s']},{r['prompt_tokens']},{r['completion_tokens']},"
                     f"{r['llm_calls']},{r['dropped_claims']},{len(r['citations'])}\n")
    print("-> latency_per_question.csv")
