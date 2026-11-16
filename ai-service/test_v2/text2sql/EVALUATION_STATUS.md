# HRM Text2SQL Evaluation Status Report

## Current Status: **OUT OF QUOTA** - Waiting for daily reset (~21 hours)

### Quota State (as of 2026-11-13)
- All 6 API keys exhausted for `sql` model (Gemini 3.1 Flash-Lite)
- Daily limit: 500 requests per key per day
- Effective daily limit: 3,000 requests (6 keys × 500)
- Used today: ~190 requests across all keys
- **Reset time: ~00:00 UTC (2026-11-14)**

### Evaluation Pipeline: READY WITH ALL FIXES

The following fixes have been implemented and are ready to run:

| Fix | File | Status |
|-----|------|--------|
| Parameter substitution (`%(uid)s`, `%(year)s`) | `run_hrm_evaluation_fixed.py` | ✅ Implemented |
| Enhanced few-shots (Vd22-Vd35) | `ai-service/src/sql/text2sql.py` | ✅ Implemented |
| Common column errors list | `ai-service/src/sql/text2sql.py` | ✅ Implemented |
| Validation false positives (`work_date`, `clock_in_time`, etc.) | `ai-service/src/sql/executor.py` | ✅ Fixed |
| UTF-8 encoding handling | `run_hrm_evaluation_fixed.py` | ✅ Fixed |
| Asyncio conflict (patched_run_execution) | `run_hrm_evaluation_fixed.py` | ✅ Fixed |
| CSV PermissionError handling | `run_hrm_evaluation_fixed.py` | ✅ Fixed |

### Previous Evaluation Results (Pre-fixes)

| Metric | Value |
|--------|-------|
| Execution Accuracy (EX) | **3.2%** |
| Non-Empty EX | 2.1% |
| Subset Non-Empty EX | 9.1% |
| Logic EX | **10.7%** |
| Bird EX | 3.7% |
| Questions evaluated | 186/187 |
| Inference errors | 149 |
| Dataframe errors | 152 |

**Key insight**: Logic EX (10.7%) > EX (3.2%) → Model understands logic but fails on exact columns/tables due to:
1. Parameter substitution not working during execution (now fixed)
2. Column hallucinations (`is_active`, `total_paid_ot_hours`, `tong_gio_ot`)
3. Wrong table aliases (`m`, `y`, `q` instead of proper names)
4. GROUP BY violations (PostgreSQL strict mode)

### Expected Improvement After Fixes

With all fixes in place, we expect:
- **Parameter substitution fix alone**: Should recover ~30-40% EX (from failed executions)
- **Enhanced few-shots + column error list**: Should recover ~15-20% EX
- **Combined target**: **EX > 50%** (acceptable threshold)

### Next Steps

1. **Wait for daily quota reset** (~00:00 UTC, 2026-11-14)
2. **Run full evaluation**:
   ```bash
   cd ai-service/test_v2/text2sql
   PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py
   ```
3. **Monitor progress** - will generate predictions for all 187 questions
4. **If quota exhausted mid-run**: Pipeline saves predictions incrementally; can resume next day

### Files Ready for Next Run
- `run_hrm_evaluation_fixed.py` - Main pipeline with all fixes
- `ai-service/src/sql/text2sql.py` - Enhanced prompt with Vd22-Vd35 few-shots
- `ai-service/src/sql/executor.py` - Fixed validator
- `benchmarks/hrm_db_only.jsonl` - 187 questions with placeholders
- `quota_state.json` - Will auto-reset on daily rollover

### Resume Capability
The pipeline saves predictions to `benchmarks/hrm_db_only-predictions.json` incrementally. If quota runs out mid-evaluation, you can:
1. Wait for reset
2. Re-run the script - it will skip already-processed questions
3. Continue from where it left off