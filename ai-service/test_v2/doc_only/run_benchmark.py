#!/usr/bin/env python3
"""
DOC_ONLY Benchmark Runner for HRM Chatbot
Runs DOC_ONLY questions through the ChatService and collects detailed metrics.

Metrics collected per question:
- input_tokens, output_tokens, total_tokens
- TTFT (Time To First Token)
- generation_time
- generated_answer
- question, golden_answer
- retrieved_docs (with scores, breadcrumbs)
- rewritten_query
- user_question (original)
- route, confidence
- cache_hit
"""

import os
import sys
import json
import time
import argparse
import io
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict

# Fix Unicode output on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from dotenv import load_dotenv
load_dotenv()

from src.chat.chat_service import ChatService


@dataclass
class BenchmarkResult:
    """Result for a single benchmark question."""
    # Identification
    id: str
    question: str
    golden_answer: str
    category: str
    source_file: str
    breadcrumb: str
    allowed_jobs: List[str]
    allowed_departments: List[str]

    # Runtime metrics
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0
    ttft_ms: float = 0.0  # Time To First Token
    generation_time_ms: float = 0.0
    total_latency_ms: float = 0.0

    # Results
    generated_answer: str = ""
    rewritten_query: str = ""
    route: str = ""
    confidence: str = ""
    cache_hit: bool = False
    cache_similarity: float = 0.0

    # Retrieved documents
    retrieved_chunks_count: int = 0
    retrieved_docs: List[Dict[str, Any]] = None

    # Error tracking
    error: Optional[str] = None

    def __post_init__(self):
        if self.retrieved_docs is None:
            self.retrieved_docs = []


class TokenTracker:
    """Tracks token usage by wrapping the key manager's complete method."""

    def __init__(self, chat_service: ChatService):
        self.chat_service = chat_service
        self.call_count = 0
        self.total_input_tokens = 0
        self.total_output_tokens = 0

    def estimate_tokens(self, text: str) -> int:
        """Rough estimation: ~4 chars per token for Vietnamese/English mixed."""
        if not text:
            return 0
        return len(text) // 4

    def track_call(self, system_prompt: str, user_prompt: str, response: str) -> Dict[str, int]:
        """Track token usage for a single LLM call."""
        input_tokens = self.estimate_tokens(system_prompt + user_prompt)
        output_tokens = self.estimate_tokens(response)
        self.total_input_tokens += input_tokens
        self.total_output_tokens += output_tokens
        self.call_count += 1
        return {
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens
        }


