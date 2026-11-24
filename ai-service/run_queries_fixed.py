import os
import json
import re
from datetime import date, datetime

os.environ['HRM_DATABASE_URL'] = 'postgresql://postgres:[REDACTED]@localhost:5432/hrm'
from src.sql.executor import run_hrm_query, SCOPED_USER_COL

with open('tests/db_only_hybrid_questions_with_answers.json', 'r', encoding='utf-8') as f:
    source = json.load(f)

user_id = '35337165-e0d0-4dd1-9c67-cc48180363af'

def default_serializer(obj):
    if isinstance(obj, (date, datetime)):
        return obj.isoformat()
    raise TypeError(f'Object of type {obj.__class__.__name__} not serializable')

def fix_sql_user_filter(sql: str) -> str:
    """Fix SQL to use table.column = %(uid)s format for user filtering."""
    # For each scoped table, ensure the user_col has table prefix
    for table, user_col in SCOPED_USER_COL.items():
        # Pattern: user_col = %(uid)s (without table prefix)
        # Replace with: table.user_col = %(uid)s
        pattern = rf'\b{re.escape(user_col)}\s*=\s*%\s*\(\s*uid\s*\)\s*s'
        replacement = f'{table}.{user_col} = %(uid)s'
        sql = re.sub(pattern, replacement, sql, flags=re.IGNORECASE)
    return sql

results = {}
errors = []
for t in source['tables']:
    for q in t['questions']:
        if q['expected_route'] == 'DB_ONLY' and 'expected_sql_query' in q:
            sql = q['expected_sql_query']
            # Fix the SQL
            sql = fix_sql_user_filter(sql)
            try:
                result = run_hrm_query(sql, user_id)
                results[q['id']] = result
            except Exception as e:
                errors.append((q['id'], str(e), sql[:200]))

with open('query_results_fixed.json', 'w', encoding='utf-8') as f:
    json.dump({'results': results, 'errors': errors}, f, ensure_ascii=False, indent=2, default=default_serializer)

with open('run_summary_fixed.txt', 'w', encoding='utf-8') as f:
    f.write(f'Success: {len(results)}\n')
    f.write(f'Errors: {len(errors)}\n')
    for e in errors[:20]:
        f.write(f'  {e[0]}: {e[1]}\n')
        f.write(f'    SQL: {e[2]}\n')