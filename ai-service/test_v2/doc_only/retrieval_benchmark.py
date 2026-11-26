#!/usr/bin/env python3
"""
DOC_ONLY Retrieval Benchmark - Tests retrieval pipeline with multiple parameter combinations.

This test focuses ONLY on retrieval (no LLM generation), following the production pipeline:
1. Query embedding (LocalEmbedder)
2. Hybrid search: Dense vector (content_vector + questions_vector) + Sparse BM25 (tsvector)
3. PBAC filtering (allowed_jobs, allowed_departments)
4. Cross-Encoder reranking (optional)
5. Same-file bonus reordering
6. Relevance threshold gating

Tests multiple configurations simultaneously to find optimal:
- RELEVANCE_THRESHOLD: [0.15, 0.30, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.76]
- top_k: [3, 5, 7, 10]
- vector_weight: [0.5, 0.6, 0.7, 0.8] (lexical_weight = 1 - vector_weight)
- with_reranker: [True, False]

Outputs detailed metrics per configuration for comparison.
"""

import os
import sys
import json
import time
import argparse
import csv
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
from concurrent.futures import ThreadPoolExecutor, as_completed

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Add ai-service root to path (where src/ lives)
AI_SERVICE_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(AI_SERVICE_ROOT))

from dotenv import load_dotenv
load_dotenv()

from src.retrievers.hybrid_retriever import HybridRetriever
from src.chat.chat_service import RELEVANCE_THRESHOLD as DEFAULT_THRESHOLD
from src.embeddings.local_embedder import LocalEmbedder
from src.db.session import get_db_connection


@dataclass
class RetrievalConfig:
    """Configuration for a single retrieval test run."""
    relevance_threshold: float
    top_k: int
    vector_weight: float
    use_reranker: bool
    lexical_weight: float = None

    def __post_init__(self):
        if self.lexical_weight is None:
            self.lexical_weight = 1.0 - self.vector_weight

    def to_dict(self):
        return {
            "relevance_threshold": self.relevance_threshold,
            "top_k": self.top_k,
            "vector_weight": self.vector_weight,
            "lexical_weight": self.lexical_weight,
            "use_reranker": self.use_reranker
        }

    def short_name(self) -> str:
        return f"T{self.relevance_threshold}_k{self.top_k}_vw{self.vector_weight}_rr{int(self.use_reranker)}"


@dataclass
class QuestionResult:
    """Result for a single question under a specific config."""
    question_id: str
    question: str
    config_name: str
    retrieved_count: int
    top1_score: float
    top1_breadcrumb: str
    gold_rank: Optional[int]
    hit_at_1: bool
    hit_at_3: bool
    hit_at_5: bool
    hit_at_10: bool
    mrr: float
    fallback: bool  # top1 < threshold
    retrieve_time_ms: float
    rerank_time_ms: float
    embed_time_ms: float
    content_similarity: float
    question_similarity: float
    vector_score: float
    text_rank: float
    error: Optional[str] = None


@dataclass
class ConfigSummary:
    """Aggregated metrics for a configuration."""
    config: RetrievalConfig
    total_questions: int
    successful: int
    hit_at_1: float
    hit_at_3: float
    hit_at_5: float
    hit_at_10: float
    mrr_at_5: float
    mrr_at_10: float
    top1_mean: float
    fallback_rate: float
    avg_retrieve_time: float
    avg_rerank_time: float
    avg_embed_time: float
    avg_content_similarity: float
    avg_question_similarity: float
    avg_vector_score: float
    avg_text_rank: float
    error_rate: float

    def passes_thresholds(self, thresholds: Dict[str, Any]) -> Dict[str, bool]:
        """Check if config passes all thresholds."""
        return {
            "hit_at_5": self.hit_at_5 >= thresholds.get("hit_at_5", 0.60),
            "mrr_at_5": self.mrr_at_5 >= thresholds.get("mrr_at_5", 0.45),
            "top1_mean": self.top1_mean >= thresholds.get("top1_mean", 0.20),
            "fallback_rate": self.fallback_rate <= thresholds.get("fallback_rate", 0.20),
        }


