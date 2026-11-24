#!/usr/bin/env python3
"""
Audit all 187 gold SQLs from db_only_hybrid_questions_with_answers.json
Execute each gold SQL against the hrm database and verify:
1. Does it execute without error?
2. What columns/rows does it return?
3. What tables does it reference?
4. What patterns does it use (LAG, CASE, FULL OUTER JOIN, etc.)?
"""
import json
import re
import sys
from pathlib import Path
from collections import defaultdict

import psycopg2
from psycopg2.extras import RealDictCursor

# Database connection (from CLAUDE.md)
HRM_DB_URL = "postgresql://hrm_ai_reader:%40Minhtrung1408@localhost:5432/hrm"
TEST_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"  # Gold UID

QS_FILE = Path(__file__).resolve().parent.parent.parent / "tests" / "db_only_hybrid_questions_with_answers.json"

# Pattern detectors
PATTERNS = {
    "LAG_OVER": r"LAG\s*\([^)]+\)\s+OVER\s*\(",
    "CASE_WHEN": r"CASE\s+WHEN",
    "FULL_OUTER_JOIN": r"FULL\s+OUTER\s+JOIN",
    "LEFT_JOIN": r"LEFT\s+JOIN",
    "RIGHT_JOIN": r"RIGHT\s+JOIN",
    "INNER_JOIN": r"INNER\s+JOIN",
    "CTE_WITH": r"^\s*WITH\s+\w+\s+AS\s*\(",
    "SUBQUERY_IN_SELECT": r"SELECT\s+(?:.*?\s+)?\(SELECT",
    "EXTRACT_QUARTER": r"EXTRACT\s*\(\s*QUARTER",
    "EXTRACT_YEAR": r"EXTRACT\s*\(\s*YEAR",
    "EXTRACT_MONTH": r"EXTRACT\s*\(\s*MONTH",
    "DATE_TRUNC": r"date_trunc\s*\(",
    "INTERVAL": r"INTERVAL\s+['\"]",
    "BETWEEN_DATES": r"BETWEEN\s+.*\s+AND\s+",
    "NULLIF": r"NULLIF\s*\(",
    "COALESCE": r"COALESCE\s*\(",
    "ROUND": r"ROUND\s*\(",
    "CAST_INT": r"::int\b",
    "CAST_NUMERIC": r"::numeric\b",
    "GROUP_BY": r"GROUP\s+BY",
    "HAVING": r"HAVING\s+",
    "OFFSET": r"OFFSET\s+\d+",
    "LIMIT": r"LIMIT\s+\d+",
    "ORDER_BY": r"ORDER\s+BY",
    "CURRENT_DATE": r"CURRENT_DATE",
    "NOW": r"NOW\s*\(",
}

def load_questions():
    data = json.loads(QS_FILE.read_text(encoding="utf-8"))
    rows = [q for t in data["tables"] for q in t["questions"]
            if q["expected_route"] == "DB_ONLY"]
    return rows

def detect_patterns(sql):
    """Detect SQL patterns in the query."""
    detected = []
    for name, pattern in PATTERNS.items():
        if re.search(pattern, sql, re.IGNORECASE):
            detected.append(name)
    return detected

def extract_tables(sql):
    """Extract table names from FROM/JOIN clauses."""
    tables = set()
    # FROM table
    for m in re.finditer(r"\bFROM\s+([a-z_][a-z0-9_]*)", sql, re.IGNORECASE):
        tables.add(m.group(1).lower())
    # JOIN table
    for m in re.finditer(r"\bJOIN\s+([a-z_][a-z0-9_]*)", sql, re.IGNORECASE):
        tables.add(m.group(1).lower())
    return tables

