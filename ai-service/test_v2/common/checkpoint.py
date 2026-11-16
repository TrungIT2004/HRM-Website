"""Checkpoint + JSONL logging utilities for test resumability and audit trail."""
import json
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Set
from threading import Lock


class TestCheckpoint:
    """
    Manages test progress persistence for quota-aware resumability.

    Usage:
        cp = TestCheckpoint("router_test")
        done_ids = cp.load_done_ids()
        for q in questions:
            if q["id"] in done_ids: continue
            result = run_test(q)
            cp.log_result(q["id"], result)
            cp.mark_done(q["id"])
    """

    def __init__(self, test_name: str, output_dir: Optional[Path] = None):
        self.test_name = test_name
        self.output_dir = output_dir or Path(__file__).resolve().parent.parent / "outputs"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.checkpoint_file = self.output_dir / f"{test_name}_checkpoint.json"
        self.jsonl_file = self.output_dir / f"{test_name}_results.jsonl"

        self._lock = Lock()
        self._done_ids: Set[str] = set()
        self._load_checkpoint()

    def _load_checkpoint(self) -> None:
        """Load completed question IDs from checkpoint file."""
        if self.checkpoint_file.exists():
            try:
                data = json.loads(self.checkpoint_file.read_text(encoding="utf-8"))
                self._done_ids = set(data.get("done_ids", []))
                print(f"[Checkpoint] Loaded {len(self._done_ids)} completed questions for {self.test_name}")
            except Exception as e:
                print(f"[Checkpoint] Failed to load: {e}")
                self._done_ids = set()
        else:
            self._done_ids = set()

    def _save_checkpoint(self) -> None:
        """Persist completed question IDs."""
        with self._lock:
            data = {
                "test_name": self.test_name,
                "done_ids": sorted(self._done_ids),
                "updated_at": time.time(),
                "count": len(self._done_ids)
            }
            self.checkpoint_file.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    def is_done(self, question_id: str) -> bool:
        """Check if question already completed."""
        return question_id in self._done_ids

    def mark_done(self, question_id: str) -> None:
        """Mark question as completed."""
        with self._lock:
            self._done_ids.add(question_id)
            self._save_checkpoint()

    def log_result(self, question_id: str, result: Dict[str, Any]) -> None:
        """Append result to JSONL file (one line per question)."""
        with self._lock:
            record = {
                "test_name": self.test_name,
                "question_id": question_id,
                "timestamp": time.time(),
                **result
            }
            with self.jsonl_file.open("a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")

    def get_done_ids(self) -> Set[str]:
        """Get set of completed question IDs."""
        return self._done_ids.copy()

    def get_remaining(self, all_ids: List[str]) -> List[str]:
        """Filter out already-completed question IDs."""
        return [qid for qid in all_ids if qid not in self._done_ids]

    def load_results(self) -> List[Dict[str, Any]]:
        """Load all results from JSONL file."""
        results = []
        if self.jsonl_file.exists():
            with self.jsonl_file.open(encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        results.append(json.loads(line))
        return results

    def reset(self) -> None:
        """Clear checkpoint and results (for fresh run)."""
        with self._lock:
            self._done_ids = set()
            if self.checkpoint_file.exists():
                self.checkpoint_file.unlink()
            if self.jsonl_file.exists():
                self.jsonl_file.unlink()
            print(f"[Checkpoint] Reset {self.test_name}")


def create_checkpoint(test_name: str) -> TestCheckpoint:
    """Factory function for test checkpoints."""
    return TestCheckpoint(test_name)


# Convenience: standard test names
ROUTER_CHECKPOINT = "llm_router"
RETRIEVAL_CHECKPOINT = "retrieval_eval"
TEXT2SQL_CHECKPOINT = "text2sql_eval"
MEMORY_A_CHECKPOINT = "memory_eval_a"
MEMORY_B_CHECKPOINT = "memory_eval_b"
RAGAS_CHECKPOINT = "ragas_eval"
LATENCY_CHECKPOINT = "latency_breakdown"