def load_testset(limit: int = 0, dataset_path: Optional[Path] = None) -> List[Dict[str, Any]]:
    """Load DOC_ONLY questions from the generated testset CSV."""
    if dataset_path is None:
        dataset_path = AI_SERVICE_ROOT / "tests" / "generated_testset.csv"

    from src.sql.router import keyword_fallback

    rows = []
    with open(dataset_path, encoding="utf-8-sig") as fh:
        for r in csv.DictReader(fh):
            if "THIEU THONG TIN" in (r.get("answer_draft") or ""):
                continue
            if keyword_fallback(r["question"]) != "DOC_ONLY":
                continue

            # Add id if missing
            if "id" not in r or not r["id"]:
                r["id"] = f"Q{len(rows)+1:03d}"

            rows.append(r)
            if limit > 0 and len(rows) >= limit:
                break

    print(f"[Dataset] Loaded {len(rows)} DOC_ONLY questions from {dataset_path}")
    return rows


def _fold(text: str) -> str:
    """Normalize Vietnamese text for comparison."""
    return "".join(c for c in __import__("unicodedata").normalize("NFD", text or "")
                   if __import__("unicodedata").category(c) != "Mn").lower()


def _norm(text: str) -> str:
    """Normalize text for gold matching (handle chunker's '|' separator)."""
    t = (text or "").replace("|", " ")
    return __import__("re").sub(r"\s+", " ", t).strip().lower()


def gold_rank(gold_preview: str, got: List[Dict], question: str = "") -> Optional[int]:
    """Find rank (1-based) of gold chunk in retrieved results."""
    needle = _norm(gold_preview)[:120]

    # Fallback keywords from question
    stop = {"làm", "sao", "để", "cho", "và", "của", "cái", "này", "kia", "có", "không",
            "được", "là", "gì", "ai", "nào", "trong", "ngoài", "về", "theo", "the"}
    q_words = [w for w in _norm(question).split() if w not in stop and len(w) > 2]

    for i, c in enumerate(got):
        hay = _norm(c.get("content", ""))
        # 1. Try match preview (priority)
        if needle and needle in hay:
            return i + 1
        # 2. Fallback: match >=2 keywords from question
        if q_words:
            hits = sum(1 for w in q_words if w in hay)
            if hits >= 2:
                return i + 1
    return None


def run_single_config(
    config: RetrievalConfig,
    questions: List[Dict[str, Any]],
    retriever: HybridRetriever
) -> List[QuestionResult]:
    """Run all questions for a single configuration."""
    results = []

    for q_data in questions:
        q = q_data["question"]
        qid = q_data.get("id", "")
        gold_preview = q_data.get("content_preview", "")

        row = QuestionResult(
            question_id=qid,
            question=q,
            config_name=config.short_name(),
            retrieved_count=0,
            top1_score=0.0,
            top1_breadcrumb="",
            gold_rank=None,
            hit_at_1=False,
            hit_at_3=False,
            hit_at_5=False,
            hit_at_10=False,
            mrr=0.0,
            fallback=False,
            retrieve_time_ms=0.0,
            rerank_time_ms=0.0,
            embed_time_ms=0.0,
            content_similarity=0.0,
            question_similarity=0.0,
            vector_score=0.0,
            text_rank=0.0,
        )

        try:
            # Embed time
            t = time.perf_counter()
            retriever.embedder.generate_embedding(q, task_type="retrieval_query")
            row.embed_time_ms = (time.perf_counter() - t) * 1000

            # Retrieve WITH reranker
            t = time.perf_counter()
            got = retriever.retrieve(
                query=q,
                jobs=["ALL"],
                departments=["ALL"],
                top_k=config.top_k,
                use_reranker=config.use_reranker,
                vw=config.vector_weight,
                lw=config.lexical_weight
            )
            row.retrieve_time_ms = (time.perf_counter() - t) * 1000

            # Retrieve WITHOUT reranker (for rerank time calculation)
            t = time.perf_counter()
            raw = retriever.retrieve(
                query=q,
                jobs=["ALL"],
                departments=["ALL"],
                top_k=config.top_k,
                use_reranker=False,
                vw=config.vector_weight,
                lw=config.lexical_weight
            )
            retrieve_time_norerank = (time.perf_counter() - t) * 1000
            row.rerank_time_ms = row.retrieve_time_ms - retrieve_time_norerank

            if not got:
                row.fallback = True
                results.append(row)
                continue

            top = got[0]
            row.retrieved_count = len(got)
            row.top1_score = top.get("relevance_score", 0.0)
            row.top1_breadcrumb = top.get("breadcrumb", "")[:120]
            row.content_similarity = top.get("content_similarity", 0.0)
            row.question_similarity = top.get("question_similarity", 0.0)
            row.vector_score = top.get("vector_score", 0.0)
            row.text_rank = top.get("text_rank", 0.0)
            row.fallback = row.top1_score < config.relevance_threshold

            # Gold rank
            rank = gold_rank(gold_preview, got, q)
            row.gold_rank = rank
            row.hit_at_1 = rank == 1
            row.hit_at_3 = rank is not None and rank <= 3
            row.hit_at_5 = rank is not None and rank <= 5
            row.hit_at_10 = rank is not None and rank <= 10
            row.mrr = 1.0 / rank if rank and rank <= 5 else 0.0

        except Exception as e:
            row.error = f"{type(e).__name__}: {e}"[:200]

        results.append(row)

    return results


