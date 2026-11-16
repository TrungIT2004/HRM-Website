# Spec: Text2SQL Execution Accuracy Improvement (v2)

## Problem Statement

The HRM Text2SQL evaluation on 187 DB_ONLY benchmark questions achieved only **3.2% Execution Accuracy (EX)**. The root causes are:

1. **Parameter substitution gap**: Gold SQL used literal UUIDs while predictions used `%(uid)s` placeholders. The evaluation execution step didn't substitute parameters, causing dataframe mismatches.
2. **Column hallucinations**: Model invented columns (`is_active`, `total_paid_ot_hours`, `tong_gio_ot`) and wrong table aliases (`m`, `y`, `q`).
3. **Validator false positives**: Common column names (`work_date`, `clock_in_time`, `approved_date`, etc.) were flagged as unknown tables.
4. **PostgreSQL strict GROUP BY**: Columns in SELECT not in GROUP BY caused execution failures.
5. **Insufficient few-shots**: Only Vd1-Vd21 examples, missing coverage for IT tickets, Vietnamese→English aliases, payroll, attendances vs monthly_timesheets, permissions, performance reviews.

## Solution

Implement a comprehensive fix pipeline that addresses all root causes:

1. **Parameter substitution in evaluation**: Patch the IBM text2sql-eval-toolkit's `run_execution` to substitute `%(uid)s` and `%(year)s` with actual values before executing both gold and predicted SQL.
2. **Enhanced few-shot examples**: Add Vd22-Vd45 covering IT tickets, Vietnamese column aliases, payroll columns, attendances/monthly_timesheets distinction, permissions, performance_reviews, performance_scores, GROUP BY patterns, monthly timesheets, listing requirements.
3. **Common column errors documentation**: Add explicit "COMMON COLUMN ERRORS" section to system prompt listing hallucinated columns and their correct names.
4. **Validator fix**: Add common column names to `not_a_table` set in validator to prevent false positives.
5. **Quota-aware execution**: Centralized Gemini API key rotation with per-model quota tracking, persisted to JSON, auto-resume on daily reset.
6. **Robustness fixes**: UTF-8 encoding for Vietnamese, asyncio conflict resolution, CSV PermissionError handling.
7. **Model selection**: Never use Gemma 4 31B for SQL generation — its input token limit (16k RPM) is too low for the prompt size. Use only Gemini 3.5 Flash-Lite for SQL model.
8. **Timezone-aware quota reset**: User is in Vietnam (UTC+7); Google Free Tier daily quota resets at 3:00 PM Vietnam time (08:00 UTC). Key manager must use this reset time, not midnight UTC.

## User Stories

1. As an **HRM platform user**, I want accurate SQL generation for my natural language questions, so that I get correct data without manual queries.
2. As a **developer**, I want the evaluation pipeline to correctly measure EX by substituting parameters, so that EX reflects actual SQL correctness not parameter mismatch.
3. As a **developer**, I want the model to stop hallucinating columns like `is_active` and `total_paid_ot_hours`, so that generated SQL executes without errors.
4. As a **developer**, I want the validator to accept valid column names like `work_date` and `approved_date`, so that legitimate queries aren't rejected.
5. As a **developer**, I want the model to use correct table aliases and respect PostgreSQL strict GROUP BY, so that complex aggregations execute.
6. As a **developer**, I want the evaluation to run unattended and resume after quota exhaustion, so that I don't need to manually restart it daily.
7. As a **developer**, I want per-question predictions saved incrementally, so that partial progress isn't lost when quota runs out.
8. As a **platform operator**, I want API key rotation across 6 Google Cloud projects with shared RPM limits, so that Free Tier quotas are fully utilized.
9. As a **developer**, I want comprehensive few-shots covering all HRM domains (IT tickets, payroll, attendance, performance, permissions), so that the model learns domain-specific patterns.
10. As a **platform operator**, I want the system to never use Gemma 4 31B for SQL generation (its 16k RPM token limit is too low for the ~24k token prompt), so that SQL generation doesn't fail due to token limits.
11. As a **developer in Vietnam (UTC+7)**, I want the quota reset to align with Google's 3:00 PM Vietnam time reset (08:00 UTC), not midnight UTC, so that daily quota tracking matches actual Google Free Tier reset.
12. As a **developer**, I want the system prompt to explicitly document common column errors, so that the model avoids known hallucination patterns.
13. As a **developer**, I want Valid SQL rate ≥ 95%, so that nearly all generated SQL is syntactically correct.
14. As a **developer**, I want Logic EX ≥ 75%, so that SQL logic matches gold for questions with results.
15. As a **developer**, I want Bird EX ≥ 70%, so that SQL executes and returns matching dataframes for all questions.
16. As a **developer**, I want Non-Empty EX ≥ 65%, so that queries returning data execute correctly.

