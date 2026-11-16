# Text2SQL Execution Accuracy Improvement — Ticket Breakdown

**Source Spec:** `SPEC_TEXT2SQL_EX_IMPROVEMENT_V2.md`  
**Target:** 187 DB_ONLY benchmark questions — EX from 3.2% → >50%

## Dependency Graph

```
01-timezone-aware-quota-reset ──────────────────┐
02-enforce-gemma-restriction ──────────────────┼──► 03-complete-fewshots-column-errors
05-fix-model-name-discrepancy ─────────────────┘           │
                                                            ▼
                                                   04-verify-incremental-save-resume
                                                            │
                                                            ▼
                                                   06-full-evaluation-run
```

## Ticket Summary

| # | Ticket | Blocked By | Can Start |
|---|--------|------------|-----------|
| 01 | Timezone-Aware Quota Reset (Vietnam UTC+7) | None | ✅ Immediately |
| 02 | Enforce Gemma 4 31B Restriction (Route/Rewrite/Summary ONLY) | None | ✅ Immediately |
| 03 | Complete Few-Shots Vd22-Vd120 & Common Column Errors | 02 | After 02 |
| 04 | Verify Incremental Prediction Save/Resume | 01 | After 01 (needs quota) |
| 05 | Fix Model Name Discrepancy (3.1 → 3.5 Flash-Lite) | None | ✅ Immediately |
| 06 | Run Full Evaluation & Validate Metrics | 01, 02, 03, 04, 05 | After all |

## Key Implementation Notes

### Model Architecture (from spec)
- **Route model**: Gemma 4 31B (`gemma-4-31b-it`) — classification/routing only, prompt < 2k tokens
- **SQL model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — full Text2SQL, prompt ~24k tokens
- **Answer model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — streaming answer generation
- **OCR model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — document OCR

### Critical Fixes Already Implemented (Code-Ready)
1. Parameter substitution in evaluation (patches IBM toolkit's `postgres_run_execution_async`)
2. Validator fix: 68 column names added to `not_a_table` in `executor.py`
3. Centralized `GeminiKeyManager` with rotation, quota tracking, JSON persistence
4. Evaluation pipeline with incremental save/resume, UTF-8, CSV PermissionError handling
5. Benchmark updated: gold SQL uses `%(uid)s` / `%(year)s` placeholders

### Current Blockers (2026-11-14)
- All 6 API keys exhausted for `sql` model (daily 500/day limit reached)
- Key 1: 401 UNAUTHENTICATED (service account deleted)
- Keys 2-5 + Base: 429 RESOURCE_EXHAUSTED
- Next reset: **2026-11-14 15:00 ICT (08:00 UTC)**
- Predictions file exists but empty (exhausted keys produced no SQL)

### Expected Recovery
- Parameter substitution fix alone: ~30-40% EX recovery
- Enhanced few-shots + column errors: ~15-20% EX recovery
- **Combined target: EX > 50%**

## Commands

```bash
# Run evaluation (after quota reset)
cd ai-service/test_v2/text2sql && PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py

# Check quota state
cat ai-service/test_v2/text2sql/quota_state.json

# View evaluation status
cat ai-service/test_v2/text2sql/EVALUATION_STATUS.md
```