def execute_gold_sql(conn, gold_sql):
    """Execute gold SQL with TEST_UID and return results."""
    # Replace gold UID with test UID - use regex to handle both quoted and unquoted
    sql = re.sub(r"'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'", "%(uid)s", gold_sql, flags=re.IGNORECASE)
    sql = re.sub(r'"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"', "%(uid)s", sql, flags=re.IGNORECASE)
    # Also handle bare UUID (unlikely but safe)
    sql = sql.replace(TEST_UID, "%(uid)s")

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SET LOCAL statement_timeout = '10s';")
            cur.execute(sql, {"uid": TEST_UID})
            rows = cur.fetchall()
            columns = [desc[0] for desc in cur.description] if cur.description else []
            return {"success": True, "rows": rows, "columns": columns, "row_count": len(rows)}
    except Exception as e:
        return {"success": False, "error": str(e), "rows": [], "columns": [], "row_count": 0}

def main():
    questions = load_questions()
    print(f"Loaded {len(questions)} DB_ONLY questions")

    conn = psycopg2.connect(HRM_DB_URL)
    conn.autocommit = True

    results = []
    pattern_counts = defaultdict(int)
    table_counts = defaultdict(int)
    error_count = 0

    for i, q in enumerate(questions):
        q_id = q["id"]
        question = q["question"]
        gold_sql = q.get("expected_sql_query", "")
        check_type = q["check_type"]

        if not gold_sql:
            results.append({
                "id": q_id,
                "question": question,
                "check_type": check_type,
                "gold_sql": "",
                "success": False,
                "error": "No gold SQL",
                "patterns": [],
                "tables": []
            })
            continue

        # Detect patterns
        patterns = detect_patterns(gold_sql)
        for p in patterns:
            pattern_counts[p] += 1

        # Extract tables
        tables = extract_tables(gold_sql)
        for t in tables:
            table_counts[t] += 1

        # Execute
        result = execute_gold_sql(conn, gold_sql)

        if not result["success"]:
            error_count += 1

        results.append({
            "id": q_id,
            "question": question,
            "check_type": check_type,
            "gold_sql": gold_sql[:200] + "..." if len(gold_sql) > 200 else gold_sql,
            "success": result["success"],
            "error": result.get("error"),
            "row_count": result["row_count"],
            "columns": result["columns"],
            "patterns": patterns,
            "tables": list(tables)
        })

        if (i + 1) % 20 == 0:
            print(f"  Processed {i + 1}/{len(questions)}")

    conn.close()

    # Summary
    print("\n" + "="*60)
    print("AUDIT SUMMARY")
    print("="*60)
    print(f"Total questions: {len(questions)}")
    print(f"Successful executions: {sum(1 for r in results if r['success'])}")
    print(f"Failed executions: {error_count}")

    print("\n--- Pattern Usage (how many gold SQLs use each) ---")
    for pattern, count in sorted(pattern_counts.items(), key=lambda x: -x[1]):
        print(f"  {pattern}: {count}")

    print("\n--- Table Usage ---")
    for table, count in sorted(table_counts.items(), key=lambda x: -x[1]):
        print(f"  {table}: {count}")

    print("\n--- Failed Queries ---")
    for r in results:
        if not r["success"]:
            print(f"  {r['id']}: {r['error'][:100]}")

    # Check type breakdown
    print("\n--- By Check Type ---")
    by_type = defaultdict(lambda: {"total": 0, "success": 0})
    for r in results:
        ct = r["check_type"]
        by_type[ct]["total"] += 1
        if r["success"]:
            by_type[ct]["success"] += 1

    for ct, stats in sorted(by_type.items()):
        print(f"  {ct}: {stats['success']}/{stats['total']} success")

    # Save detailed results
    output_file = Path(__file__).resolve().parent / "results" / "gold_sql_audit.json"
    output_file.parent.mkdir(exist_ok=True)
    output_file.write_text(json.dumps({
        "summary": {
            "total": len(questions),
            "success": sum(1 for r in results if r["success"]),
            "failed": error_count,
            "pattern_counts": dict(pattern_counts),
            "table_counts": dict(table_counts),
        },
        "results": results
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n-> Detailed results saved to: {output_file}")

if __name__ == "__main__":
    main()