def summarize_config(config: RetrievalConfig, results: List[QuestionResult]) -> ConfigSummary:
    """Compute aggregate metrics for a configuration."""
    n = len(results) or 1
    scored = [r for r in results if r.error is None]
    s_n = len(scored) or 1

    return ConfigSummary(
        config=config,
        total_questions=n,
        successful=s_n,
        hit_at_1=sum(1 for r in scored if r.hit_at_1) / n,
        hit_at_3=sum(1 for r in scored if r.hit_at_3) / n,
        hit_at_5=sum(1 for r in scored if r.hit_at_5) / n,
        hit_at_10=sum(1 for r in scored if r.hit_at_10) / n,
        mrr_at_5=sum(r.mrr for r in scored) / n,
        mrr_at_10=sum(1.0 / r.gold_rank for r in scored if r.gold_rank and r.gold_rank <= 10) / n,
        top1_mean=sum(r.top1_score for r in scored) / s_n,
        fallback_rate=sum(1 for r in scored if r.fallback) / n,
        avg_retrieve_time=sum(r.retrieve_time_ms for r in scored) / s_n,
        avg_rerank_time=sum(r.rerank_time_ms for r in scored) / s_n,
        avg_embed_time=sum(r.embed_time_ms for r in scored) / s_n,
        avg_content_similarity=sum(r.content_similarity for r in scored) / s_n,
        avg_question_similarity=sum(r.question_similarity for r in scored) / s_n,
        avg_vector_score=sum(r.vector_score for r in scored) / s_n,
        avg_text_rank=sum(r.text_rank for r in scored) / s_n,
        error_rate=sum(1 for r in results if r.error) / n,
    )


def print_config_table(summaries: List[ConfigSummary], thresholds: Dict[str, Any]):
    """Print a comparison table of all configurations."""
    print("\n" + "=" * 140)
    print("CONFIGURATION COMPARISON")
    print("=" * 140)

    # Header
    header = f"{'Config':<25} {'Hit@1':>7} {'Hit@3':>7} {'Hit@5':>7} {'Hit@10':>7} {'MRR@5':>7} {'Top1':>7} {'Fallback':>8} {'Retr(ms)':>8} {'Rerank':>7} {'Pass':>4}"
    print(header)
    print("-" * len(header))

    for s in sorted(summaries, key=lambda x: (-x.hit_at_5, -x.mrr_at_5, x.fallback_rate)):
        config = s.config
        passes = s.passes_thresholds(thresholds)
        all_pass = all(passes.values())
        pass_str = "✅" if all_pass else "❌"

        line = (f"{config.short_name():<25} "
                f"{s.hit_at_1:>7.4f} {s.hit_at_3:>7.4f} {s.hit_at_5:>7.4f} {s.hit_at_10:>7.4f} "
                f"{s.mrr_at_5:>7.4f} {s.top1_mean:>7.4f} {s.fallback_rate:>8.4f} "
                f"{s.avg_retrieve_time:>8.1f} {s.avg_rerank_time:>7.1f} {pass_str:>4}")
        print(line)

    print("\nThresholds:", thresholds)


