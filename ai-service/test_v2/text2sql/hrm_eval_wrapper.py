#!/usr/bin/env python3
"""
HRM Text2SQL Evaluation Wrapper

Clean wrapper around text2sql-eval-toolkit that handles:
1. Placeholder replacement (%(uid)s, %(year)s) for PostgreSQL compatibility
2. UUID serialization in query results
3. UTF-8 encoding for file operations

No monkey-patching - wraps upstream calls instead.
"""

import os
import json
import uuid
import asyncio
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional
from functools import wraps

import pandas as pd
import numpy as np
import asyncpg

from text2sql_eval_toolkit.execution.execution_tools import (
    run_sql_and_get_dataframe_async as upstream_run_sql,
    postgres_run_execution_async as upstream_postgres_run,
    quote_mixed_case_columns,
)
from text2sql_eval_toolkit.metrics.text2sql_utils import (
    is_sqlglot_parsable as upstream_is_sqlglot_parsable,
    sqlglot_parsed_queries_equivalent as upstream_sqlglot_parsed_equivalent,
    sqlglot_optimized_equivalence as upstream_sqlglot_optimized_equivalence,
    sqlparse_queries_equivalent as upstream_sqlparse_equivalent,
    sql_exact_match as upstream_sql_exact_match,
)
from text2sql_eval_toolkit.utils import get_benchmark_info, get_writable_data_root


# Configuration
TEST_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"
TEST_YEAR = 2026

# SQLGlot schema for HRM benchmark (built once)
_SQLGLOT_SCHEMA: Optional[Dict[str, List[str]]] = None


def _build_sqlglot_schema() -> Dict[str, List[str]]:
    """Build sqlglot schema mapping from benchmark schema file."""
    global _SQLGLOT_SCHEMA
    if _SQLGLOT_SCHEMA is not None:
        return _SQLGLOT_SCHEMA

    schema_path = Path(__file__).parent / "benchmarks" / "hrm_db_only-schema.json"
    with open(schema_path, "r", encoding="utf-8") as f:
        raw_schema = json.load(f)

    _SQLGLOT_SCHEMA = {}
    for table_name, table_info in raw_schema.items():
        columns = [col["name"] for col in table_info["columns"]]
        _SQLGLOT_SCHEMA[table_name] = columns
    return _SQLGLOT_SCHEMA


def replace_placeholders(sql: str) -> str:
    """Replace %(uid)s and %(year)s placeholders with actual values for PostgreSQL."""
    return sql.replace("%(uid)s", f"'{TEST_UID}'").replace("%(year)s", str(TEST_YEAR))


