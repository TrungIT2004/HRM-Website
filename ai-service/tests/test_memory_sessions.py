"""
Memory Eval: 10 sessions >= 5 turns tu tests/data/memory_dataset.csv.

Chay: python tests/test_memory_sessions.py
Khong can server (FastAPI TestClient, in-process).

Luoi:
  turn 0  -> POST /chat/query {question}                       -> tao conversation moi
  turn N  -> POST /chat/query {question, conversation_id}      -> may tu lay summary + 6 msgs gan nhat
  Danh gia 3 tang: rewritten_query vs cot `rewrite`,
                  answer        vs cot `answer`,
                  context_summary (moc 8/14/20 msgs) giu entity cua turn 0,
                  nho lai (hỏi lại turn 0 sau khi het session).
"""
import sys
import csv
import json
import re
import time
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

import docx
from dotenv import load_dotenv
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
load_dotenv()

from main import app, INTERNAL_API_SECRET  # noqa: E402

HEADERS = {"X-Internal-Secret": INTERNAL_API_SECRET}

CSV_FILE = Path(__file__).resolve().parent / "data" / "memory_dataset.csv"
DOCS_DIR = Path(__file__).resolve().parent / "memory_docs"
OUT_JSON = Path(__file__).resolve().parent / "memory_session_results.json"
DOC_PREFIX = "MEMEVAL_"

MIN_TURNS = 5
MAX_SESSIONS = 15
SUMMARY_MILESTONES = {8, 14, 20}   # chan: (msg_count - 8) % 6 == 0
# ponytail: heuristic so keyword overlap, khong phai NER. Ceiling: entity tieng Viet
# co dau (`Bảo`, `đấu`) bi dem trung khi khac bien dich. Nang len -> embedding similarity.
SUMMARY_KEEP_THRESHOLD = 0.5

client = TestClient(app)