def print_detailed_summary(summaries: List[ConfigSummary]):
    """Print detailed metrics for the best configuration."""
    best = max(summaries, key=lambda x: (x.hit_at_5, x.mrr_at_5, -x.fallback_rate))

    print("\n" + "=" * 140)
    print(f"BEST CONFIGURATION: {best.config.short_name()}")
    print("=" * 140)
    print(f"  Relevance Threshold: {best.config.relevance_threshold}")
    print(f"  Top K: {best.config.top_k}")
    print(f"  Vector Weight: {best.config.vector_weight} (Lexical: {best.config.lexical_weight})")
    print(f"  Use Reranker: {best.config.use_reranker}")
    print()
    print("  Retrieval Quality:")
    print(f"    Hit@1:     {best.hit_at_1:.4f} ({best.hit_at_1*100:.1f}%)")
    print(f"    Hit@3:     {best.hit_at_3:.4f} ({best.hit_at_3*100:.1f}%)")
    print(f"    Hit@5:     {best.hit_at_5:.4f} ({best.hit_at_5*100:.1f}%)")
    print(f"    Hit@10:    {best.hit_at_10:.4f} ({best.hit_at_10*100:.1f}%)")
    print(f"    MRR@5:     {best.mrr_at_5:.4f}")
    print(f"    MRR@10:    {best.mrr_at_10:.4f}")
    print(f"    Top1 Mean: {best.top1_mean:.4f}")
    print(f"    Fallback:  {best.fallback_rate:.4f} ({best.fallback_rate*100:.1f}%)")
    print()
    print("  Component Scores:")
    print(f"    Content Similarity:  {best.avg_content_similarity:.4f}")
    print(f"    Question Similarity: {best.avg_question_similarity:.4f}")
    print(f"    Vector Score:        {best.avg_vector_score:.4f}")
    print(f"    Text Rank (BM25):    {best.avg_text_rank:.4f}")
    print()
    print("  Latency (mean):")
    print(f"    Embed:     {best.avg_embed_time:.1f} ms")
    print(f"    Retrieve:  {best.avg_retrieve_time:.1f} ms")
    print(f"    Rerank:    {best.avg_rerank_time:.1f} ms")
    print(f"    Total:     {best.avg_retrieve_time + best.avg_embed_time:.1f} ms")
    print()
    print("  Reliability:")
    print(f"    Error Rate:  {best.error_rate:.4f}")
    print(f"    Success:     {best.successful}/{best.total_questions}")


