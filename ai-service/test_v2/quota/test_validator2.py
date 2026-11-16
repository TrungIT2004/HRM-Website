"""Validator regression tests for model-generated SQL (with placeholders).

Tests the SQL patterns that the model should generate, using %(uid)s and %(year)s
placeholders instead of literal UUIDs.

Chạy: python test_v2/quota/test_validator2.py
Output: test_v2/outputs/validator_test_output2.txt
"""
import sys
from pathlib import Path

from test_v2.common import setup_test_env, get_output_path

setup_test_env()

from src.sql.executor import validate_sql


def main() -> None:
    OUT = get_output_path("validator_test_output2.txt")
    OUT.parent.mkdir(parents=True, exist_ok=True)

    test_cases = [
        ("user_permission_grants_07 model SQL",
         "SELECT permission, granted_at FROM user_permission_grants "
         "WHERE user_id = %(uid)s AND EXTRACT(YEAR FROM granted_at) = %(year)s "
         "ORDER BY granted_at"),
        ("wrong user_col (requestor_id) - should FAIL",
         "SELECT permission, granted_at FROM user_permission_grants "
         "WHERE requestor_id = %(uid)s AND EXTRACT(YEAR FROM granted_at) = %(year)s "
         "ORDER BY granted_at"),
        ("monthly_timesheets_07 model SQL",
         "SELECT period_month, total_actual_ot_hours, total_paid_ot_hours, "
         "(total_actual_ot_hours - total_paid_ot_hours) AS diff_hours "
         "FROM monthly_timesheets "
         "WHERE user_id = %(uid)s AND period_year = %(year)s "
         "AND period_month = EXTRACT(MONTH FROM CURRENT_DATE)::int"),
        ("asset_requests_03 model SQL",
         "SELECT status, rejection_reason, reason FROM asset_requests "
         "WHERE requestor_id = %(uid)s AND status = 'rejected' "
         "ORDER BY created_at DESC"),
        ("it_tickets_05 model SQL",
         "SELECT assignee_id, status, description FROM it_tickets "
         "WHERE reporter_id = %(uid)s AND category = 'NETWORK' "
         "ORDER BY created_at DESC LIMIT 1"),
        ("performance_reviews_06 model SQL",
         "SELECT leader_confirmed, status FROM performance_reviews "
         "WHERE user_id = %(uid)s "
         "ORDER BY period_year DESC, period_month DESC LIMIT 1"),
        ("EXTRACT with granted_at",
         "SELECT permission FROM user_permission_grants "
         "WHERE user_id = %(uid)s AND EXTRACT(YEAR FROM granted_at) = %(year)s"),
        ("with alias upg",
         "SELECT upg.permission, upg.granted_at FROM user_permission_grants upg "
         "WHERE upg.user_id = %(uid)s AND EXTRACT(YEAR FROM upg.granted_at) = %(year)s "
         "ORDER BY upg.granted_at"),
    ]

    with open(OUT, 'w', encoding='utf-8') as f:
        for name, sql in test_cases:
            ok, clean, err = validate_sql(sql)
            f.write(f'{name}:\n')
            f.write(f'  OK: {ok}, Error: {err}\n')
            f.write(f'  Clean: {clean}\n\n')
            status = "PASS" if ok else "FAIL"
            expected_fail = "should FAIL" in name
            actual_fail = not ok
            if expected_fail == actual_fail:
                print(f"  {name}: {status} ✓")
            else:
                print(f"  {name}: {status} ✗ (unexpected)")

    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()