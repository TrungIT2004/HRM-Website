"""Validator regression tests for gold SQL queries.

Runs the gold SQL from benchmark through validate_sql() to catch
regressions (column hallucinations, GROUP BY, etc.).

Chạy: python test_v2/quota/test_validator.py
Output: test_v2/outputs/validator_test_output.txt
"""
import sys
from pathlib import Path

from test_v2.common import setup_test_env, get_output_path

setup_test_env()

from src.sql.executor import validate_sql


def main() -> None:
    OUT = get_output_path("validator_test_output.txt")
    OUT.parent.mkdir(parents=True, exist_ok=True)

    gold_queries = [
        ("user_permission_grants_07",
         "SELECT permission, granted_at FROM user_permission_grants "
         "WHERE user_id = '35337165-e0d0-4dd1-9c67-cc48180363af' "
         "AND EXTRACT(YEAR FROM granted_at) = EXTRACT(YEAR FROM CURRENT_DATE) "
         "ORDER BY granted_at"),
        ("monthly_timesheets_07",
         "SELECT period_month, total_actual_ot_hours, total_paid_ot_hours, "
         "(total_actual_ot_hours - total_paid_ot_hours) AS diff_hours "
         "FROM monthly_timesheets "
         "WHERE user_id = '35337165-e0d0-4dd1-9c67-cc48180363af' "
         "AND period_year = EXTRACT(YEAR FROM CURRENT_DATE)::int "
         "AND period_month = EXTRACT(MONTH FROM CURRENT_DATE)::int"),
        ("asset_requests_03",
         "SELECT status, rejection_reason, reason FROM asset_requests "
         "WHERE requestor_id = '35337165-e0d0-4dd1-9c67-cc48180363af' "
         "AND status = 'rejected' ORDER BY created_at DESC"),
        ("it_tickets_05",
         "SELECT assignee_id, status, description FROM it_tickets "
         "WHERE reporter_id = '35337165-e0d0-4dd1-9c67-cc48180363af' "
         "AND category = 'NETWORK' ORDER BY created_at DESC LIMIT 1"),
        ("performance_reviews_06",
         "SELECT leader_confirmed, status FROM performance_reviews "
         "WHERE user_id = '35337165-e0d0-4dd1-9c67-cc48180363af' "
         "ORDER BY period_year DESC, period_month DESC LIMIT 1"),
    ]

    with open(OUT, 'w', encoding='utf-8') as f:
        for name, sql in gold_queries:
            ok, clean, err = validate_sql(sql)
            f.write(f'{name}: OK={ok}, Error={err}\n')
            f.write(f'  Clean: {clean}\n\n')
            status = "PASS" if ok else "FAIL"
            print(f"  {name}: {status}")
            if not ok:
                print(f"    Error: {err}")

    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()