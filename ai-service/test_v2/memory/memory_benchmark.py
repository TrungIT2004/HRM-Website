#!/usr/bin/env python3
"""
Memory Benchmark Test for HRM AI Service
=======================================
Chạy pipeline CHAT THẬT (rewrite + route + answer) qua ChatService — chính là
production pipeline routing/rewriting của chatbot. Mỗi cuộc hội thoại chạy nối
chuỗi (turn 1..12 cùng conversation_id) để đo trí nhớ đa lượt.

API KEY rotation: ChatService nội bộ đã xoay 7 Gemini key
(GEMINI_API_KEY_0..6) + token bucket + sticky affinity mỗi conversation,
không cần xử lý ở file này.

Chạy tu ai-service:
    python test_v2/memory/memory_benchmark.py
    python test_v2/memory/memory_benchmark.py --no-cleanup
Yêu cầu: PostgreSQL hrm_ai đang chạy, DATABASE_URL/INTERNAL_API_SECRET đã cấu
hình, ít nhất 1 GEMINI_API_KEY_* hợp lệ.
"""
import sys
import json
import time
import re
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from src.chat.chat_service import ChatService, reset_usage, take_usage

try:
    from src.embeddings.local_embedder import LocalEmbedder
    _HAS_EMBED = True
except Exception:
    LocalEmbedder = None  # type: ignore
    _HAS_EMBED = False

try:
    from src.retrievers.hybrid_retriever import HybridRetriever
    _HAS_RETR = True
except Exception:
    HybridRetriever = None  # type: ignore
    _HAS_RETR = False

EVAL_USER = "EVAL_MEM_BENCH"
_STOP = {"lam", "sao", "de", "cho", "va", "cua", "cai", "nay", "kia", "co",
         "khong", "duoc", "la", "gi", "ai", "nao", "trong", "ngoai", "ve",
         "theo", "voi", "nhu", "thi", "khi", "neu", "cac", "nhung", "mot",
         "nhat"}


def fold(t: str) -> str:
    t = unicodedata.normalize("NFD", t or "")
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", t.lower()).strip()


def cosine(v1, v2) -> Optional[float]:
    if not v1 or not v2 or len(v1) != len(v2):
        return None
    dot = sum(a * b for a, b in zip(v1, v2))
    n1 = sum(a * a for a in v1) ** 0.5
    n2 = sum(b * b for b in v2) ** 0.5
    if n1 == 0 or n2 == 0:
        return None
    return round(dot / (n1 * n2), 4)


def carryover(sys_rw: str, exp_rw: str, question: str) -> Optional[float]:
    need = [w for w in fold(exp_rw).split()
            if w not in fold(question).split() and len(w) > 2 and w not in _STOP]
    if not need:
        return None
    fw = fold(sys_rw)
    return round(sum(1 for w in need if w in fw) / len(need), 4)


def rank_of(gold, got) -> Optional[int]:
    for i, c in enumerate(got or []):
        if str(c.get("chunk_id")) == str(gold):
            return i + 1
    return None