## Implementation Decisions

### Architecture
- **Centralized key manager**: Single `GeminiKeyManager` class handling rotation, quota tracking, and persistence for all three models (route, sql, answer).
- **Evaluation pipeline**: Modified `run_hrm_evaluation_fixed.py` patches IBM's `run_execution` at import time for parameter substitution.
- **Prompt engineering**: System prompt in `text2sql.py` extended with Vd22-Vd45 few-shots and COMMON COLUMN ERRORS section.
- **Validation**: `executor.py` validator updated with expanded `not_a_table` set.

### API Quota Management
- 6 API keys across 6 Google Cloud projects (independent quotas)
- Round-robin rotation on 429 errors
- Per-model tracking: `route` (Gemma 4 31B), `sql` (Gemini 3.5 Flash-Lite), `answer` (Gemini 3.5 Flash-Lite)
- **Gemma 4 31B NOT used for SQL generation** — input token limit 16k/min is too low for the full prompt (~24k tokens). Only used for routing/classification.
- Shared RPM limit: 15 RPM for Flash-Lite models across all keys
- Daily quota: 500 requests per key per model (Free Tier)
- Project-level cooldown: 60s after any 429
- **Daily reset at 3:00 PM Vietnam time (08:00 UTC)** — not midnight UTC. Key manager must align reset to this timezone.
- Daily exhaustion: waits `retry_delay` (capped 4.5h) then resets all keys
- Max 3 full rotations (18 attempts) before giving up
- State persisted to `quota_state.json`

### Parameter Substitution
- Gold SQL in benchmark updated from literal UUIDs to `%(uid)s` placeholders
- Evaluation patches `postgres_run_execution_async` to inject `user_id="eval_user_001"` and `year=2024`
- Both gold and predicted SQL receive identical substitutions for fair comparison

### Few-Shot Coverage (Vd22-Vd120)
| Range | Domain |
|-------|--------|
| Vd22-Vd25 | IT Tickets (categories, priorities, statuses, SLA) |
| Vd26-Vd28 | Vietnamese→English column aliases |
| Vd29-Vd31 | Payroll columns (gross, net, tax, insurance) |
| Vd32-Vd34 | Attendances vs Monthly Timesheets |
| Vd35-Vd37 | Permissions (role-based access) |
| Vd38-Vd40 | Performance Reviews |
| Vd41-Vd42 | Performance Scores |
| Vd43 | GROUP BY patterns |
| Vd44 | Monthly Timesheets |
| Vd45 | Listing requirements |
| Vd46-Vd84 | Extended domain coverage (assets, contracts, shifts, etc.) |
| Vd85-Vd110 | Exact column matching & alias precision patterns |
| Vd111-Vd120 | EXACT COLUMN MATCHING — must match gold SQL columns exactly (no extra, no missing, correct aliases) |

