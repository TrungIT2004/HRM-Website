#!/usr/bin/env python3
"""
Routing Benchmark Test for HRM AI Service
Tests the LLM router (rewrite + route) with Gemini 3.5 Flash Lite
"""

import sys
import json
import time
import os
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from src.sql.router import build_router_prompt, parse_router_output, ROUTE_LABELS
from src.chat.chat_service import ChatService, reset_usage, take_usage


class RoutingBenchmark:
    def __init__(self, dataset_path: str, model: str = "gemini-1.5-flash"):
        self.dataset_path = dataset_path
        self.model = model
        self.chat_service = ChatService()
        self.results_dir = Path(__file__).parent / "results"
        self.results_dir.mkdir(exist_ok=True)

        # Create timestamped run folder
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.run_dir = self.results_dir / f"routing_benchmark_{timestamp}"
        self.run_dir.mkdir(parents=True, exist_ok=True)

        print(f"Results will be saved to: {self.run_dir}")

    def load_dataset(self) -> List[Dict[str, Any]]:
        """Load test dataset from JSON file."""
        with open(self.dataset_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Handle different dataset formats
        questions = []
        if isinstance(data, list):
            # Direct list of questions
            for item in data:
                if isinstance(item, dict) and "question" in item:
                    questions.append(item)
        elif isinstance(data, dict) and "tables" in data:
            # db_only_hybrid_questions.json format
            for table in data.get("tables", []):
                for q in table.get("questions", []):
                    q_copy = q.copy()
                    q_copy["table"] = table["table"]
                    questions.append(q_copy)
        elif isinstance(data, dict) and "details" in data:
            # llm_router_test.json format - questions in "details" array
            questions = data["details"]
        elif isinstance(data, dict) and "questions" in data:
            questions = data["questions"]

        print(f"Loaded {len(questions)} test questions")
        return questions

    def run_single_test(self, question: str, history: List[Dict[str, str]] = None,
                        context_summary: str = None, expected_route: str = None) -> Dict[str, Any]:
        """Run a single routing test and measure execution time with token usage."""
        if history is None:
            history = []

        # Reset usage tracker before each test
        reset_usage()

        start_time = time.perf_counter()

        # Use the chat_service's rewrite_and_route_step
        rewritten_query, route = self.chat_service.rewrite_and_route_step(
            question, history, context_summary
        )

        end_time = time.perf_counter()
        execution_time_ms = (end_time - start_time) * 1000

        # Get token usage from the global tracker
        usage = take_usage()

        result = {
            "original_query": question,
            "rewritten_query": rewritten_query,
            "routing_result": route,
            "expected_route": expected_route,
            "correct": route == expected_route if expected_route else None,
            "execution_time_ms": round(execution_time_ms, 2),
            "input_token_usage": usage["in"],
            "output_token_usage": usage["out"],
            "total_token_usage": usage["in"] + usage["out"],
            "llm_calls": usage["calls"],
            "timestamp": datetime.now().isoformat()
        }

        return result

    def run_benchmark(self, questions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Run benchmark on all questions."""
        results = []

        for i, q in enumerate(questions):
            question_text = q.get("question", "")
            expected = q.get("expected_route") or q.get("expected")

            print(f"\n[{i+1}/{len(questions)}] Testing: {question_text[:80]}...")
            print(f"  Expected: {expected}")

            history = q.get("history", [])
            context_summary = q.get("context_summary")

            try:
                result = self.run_single_test(
                    question=question_text,
                    history=history,
                    context_summary=context_summary,
                    expected_route=expected
                )
                results.append(result)

                print(f"  Predicted: {result['routing_result']}")
                print(f"  Correct: {result['correct']}")
                print(f"  Time: {result['execution_time_ms']}ms")
                print(f"  Tokens: in={result['input_token_usage']}, out={result['output_token_usage']}")

            except Exception as e:
                print(f"  ERROR: {e}")
                results.append({
                    "original_query": question_text,
                    "rewritten_query": "",
                    "routing_result": "ERROR",
                    "expected_route": expected,
                    "correct": False,
                    "execution_time_ms": 0,
                    "input_token_usage": 0,
                    "output_token_usage": 0,
                    "total_token_usage": 0,
                    "llm_calls": 0,
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                })

        return results

    def save_results(self, results: List[Dict[str, Any]], questions: List[Dict[str, Any]]):
        """Save results to JSON files."""
        # Save summary
        total = len(results)
        correct = sum(1 for r in results if r.get("correct") is True)
        accuracy = correct / total if total > 0 else 0
        avg_time = sum(r.get("execution_time_ms", 0) for r in results) / total if total > 0 else 0
        total_input_tokens = sum(r.get("input_token_usage", 0) for r in results)
        total_output_tokens = sum(r.get("output_token_usage", 0) for r in results)
        total_tokens = sum(r.get("total_token_usage", 0) for r in results)

        summary = {
            "test_name": "routing_benchmark",
            "model": self.model,
            "dataset": self.dataset_path,
            "total_questions": total,
            "correct": correct,
            "accuracy": round(accuracy, 4),
            "avg_execution_time_ms": round(avg_time, 2),
            "total_input_tokens": total_input_tokens,
            "total_output_tokens": total_output_tokens,
            "total_tokens": total_tokens,
            "timestamp": datetime.now().isoformat(),
            "per_route": {}
        }

        # Per-route stats
        for r in results:
            expected = r.get("expected_route")
            if expected:
                if expected not in summary["per_route"]:
                    summary["per_route"][expected] = {"total": 0, "correct": 0}
                summary["per_route"][expected]["total"] += 1
                if r.get("correct"):
                    summary["per_route"][expected]["correct"] += 1

        for route, stats in summary["per_route"].items():
            stats["accuracy"] = round(stats["correct"] / stats["total"], 4) if stats["total"] > 0 else 0

        # Save summary
        summary_file = self.run_dir / "summary.json"
        with open(summary_file, 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)

        # Save individual results
        results_file = self.run_dir / "results.json"
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)

        # Save detailed per-question files
        for i, (result, question) in enumerate(zip(results, questions)):
            detail = {
                "question_id": question.get("id", f"q_{i}"),
                "original_query": result["original_query"],
                "rewritten_query": result["rewritten_query"],
                "routing_result": result["routing_result"],
                "expected_route": result.get("expected_route"),
                "correct": result.get("correct"),
                "execution_time_ms": result["execution_time_ms"],
                "input_token_usage": result.get("input_token_usage"),
                "output_token_usage": result.get("output_token_usage"),
                "total_token_usage": result.get("total_token_usage"),
                "llm_calls": result.get("llm_calls"),
                "timestamp": result["timestamp"],
                "metadata": {
                    "table": question.get("table"),
                    "category": question.get("category"),
                    "check_type": question.get("check_type"),
                    "variant": question.get("variant"),
                    "source_file": question.get("source_file"),
                    "history": question.get("history", []),
                    "context_summary": question.get("context_summary")
                }
            }
            detail_file = self.run_dir / f"q_{i:03d}_{question.get('id', 'unknown')}.json"
            with open(detail_file, 'w', encoding='utf-8') as f:
                json.dump(detail, f, ensure_ascii=False, indent=2)

        print(f"\n{'='*60}")
        print(f"BENCHMARK COMPLETE")
        print(f"{'='*60}")
        print(f"Total: {total}")
        print(f"Correct: {correct}")
        print(f"Accuracy: {accuracy:.2%}")
        print(f"Avg Time: {avg_time:.2f}ms")
        print(f"Total Tokens: {total_tokens} (in: {total_input_tokens}, out: {total_output_tokens})")
        print(f"\nPer-route:")
        for route, stats in summary["per_route"].items():
            print(f"  {route}: {stats['correct']}/{stats['total']} = {stats['accuracy']:.2%}")
        print(f"\nResults saved to: {self.run_dir}")

    def run(self):
        """Main entry point."""
        print(f"{'='*60}")
        print(f"ROUTING BENCHMARK - {self.model}")
        print(f"{'='*60}")
        print(f"Dataset: {self.dataset_path}")
        print(f"Results dir: {self.run_dir}")

        questions = self.load_dataset()
        results = self.run_benchmark(questions)
        self.save_results(results, questions)

        return results


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Run routing benchmark test")
    parser.add_argument("--dataset", type=str,
                       default="ai-service/test_v2/dataset/routing_test.json",
                       help="Path to test dataset JSON")
    parser.add_argument("--model", type=str, default="gemini-1.5-flash",
                       help="Model to use for routing")

    args = parser.parse_args()

    dataset_path = Path(args.dataset)
    if not dataset_path.is_absolute():
        dataset_path = Path(__file__).resolve().parent.parent.parent / args.dataset

    if not dataset_path.exists():
        print(f"Dataset not found: {dataset_path}")
        sys.exit(1)

    benchmark = RoutingBenchmark(str(dataset_path), args.model)
    benchmark.run()


if __name__ == "__main__":
    main()