# ---------------------------------------------------------------- data
def load_sessions() -> Dict[int, List[Dict[str, str]]]:
    """CSV -> {session_id: [turn theo turn_id]}"""
    sessions: Dict[int, List[Dict[str, str]]] = defaultdict(list)
    with open(CSV_FILE, encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            sessions[int(row["session_id"])].append(row)
    for turns in sessions.values():
        turns.sort(key=lambda t: int(t["turn_id"]))
    return sessions


def select_sessions(sessions: Dict[int, List[Dict[str, str]]]) -> List[int]:
    """10 session dai nhat (>= MIN_TURNS), tie-break theo session_id de chay lai cho cung ket qua."""
    ok = [(sid, len(t)) for sid, t in sessions.items() if len(t) >= MIN_TURNS]
    ok.sort(key=lambda x: (-x[1], x[0]))
    return [sid for sid, _ in ok[:MAX_SESSIONS]]


def build_docx(turns: List[Dict[str, str]], sid: int) -> Path:
    """Gom 1 session thanh 1 .docx: tieu de = rewrite, body = question + rewrite + answer.

    ponytail: chunker bo sach block < min_chunk_chars (80, legal_chunker.py:13) va 47%
    answer trong dataset ngan hon ngan do -- turn 0 cua session 214 chi 71 ky tu nen
    bi drop khoi document_chunks, khong retrieve duoc. Gop ca 3 truong vao body la
    cach re nhat de moi chunk > 80. Ceiling: chunk thua cau hoi mo. Fix that la ha
    min_chunk_chars trong chunker.
    """
    DOCS_DIR.mkdir(exist_ok=True)
    d = docx.Document()
    for t in turns:
        d.add_heading(t["rewrite"].strip(), level=1)
        d.add_paragraph(f"{t['question'].strip()} {t['rewrite'].strip()} {t['answer'].strip()}")
    path = DOCS_DIR / f"{DOC_PREFIX}conv_{sid}.docx"
    d.save(path)
    return path


def cleanup_old_docs() -> None:
    """Xoa ket cua lan chay truoc: chunks + documents (CASCADE thu cong nhu cleanup_eval.py)
    va semantic_cache -- cache hit 100% short-circuit truoc _retrieve_lazy nen khong tao
    context_summary, lam sai diem tang summary/recall."""
    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        DELETE FROM document_chunks
        WHERE document_id IN (SELECT id FROM knowledge_documents WHERE file_name LIKE %s);
    """, (f"{DOC_PREFIX}%",))
    chunks = cur.rowcount
    cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE %s;", (f"{DOC_PREFIX}%",))
    docs = cur.rowcount
    cur.execute("DELETE FROM semantic_cache;")
    cache = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()
    print(f"[cleanup] -{chunks} chunks, -{docs} documents, -{cache} semantic_cache")


def upload(path: Path) -> Optional[str]:
    """Upload .docx, tra document_id (hoac None). SHA-256 trung -> tai dung ban cu."""
    with open(path, "rb") as f:
        resp = client.post(
            "/api/v1/documents/upload",
            files={"file": (path.name, f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
            data={"allowed_jobs": "ALL", "allowed_departments": "ALL", "uploaded_by": "MEMEVAL"},
        )
    if resp.status_code != 200:
        print(f"  [upload] {path.name} FAIL {resp.status_code}: {resp.text[:200]}")
        return None
    body = resp.json()
    doc_id = body.get("document_id")
    if body.get("status") == "DUPLICATE":
        print(f"  [upload] {path.name} trung SHA-256 -> dung lai {doc_id} ({body.get('current_status')})")
    else:
        print(f"  [upload] {path.name} -> {doc_id}")
    return doc_id


def wait_ready(doc_id: str, max_wait: int = 600) -> bool:
    start = time.time()
    while time.time() - start < max_wait:
        body = client.get(f"/api/v1/documents/{doc_id}").json()
        if body["status"] == "COMPLETED":
            print(f"  [ingest] {doc_id} COMPLETED, {body.get('chunk_count')} chunks")
            return True
        if body["status"] == "FAILED":
            print(f"  [ingest] {doc_id} FAILED: {body.get('error_message')}")
            return False
        time.sleep(3)
    print(f"  [ingest] {doc_id} timeout")
    return False


# ---------------------------------------------------------------- scoring
WORD_RE = re.compile(r"\w{4,}", re.UNICODE)
# ponytail: stopword tieng Viet hard-code, khong dung NLP. Ceiling: bo qua
# tu khoa co nghia ("dien tich"), nen entity that la mau thuan bi tinh nham.
STOPWORDS = {
    "này", "được", "của", "không", "những", "một", "cho", "với", "nào", "gì",
    "phần", "trăm", "lãnh", "nhiêu", "toàn", "cũng", "đã", "đang", "này", "khi",
    "nào", "về", "trong", "thời", "đại", "phải", "từ", "ra", "vào", "các", "như",
}


def content_words(text: str) -> set:
    return {w.lower() for w in WORD_RE.findall(text or "")} - STOPWORDS


def overlap(expected: str, actual: str) -> float:
    exp = content_words(expected)
    return (len(exp & content_words(actual)) / len(exp)) if exp else 1.0


# ---------------------------------------------------------------- chat
def chat(question: str, conv_id: Optional[str], user_id: str) -> Dict[str, Any]:
    resp = client.post("/api/v1/chat/query", headers=HEADERS, json={
        "question": question,
        "conversation_id": conv_id,
        "user_id": user_id,
        "user_jobs": ["ALL"],
        "department": "ALL",
        "top_k": 3,
    })
    if resp.status_code != 200:
        raise RuntimeError(f"chat {resp.status_code}: {resp.text[:300]}")
    return resp.json()


def conversation_detail(conv_id: str, user_id: str) -> Dict[str, Any]:
    return client.get(f"/api/v1/chat/conversations/{conv_id}",
                      headers=HEADERS, params={"user_id": user_id}).json()


def run_session(sid: int, turns: List[Dict[str, str]]) -> Dict[str, Any]:
    user_id = f"MEMEVAL_{sid}"
    conv_id: Optional[str] = None
    rows, summaries = [], []

    for i, t in enumerate(turns):
        res = chat(t["question"], conv_id, user_id)
        conv_id = res["conversation_id"]
        rw, ans = res.get("rewritten_query", ""), res.get("answer", "")
        a_score = overlap(t["answer"], ans)
        # Chi cham turn co `rewrite != question`: turn hop cau hoi da tu nhien thi
        # condense_question tra ve nguyen cau, cho 1.0 o do la diem ao.
        needs = t["rewrite"].strip() != t["question"].strip()
        r_score = overlap(t["rewrite"], rw) if needs else None

        rows.append({
            "turn": i,
            "question": t["question"],
            "expected_rewrite": t["rewrite"],
            "actual_rewrite": rw,
            "llm_rewritten": rw.strip() != t["question"].strip(),
            "needs_rewrite": needs,
            "rewrite_score": round(r_score, 3) if needs else None,
            "answer_score": round(a_score, 3),
            "citations": len(res.get("citations") or []),
            "cached": bool(res.get("cached")),
            "answer": ans,
        })

        detail = conversation_detail(conv_id, user_id)
        n_msgs = len(detail["messages"])
        summary = detail.get("context_summary") or ""
        if n_msgs in SUMMARY_MILESTONES or i == 3:
            # ponytail: chi giu entity turn 0. Ceiling: thuc te summary luu ca danh
            # tinh/nguon goc, kiem tra entity o moi moc se chat hon.
            keep = overlap(turns[0]["rewrite"], summary)
            summaries.append({
                "after_turn": i, "messages": n_msgs,
                "first_entity_score": round(keep, 3),
                "ok": bool(summary) and keep >= SUMMARY_KEEP_THRESHOLD,
                "context_summary": summary,
            })
            print(f"  turn {i}: msgs={n_msgs} summary_keep={keep:.2f} "
                  f"{'OK' if summaries[-1]['ok'] else 'MISS'}")

    # Nho lai: turn 5+ chi con summary + 4 msgs gan nhat, hoi lai turn 0
    recall_score, recall_answer = 0.0, ""
    if len(turns) >= 5:
        r = chat(turns[0]["question"], conv_id, user_id)
        recall_answer = r.get("answer", "")
        recall_score = overlap(turns[0]["answer"], recall_answer)
        print(f"  recall turn 0: score={recall_score:.2f} cached={r.get('cached', False)}")

    n = len(rows)
    graded = [r for r in rows if r["needs_rewrite"]]
    return {
        "session_id": sid,
        "conversation_id": conv_id,
        "turns": n,
        "graded_turns": len(graded),
        "rewrite_score": round(sum(r["rewrite_score"] for r in graded) / len(graded), 3) if graded else None,
        "llm_rewrote": sum(1 for r in rows if r["llm_rewritten"]),
        "answer_score": round(sum(r["answer_score"] for r in rows) / n, 3),
        "summaries": summaries,
        "summary_ok": all(s["ok"] for s in summaries) and bool(summaries),
        "recall_score": round(recall_score, 3),
        "recall_answer": recall_answer,
        "rows": rows,
    }


# ---------------------------------------------------------------- main
def main() -> None:
    sessions = load_sessions()
    print(f"[data] {sum(len(t) for t in sessions.values())} turns / {len(sessions)} sessions")

    selected = select_sessions(sessions)
    print(f"[select] {selected}")

    DOCS_DIR.mkdir(exist_ok=True)
    cleanup_old_docs()

    print("[ingest] upload + nap document_chunks...")
    ready = []
    for sid in selected:
        doc_id = upload(build_docx(sessions[sid], sid))
        if doc_id and wait_ready(doc_id):
            ready.append(sid)
    if not ready:
        print("Khong session nao nap duoc chunks. Dung.")
        return

    results = []
    for sid in ready:
        turns = sessions[sid]
        print(f"\n=== session {sid} ({len(turns)} turns) ===")
        try:
            results.append(run_session(sid, turns))
        except Exception as e:
            print(f"  ERROR: {e}")
            results.append({"session_id": sid, "error": str(e), "turns": 0, "graded_turns": 0,
                            "llm_rewrote": 0, "rewrite_score": None, "answer_score": 0.0,
                            "summary_ok": False, "recall_score": 0.0})

    print("\n" + "=" * 72)
    print(f"{'session':>8} {'turns':>6} {'graded':>7} {'llm_rw':>7} {'rewrite':>9} {'answer':>8} {'summary':>8} {'recall':>8}")
    for r in results:
        rw = f"{r['rewrite_score']:.2f}" if r.get("rewrite_score") is not None else "n/a"
        print(f"{r['session_id']:>8} {r['turns']:>6} {r.get('graded_turns', 0):>7} "
              f"{r.get('llm_rewrote', 0):>7} {rw:>9} {r['answer_score']:>8.2f} "
              f"{'OK' if r['summary_ok'] else 'MISS':>8} {r['recall_score']:>8.2f}")
    ok = [r for r in results if r.get("turns")]
    graded = [r for r in ok if r.get("rewrite_score") is not None]
    if ok:
        rw_avg = sum(r["rewrite_score"] for r in graded) / len(graded) if graded else float("nan")
        print(f"\nTONG: rewrite={rw_avg:.2f} (chi {len(graded)} session co turn can rewrite) "
              f"llm_rewrote={sum(r['llm_rewrote'] for r in ok)}/{sum(r['turns'] for r in ok)} turn "
              f"answer={sum(r['answer_score'] for r in ok)/len(ok):.2f} "
              f"summary_ok={sum(1 for r in ok if r['summary_ok'])}/{len(ok)} "
              f"recall={sum(r['recall_score'] for r in ok)/len(ok):.2f}")

    OUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nChi tiet: {OUT_JSON}")


if __name__ == "__main__":
    main()
