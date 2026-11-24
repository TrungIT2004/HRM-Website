"""Evaluation logger using stdlib logging with JSONL output.

Replaces custom logger with stdlib logging + json formatter.
"""
import json
import logging
import sys
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path
from typing import Any, Dict, Optional


class _DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)


class EvaluationLogger:
    """Structured logger for evaluation runs using stdlib logging."""

    def __init__(
        self,
        test_name: str,
        model: str,
        thresholds: Dict[str, tuple],
        test_uid: str,
        results_dir: Optional[Path] = None,
    ):
        self.test_name = test_name
        self.model = model
        self.thresholds = thresholds
        self.test_uid = test_uid

        # Create run directory with timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        run_dir_name = f"{timestamp}_{test_name}"
        base = results_dir or Path(__file__).resolve().parent / "results"
        self.run_dir = base / run_dir_name
        self.run_dir.mkdir(parents=True, exist_ok=True)

        # Files
        self.questions_file = self.run_dir / "questions.jsonl"
        self.meta_file = self.run_dir / "run_meta.json"
        self.summary_file = self.run_dir / "summary.json"

        # Setup JSONL file handler for questions
        self._questions_logger = logging.getLogger(f"eval.questions.{test_name}")
        self._questions_logger.setLevel(logging.INFO)
        self._questions_logger.propagate = False
        self._questions_logger.handlers.clear()

        fh = logging.FileHandler(self.questions_file, encoding="utf-8")
        fh.setFormatter(logging.Formatter("%(message)s"))
        self._questions_logger.addHandler(fh)

        # Run metadata
        self.run_meta = {
            "test_name": test_name,
            "model": model,
            "thresholds": {k: {"op": op, "target": t} for k, (op, t) in thresholds.items()},
            "test_uid": test_uid,
            "started_at_utc": datetime.now(timezone.utc).isoformat(),
            "started_at_local": datetime.now().astimezone().isoformat(),
        }
        self._write_meta()

        self._question_count = 0

    def _write_meta(self) -> None:
        self.meta_file.write_text(
            json.dumps(self.run_meta, ensure_ascii=False, indent=2, cls=_DecimalEncoder),
            encoding="utf-8",
        )

    def log_question(self, qdata: Dict[str, Any]) -> None:
        """Append a question result to JSONL."""
        self._question_count += 1
        record = {
            "question_number": self._question_count,
            "timestamp_utc": datetime.now(timezone.utc).isoformat(),
            "timestamp_local": datetime.now().astimezone().isoformat(),
            **qdata,
        }
        # Log as JSON line
        self._questions_logger.info(json.dumps(record, ensure_ascii=False, cls=_DecimalEncoder))

    def finalize(self, summary: Dict[str, Any]) -> None:
        """Write final summary and update run_meta with completion time."""
        self.run_meta["completed_at_utc"] = datetime.now(timezone.utc).isoformat()
        self.run_meta["completed_at_local"] = datetime.now().astimezone().isoformat()
        self.run_meta["total_questions"] = self._question_count
        self._write_meta()

        # Write summary
        summary_data = {
            "test_name": self.test_name,
            "model": self.model,
            "test_uid": self.test_uid,
            "run_dir": str(self.run_dir),
            "summary": summary,
        }
        self.summary_file.write_text(
            json.dumps(summary_data, ensure_ascii=False, indent=2, cls=_DecimalEncoder),
            encoding="utf-8",
        )

    def get_run_dir(self) -> Path:
        return self.run_dir


# Backward-compatible: simple dict-based logging for existing code
def create_logger(
    test_name: str,
    model: str,
    thresholds: Dict[str, tuple],
    test_uid: str,
) -> EvaluationLogger:
    return EvaluationLogger(test_name, model, thresholds, test_uid)