def load_dataset(dataset_path: Path) -> List[Dict[str, Any]]:
    """Load the DOC_ONLY dataset from JSON file."""
    with open(dataset_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    print(f"[Dataset] Loaded {len(data)} questions from {dataset_path}")
    return data


def run_single_question(
    chat_service: ChatService,
    question_data: Dict[str, Any],
    user_id: str = "ANONYMOUS",
    jobs: Optional[List[str]] = None,
    departments: Optional[List[str]] = None
) -> BenchmarkResult:
    """Run a single question through the ChatService and collect metrics."""

    # Initialize result with dataset metadata
    result = BenchmarkResult(
        id=question_data.get("id", ""),
        question=question_data.get("question", ""),
        golden_answer=question_data.get("ground_truth", ""),
        category=question_data.get("category", ""),
        source_file=question_data.get("source_file", ""),
        breadcrumb=question_data.get("breadcrumb", ""),
        allowed_jobs=question_data.get("allowed_jobs", ["ALL"]),
        allowed_departments=question_data.get("allowed_departments", ["ALL"]),
    )

    # Use allowed jobs/departments from dataset for PBAC
    test_jobs = jobs or result.allowed_jobs
    test_depts = departments or result.allowed_departments

    # Track timing
    start_time = time.perf_counter()
    ttft_start = None
    first_token_received = False

    try:
        # Call the chat service
        response = chat_service.answer_query(
            question=result.question,
            conversation_id=None,
            user_id=user_id,
            jobs=test_jobs,
            departments=test_depts,
            top_k=7,
            background_tasks=None
        )

        total_latency_ms = round((time.perf_counter() - start_time) * 1000, 1)
        result.total_latency_ms = total_latency_ms

        # Extract metrics from response
        result.generated_answer = response.get("answer", "")
        result.rewritten_query = response.get("rewritten_query", "")
        result.route = response.get("route", "") if "route" in response else "DOC_ONLY"
        result.confidence = response.get("confidence", "")
        result.cache_hit = response.get("cached", False)
        result.cache_similarity = response.get("cache_similarity", 0.0)
        result.retrieved_chunks_count = response.get("retrieved_chunks_count", 0)

        # Extract citations as retrieved docs
        citations = response.get("citations", [])
        result.retrieved_docs = []
        for cite in citations:
            result.retrieved_docs.append({
                "document_name": cite.get("document_name", ""),
                "breadcrumb": cite.get("breadcrumb", ""),
                "page_number": cite.get("page_number"),
                "file_url": cite.get("file_url"),
                "chunk_type": cite.get("chunk_type", ""),
                "relevance_score": cite.get("relevance_score", 0.0),
            })

        # Estimate tokens (rough approximation)
        # The answer_query method makes multiple LLM calls internally
        # We'll estimate based on total prompt + response size
        prompt_size = len(result.question) + len(result.rewritten_query) + sum(
            len(json.dumps(doc, ensure_ascii=False)) for doc in result.retrieved_docs
        )
        result.input_tokens = prompt_size // 4
        result.output_tokens = len(result.generated_answer) // 4
        result.total_tokens = result.input_tokens + result.output_tokens

        # TTFT and generation time are approximated since we don't have streaming access
        # For non-streaming, TTFT ≈ total_latency (first token = full response)
        # In practice, we'd need streaming to measure true TTFT
        result.ttft_ms = total_latency_ms  # Approximation for non-streaming
        result.generation_time_ms = total_latency_ms

    except Exception as e:
        result.error = f"{type(e).__name__}: {str(e)}"
        result.total_latency_ms = round((time.perf_counter() - start_time) * 1000, 1)
        print(f"  [ERROR] {result.id}: {result.error}")

    return result


def save_question_result(result: BenchmarkResult, results_dir: Path):
    """Save individual question result as JSON."""
    q_file = results_dir / f"{result.id}.json"
    q_file.write_text(json.dumps(asdict(result), ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  [Saved] {q_file.name}")


def generate_summary_markdown(results: List[BenchmarkResult], results_dir: Path, dataset_name: str):
    """Generate a summary markdown report."""
    total = len(results)
    successful = [r for r in results if r.error is None]
    failed = [r for r in results if r.error is not None]

    # Calculate averages
    if successful:
        avg_latency = sum(r.total_latency_ms for r in successful) / len(successful)
        avg_tokens = sum(r.total_tokens for r in successful) / len(successful)
        avg_input_tokens = sum(r.input_tokens for r in successful) / len(successful)
        avg_output_tokens = sum(r.output_tokens for r in successful) / len(successful)
        cache_hits = sum(1 for r in successful if r.cache_hit)
        avg_chunks = sum(r.retrieved_chunks_count for r in successful) / len(successful)
    else:
        avg_latency = avg_tokens = avg_input_tokens = avg_output_tokens = avg_chunks = 0
        cache_hits = 0

    # Confidence distribution
    confidence_dist = {}
    for r in successful:
        conf = r.confidence or "UNKNOWN"
        confidence_dist[conf] = confidence_dist.get(conf, 0) + 1

    # Route distribution
    route_dist = {}
    for r in successful:
        route = r.route or "DOC_ONLY"
        route_dist[route] = route_dist.get(route, 0) + 1

    # Category distribution
    category_dist = {}
    for r in successful:
        cat = r.category or "UNKNOWN"
        category_dist[cat] = category_dist.get(cat, 0) + 1

    md_lines = [
        f"# DOC_ONLY Benchmark Results",
        f"",
        f"**Dataset:** {dataset_name}",
        f"**Run Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Questions:** {total}",
        f"**Successful:** {len(successful)}",
        f"**Failed:** {len(failed)}",
        f"",
        f"## Overall Metrics",
        f"",
        f"| Metric | Value |",
        f"|--------|-------|",
        f"| Average Latency | {avg_latency:.1f} ms |",
        f"| Average Total Tokens | {avg_tokens:.0f} |",
        f"| Average Input Tokens | {avg_input_tokens:.0f} |",
        f"| Average Output Tokens | {avg_output_tokens:.0f} |",
        f"| Cache Hit Rate | {cache_hits}/{len(successful)} ({cache_hits/len(successful)*100:.1f}%) |" if successful else "| Cache Hit Rate | N/A |",
        f"| Average Retrieved Chunks | {avg_chunks:.1f} |",
        f"",
        f"## Confidence Distribution",
        f"",
        f"| Confidence | Count | Percentage |",
        f"|------------|-------|------------|",
    ]

    for conf, count in sorted(confidence_dist.items(), key=lambda x: -x[1]):
        pct = count / len(successful) * 100 if successful else 0
        md_lines.append(f"| {conf} | {count} | {pct:.1f}% |")

    md_lines.extend([
        f"",
        f"## Route Distribution",
        f"",
        f"| Route | Count | Percentage |",
        f"|-------|-------|------------|",
    ])

    for route, count in sorted(route_dist.items(), key=lambda x: -x[1]):
        pct = count / len(successful) * 100 if successful else 0
        md_lines.append(f"| {route} | {count} | {pct:.1f}% |")

    md_lines.extend([
        f"",
        f"## Category Distribution",
        f"",
        f"| Category | Count | Percentage |",
        f"|----------|-------|------------|",
    ])

    for cat, count in sorted(category_dist.items(), key=lambda x: -x[1]):
        pct = count / len(successful) * 100 if successful else 0
        md_lines.append(f"| {cat} | {count} | {pct:.1f}% |")

    if failed:
        md_lines.extend([
            f"",
            f"## Failed Questions",
            f"",
            f"| ID | Question | Error |",
            f"|----|----------|-------|",
        ])
        for r in failed:
            q_short = r.question[:60] + "..." if len(r.question) > 60 else r.question
            err_short = r.error[:80] + "..." if len(r.error) > 80 else r.error
            md_lines.append(f"| {r.id} | {q_short} | {err_short} |")

    md_lines.extend([
        f"",
        f"## Per-Question Details",
        f"",
        f"| ID | Category | Latency (ms) | Tokens (in/out) | Confidence | Cache | Chunks |",
        f"|----|----------|--------------|-----------------|------------|-------|--------|",
    ])

    for r in sorted(successful, key=lambda x: x.id):
        md_lines.append(
            f"| {r.id} | {r.category} | {r.total_latency_ms:.1f} | "
            f"{r.input_tokens}/{r.output_tokens} | {r.confidence} | "
            f"{'✓' if r.cache_hit else '✗'} | {r.retrieved_chunks_count} |"
        )

    # Write markdown file
    md_file = results_dir / "SUMMARY.md"
    md_file.write_text("\n".join(md_lines), encoding="utf-8")
    print(f"[Summary] Written to {md_file}")


def main():
    parser = argparse.ArgumentParser(description="Run DOC_ONLY benchmark")
    parser.add_argument(
        "--dataset",
        default="dataset/doc_only_120.json",
        help="Path to dataset JSON file (relative to script dir)"
    )
    parser.add_argument(
        "--user-id",
        default="ANONYMOUS",
        help="User ID for testing (default: ANONYMOUS)"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Limit number of questions to test (0 = all)"
    )
    parser.add_argument(
        "--offset",
        type=int,
        default=0,
        help="Offset to start from"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only load dataset and print questions, don't run ChatService"
    )
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    dataset_path = script_dir / args.dataset

    if not dataset_path.exists():
        print(f"[ERROR] Dataset not found: {dataset_path}")
        sys.exit(1)

    # Create timestamped results directory
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    results_dir = script_dir / "results" / timestamp
    results_dir.mkdir(parents=True, exist_ok=True)
    print(f"[Results] Output directory: {results_dir}")

    # Load dataset
    dataset = load_dataset(dataset_path)

    # Apply offset and limit
    if args.offset > 0:
        dataset = dataset[args.offset:]
    if args.limit > 0:
        dataset = dataset[:args.limit]

    print(f"[Benchmark] Testing {len(dataset)} questions...")

    if args.dry_run:
        print("[Dry-run] Dataset loaded successfully. Questions:")
        for i, q in enumerate(dataset):
            print(f"  {i+1}. [{q.get('id', 'N/A')}] {q.get('question', '')[:80]}... (category: {q.get('category', 'N/A')})")
        print(f"\n[Dry-run] Total: {len(dataset)} questions. Exiting without running ChatService.")
        return

    # Initialize ChatService
    print("[Init] Initializing ChatService...")
    chat_service = ChatService()
    print("[Init] ChatService ready")

    # Run benchmark
    results = []
    for i, q_data in enumerate(dataset):
        print(f"\n[{i+1}/{len(dataset)}] {q_data.get('id', 'N/A')}: {q_data.get('question', '')[:60]}...")

        result = run_single_question(
            chat_service=chat_service,
            question_data=q_data,
            user_id=args.user_id
        )

        results.append(result)
        save_question_result(result, results_dir)

        # Print quick status
        if result.error:
            print(f"  [FAILED] {result.error[:100]}")
        else:
            print(f"  [OK] Latency: {result.total_latency_ms:.1f}ms, Tokens: {result.total_tokens}, Confidence: {result.confidence}, Cache: {'HIT' if result.cache_hit else 'MISS'}")

    # Generate summary
    print(f"\n[Summary] Generating report...")
    generate_summary_markdown(results, results_dir, dataset_path.name)

    # Print final summary
    successful = [r for r in results if r.error is None]
    print(f"\n{'='*60}")
    print(f"BENCHMARK COMPLETE")
    print(f"{'='*60}")
    print(f"Total: {len(results)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(results) - len(successful)}")
    if successful:
        avg_lat = sum(r.total_latency_ms for r in successful) / len(successful)
        avg_tok = sum(r.total_tokens for r in successful) / len(successful)
        print(f"Avg Latency: {avg_lat:.1f} ms")
        print(f"Avg Tokens: {avg_tok:.0f}")
    print(f"Results saved to: {results_dir}")


if __name__ == "__main__":
    main()