def save_results(summaries: List[ConfigSummary], all_results: List[QuestionResult],
                 output_dir: Path, questions: List[Dict[str, Any]]):
    """Save detailed results to JSON files."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # Save per-config summaries
    summary_data = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "total_questions": len(questions),
        "configs": []
    }

    for s in summaries:
        summary_data["configs"].append({
            "config": s.config.to_dict(),
            "metrics": {
                "total_questions": s.total_questions,
                "successful": s.successful,
                "hit_at_1": round(s.hit_at_1, 4),
                "hit_at_3": round(s.hit_at_3, 4),
                "hit_at_5": round(s.hit_at_5, 4),
                "hit_at_10": round(s.hit_at_10, 4),
                "mrr_at_5": round(s.mrr_at_5, 4),
                "mrr_at_10": round(s.mrr_at_10, 4),
                "top1_mean": round(s.top1_mean, 4),
                "fallback_rate": round(s.fallback_rate, 4),
                "avg_retrieve_time": round(s.avg_retrieve_time, 1),
                "avg_rerank_time": round(s.avg_rerank_time, 1),
                "avg_embed_time": round(s.avg_embed_time, 1),
                "avg_content_similarity": round(s.avg_content_similarity, 4),
                "avg_question_similarity": round(s.avg_question_similarity, 4),
                "avg_vector_score": round(s.avg_vector_score, 4),
                "avg_text_rank": round(s.avg_text_rank, 4),
                "error_rate": round(s.error_rate, 4),
            },
            "passes_thresholds": s.passes_thresholds({
                "hit_at_5": 0.60, "mrr_at_5": 0.45, "top1_mean": 0.20, "fallback_rate": 0.20
            })
        })

    summary_file = output_dir / "config_comparison.json"
    summary_file.write_text(json.dumps(summary_data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n[Saved] Config comparison: {summary_file}")

    # Save per-question results for best config
    best = max(summaries, key=lambda x: (x.hit_at_5, x.mrr_at_5, -x.fallback_rate))
    best_results = [r for r in all_results if r.config_name == best.config.short_name()]

    detail_data = {
        "best_config": best.config.to_dict(),
        "questions": [asdict(r) for r in best_results]
    }
    detail_file = output_dir / f"detail_{best.config.short_name()}.json"
    detail_file.write_text(json.dumps(detail_data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[Saved] Detail results: {detail_file}")

    # Save all results (can be large)
    all_data = {
        "configs": [s.config.to_dict() for s in summaries],
        "results": [asdict(r) for r in all_results]
    }
    all_file = output_dir / "all_results.json"
    all_file.write_text(json.dumps(all_data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[Saved] All results: {all_file}")


def generate_configs() -> List[RetrievalConfig]:
    """Generate all parameter combinations to test."""
    configs = []

    # Thresholds to test (from 0.15 current to 0.76 calibrated)
    thresholds = [0.15, 0.30, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.76]

    # Top-k values
    top_ks = [3, 5, 7, 10]

    # Vector weights (lexical = 1 - vector)
    vector_weights = [0.5, 0.6, 0.7, 0.8]

    # Reranker on/off
    reranker_options = [True, False]

    for t in thresholds:
        for k in top_ks:
            for vw in vector_weights:
                for rr in reranker_options:
                    configs.append(RetrievalConfig(
                        relevance_threshold=t,
                        top_k=k,
                        vector_weight=vw,
                        use_reranker=rr
                    ))

    print(f"[Config] Generated {len(configs)} parameter combinations")
    return configs


def main():
    parser = argparse.ArgumentParser(description="DOC_ONLY Retrieval Benchmark")
    parser.add_argument("--n", type=int, default=30, help="Number of questions to test (0 = all)")
    parser.add_argument("--workers", type=int, default=4, help="Parallel workers for configs")
    parser.add_argument("--output", type=str, default=None, help="Output directory (default: timestamped)")
    parser.add_argument("--quick", action="store_true", help="Run quick subset of configs")
    args = parser.parse_args()

    # Load questions
    questions = load_testset(limit=args.n)
    if not questions:
        print("[ERROR] No questions loaded!")
        sys.exit(1)

    # Initialize retriever
    print("[Init] Initializing HybridRetriever...")
    retriever = HybridRetriever()
    print(f"[Init] Retriever ready (reranker: {'ON' if retriever.reranker else 'OFF'})")

    # Generate configs
    if args.quick:
        # Quick test: fewer combinations
        configs = [
            RetrievalConfig(0.15, 5, 0.7, True),
            RetrievalConfig(0.30, 5, 0.7, True),
            RetrievalConfig(0.50, 5, 0.7, True),
            RetrievalConfig(0.60, 5, 0.7, True),
            RetrievalConfig(0.70, 5, 0.7, True),
            RetrievalConfig(0.76, 5, 0.7, True),
            RetrievalConfig(0.15, 7, 0.7, True),
            RetrievalConfig(0.50, 7, 0.7, True),
            RetrievalConfig(0.15, 5, 0.7, False),
            RetrievalConfig(0.50, 5, 0.7, False),
        ]
    else:
        configs = generate_configs()

    # Run all configs (parallel)
    all_results = []
    summaries = []

    print(f"\n[Benchmark] Running {len(configs)} configurations on {len(questions)} questions...")
    print(f"[Benchmark] Using {args.workers} workers\n")

    start_time = time.perf_counter()

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_config = {
            executor.submit(run_single_config, config, questions, retriever): config
            for config in configs
        }

        completed = 0
        for future in as_completed(future_to_config):
            config = future_to_config[future]
            try:
                results = future.result()
                all_results.extend(results)
                summary = summarize_config(config, results)
                summaries.append(summary)
                completed += 1
                print(f"  [{completed}/{len(configs)}] {config.short_name()}: "
                      f"Hit@5={summary.hit_at_5:.4f}, MRR@5={summary.mrr_at_5:.4f}, "
                      f"Fallback={summary.fallback_rate:.4f}, Top1={summary.top1_mean:.4f}")
            except Exception as e:
                print(f"  [ERROR] {config.short_name()}: {e}")

    elapsed = time.perf_counter() - start_time
    print(f"\n[Benchmark] Completed in {elapsed:.1f}s")

    # Print results
    thresholds = {"hit_at_5": 0.60, "mrr_at_5": 0.45, "top1_mean": 0.20, "fallback_rate": 0.20}
    print_config_table(summaries, thresholds)
    print_detailed_summary(summaries)

    # Save results
    if args.output:
        output_dir = Path(args.output)
    else:
        timestamp = time.strftime("%Y-%m-%d_%H-%M-%S")
        output_dir = AI_SERVICE_ROOT / "test_v2" / "doc_only" / "results" / f"retrieval_bench_{timestamp}"

    save_results(summaries, all_results, output_dir, questions)

    print(f"\n✅ Benchmark complete! Results in: {output_dir}")


if __name__ == "__main__":
    main()