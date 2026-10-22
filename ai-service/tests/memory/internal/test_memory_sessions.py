"""
Rewrite-only eval tren du lieu NOI BO: tests/memory/internal/memory_internal.csv
(30 conv x 12 turns, full triple Q/A/rewrite; dap an neo chunk noi bo / BLLĐ).

Chay: python tests/memory/internal/test_memory_sessions.py
Khong can DB/server (goi thang ChatService.rewrite_and_route_step = dung duong
prod: merged rewrite+route, 1 LLM call/turn; kem route moi turn). Moi turn i
dung gold history j<i de viet lai, cham overlap vs cot `rewrite`.

Output: tests/memory/internal/memory_internal_results.json (tung cau + route).
"""
import sys
import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from src.chat.chat_service import ChatService  # noqa: E402

CSV_FILE = Path(__file__).resolve().parent / "memory_internal.csv"
OUT_JSON = Path(__file__).resolve().parent / "memory_internal_results.json"

MAX_SESSIONS = 50

WORD_RE = re.compile(r"\w{4,}", re.UNICODE)
# ponytail: stopword tieng Viet hard-code, khong dung NLP. Ceiling: tu co nghia
# bi loai nham. Nang len -> embedding similarity.
STOPWORDS = {
    "này", "được", "của", "không", "những", "một", "cho", "với", "nào", "gì",
    "phần", "trăm", "lãnh", "nhiêu", "toàn", "cũng", "đã", "đang", "khi",
    "về", "trong", "thời", "đại", "phải", "từ", "ra", "vào", "các", "như",
}


def content_words(text: str) -> set:
    return {w.lower() for w in WORD_RE.findall(text or "")} - STOPWORDS


def overlap(expected: str, actual: str) -> float:
    exp = content_words(expected)
    return (len(exp & content_words(actual)) / len(exp)) if exp else 1.0


def load_sessions() -> Dict[int, List[Dict[str, str]]]:
    sessions: Dict[int, List[Dict[str, str]]] = defaultdict(list)
    with open(CSV_FILE, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            sessions[int(row["session_id"])].append(row)
    for turns in sessions.values():
        turns.sort(key=lambda t: int(t["turn_id"]))
    return sessions


def select_sessions(sessions: Dict[int, List[Dict[str, str]]]) -> List[int]:
    # ponytail: top dai nhat, tie-break session_id de chay lai giong nhau.
    # Ceiling: session ngan (<6 turns) chua duoc test.
    ranked = sorted(sessions.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    return [sid for sid, _ in ranked[:MAX_SESSIONS]]


def run_session(sid: int, turns: List[Dict[str, str]], svc: ChatService) -> Dict:
    # ponytail: history lay tu gold Q/A, khong dung summary rolling.
    # Ceiling: session >20 msgs lech khoi prod (prod co context_summary).
    history: List[Dict[str, str]] = []
    rows = []
    for i, t in enumerate(turns):
        rw, route = svc.rewrite_and_route_step(t["question"], history, None)
        # ponytail: chi cham turn co rewrite != question; turn cau hoi da doc lap
        # thi condense tra ve nguyen cau, cho 1.0 la diem ao.
        needs = t["rewrite"].strip() != t["question"].strip()
        r_score = round(overlap(t["rewrite"], rw), 3) if needs else None
        rows.append({
            "turn": i,
            "question": t["question"],
            "expected_rewrite": t["rewrite"],
            "actual_rewrite": rw,
            "llm_rewritten": rw.strip() != t["question"].strip(),
            "route": route,
            "needs_rewrite": needs,
            "rewrite_score": r_score,
        })
        history.append({"role": "USER", "content": t["question"]})
        history.append({"role": "ASSISTANT", "content": t["answer"]})

    graded = [r for r in rows if r["needs_rewrite"]]
    return {
        "session_id": sid,
        "turns": len(rows),
        "graded_turns": len(graded),
        "rewrite_score": round(sum(r["rewrite_score"] for r in graded) / len(graded), 3) if graded else None,
        "llm_rewrote": sum(1 for r in rows if r["llm_rewritten"]),
        "rows": rows,
    }


def main() -> None:
    sessions = load_sessions()
    print(f"[data] {sum(len(t) for t in sessions.values())} turns / {len(sessions)} sessions")
    selected = select_sessions(sessions)
    print(f"[select] top {len(selected)}: {selected}")

    svc = ChatService()  # 1 lan; condense khong dung retriever/DB
    results = []
    for sid in selected:
        print(f"=== session {sid} ({len(sessions[sid])} turns) ===")
        try:
            r = run_session(sid, sessions[sid], svc)
            rw = f"{r['rewrite_score']:.2f}" if r["rewrite_score"] is not None else "n/a"
            print(f"  rewrite={rw} llm_rewrote={r['llm_rewrote']}/{r['turns']}")
            results.append(r)
        except Exception as e:
            print(f"  ERROR: {e}")
            results.append({"session_id": sid, "turns": 0, "graded_turns": 0,
                            "rewrite_score": None, "llm_rewrote": 0, "rows": [],
                            "error": str(e)})

    print("\n" + "=" * 64)
    print(f"{'session':>8} {'turns':>6} {'graded':>7} {'llm_rw':>7} {'rewrite':>9}")
    for r in results:
        rw = f"{r['rewrite_score']:.2f}" if r.get("rewrite_score") is not None else "n/a"
        print(f"{r['session_id']:>8} {r.get('turns', 0):>6} {r.get('graded_turns', 0):>7} "
              f"{r.get('llm_rewrote', 0):>7} {rw:>9}")
    ok = [r for r in results if r.get("turns")]
    graded = [r for r in ok if r.get("rewrite_score") is not None]
    if ok:
        rw_avg = sum(r["rewrite_score"] for r in graded) / len(graded) if graded else float("nan")
        print(f"\nTONG: rewrite={rw_avg:.3f} ({len(graded)}/{len(ok)} session cham duoc) "
               f"llm_rewrote={sum(r['llm_rewrote'] for r in ok)}/{sum(r['turns'] for r in ok)} turn")
        # ponytail: khong gate PASS/FAIL — bo internal de kho hon han, so la baseline
        # mo ta de diff hoi quy, khong phai diem do/truot. Gate prod giu bo QRECC + retrieval.
        print(f"ROUTE: {dict(Counter(r.get('route') for s in ok for r in s['rows']))}")

    OUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Chi tiet: {OUT_JSON}")


if __name__ == "__main__":
    main()
