"""
Tach ket qua 2 file test lon thanh JSON rieng cho tung session + 1 file tong hop.

Input : tests/viquad_eval_results.json, tests/memory_session_results.json
Output: tests/results/<test>_<session>.json + tests/results/summary.json
Chay  : python tests/split_results.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "results"
OUT.mkdir(exist_ok=True)


def dump(name, obj):
    (OUT / name).write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")
    return OUT / name


def split_viquad():
    src = HERE / "viquad_eval_results.json"
    if not src.exists():
        return None
    d = json.loads(src.read_text(encoding="utf-8"))
    per_query = []
    for r in d["rows"]:
        f = dump(
            f"viquad_q{r['idx'] + 1:03d}.json",
            {"test": "test_standard_eval", "suite": d["name"], "query_index": r["idx"], **r},
        )
        per_query.append(f.name)
    meta = {k: v for k, v in d.items() if k != "rows"}
    meta["per_query_files"] = per_query
    return dump("viquad_summary.json", {"test": "test_standard_eval", **meta})


def split_memory():
    src = HERE / "memory_session_results.json"
    if not src.exists():
        return None
    d = json.loads(src.read_text(encoding="utf-8"))
    per_session = []
    for s in d:
        f = dump(
            f"memory_session_{s['session_id']}.json",
            {"test": "test_memory_sessions", **{k: v for k, v in s.items() if k != "rows"}},
        )
        per_session.append(f.name)

    n = len(d)
    agg = {
        "n_sessions": n,
        "rewrite_score": round(sum(s["rewrite_score"] for s in d) / n, 4),
        "answer_score": round(sum(s["answer_score"] for s in d) / n, 4),
        "recall_score": round(sum(s["recall_score"] for s in d) / n, 4),
        "summary_ok": sum(1 for s in d if s["summary_ok"]),
        "total_turns": sum(s["turns"] for s in d),
        "total_graded": sum(s["graded_turns"] for s in d),
        "total_llm_rewrote": sum(s["llm_rewrote"] for s in d),
        "worst_sessions": sorted(d, key=lambda s: s["answer_score"])[:3],
    }
    for s in agg["worst_sessions"]:
        s.pop("rows", None)
        s.pop("recall_answer", None)
    return dump(
        "memory_summary.json",
        {"test": "test_memory_sessions", "aggregate": agg, "per_session_files": per_session},
    )


if __name__ == "__main__":
    v = split_viquad()
    m = split_memory()
    print("viquad :", v.name if v else "MISSING")
    print("memory :", m.name if m else "MISSING")
    print("files  :", len(list(OUT.glob('*.json'))))