def _convert_uuids(obj: Any) -> Any:
    """Recursively convert UUID objects to strings in any data structure."""
    if isinstance(obj, uuid.UUID):
        return str(obj)
    if isinstance(obj, dict):
        return {k: _convert_uuids(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_convert_uuids(v) for v in obj]
    if isinstance(obj, tuple):
        return tuple(_convert_uuids(v) for v in obj)
    return obj


def _convert_numpy_types(obj: Any) -> Any:
    """Recursively convert numpy types to native Python types for JSON serialization."""
    if isinstance(obj, (np.integer, np.int64, np.int32, np.int16, np.int8)):
        return int(obj)
    if isinstance(obj, (np.floating, np.float64, np.float32, np.float16)):
        return float(obj)
    if isinstance(obj, np.bool_):
        return bool(obj)
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    if isinstance(obj, dict):
        return {k: _convert_numpy_types(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_convert_numpy_types(v) for v in obj]
    if isinstance(obj, tuple):
        return tuple(_convert_numpy_types(v) for v in obj)
    return obj


# --- Execution wrappers ---

async def run_sql_and_get_dataframe_async(
    pool: asyncpg.Pool,
    schema_name: str,
    sql: str,
    timeout: int = 90,
) -> pd.DataFrame:
    """
    Wrapper around upstream run_sql_and_get_dataframe_async that:
    1. Replaces placeholders before execution
    2. Converts UUIDs to strings in results
    """
    sql = replace_placeholders(sql)

    async def _execute_query():
        async with pool.acquire() as conn:
            await conn.execute(f"SET search_path TO {schema_name}")
            rows = await conn.fetch(sql)
            if rows:
                columns = rows[0].keys()
            else:
                columns = []
            data = []
            for row in rows:
                row_dict = dict(row)
                # Convert UUID objects to strings
                for k, v in row_dict.items():
                    if isinstance(v, uuid.UUID):
                        row_dict[k] = str(v)
                data.append(row_dict)
            return await asyncio.to_thread(pd.DataFrame, data, columns=columns)

    return await asyncio.wait_for(_execute_query(), timeout=timeout)


async def postgres_run_execution_async(
    connection_string: str,
    schema_name: str,
    predictions_path: str,
    max_concurrent_tasks: int = 16,
    per_query_timeout_s: int = 90,
    force_rerun: bool = False,
) -> int:
    """
    Wrapper around upstream postgres_run_execution_async that:
    1. Replaces placeholders in all SQL before execution
    2. Uses our wrapped run_sql_and_get_dataframe_async for UUID handling
    """
    # Read and modify predictions file
    with open(predictions_path, "r", encoding="utf-8") as pf:
        predictions_data = json.load(pf)

    # Replace placeholders in all SQL fields
    for obj in predictions_data:
        # Gold SQL
        if "sql" in obj:
            gt_sqls = obj["sql"]
            if not isinstance(gt_sqls, list):
                gt_sqls = [gt_sqls]
            obj["sql"] = [replace_placeholders(sql) for sql in gt_sqls]

        # Also check metadata.sql
        if "metadata" in obj and "sql" in obj["metadata"]:
            gt_sqls = obj["metadata"]["sql"]
            if not isinstance(gt_sqls, list):
                gt_sqls = [gt_sqls]
            obj["metadata"]["sql"] = [replace_placeholders(sql) for sql in gt_sqls]

        # Predicted SQL and logic SQL
        for _model_name, model_predictions in obj.get("predictions", {}).items():
            for key in ["predicted_sql", "logic_sql"]:
                if key in model_predictions and model_predictions[key]:
                    model_predictions[key] = replace_placeholders(model_predictions[key])

    # Write back modified predictions
    with open(predictions_path, "w", encoding="utf-8") as pf:
        json.dump(predictions_data, pf, indent=4, ensure_ascii=False)

    # Now run with our wrapped execution function
    from text2sql_eval_toolkit.execution.execution_tools import quote_mixed_case_columns
    from text2sql_eval_toolkit.logging import get_logger

    logger = get_logger(__name__)

    pool = await asyncpg.create_pool(
        dsn=connection_string,
        min_size=1,
        max_size=max_concurrent_tasks,
        server_settings={"search_path": schema_name},
    )
    semaphore = asyncio.Semaphore(max_concurrent_tasks)

    query_count = 0
    query_lock = asyncio.Lock()

    async def run_sql_with_count(sql: str) -> pd.DataFrame:
        nonlocal query_count
        df = await run_sql_and_get_dataframe_async(
            pool, schema_name, sql, per_query_timeout_s
        )
        async with query_lock:
            query_count += 1
        return df

    async def process_prediction(obj: Dict) -> Dict:
        async with semaphore:
            obj = json.loads(json.dumps(obj))  # deepcopy-safe

            if "metadata" in obj and "sql" in obj["metadata"]:
                obj["sql"] = obj["metadata"]["sql"]

            gt_sqls = obj.get("sql")
            if not isinstance(gt_sqls, list):
                gt_sqls = [gt_sqls]

            gt_dfs = []
            for gt_sql in gt_sqls:
                try:
                    gt_df = await run_sql_with_count(gt_sql)
                    gt_dfs.append(gt_df.to_json(orient="split"))
                except asyncio.TimeoutError:
                    logger.error(f"GT SQL timed out after {per_query_timeout_s}s")
                    obj["gt_sql_execution_error"] = (
                        f"GT SQL timed out after {per_query_timeout_s}s"
                    )
                except Exception as e:
                    logger.error(f"Error running ground truth SQL: {e}")
                    logger.error(f"SQL: {gt_sql}")
                    obj["gt_sql_execution_error"] = (
                        f"Error running ground truth SQL: {e}"
                    )

            if gt_dfs:
                obj["gt_df"] = gt_dfs if len(gt_dfs) > 1 else gt_dfs[0]
                obj.pop("gt_sql_execution_error", None)

            async def _run_and_store_df(
                sql_key: str,
                df_key: str,
                error_key: str,
                truncated_flag_key: str,
                execution_time_key: str,
                model_predictions: dict,
                obj: dict,
                run_sql_fn,
            ):
                sql = model_predictions.get(sql_key)
                if not sql or (df_key in model_predictions and not force_rerun):
                    return

                sql = quote_mixed_case_columns(sql)
                model_predictions[sql_key] = sql

                try:
                    import time
                    execution_start = time.perf_counter()
                    df = await run_sql_fn(sql)
                    execution_end = time.perf_counter()
                    execution_time_ms = (execution_end - execution_start) * 1000

                    # Determine max ground truth row count
                    if isinstance(obj["gt_df"], list):
                        max_gt_rows = max(
                            pd.read_json(gt, orient="split").shape[0]
                            for gt in obj["gt_df"]
                        )
                    else:
                        max_gt_rows = pd.read_json(obj["gt_df"], orient="split").shape[0]

                    # Truncate if too many rows
                    if df.shape[0] - max_gt_rows >= 10:
                        df = df.head(max_gt_rows + 9)
                        model_predictions[truncated_flag_key] = True

                    model_predictions[df_key] = df.to_json(orient="split")
                    model_predictions[execution_time_key] = round(execution_time_ms, 2)
                    model_predictions.pop(error_key, None)

                except asyncio.TimeoutError:
                    model_predictions[error_key] = (
                        f"Error running SQL: timed out after {per_query_timeout_s}s"
                    )
                    model_predictions[execution_time_key] = None
                    logger.debug(f"SQL timed out after {per_query_timeout_s}s")
                except Exception as e:
                    model_predictions[error_key] = f"Error running SQL: {e}"
                    model_predictions[execution_time_key] = None
                    logger.debug(f"SQL error: {e}")

            for _model_name, model_predictions in obj.get("predictions", {}).items():
                await _run_and_store_df(
                    sql_key="predicted_sql",
                    df_key="predicted_df",
                    error_key="sql_execution_error",
                    truncated_flag_key="predicted_df_truncated",
                    execution_time_key="execution_time_ms",
                    model_predictions=model_predictions,
                    obj=obj,
                    run_sql_fn=run_sql_with_count,
                )
                await _run_and_store_df(
                    sql_key="logic_sql",
                    df_key="logic_df",
                    error_key="logic_sql_execution_error",
                    truncated_flag_key="logic_df_truncated",
                    execution_time_key="logic_execution_time_ms",
                    model_predictions=model_predictions,
                    obj=obj,
                    run_sql_fn=run_sql_with_count,
                )

            return obj

    # Process all predictions
    tasks = [process_prediction(obj) for obj in predictions_data]
    results = await asyncio.gather(*tasks)

    # Write results back
    with open(predictions_path, "w", encoding="utf-8") as pf:
        json.dump(results, pf, indent=4, ensure_ascii=False)

    await pool.close()
    return query_count


# --- Evaluation metric wrappers ---

def is_sqlglot_parsable(sql: str, db_type: str = "sqlite") -> bool:
    """Wrapper that replaces placeholders before parsing."""
    sql = replace_placeholders(sql)
    # Use postgres dialect for HRM benchmark
    return upstream_is_sqlglot_parsable(sql, "postgres")


def sqlglot_parsed_queries_equivalent(
    sql1: str, sql2: str, dialect: str = ""
) -> bool:
    """Wrapper that replaces placeholders before comparing."""
    sql1 = replace_placeholders(sql1)
    sql2 = replace_placeholders(sql2)
    try:
        from sqlglot import parse_one
        ast1 = parse_one(sql1, read="postgres")
        ast2 = parse_one(sql2, read="postgres")
        return ast1 == ast2
    except Exception:
        return False


def sqlglot_optimized_equivalence(
    sql1: str, sql2: str, dialect: str = ""
) -> int:
    """Wrapper that replaces placeholders before optimizing."""
    sql1 = replace_placeholders(sql1)
    sql2 = replace_placeholders(sql2)
    try:
        from sqlglot import parse_one
        from sqlglot.optimizer import optimize
        ast1 = optimize(parse_one(sql1, read="postgres"))
        ast2 = optimize(parse_one(sql2, read="postgres"))
        return int(ast1 == ast2)
    except Exception:
        return 0


def sqlparse_queries_equivalent(sql1: str, sql2: str) -> bool:
    """Wrapper that replaces placeholders before comparing."""
    sql1 = replace_placeholders(sql1)
    sql2 = replace_placeholders(sql2)
    return upstream_sqlparse_equivalent(sql1, sql2)


def sql_exact_match(sql1: str, sql2: str) -> bool:
    """Wrapper that replaces placeholders before comparing."""
    sql1 = replace_placeholders(sql1)
    sql2 = replace_placeholders(sql2)
    return upstream_sql_exact_match(sql1, sql2)


# --- File I/O wrapper ---

class UTF8FileHandler:
    """Context manager for UTF-8 file operations with CSV lock handling."""

    def __init__(self):
        self._original_open = open
        self._temp_files = []

    def __enter__(self):
        import builtins
        builtins.open = self._patched_open
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        import builtins
        builtins.open = self._original_open
        # Clean up temp files on exit
        for tmp_path, orig_path in self._temp_files:
            try:
                if os.path.exists(tmp_path):
                    os.replace(tmp_path, orig_path)
            except Exception:
                pass

    def _patched_open(self, *args, **kwargs):
        if 'encoding' not in kwargs and args and isinstance(args[0], str) and args[0].endswith('.json'):
            kwargs['encoding'] = 'utf-8'
        try:
            return self._original_open(*args, **kwargs)
        except PermissionError:
            # Handle case where CSV file is locked (e.g., open in Excel)
            if args and isinstance(args[0], str) and args[0].endswith('.csv'):
                tmp_path = tempfile.mktemp(suffix='.csv', dir=os.path.dirname(args[0]))
                kwargs['encoding'] = kwargs.get('encoding', 'utf-8')
                handle = self._original_open(tmp_path, *args[1:], **kwargs)
                self._temp_files.append((tmp_path, args[0]))
                return handle
            raise


class NumpyJSONEncoder(json.JSONEncoder):
    """JSON encoder that handles numpy types."""
    def default(self, obj):
        if isinstance(obj, (np.integer, np.int64, np.int32, np.int16, np.int8)):
            return int(obj)
        if isinstance(obj, (np.floating, np.float64, np.float32, np.float16)):
            return float(obj)
        if isinstance(obj, np.bool_):
            return bool(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return super().default(obj)


# --- Evaluation runner ---

def run_evaluation_step() -> tuple:
    """Run evaluation metrics with HRM-specific wrappers."""
    print("Running evaluation metrics...")

    # Apply metric wrappers
    import text2sql_eval_toolkit.metrics.text2sql_utils as t2s_utils
    import text2sql_eval_toolkit.evaluation.evaluation_tools as et_eval

    t2s_utils.is_sqlglot_parsable = is_sqlglot_parsable
    t2s_utils.sqlglot_parsed_queries_equivalent = sqlglot_parsed_queries_equivalent
    t2s_utils.sqlglot_optimized_equivalence = sqlglot_optimized_equivalence
    t2s_utils.sqlparse_queries_equivalent = sqlparse_queries_equivalent
    t2s_utils.sql_exact_match = sql_exact_match

    et_eval.is_sqlglot_parsable = is_sqlglot_parsable
    et_eval.sqlglot_parsed_queries_equivalent = sqlglot_parsed_queries_equivalent
    et_eval.sqlglot_optimized_equivalence = sqlglot_optimized_equivalence
    et_eval.sqlparse_queries_equivalent = sqlparse_queries_equivalent
    et_eval.sql_exact_match = sql_exact_match

    # Patch json.dump in evaluation_tools to use numpy-aware encoder
    import text2sql_eval_toolkit.evaluation.evaluation_tools as et_eval_module
    original_json_dump = et_eval_module.json.dump

    def patched_json_dump(obj, fp, *args, **kwargs):
        if 'cls' not in kwargs:
            kwargs['cls'] = NumpyJSONEncoder
        return original_json_dump(obj, fp, *args, **kwargs)

    et_eval_module.json.dump = patched_json_dump

    try:
        # Run evaluation with UTF-8 file handling
        with UTF8FileHandler():
            from text2sql_eval_toolkit import run_evaluation
            data, summary_df = run_evaluation("hrm_db_only", use_llm=False, force_rerun=True)
    finally:
        # Restore original json.dump
        et_eval_module.json.dump = original_json_dump

    print("\n=== Evaluation Summary ===")
    print(summary_df.to_string())

    return data, summary_df


if __name__ == "__main__":
    # Quick test
    print("Testing placeholder replacement:")
    test_sql = "SELECT * FROM users WHERE user_id = %(uid)s AND year = %(year)s"
    print(f"Original: {test_sql}")
    print(f"Replaced: {replace_placeholders(test_sql)}")

    print("\nTesting UUID conversion:")
    test_data = {"id": uuid.uuid4(), "nested": {"uid": uuid.uuid4()}}
    print(f"Original: {test_data}")
    print(f"Converted: {_convert_uuids(test_data)}")

    print("\nWrapper module loaded successfully.")