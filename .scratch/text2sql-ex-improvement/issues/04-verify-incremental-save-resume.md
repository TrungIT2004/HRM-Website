# 04: Verify Incremental Prediction Save/Resume

**What to build:** The evaluation pipeline saves predictions incrementally to `hrm_db_only-predictions.json` after each question and resumes from the last completed question after quota exhaustion or restart.

**Blocked by:** 01 (needs quota reset to test under real conditions)

**Status:** ready-for-agent

- [ ] Verify `generate_predictions()` in `run_hrm_evaluation_fixed.py:212-217` saves after each question (already implemented)
- [ ] Verify pipeline loads existing predictions file on startup and skips already-processed questions
- [ ] Test under real quota exhaustion: run until 429, wait for reset, re-run → verify no duplicate API calls
- [ ] Test process restart mid-run: kill process, restart → verify resumes from last saved question
- [ ] Verify predictions file grows incrementally (not rewritten entirely each time — acceptable if rewritten, but must be atomic)
- [ ] Verify CSV PermissionError handling works when file is open in Excel (patched `builtins.open` in evaluation step)
- [ ] Test: UTF-8 encoding for Vietnamese characters in questions/SQL