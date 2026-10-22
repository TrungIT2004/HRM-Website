"""Latency + usage memory theo tung turn (doc answers_memory.json san co)."""
import json
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
rows = json.loads((HERE / "answers_memory.json").read_text(encoding="utf-8"))


def stats(rs: list, key: str) -> dict:
    v = sorted(r[key] for r in rs)
    return {"n": len(v), "mean": round(statistics.mean(v), 2),
            "p50": round(statistics.median(v), 2),
            "p95": round(v[max(0, int(len(v) * 0.95) - 1)], 2),
            "max": round(v[-1], 2)}


print("== ELAPSED end-to-end/turn (giay) ==")
print(" all:", stats(rows, "elapsed_s"))
t1 = [r for r in rows if r["turn_index"] == 1]
tn = [r for r in rows if r["turn_index"] > 1]
print(" turn1:", stats(t1, "elapsed_s"))
print(" turn2+:", stats(tn, "elapsed_s"))
print("== TOKENS/turn ==")
print(" prompt_in:", stats(rows, "prompt_tokens"))
print(" completion_out:", stats(rows, "completion_tokens"))
print("== CONFIDENCE ==",
      {k: sum(1 for r in rows if r["confidence"] == k) for k in ("HIGH", "MEDIUM", "LOW")})

if "--csv" in sys.argv:
    with open(HERE / "latency_per_turn.csv", "w", encoding="utf-8-sig") as fh:
        fh.write("id,conversation_id,turn_index,answerable,confidence,elapsed_s,"
                 "prompt_tokens,completion_tokens,rewrite_cosine,carryover,"
                 "rank_before,rank_after\n")
        for r in rows:
            fh.write(f"{r['id']},{r['conversation_id']},{r['turn_index']},"
                     f"{int(r['answerable'])},{r['confidence']},{r['elapsed_s']},"
                     f"{r['prompt_tokens']},{r['completion_tokens']},"
                     f"{r['rewrite_cosine']},{r['carryover']},"
                     f"{r['rank_before']},{r['rank_after']}\n")
    print("-> latency_per_turn.csv")