class MemoryBenchmark:
    def __init__(self, dataset_path: str, model: str = "gemini-3.5-flash-lite",
                 user_id: str = EVAL_USER, cleanup: bool = True):
        self.dataset_path = dataset_path
        self.model = model
        self.user_id = user_id
        self.cleanup = cleanup
        self.chat_service = ChatService()
        self.results_dir = Path(__file__).parent / "results"
        self.results_dir.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.run_dir = self.results_dir / f"memory_benchmark_{timestamp}"
        self.run_dir.mkdir(parents=True, exist_ok=True)
        print(f"Results will be saved to: {self.run_dir}")

        self.embedder = LocalEmbedder() if _HAS_EMBED else None
        self.retriever = HybridRetriever(use_reranker=False) if _HAS_RETR else None

    def load_dataset(self) -> List[Dict[str, Any]]:
        with open(self.dataset_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        if isinstance(data, dict) and "details" in data:
            data = data["details"]
        print(f"Loaded {len(data)} memory turns")
        return data

    def run_single_turn(self, question: str, conversation_id: Optional[str],
                        rewrite_expected: str, relevant_chunk_ids: List[str],
                        ground_truth: str) -> Dict[str, Any]:
        """1 turn qua production pipeline ChatService.answer_query (rewrite+route)."""
        reset_usage()
        t0 = time.perf_counter()
        try:
            out = self.chat_service.answer_query(
                question, conversation_id=conversation_id, user_id=self.user_id,
                jobs=["ALL"], departments=["ALL"], top_k=5)
        except Exception as e:
            out = {"answer": f"[LOI GEN: {e}]", "rewritten_query": question,
                   "citations": [], "confidence": "LOW", "conversation_id": conversation_id}
        u = take_usage()
        elapsed = round((time.perf_counter() - t0) * 1000, 2)

        sys_rw = out.get("rewritten_query") or question
        exp_rw = rewrite_expected or ""
        cos = car = None
        if self.embedder and exp_rw:
            try:
                v1 = self.embedder.generate_embedding(sys_rw, task_type="retrieval_query")
                v2 = self.embedder.generate_embedding(exp_rw, task_type="retrieval_query")
                cos = cosine(v1, v2)
                car = carryover(sys_rw, exp_rw, question)
            except Exception:
                pass

        gold = (relevant_chunk_ids or [None])[0]
        rb = ra = None
        if self.retriever and gold:
            try:
                rb = rank_of(gold, self.retriever.retrieve(
                    query=question, jobs=["ALL"], departments=["ALL"], top_k=5,
                    use_reranker=True))
                ra = rank_of(gold, self.retriever.retrieve(
                    query=sys_rw, jobs=["ALL"], departments=["ALL"], top_k=5,
                    use_reranker=True))
            except Exception:
                pass

        return {
            "conversation_id": out.get("conversation_id") or conversation_id,
            "question": question, "rewritten_query": sys_rw,
            "rewrite_expected": exp_rw, "rewrite_cosine": cos, "carryover": car,
            "rank_before": rb, "rank_after": ra,
            "route": out.get("route"), "answer": out.get("answer", ""),
            "confidence": out.get("confidence", "?"),
            "answerable": "THIEU THONG TIN" not in (ground_truth or ""),
            "citations": out.get("citations", []) or [],
            "elapsed_ms": elapsed,
            "prompt_tokens": u["in"], "completion_tokens": u["out"],
            "total_tokens": u["in"] + u["out"], "llm_calls": u["calls"],
        }

    def run_benchmark(self, questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        # Nhom turn theo conversation_id, luu thu tu turn_index (chay noi chuoi).
        by_conv: Dict[str, List[Dict[str, Any]]] = {}
        for q in questions:
            by_conv.setdefault(q["conversation_id"], []).append(q)
        for cid in by_conv:
            by_conv[cid].sort(key=lambda r: r["turn_index"])

        results: List[Dict[str, Any]] = []
        for cid, turns in by_conv.items():
            conversation_id = None  # None o luot dau -> service tao moi
            print(f"\n=== Conversation {cid} ({len(turns)} turns) ===")
            for q in turns:
                res = self.run_single_turn(
                    q["question"], conversation_id,
                    q.get("rewrite_expected", ""), q.get("relevant_chunk_ids"),
                    q.get("ground_truth", ""))
                res.update({
                    "id": q["id"], "turn_index": q["turn_index"],
                    "category": q.get("category"), "source_file": q.get("source_file"),
                })
                # Luot tiep theo dung conversation_id tra ve tu service (ghi nho lich su trong DB).
                conversation_id = res["conversation_id"]
                results.append(res)
                print(f"  T{q['turn_index']} route={res['route']} "
                      f"cos={res['rewrite_cosine']} carry={res['carryover']} "
                      f"rank {res['rank_before']}->{res['rank_after']} "
                      f"tok={res['total_tokens']} {res['elapsed_ms']}ms")
        return results

    def save_results(self, results: List[Dict[str, Any]],
                     questions: List[Dict[str, Any]]) -> Dict[str, Any]:
        total = len(results)
        rec_cos = [r for r in results if r["rewrite_cosine"] is not None]
        rec_car = [r for r in results if r["carryover"] is not None]
        hit_before = sum(1 for r in results
                         if r["rank_before"] and r["rank_before"] <= 5) / max(1, total)
        hit_after = sum(1 for r in results
                        if r["rank_after"] and r["rank_after"] <= 5) / max(1, total)

        summary = {
            "test_name": "memory_benchmark",
            "model": self.model,
            "dataset": self.dataset_path,
            "user_id": self.user_id,
            "total_turns": total,
            "total_conversations": len(set(r["conversation_id"] for r in results)),
            "rewrite_cosine_mean": round(sum(r["rewrite_cosine"] for r in rec_cos) / max(1, len(rec_cos)), 4) if rec_cos else None,
            "carryover_mean": round(sum(r["carryover"] for r in rec_car) / max(1, len(rec_car)), 4) if rec_car else None,
            "hit_at_5_before": round(hit_before, 4),
            "hit_at_5_after": round(hit_after, 4),
            "total_input_tokens": sum(r["prompt_tokens"] for r in results),
            "total_output_tokens": sum(r["completion_tokens"] for r in results),
            "total_tokens": sum(r["total_tokens"] for r in results),
            "total_llm_calls": sum(r["llm_calls"] for r in results),
            "total_elapsed_ms": round(sum(r["elapsed_ms"] for r in results), 2),
            "avg_elapsed_ms": round(sum(r["elapsed_ms"] for r in results) / max(1, total), 2),
            "timestamp": datetime.now().isoformat(),
        }

        with open(self.run_dir / "summary.json", 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        with open(self.run_dir / "results.json", 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)

        print(f"\n{'='*60}\nMEMORY BENCHMARK COMPLETE\n{'='*60}")
        print(f"Turns: {total} | Conversations: {summary['total_conversations']}")
        print(f"Rewrite cosine mean: {summary['rewrite_cosine_mean']} (n={len(rec_cos)})")
        print(f"Carryover mean: {summary['carryover_mean']} (n={len(rec_car)})")
        print(f"Hit@5 before={hit_before:.2%} after={hit_after:.2%}")
        print(f"Tokens: {summary['total_tokens']} "
              f"(in {summary['total_input_tokens']}, out {summary['total_output_tokens']})")
        print(f"Avg time: {summary['avg_elapsed_ms']}ms | Total: {summary['total_elapsed_ms']}ms")
        print(f"\nResults saved to: {self.run_dir}")
        return summary

    def run(self):
        print(f"{'='*60}\nMEMORY BENCHMARK - {self.model}\n{'='*60}")
        questions = self.load_dataset()
        results = self.run_benchmark(questions)
        self.save_results(results, questions)
        if self.cleanup:
            self._cleanup()
        return results

    def _cleanup(self) -> None:
        """Xoa conversations test khoi DB de khong o po du lieu that."""
        try:
            from src.db.session import get_db_connection
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("DELETE FROM chat_messages WHERE conversation_id IN "
                        "(SELECT id FROM chat_conversations WHERE user_id=%s);",
                        (self.user_id,))
            cur.execute("DELETE FROM chat_conversations WHERE user_id=%s;", (self.user_id,))
            conn.commit()
            cur.close()
            conn.close()
            print(f"[cleanup] da xoa conversations cua {self.user_id}")
        except Exception as e:
            print(f"[cleanup] bo qua (khong xoa duoc): {e}")


def main() -> None:
    import argparse
    parser = argparse.ArgumentParser(description="Run memory benchmark test")
    parser.add_argument("--dataset", type=str,
                        default="ai-service/test_v2/memory/dataset/memory_test.json",
                        help="Path to memory dataset JSON")
    parser.add_argument("--model", type=str, default="gemini-3.5-flash-lite",
                        help="Model (duoc ChatService doc tu env, ghi lai de luu)")
    parser.add_argument("--user-id", type=str, default=EVAL_USER,
                        help="User id cho conversations test (duoc xoa sau khi chay)")
    parser.add_argument("--no-cleanup", action="store_true",
                        help="Giu lai conversations test trong DB sau khi chay")
    args = parser.parse_args()

    dataset_path = Path(args.dataset)
    if not dataset_path.is_absolute():
        dataset_path = Path(__file__).resolve().parent.parent.parent / args.dataset
    if not dataset_path.exists():
        print(f"Dataset not found: {dataset_path}")
        sys.exit(1)

    bench = MemoryBenchmark(str(dataset_path), args.model, args.user_id,
                            cleanup=not args.no_cleanup)
    bench.run()


if __name__ == "__main__":
    main()
