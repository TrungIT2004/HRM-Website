"""Tra loi multi-turn NOI BO end-to-end: 12 conv x 12 turns qua POST /chat/query
that (rewrite+route -> retrieval -> threshold 0.64 -> LLM answer), noi turn
bang conversation_id. Ghi dap an + citations + refused + latency moi turn.

Chay: python tests/memory/internal/test_answers.py
Output: tests/memory/internal/memory_answer_results.json
Danh gia: overlap vs gold answer CHI DE SAP XEP review tay (khong phai gate);
nguoi cham 20-30 turns co overlap thap / refused.
"""
import sys
import csv
import json
import os
import re
import time
from collections import defaultdict
from pathlib import Path
from typing import Dict, List

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))
from dotenv import load_dotenv  # noqa: E402

load_dotenv()

from fastapi.testclient import TestClient  # noqa: E402

from main import app, INTERNAL_API_SECRET  # noqa: E402
from src.chat.chat_service import _NO_INFO_MARKERS, reset_usage, take_usage  # noqa: E402

HERE = Path(__file__).resolve().parent
CSV_FILE = HERE / "memory_internal.csv"
OUT_JSON = HERE / "memory_answer_results.json"
HEADERS = {"X-Internal-Secret": INTERNAL_API_SECRET}
USER = "35337165-e0d0-4dd1-9c67-cc48180363af"  # hr.employee, da seed resignation/timesheet (that, khong phai UUID ao)

# mac dinh full 30 conv; EVAL_SIDS="1001,...,1010" de chia batch (moi batch ~20 phut,
# timeout tool 60 phut). Ket qua ghi tien trien sau moi conv de timeout khong mat so.
_ALL_SIDS = list(range(1001, 1031))
SIDS = [int(x) for x in os.getenv("EVAL_SIDS", "").split(",") if x.strip()] or _ALL_SIDS

WORD_RE = re.compile(r"\w{4,}", re.UNICODE)
STOP = {"này", "được", "của", "không", "những", "một", "cho", "với", "nào", "gì",
        "phần", "trăm", "lãnh", "nhiêu", "toàn", "cũng", "đã", "đang", "khi",
        "về", "trong", "thời", "đại", "phải", "từ", "ra", "vào", "các", "như"}


def words(t: str) -> set:
    return {w.lower() for w in WORD_RE.findall(t or "")} - STOP


def overlap(exp: str, act: str) -> float:
    e = words(exp)
    return round(len(e & words(act)) / len(e), 3) if e else 1.0


client = TestClient(app)


def cleanup() -> None:
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                "(SELECT id FROM chat_conversations WHERE user_id = %s);", (USER,))
    cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (USER,))
    cur.execute("DELETE FROM semantic_cache;")  # dap an run nay co the sai, khong de poison
    conn.commit()
    cur.close()
    conn.close()


def main() -> None:
    turns: Dict[int, List[Dict[str, str]]] = defaultdict(list)
    with open(CSV_FILE, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            if int(row["session_id"]) in SIDS:
                turns[int(row["session_id"])].append(row)
    for v in turns.values():
        v.sort(key=lambda t: int(t["turn_id"]))
    assert len(turns) == len(SIDS), f"thieu conv: {sorted(turns)}"

    cleanup()
    results, lat = [], []
    for sid in SIDS:
        conv_id = None
        rows = []
        for t in turns[sid]:
            t0 = time.time()
            reset_usage()  # ponytail: do token/turn; background title-gen co the rot vao turn sau (nhieu).
            r = client.post("/api/v1/chat/query", headers=HEADERS, json={
                "question": t["question"], "conversation_id": conv_id,
                "user_id": USER, "user_jobs": ["ALL"],
                "department": "ALL", "top_k": 3})
            dt = round(time.time() - t0, 2)
            usage = take_usage()
            r.raise_for_status()
            b = r.json()
            conv_id = b["conversation_id"]
            ans = b.get("answer", "")
            cits = b.get("citations") or []
            route = b.get("route", "")
            # ponytail: turn DB_ONLY tra loi ca nhan hoa theo user that, khong so
            # duoc voi gold doc chung — chi check route dung + khong loi, overlap chi tham khao.
            db_turn = route in ("DB_ONLY", "HYBRID")
            err = "Text-to-SQL failed" in ans or "Lỗi truy vấn" in ans
            rows.append({
                "turn": int(t["turn_id"]), "question": t["question"],
                "gold_answer": t["answer"], "actual_answer": ans,
                "rewritten": b.get("rewritten_query", ""),
                "route": route,
                "citations": [c.get("document_name", "?") for c in cits],
                "refused": any(m in ans.lower() for m in _NO_INFO_MARKERS),
                "db_ok": (not err) if db_turn else None,
                "overlap": overlap(t["answer"], ans),
                "latency_s": dt,
                "tok_in": usage["in"], "tok_out": usage["out"], "llm_calls": usage["calls"],
            })
            lat.append(dt)
        results.append({"session_id": sid, "conversation_id": conv_id, "rows": rows})
        OUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"sid {sid}: refused={sum(1 for r in rows if r['refused'])}/12 "
              f"avg_overlap={sum(r['overlap'] for r in rows)/12:.2f} "
              f"tok_in={sum(r['tok_in'] for r in rows)} tok_out={sum(r['tok_out'] for r in rows)}")

    lat.sort()
    print(f"\nLATENCY p50={lat[len(lat)//2]:.1f}s p95={lat[int(len(lat)*0.95)]:.1f}s "
          f"max={lat[-1]:.1f}s n={len(lat)}")
    ti = sum(r["tok_in"] for s in results for r in s["rows"])
    to = sum(r["tok_out"] for s in results for r in s["rows"])
    tc = sum(r["llm_calls"] for s in results for r in s["rows"])
    print(f"TOKENS in={ti} out={to} total={ti+to} calls={tc} "
          f"avg/turn in={ti/len(lat):.0f} out={to/len(lat):.0f}")
    low = [(s["session_id"], r["turn"], r["overlap"], r["question"][:60])
           for s in results for r in s["rows"]
           if not r["refused"] and r.get("route") not in ("DB_ONLY", "HYBRID")
           and r["overlap"] < 0.4]
    dbbad = [(s["session_id"], r["turn"], r["question"][:60])
             for s in results for r in s["rows"] if r.get("db_ok") is False]
    print(f"REVIEW QUEUE ({len(low)} turns DOC overlap<0.4, chua refused):")
    for sid, t, o, q in low[:30]:
        print(f"  [{sid} t{t} ov={o}] {q}")
    print(f"DB_ERRORS ({len(dbbad)} turns DB loi): {[f'{s}t{t}' for s, t, _ in dbbad[:10]]}")

    OUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Chi tiet: {OUT_JSON}")
    cleanup()


if __name__ == "__main__":
    main()
