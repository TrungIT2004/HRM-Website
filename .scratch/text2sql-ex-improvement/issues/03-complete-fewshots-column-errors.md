# 03: Complete Few-Shots (Vd22-Vd120) & Common Column Errors

**What to build:** Full few-shot coverage in `text2sql.py` system prompt covering all HRM domains per spec table, plus explicit "COMMON COLUMN ERRORS" section documenting all 11 hallucinated column patterns.

**Blocked by:** 02 (correct SQL model must be in place first)

**Status:** ready-for-agent

- [ ] Verify `text2sql.py` contains all 99 few-shots (Vd22 through Vd120):
  - Vd22-Vd25: IT Tickets (categories, priorities, statuses, SLA)
  - Vd26-Vd28: Vietnamese→English column aliases
  - Vd29-Vd31: Payroll columns (gross, net, tax, insurance)
  - Vd32-Vd34: Attendances vs Monthly Timesheets distinction
  - Vd35-Vd37: Permissions (role-based access)
  - Vd38-Vd40: Performance Reviews
  - Vd41-Vd42: Performance Scores
  - Vd43: GROUP BY patterns (PostgreSQL strict mode)
  - Vd44: Monthly Timesheets
  - Vd45: Listing requirements
  - Vd46-Vd84: Extended domain coverage (assets, contracts, shifts, etc.)
  - Vd85-Vd110: Exact column matching & alias precision patterns
  - Vd111-Vd120: EXACT COLUMN MATCHING — must match gold SQL columns exactly
- [ ] Verify COMMON COLUMN ERRORS section (Vd32) documents all 11 items:
  1. `is_active` → doesn't exist on users (only on `salaries`, `user_contracts`)
  2. `total_paid_ot_hours` → use `total_actual_ot_hours` AND `total_paid_ot_hours` in monthly_timesheets
  3. `tong_gio_ot` → Vietnamese alias, not a real column (use `total_hours`)
  4. `m`, `y`, `q` → wrong aliases, use full table names
  5. `approved_date` in payrolls → use `approved_at`
  6. `bonus_pay`, `allowance_pay`, `basic_pay`, `overtime_pay` → don't exist in payrolls
  7. `work_date` on monthly_timesheets → only has `period_month`, `period_year`
- [ ] Verify `build_text2sql_prompt()` includes all few-shots and column errors in system prompt
- [ ] Test: generate SQL for known hallucination triggers → verify correct columns used