# 05: Text2SQL EX Evaluation — Full Benchmark Run

**What to build:**
Execute the complete 187-question Text2SQL benchmark using IBM text2sql-eval-toolkit with EX (execution) and VES metrics. The runner `test_v2/text2sql/run_hrm_evaluation_fixed.py` already has all fixes (key rotation, fallbacks, EX metrics). Run after daily quota reset (3 PM ICT / 08:00 UTC).

**Blocked by:** None (can start after daily quota reset)

**Status:** ready-for-agent

- [ ] Run: `python -m test_v2.text2sql.run_hrm_evaluation_fixed`
- [ ] Output: `test_v2/outputs/hrm_text2sql_eval.json` with per-question breakdown
- [ ] Metrics achieved:
  - EX accuracy ≥ 75%
  - VES ≥ 70%
  - Zero "All keys exhausted" errors (key rotation works)
- [ ] Key rotation stress: 10/10 concurrent test runs pass without quota failure