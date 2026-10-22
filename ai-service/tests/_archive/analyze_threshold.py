"""
Phan tich RELEVANCE_THRESHOLD tu du lieu co nhan that (memory_session_results.json).

Moi turn co: top1_score (diem rerank) + answer_score (do khop voi dap an that).
Tinh precision/recall theo tung nguong de CHON nguong, khong doan.
Tinh them: voi nguong hien tai, bao nhieu turn bi chan sai.
"""
import json
from pathlib import Path

SRC = Path(__file__).resolve().parent / "memory_session_results.json"
OUT = Path(__file__).resolve().parent / "results" / "threshold_analysis.json"
CURRENT = 0.20  # RELEVANCE_THRESHOLD trong src/chat/chat_service.py
GOOD = 0.5     # answer_score >= 0.5 = tra loi dung

d = json.loads(SRC.read_text(encoding="utf-8"))
turns = [r for s in d for r in s["rows"] if r.get("top1_score") is not None]

# Turn bi chan: confidence=LOW va khong co citation.
blocked = [r for r in turns if r["confidence"] == "LOW" and r["citations"] == 0]
answerable = [r for r in turns if r["confidence"] != "LOW" or r["citations"] > 0]

print(f"turn co diem: {len(turns)} | bi chan: {len(blocked)} | tra loi: {len(answerable)}")
print(f"trong {len(blocked)} turn bi chan, {sum(1 for r in blocked if r['answer_score'] >= GOOD)} "
      f"thuc ra CO the tra loi (top1 da dung nhung bi nguong chan)\n")

print(f"{'nguong':>7} {'giai':>6} {'chan':>6} {'sai':>6} {'dung':>6} {'trong':>6} "
      f"{'recall':>7} {'precision':>10}")
rows = []
for thr in [i / 100 for i in range(0, 101, 2)]:
    kept = [r for r in turns if r["top1_score"] >= thr]
    if not kept:
        continue
    good = sum(1 for r in kept if r["answer_score"] >= GOOD)
    bad = len(kept) - good
    blocked_n = sum(1 for r in turns if r["top1_score"] < thr)
    blocked_bad = sum(1 for r in blocked if r["top1_score"] >= thr)
    recall = good / len(turns)
    prec = good / len(kept)
    mark = " <- hien tai" if abs(thr - CURRENT) < 0.001 else ""
    print(f"{thr:7.2f} {good:6d} {blocked_n:6d} {bad:6d} {blocked_bad:6d} "
          f"{good / len(answerable):6.0%} {prec:9.0%}{mark}")
    rows.append({
        "threshold": thr, "kept": len(kept), "good": good, "wrong": bad,
        "blocked_total": blocked_n, "blocked_that_should_keep": blocked_bad,
        "recall": round(recall, 4), "precision": round(prec, 4),
    })

OUT.write_text(json.dumps({
    "current_threshold": CURRENT,
    "n_turns_scored": len(turns),
    "n_blocked": len(blocked),
    "n_blocked_but_should_answer": sum(1 for r in blocked if r["answer_score"] >= GOOD),
    "grid": rows,
}, ensure_ascii=False, indent=2), encoding="utf-8")

best = max(rows, key=lambda r: (r["recall"], r["precision"]))
print(f"\n-> {OUT.name}")
print(f"Best recall: nguong={best['threshold']:.2f} recall={best['recall']:.0%} "
      f"precision={best['precision']:.0%}")
