import os
import json
import re
from datetime import date, datetime, time
from decimal import Decimal

os.environ['HRM_DATABASE_URL'] = 'postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm'
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
    """Run query directly without the full validation (use after manual fix)."""
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

    # For tables with aliases (like "users u"), find the alias and use it
    # Pattern: FROM users u ... WHERE u.user_id = ...
    # Pattern: FROM users ... WHERE user_id = ... (no alias)

    # Let's be more surgical: only fix the WHERE clause for the main scoped table
    # Find which scoped table is the main one being queried
    main_table = None
    for table in SCOPED_USER_COL:
        # Check if table appears in FROM clause (not in JOIN)
        if re.search(rf'\bFROM\s+{table}\b', sql, re.IGNORECASE):
            main_table = table
            break
        # Check for FROM table alias
        if re.search(rf'\bFROM\s+{table}\s+\w+', sql, re.IGNORECASE):
            main_table = table
            break

    if main_table:
        user_col = SCOPED_USER_COL[main_table]
        # Check if there's an alias
        alias_match = re.search(rf'\bFROM\s+{main_table}\s+(\w+)', sql, re.IGNORECASE)
        if alias_match:
            alias = alias_match.group(1)
            # Replace alias.user_col = %(uid)s or user_col = %(uid)s with alias.user_col = %(uid)s
            pattern = rf'\b{alias}\.{user_col}\s*=\s*%\s*\(\s*uid\s*\)\s*s'
            if not re.search(pattern, sql, re.IGNORECASE):
                # Try to find bare user_col = %(uid)s and prefix with alias
                pattern2 = rf'\b{user_col}\s*=\s*%\s*\(\s*uid\s*\)\s*s'
                sql = re.sub(pattern2, f'{alias}.{user_col} = %(uid)s', sql, flags=re.IGNORECASE)
        else:
            # No alias, use table name
            pattern = rf'\b{main_table}\.{user_col}\s*=\s*%\s*\(\s*uid\s*\)\s*s'
            if not re.search(pattern, sql, re.IGNORECASE):
                pattern2 = rf'\b{user_col}\s*=\s*%\s*\(\s*uid\s*\)\s*s'
                sql = re.sub(pattern2, f'{main_table}.{user_col} = %(uid)s', sql, flags=re.IGNORECASE)

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

with open('query_results_fixed3.json', 'w', encoding='utf-8') as f:
    json.dump({'results': results, 'errors': errors}, f, ensure_ascii=False, indent=2, default=default_serializer)

with open('run_summary_fixed3.txt', 'w', encoding='utf-8') as f:
    f.write(f'Success: {len(results)}\n')
    f.write(f'Errors: {len(errors)}\n')
    for e in errors[:20]:
        f.write(f'  {e[0]}: {e[1]}\n')
        f.write(f'    SQL: {e[2]}\n')