import os
import json
import re
from datetime import date, datetime, time
from decimal import Decimal

os.environ['HRM_DATABASE_URL'] = 'postgresql://postgres:[REDACTED]@localhost:5432/hrm'
from src.sql.executor import run_hrm_query, SCOPED_USER_COL, validate_sql, _escape_literal_percents
from src.db.session import get_hrm_connection
from psycopg2.extras import RealDictCursor

with open('tests/db_only_hybrid_questions_with_answers.json', 'r', encoding='utf-8') as f:
    source = json.load(f)

user_id = '35337165-e0d0-4dd1-9c67-cc48180363af'

def default_serializer(obj):
    if isinstance(obj, (date, datetime, time)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f'Object of type {obj.__class__.__name__} not serializable')

def run_query_direct(sql: str, user_id: str):
    """Run query directly without the full validation."""
    try:
        conn = get_hrm_connection()
    except Exception as e:
        raise RuntimeError(f"Không kết nối được DB nghiệp vụ: {e}")
    try:
        conn.autocommit = True
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SET LOCAL statement_timeout = '5s';")
        cur.execute(_escape_literal_percents(sql), {"uid": user_id, "year": date.today().year})
        rows: list[dict] = cur.fetchall()
        rows = [dict(r) for r in rows[:100]]
        return {"columns": list(rows[0].keys()) if rows else [],
                "rows": rows, "row_count": len(rows)}
    except Exception as e:
        raise RuntimeError(f"Lỗi truy vấn dữ liệu cá nhân: {e}")
    finally:
        try:
            conn.close()
        except Exception:
            pass

def fix_sql(sql: str) -> str:
    """Fix SQL to use proper format with %(uid)s placeholder and table prefix."""
    # First, replace literal UUID with %(uid)s placeholder
    sql = re.sub(r"'35337165-e0d0-4dd1-9c67-cc48180363af'", '%(uid)s', sql)

    # For each scoped table, check if it's the main FROM table
    for table, user_col in SCOPED_USER_COL.items():
        # Check if this table is in the FROM clause (main table)
        from_match = re.search(rf'\bFROM\s+{table}\b', sql, re.IGNORECASE)
        if not from_match:
            continue

        # Check if there's an alias
        alias_match = re.search(rf'\bFROM\s+{table}\s+(\w+)', sql, re.IGNORECASE)
        if alias_match:
            alias = alias_match.group(1)
            prefix = alias
        else:
            prefix = table

        # Now fix the WHERE clause for this table's user_col
        # Pattern: WHERE user_col = ... (without table prefix)
        # But NOT: WHERE prefix.user_col = ... (already has prefix)
        # Use word boundary to avoid matching WHERE prefix
        pattern = rf'(WHERE\s+)(?:{re.escape(prefix)}\.)?{re.escape(user_col)}\s*='
        replacement = rf'\1{prefix}.{user_col} ='
        sql = re.sub(pattern, replacement, sql, flags=re.IGNORECASE)

    return sql

results = {}
errors = []
for t in source['tables']:
    for q in t['questions']:
        if q['expected_route'] == 'DB_ONLY' and 'expected_sql_query' in q:
            sql = q['expected_sql_query']
            sql = fix_sql(sql)
            try:
                result = run_query_direct(sql, user_id)
                results[q['id']] = result
            except Exception as e:
                errors.append((q['id'], str(e), sql[:300]))

with open('query_results_fixed4.json', 'w', encoding='utf-8') as f:
    json.dump({'results': results, 'errors': errors}, f, ensure_ascii=False, indent=2, default=default_serializer)

with open('run_summary_fixed4.txt', 'w', encoding='utf-8') as f:
    f.write(f'Success: {len(results)}\n')
    f.write(f'Errors: {len(errors)}\n')
    for e in errors[:20]:
        f.write(f'  {e[0]}: {e[1]}\n')
        f.write(f'    SQL: {e[2]}\n')