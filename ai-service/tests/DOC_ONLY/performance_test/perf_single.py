"""Performance don le (1 cau hoi dai dien x 3 lan): TTFT, total, tokens/s, RAM/VRAM.

- TTFT = t0 -> token event dau (gom rewrite + retrieve + token dau).
- Gen window = token dau -> token cuoi; tokens/s = completion_tokens / window.
- VRAM peak: torch.cuda peak (process) + nvidia-smi (board) truoc/sau.
- RAM: psutil RSS process truoc/sau.
- Purge cache truoc MOI lan de do full pipeline (khong do nham cache-hit).

Chay tu ai-service:
    python tests/DOC_ONLY/performance_test/perf_single.py
Output: tests/DOC_ONLY/performance_test/perf_single.json
"""
import json
import subprocess
import sys
import time
from pathlib import Path

import psutil
import torch

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv()

HERE = Path(__file__).resolve().parent
OUT = HERE / "perf_single.json"
EVAL_USER = "EVAL_PERF"
REPEATS = 3


def board_vram() -> dict:
    try:
        out = subprocess.check_output(
            ["nvidia-smi", "--query-gpu=memory.used,memory.total",
             "--format=csv,noheader,nounits"], text=True)
        used, total = [int(x) for x in out.strip().split(",")]
        return {"used_mib": used, "total_mib": total}
    except Exception as e:
        return {"error": str(e)[:100]}


def purge_one(question: str) -> None:
    from src.db.session import get_db_connection
    from src.embeddings.local_embedder import LocalEmbedder
    v = LocalEmbedder().generate_embedding(question, task_type="retrieval_query")
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT id FROM semantic_cache "
                    "WHERE 1 - (query_vector <=> %s::vector) >= 0.90", (str(v),))
        ids = [r[0] for r in cur.fetchall()]
        if ids:
            cur.execute("DELETE FROM semantic_cache WHERE id = ANY(%s::uuid[])", (ids,))
        conn.commit()
    finally:
        cur.close()
        conn.close()


def consume(stream):
    """Doc SSE events, tra ve (t_first_token, t_last_token, t_done, full_text)."""
    t_first = t_last = t_done = None
    texts = []
    t0 = time.perf_counter()
    for raw in stream:
        line = raw.strip()
        if not line.startswith("data:"):
            continue
        try:
            ev = json.loads(line[5:].strip())
        except Exception:
            continue
        now = time.perf_counter() - t0
        if ev.get("type") == "token" and ev.get("content"):
            if t_first is None:
                t_first = now
            t_last = now
            texts.append(ev["content"])
        elif ev.get("type") == "done":
            t_done = now
            break
    return t_first, t_last, t_done, "".join(texts)


def main() -> None:
    ds = json.loads((HERE.parent / "datasets" / "doc_only_120.json").read_text(encoding="utf-8"))
    q = next(r["question"] for r in ds if r["id"] == "D050")

    from src.chat.chat_service import ChatService, reset_usage, take_usage
    svc = ChatService()
    proc = psutil.Process()
    runs = []
    for k in range(REPEATS):
        purge_one(q)
        if torch.cuda.is_available():
            torch.cuda.reset_peak_memory_stats()
        ram0, vram0 = proc.memory_info().rss // 1048576, board_vram()
        reset_usage()
        t0 = time.perf_counter()
        t_first, t_last, t_done, text = consume(
            svc.answer_query_stream(q, user_id=EVAL_USER, jobs=["ALL"],
                                    departments=["ALL"], top_k=5))
        u = take_usage()
        ram1 = proc.memory_info().rss // 1048576
        vpeak = torch.cuda.max_memory_allocated() // 1048576 if torch.cuda.is_available() else 0
        vram1 = board_vram()
        gen_win = (t_last - t_first) if t_first and t_last else 0.0
        # ponytail: stream path khong co usage (xem USAGE_ACC) — u["out"] o day
        # CHI la rewrite call. Toc do sinh do bang chars/s (chinh xac) + est
        # tok/s = chars/4 (uoc luong, tieng Viet ~3-4 chars/token).
        n_chars = len(text)
        runs.append({
            "run": k + 1, "ttft_s": round(t_first or 0.0, 2),
            "gen_window_s": round(gen_win, 2), "total_s": round(t_done or 0.0, 2),
            "answer_chars": n_chars,
            "chars_per_s": round(n_chars / gen_win, 1) if gen_win > 0 else 0.0,
            "tokens_per_s_est": round(n_chars / 4 / gen_win, 1) if gen_win > 0 else 0.0,
            "prompt_tokens": u["in"], "completion_tokens": u["out"], "llm_calls": u["calls"],
            "ram_rss_mib": (ram0, ram1),
            "vram_process_peak_mib": vpeak, "vram_board_mib": (vram0, vram1),
        })
        print(f"[{k + 1}/{REPEATS}] TTFT={runs[-1]['ttft_s']}s total={runs[-1]['total_s']}s "
              f"chars/s={runs[-1]['chars_per_s']} vram_peak={vpeak}MiB", flush=True)

    from src.db.session import get_db_connection
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                    "(SELECT id FROM chat_conversations WHERE user_id = %s);", (EVAL_USER,))
        cur.execute("DELETE FROM chat_conversations WHERE user_id = %s;", (EVAL_USER,))
        conn.commit()
    finally:
        cur.close()
        conn.close()

    OUT.write_text(json.dumps({"question": q, "runs": runs}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()
