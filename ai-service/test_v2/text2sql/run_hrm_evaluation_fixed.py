#!/usr/bin/env python3
"""
HRM Text-to-SQL Evaluation Pipeline (Clean Wrapper Version)

Uses hrm_eval_wrapper.py for clean integration with text2sql-eval-toolkit
without monkey-patching.
"""

import os
import json
import asyncio
import time
from pathlib import Path
import sys

# Add ai-service to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

# Load .env file
env_path = Path(__file__).parent.parent.parent / ".env"
if env_path.exists():
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ[key.strip()] = value.strip()

# Set PostgreSQL connection string for the toolkit
os.environ["HRM_POSTGRES_CONNECTION_STRING"] = "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm"
os.environ["TEXT2SQL_EVAL_TOOLKIT_DATA_ROOT"] = str(Path(__file__).parent / "benchmarks")

TEST_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"
TEST_YEAR = 2026

# Import clean wrapper
from .hrm_eval_wrapper import (
    postgres_run_execution_async,
    run_evaluation_step,
    replace_placeholders,
)


async def generate_predictions():
    """Generate SQL predictions using the HRM text2sql pipeline with incremental save/resume."""
    from src.sql.executor import generate_personal_rows
    from src.sql.text2sql import build_text2sql_prompt, extract_sql
    from src.sql.schema_registry import describe_schema

    # Load benchmark questions
    benchmark_file = Path(__file__).parent / "benchmarks" / "hrm_db_only.jsonl"
    questions = []
    with open(benchmark_file, "r", encoding="utf-8") as f:
        for line in f:
            questions.append(json.loads(line))

    # Load existing predictions for resume capability
    predictions_path = Path(__file__).parent / "benchmarks" / "results" / "hrm_db_only-predictions.json"
    existing_predictions = {}
    if predictions_path.exists():
        try:
            with open(predictions_path, "r", encoding="utf-8") as f:
                existing_data = json.load(f)
            for pred in existing_data:
                qid = pred["question_id"]
                pred_sql = pred.get("predictions", {}).get("hrm_text2sql", {}).get("predicted_sql", "")
                if pred_sql and pred_sql.strip():
                    existing_predictions[qid] = pred
            print(f"Loaded {len(existing_predictions)} completed predictions from {predictions_path} (resume mode)")
        except Exception as e:
            print(f"Warning: Could not load existing predictions: {e}")

    print(f"Generating predictions for {len(questions)} questions...")

    # Get LLM completion function
    llm_complete = get_llm_complete()

    predictions = []
    last_call_time = 0
    min_interval = 6.0  # seconds between calls (10 RPM = 6 sec, conservative for Free Tier)
    save_interval = 5  # Save every N predictions

    for i, q in enumerate(questions):
        question = q["question"]
        gold_sql = q["gold_sql"]
        qid = q["metadata"]["original_id"]

        # Skip if already completed (has non-empty predicted_sql)
        if qid in existing_predictions:
            predictions.append(existing_predictions[qid])
            if (i + 1) % 10 == 0:
                print(f"  Skipped {i + 1}/{len(questions)} (already completed: {qid})")
            continue

        try:
            # Rate limiting for Free Tier (15 RPM)
            elapsed = time.monotonic() - last_call_time
            if elapsed < min_interval:
                wait_time = min_interval - elapsed
                print(f"  Rate limiting: waiting {wait_time:.1f}s...")
                time.sleep(wait_time)

            # Generate SQL using HRM text2sql pipeline
            rows, predicted_sql = generate_personal_rows(
                llm_complete=llm_complete,
                question=question,
                user_id=TEST_UID
            )
            last_call_time = time.monotonic()

            pred_entry = {
                "question_id": qid,
                "question": question,
                "sql": gold_sql,  # ground truth SQL (with placeholders)
                "predictions": {
                    "hrm_text2sql": {
                        "predicted_sql": predicted_sql,
                        "token_usage": {
                            "prompt_tokens": 0,
                            "completion_tokens": 0,
                            "total_tokens": 0,
                        },
                        "inference_time_ms": 0,
                    }
                },
                "metadata": q["metadata"]
            }
            predictions.append(pred_entry)

            # Incremental save
            if len(predictions) % save_interval == 0:
                predictions_path.parent.mkdir(parents=True, exist_ok=True)
                with open(predictions_path, "w", encoding="utf-8") as f:
                    json.dump(predictions, f, indent=2, ensure_ascii=False)
                print(f"  Saved {len(predictions)}/{len(questions)} predictions (incremental)")

            if (i + 1) % 10 == 0:
                print(f"  Generated {i + 1}/{len(questions)} predictions")

        except Exception as e:
            err_msg = str(e).encode('ascii', 'replace').decode('ascii')
            print(f"  Error on question {qid}: {err_msg}")
            pred_entry = {
                "question_id": qid,
                "question": question,
                "sql": gold_sql,
                "predictions": {
                    "hrm_text2sql": {
                        "predicted_sql": "",
                        "inference_error": str(e),
                        "token_usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
                        "inference_time_ms": 0,
                    }
                },
                "metadata": q["metadata"]
            }
            predictions.append(pred_entry)

    # Final save
    predictions_path.parent.mkdir(parents=True, exist_ok=True)
    with open(predictions_path, "w", encoding="utf-8") as f:
        json.dump(predictions, f, indent=2, ensure_ascii=False)

    print(f"Predictions saved to {predictions_path} ({len(predictions)} total)")
    return str(predictions_path)


