# 06: Run Full Evaluation & Validate Metrics

**What to build:** Complete 187-question evaluation run achieving target metrics after all infrastructure fixes are in place.

**Blocked by:** 01, 02, 03, 04, 05 (all infrastructure must work)

**Status:** ready-for-agent

- [ ] Wait for daily quota reset at 08:00 UTC (3:00 PM Vietnam time)
- [ ] Run: `cd ai-service/test_v2/text2sql && PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py`
- [ ] Verify pipeline completes all 187 questions without manual intervention
- [ ] Verify parameter substitution works: no `%(uid)s` or `%(year)s` placeholders in executed SQL
- [ ] Verify metrics meet or exceed targets:
  - Valid SQL (SQLGlot) ≥ 95%
  - Logic EX ≥ 75%
  - Bird EX ≥ 70%
  - Non-Empty EX ≥ 65%
- [ ] Document results in `EVALUATION_STATUS.md` with timestamp and metrics
- [ ] If targets not met: analyze failure modes, iterate on few-shots/column errors