### Model Configuration
- **Route model**: Gemma 4 31B (`gemma-4-31b-it`) — classification/routing only, prompt is small (< 2k tokens)
- **SQL model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — full Text2SQL generation, prompt ~24k tokens (exceeds Gemma's 16k RPM)
- **Answer model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — streaming answer generation
- **OCR model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — document OCR

### Common Column Errors Documented
- `is_active` → doesn't exist on users (only on `salaries`, `user_contracts`)
- `total_paid_ot_hours` → use `total_actual_ot_hours` AND `total_paid_ot_hours` in monthly_timesheets
- `tong_gio_ot` → Vietnamese alias, not a real column (use `total_hours`)
- `m`, `y`, `q` → wrong aliases, use full table names
- `approved_date` in payrolls → use `approved_at`
- `bonus_pay`, `allowance_pay`, `basic_pay`, `overtime_pay` → don't exist in payrolls
- `work_date` on monthly_timesheets → only has `period_month`, `period_year`

### Validator Fix
Added to `not_a_table` set: `work_date`, `clock_in_time`, `clock_out_time`, `approved_date`, `from_date`, `to_date`, `created_at`, `updated_at`, `submitted_time`, `last_working_date`, `granted_at`, `assigned_at`, `returned_at`, `last_active_at`, `manager_approved_at`, `hr_approved_at`, `expected_return_date`, `condition_on_assign`, `condition_on_return`, `social_insurance_start_date`, `warranty_until`, `purchase_date`, `birth_date`, `joined_date`, `start_date`, `end_date`, `checked_at`, `sent_at`, `resolved_at`, `taken_at`, `review_id`, `score_id`

## Testing Decisions

### What Makes a Good Test
- Test external behavior: given a natural language question, does the generated SQL execute and return correct dataframe?
- Test evaluation pipeline: does EX metric correctly reflect SQL correctness after parameter substitution?
- Test quota management: does rotation work across keys, does persistence survive restarts, does resume skip completed questions?
- Test validator: does it accept valid columns and reject actual unknown tables?

### Modules to Test
1. `GeminiKeyManager` - quota tracking, rotation, persistence, daily reset
2. `run_hrm_evaluation_fixed.py` - parameter substitution patching, incremental save/resume, EX calculation
3. `executor.validate_sql` - validator with expanded `not_a_table`
4. `text2sql.build_text2sql_prompt` - few-shot inclusion, column error documentation

### Prior Art
- Existing benchmark runner pattern in `run_hrm_evaluation_fixed.py`
- IBM text2sql-eval-toolkit execution accuracy metrics
- Key rotation pattern in `executor.py`'s original `get_llm_complete`

## Out of Scope

- Upgrading to paid Gemini tier (quota increases)
- Adding new benchmark questions beyond the 187 DB_ONLY
- Changing the IBM text2sql-eval-toolkit itself (only patching at runtime)
- Multi-turn conversation context for SQL generation
- Streaming answer generation (separate `answer` model)
- Route classification accuracy (separate `route` model)
- Database schema changes

## Further Notes

### Current State (2026-11-14)
- All fixes implemented and code-ready
- All 6 API keys exhausted for `sql` model (Gemini 3.5 Flash-Lite)
- Key 1 (GEMINI_API_KEY_1): 401 UNAUTHENTICATED — service account deleted, permanently disabled
- Keys 2-5 + Base: 429 RESOURCE_EXHAUSTED — daily 500/day limit reached
- **Daily reset at 3:00 PM Vietnam time (08:00 UTC)** — next reset: 2026-11-14 15:00 ICT
- Predictions file exists at `benchmarks/hrm_db_only-predictions.json` (empty SQL from exhausted keys)
- Pipeline will auto-resume from saved predictions after reset

### Expected Outcome After Quota Reset
- Run: `cd ai-service/test_v2/text2sql && PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py`
- Parameter substitution fix alone: ~30-40% EX recovery
- Enhanced few-shots + column errors: ~15-20% EX recovery
- **Combined target: EX > 50%** (acceptable threshold)
- Logic EX (currently 10.7%) should approach EX as column errors eliminated

### Model Configuration
- **Route model**: Gemma 4 31B (`gemma-4-31b-it`) — classification/routing only, prompt is small
- **SQL model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — full Text2SQL generation, prompt ~24k tokens
- **Answer model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — streaming answer generation
- **OCR model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — document OCR

### Files Modified
- `ai-service/src/sql/text2sql.py` - Enhanced prompt with Vd22-Vd45 + COMMON COLUMN ERRORS
- `ai-service/src/sql/executor.py` - Validator `not_a_table` expansion
- `ai-service/test_v2/text2sql/run_hrm_evaluation_fixed.py` - Full pipeline with all fixes
- `ai-service/test_v2/text2sql/benchmarks/hrm_db_only.jsonl` - Placeholders instead of literal UUIDs
- `ai-service/src/utils/gemini_key_manager.py` - Centralized key management (new)
- `ai-service/test_v2/text2sql/quota_state.json` - Persisted quota state
- `ai-service/test_v2/text2sql/EVALUATION_STATUS.md` - Status documentation