async def run_execution_step(predictions_path: str):
    """Execute SQL queries against PostgreSQL database using clean wrapper."""
    print("Running SQL execution against PostgreSQL...")

    from text2sql_eval_toolkit.utils import get_benchmark_info
    import os

    benchmark_info = get_benchmark_info("hrm_db_only")
    db_engine = benchmark_info["db_engine"]
    connection_string = os.getenv(db_engine["connection_string_env_var"])
    schema_name = db_engine.get("schema_name", "public")

    query_count = await postgres_run_execution_async(
        connection_string=connection_string,
        schema_name=schema_name,
        predictions_path=predictions_path,
        max_concurrent_tasks=16,
        per_query_timeout_s=90,
        force_rerun=False,
    )

    print(f"Executed {query_count} queries")

    # DEBUG: Check file after execution
    import json
    with open(predictions_path, "r", encoding="utf-8") as pf:
        data = json.load(pf)
    for pred in data[:3]:
        if 'hrm_text2sql' in pred.get('predictions', {}):
            pred_sql = pred['predictions']['hrm_text2sql'].get('predicted_sql', '')
            if '%(uid)s' in pred_sql:
                print(f"DEBUG: STILL HAS PLACEHOLDERS after execution: {pred['question_id']}")
                break
    else:
        print("DEBUG: No placeholders in first 3 predictions after execution")

    return query_count


# run_evaluation_step is imported from hrm_eval_wrapper


def get_llm_complete():
    """Get the LLM completion function for SQL generation using shared utility."""
    import sys
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))

    from src.utils.llm_completion import complete_sql

    def sync_llm_complete(system_prompt: str, user_prompt: str, tag: str = "") -> str:
        """Complete using the SQL model with centralized key rotation."""
        return complete_sql(system_prompt, user_prompt, temperature=0.0)

    return sync_llm_complete


async def main():
    print("=" * 60)
    print("HRM Text-to-SQL Evaluation Pipeline (Fixed)")
    print("=" * 60)

    # Check for any API key
    has_key = False
    for i in range(1, 6):
        if os.getenv(f"GEMINI_API_KEY_{i}"):
            has_key = True
            break
    if not has_key and not os.getenv("GEMINI_API_KEY"):
        print("\nERROR: No GEMINI_API_KEY* found in .env file")
        return

    # Step 1: Generate predictions
    print("\n[Step 1/3] Generating SQL predictions...")
    predictions_path = await generate_predictions()

    # Step 2: Execute SQL against database
    print("\n[Step 2/3] Executing SQL queries...")
    await run_execution_step(predictions_path)

    # Step 3: Run evaluation
    print("\n[Step 3/3] Computing metrics...")
    data, summary_df = run_evaluation_step()

    print("\n" + "=" * 60)
    print("Evaluation Complete!")
    print("=" * 60)

    # Print key metrics
    if len(summary_df) > 0:
        row = summary_df[summary_df["Model"] == "hrm_text2sql"]
        if len(row) > 0:
            row = row.iloc[0]
            print(f"\nExecution Accuracy (EX): {row.get('execution_accuracy_avg', 'N/A'):.2%}")
            print(f"Non-Empty EX: {row.get('non_empty_execution_accuracy_avg', 'N/A'):.2%}")
            print(f"Subset Non-Empty EX: {row.get('subset_non_empty_execution_accuracy_avg', 'N/A'):.2%}")
            print(f"Logic EX: {row.get('logic_execution_accuracy_avg', 'N/A'):.2%}")
            print(f"Bird EX: {row.get('bird_execution_accuracy_avg', 'N/A'):.2%}")
            print(f"SQL Exact Match: {row.get('sql_exact_match_avg', 'N/A'):.2%}")
            print(f"SQLGlot Equivalence: {row.get('sqlglot_equivalence_avg', 'N/A'):.2%}")
            print(f"SQLGlot Optimized Equiv: {row.get('sqlglot_optimized_equivalence_avg', 'N/A'):.2%}")
            print(f"SQLParse Equivalence: {row.get('sqlparse_equivalence_avg', 'N/A'):.2%}")
            print(f"Valid SQL (SQLGlot): {row.get('is_sqlglot_parsable_avg', 'N/A'):.2%}")
            print(f"Valid SQL (sqlparse): {row.get('is_sqlparse_parsable_avg', 'N/A'):.2%}")


if __name__ == "__main__":
    asyncio.run(main())