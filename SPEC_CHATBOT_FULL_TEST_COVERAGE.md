# Spec: HRM Chatbot Full Test Coverage for Production Report

## Problem Statement

The HRM chatbot has 5 routing paths (DB_ONLY/Text2SQL, DOC_ONLY/RAG, HYBRID, DIRECTORY, OUT_OF_SCOPE). While Text2SQL evaluation is well-defined with the IBM text2sql-eval-toolkit, there is **no comprehensive test plan covering all routes end-to-end** for a production-readiness report. The team needs a single spec documenting what to test, how to test it, and acceptance criteria for each route.

## Solution

Create a unified test specification covering all 5 chatbot routes with:
- Existing test infrastructure mapped to each route
- Missing test gaps identified (especially HYBRID end-to-end)
- Acceptance criteria per route
- Execution commands and expected outputs
- Report structure for production gate review

## User Stories

1. As a **platform engineer**, I want a complete test matrix for all 5 chatbot routes, so that I can demonstrate production readiness in my report.
2. As a **platform engineer**, I want to run all tests with a single command per route, so that CI/CD can execute them reliably.
3. As a **platform engineer**, I want acceptance criteria defined per route, so that "done" is unambiguous.
4. As a **platform engineer**, I want the HYBRID route tested end-to-end (Text2SQL + RAG combined), so that cross-domain questions are validated.
5. As a **platform engineer**, I want DOC_ONLY generation quality measured with a reliable judge, so that RAG answer quality is quantified.
6. As a **platform engineer**, I want routing accuracy measured for both keyword and LLM routers, so that misroutes are caught.
6. As a **platform engineer**, I want quota resilience tested (key rotation, daily reset, persistence), so that Free Tier limits don't cause silent failures.
7. As a **platform engineer**, I want Vietnamese localization verified (dates, statuses, numbers), so that UX is correct for Vietnam users.
8. As a **platform engineer**, I want error handling paths tested (guard rejections, DB failures, LLM timeouts), so that production incidents are minimized.

## Implementation Decisions

### Test Architecture

**Five independent test suites**, one per route, plus cross-cutting suites:

| Route | Primary Test File | Secondary Test Files | Metrics |
|-------|-------------------|---------------------|---------|
| DB_ONLY | `run_hrm_evaluation_fixed.py` | `eval_db_retrieval.py`, `eval_db_generation.py`, `eval_db_answer.py` | EX, Valid SQL, Logic EX, Bird EX, Non-Empty EX, sql_ok, rows_match, fact_recall, answer_ok |
| DOC_ONLY | `eval_retrieval.py` | `eval_ragas_full.py` | Hit@5, MRR@5, Top1, Fallback; RAGAS: faithfulness, answer_relevancy, context_precision, context_recall |
| HYBRID | **NEW: `eval_hybrid.py`** | Uses DB_ONLY + DOC_ONLY datasets | Route accuracy, combined answer quality, SQL+retrieval correctness |
| DIRECTORY | `test_directory.py`, `test_router_accuracy.py` | — | Route accuracy, card rendering, disambiguation |
| OUT_OF_SCOPE | `test_router_accuracy.py` | — | Route accuracy, rejection consistency |

**Cross-cutting:**
- Routing: `test_router_accuracy.py` (keyword), `test_llm_router_full.py` (LLM/Gemma)
- Quota resilience: `test_key_rotation.py` (expand)
- Localization: embedded in answer quality checks
- Error handling: code review of `chat_service.py` + manual fault injection

### API Quota Management (from SPEC_TEXT2SQL_EX_IMPROVEMENT_V2)

- 6 API keys across 6 Google Cloud projects (independent quotas)
- Round-robin rotation on 429 errors
- Per-model tracking: `route` (Gemma 4 31B), `sql` (Gemini 3.5 Flash-Lite), `answer` (Gemini 3.5 Flash-Lite)
- **Gemma 4 31B NOT used for SQL generation** — input token limit 16k/min too low for ~24k token prompt
- Shared RPM limit: 15 RPM for Flash-Lite models across all keys
- Daily quota: 500 requests per key per model (Free Tier)
- Project-level cooldown: 60s after any 429
- **Daily reset at 3:00 PM Vietnam time (08:00 UTC)** — key manager aligns to this
- Daily exhaustion: waits `retry_delay` (capped 4.5h) then resets all keys
- Max 3 full rotations (18 attempts) before giving up
- State persisted to `quota_state.json`

### Benchmark Data

| Dataset | Questions | Source |
|---------|-----------|--------|
| DB_ONLY | 187 | `benchmarks/hrm_db_only.jsonl` |
| DOC_ONLY | 146 | `tests/retrieval_doc_only/eval_retrieval.py --n 146` |
| HYBRID | 34 | `tests/db_only_hybrid_questions.json` (filter `expected_route: "HYBRID"`) |
| DIRECTORY | 30+ | `tests/routing/test_directory.py` |
| OUT_OF_SCOPE | 20+ | `tests/routing/test_router_accuracy.py` |

### Model Configuration

- **Route model**: Gemma 4 31B (`gemma-4-31b-it`) — classification only, prompt < 2k tokens
- **SQL model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — full Text2SQL, prompt ~24k tokens
- **Answer model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — streaming answer generation
- **OCR model**: Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — document OCR

## Testing Decisions

### What Makes a Good Test

- **External behavior only**: Given natural language input, does the route produce correct output?
- **No implementation detail coupling**: Tests survive refactoring of internal functions
- **Deterministic where possible**: Retrieval uses `--reuse` to avoid re-ingestion variance
- **Quota-aware**: All LLM tests respect rate limits, save incrementally, resume on reset
- **Vietnamese-first**: Date format DD/MM/YYYY, status translation, number formatting validated

### Modules to Test

1. **DB_ONLY (Text2SQL)**
   - `GeminiKeyManager` — quota tracking, rotation, persistence, daily reset (3 PM ICT)
   - `run_hrm_evaluation_fixed.py` — parameter substitution, incremental save/resume, EX calculation
   - `executor.validate_sql` — validator with expanded `not_a_table` (50+ columns)
   - `text2sql.build_text2sql_prompt` — few-shots Vd22-Vd120 + COMMON COLUMN ERRORS

2. **DOC_ONLY (RAG)**
   - `HybridRetriever.retrieve` — Hit@5, MRR, fallback rate
   - `ChatService.answer_query` — end-to-end answer generation
   - RAGAS judge — **decide: switch from gpt-oss to Gemini/Claude, or use deterministic fact-checking**

3. **HYBRID (NEW)**
   - Route classification accuracy for HYBRID questions
   - Combined SQL + retrieval correctness
   - Answer quality when both personal data and policy needed

4. **Routing Layer**
   - Keyword fallback router (`test_router_accuracy.py`) — target ≥ 90% overall
   - LLM router (`test_llm_router_full.py`) — target ≥ 95% overall
   - OUT_OF_SCOPE rejection consistency

5. **DIRECTORY**
   - Public employee lookup (no LLM)
   - Card rendering, disambiguation on name collisions

6. **System Reliability**
   - `test_key_rotation.py` — expand for quota resilience (simulate 429, daily reset, persistence)
   - `chat_service.py` error paths — guard, DB failure, LLM timeout, streaming parity

7. **Localization (VN)**
   - Date: DD/MM/YYYY in all answers
   - Status: PENDING → "đang chờ duyệt", APPROVED → "đã duyệt", etc.
   - Numbers: 15.000.000 VND format (dot separators)

### Prior Art

- IBM text2sql-eval-toolkit execution accuracy (EX, Valid SQL, Logic EX, Bird EX, Non-Empty EX)
- Existing retrieval eval pattern: `eval_retrieval.py`, `eval_db_retrieval.py`
- Existing generation eval pattern: `eval_db_answer.py`, `eval_ragas_full.py`
- Router accuracy pattern: `test_router_accuracy.py`, `test_llm_router_full.py`
- Key rotation pattern: `gemini_key_manager.py`, `test_key_rotation.py`

## Out of Scope

- Upgrading to paid Gemini tier (quota increases)
- Adding new benchmark questions beyond existing datasets
- Changing the IBM text2sql-eval-toolkit itself (only runtime patching)
- Multi-turn conversation context for SQL generation (separate memory test)
- Database schema changes
- Frontend/UI testing (separate web test suite)

## Further Notes

### Current State (2026-11-14)

| Component | Status |
|-----------|--------|
| DB_ONLY Text2SQL | All fixes implemented; waiting for quota reset (3 PM ICT today) |
| DB_ONLY Retrieval/Generation/Answer | Test files ready; need to run with full 187 questions |
| DOC_ONLY Retrieval | **PASS**: Hit@5=100%, MRR=0.9825, Fallback=0% |
| DOC_ONLY Generation | RAGAS judge unreliable (gpt-oss); needs judge swap or deterministic checker |
| HYBRID | **GAP**: No end-to-end test file exists |
| Routing (Keyword) | PASS: 90% overall, DB_ONLY 92.8%, HYBRID 78.6% |
| Routing (LLM/Gemma) | PASS: 96% overall, DB 94.7%, DOC 98.3%, HYB 91.2% |
| DIRECTORY | PASS: 30+ checks |
| OUT_OF_SCOPE | PASS: consistent rejection |
| Quota Management | Centralized manager implemented; Key 1 permanently disabled (401); Keys 2-6 rotate |
| Localization | Implemented in `chat_service.py`; needs verification in answer quality tests |

### Execution Order (Post Quota Reset)

```bash
# 1. Full IBM Text2SQL evaluation (all 5 EX metrics)
cd ai-service/test_v2/text2sql
PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py

# 2. DB_ONLY retrieval/generation/answer (3 scripts)
cd ai-service
python tests/retrieval_db_only/eval_db_retrieval.py --n 187
python tests/retrieval_db_only/eval_db_generation.py --n 187
python tests/retrieval_db_only/eval_db_answer.py --n 187

# 3. Router tests
python tests/routing/test_router_accuracy.py
python tests/routing/test_llm_router_full.py

# 4. DOC_ONLY retrieval (already PASS, re-run for report)
python tests/retrieval_doc_only/eval_retrieval.py --n 146 --reuse

# 5. DOC_ONLY generation — DECIDE ON JUDGE FIRST
# Option A: python tests/generation/doc_only/eval_ragas_full.py --n 80 --review review_30_manual.json
# Option B: Build deterministic fact-checker (like eval_db_answer.py)

# 6. DIRECTORY
python tests/routing/test_directory.py

# 7. HYBRID — CREATE eval_hybrid.py first
# (new file needed, ~30 questions from db_only_hybrid_questions.json)

# 8. Quota resilience
# Expand test_key_rotation.py with fault injection

# 9. Compile report
```

### HYBRID Evaluation Design (New File Needed)

```python
# ai-service/tests/hybrid/eval_hybrid.py
# Questions: Filter db_only_hybrid_questions.json for expected_route == "HYBRID" (34 questions)
# Steps per question:
#   1. Route classification → assert HYBRID
#   2. Execute SQL → get personal data rows
#   3. Retrieve policy chunks → get relevant docs
#   4. Generate combined answer (ChatService.answer_query)
#   5. Verify: SQL correct (rows_match), retrieval correct (Hit@5), answer factually consistent
# Metrics: route_acc, sql_ok, retrieval_hit_at_5, answer_ok, combined_latency
```

### DOC_ONLY Generation Judge Decision

**Current**: RAGAS with gpt-oss judge → high false negatives on Vietnamese OCR content
**Options**:
1. **Switch judge to Gemini 3.5 Flash-Lite** (same model as answer, but separate calls) — uses quota
2. **Switch judge to Claude** (via API) — best quality, costs money
3. **Deterministic fact-checker** (like `eval_db_answer.py`): extract claims from answer, verify against retrieved chunks — no LLM judge needed
4. **Human review** of 30 sampled questions (`review_30_manual.json`) — most reliable, manual effort

**Recommendation**: Option 3 (deterministic) for CI, Option 4 for report appendix

### Acceptance Criteria for Production Gate

| Route | Metric | Target |
|-------|--------|--------|
| DB_ONLY | Execution Accuracy (EX) | > 50% |
| DB_ONLY | Valid SQL (SQLGlot) | ≥ 95% |
| DB_ONLY | Logic EX | ≥ 75% |
| DB_ONLY | Bird EX | ≥ 70% |
| DB_ONLY | Non-Empty EX | ≥ 65% |
| DB_ONLY | Answer fact_recall | ≥ 75% |
| DB_ONLY | Answer answer_ok | ≥ 65% |
| DOC_ONLY | Retrieval Hit@5 | = 100% |
| DOC_ONLY | Retrieval MRR@5 | ≥ 0.95 |
| DOC_ONLY | Retrieval Fallback | = 0% |
| DOC_ONLY | Generation faithfulness | ≥ 0.80 (with reliable judge) |
| DOC_ONLY | Generation answer_relevancy | ≥ 0.80 |
| HYBRID | Route accuracy | ≥ 90% |
| HYBRID | Combined answer_ok | ≥ 60% |
| Routing (LLM) | Overall accuracy | ≥ 95% |
| Routing (Keyword) | Overall accuracy | ≥ 90% |
| DIRECTORY | Route accuracy | = 100% |
| OUT_OF_SCOPE | Rejection consistency | = 100% |
| System | Quota rotation works | 6 keys, 3 rotations max |
| System | Daily reset at 3 PM ICT | Verified |
| Localization | Date format | DD/MM/YYYY |
| Localization | Status translation | All mapped |
| Localization | Number format | Dot separators |

### Files to Reference

- `SPEC_TEXT2SQL_EX_IMPROVEMENT_V2.md` — Detailed Text2SQL fixes (source of truth for DB_ONLY)
- `ai-service/test_v2/text2sql/EVALUATION_STATUS.md` — Current quota status
- `ai-service/tests/retrieval_doc_only/RETRIEVAL_DOC_ONLY_RESULTS.md` — DOC_ONLY retrieval results
- `ai-service/tests/routing/LLM_ROUTING_TEST_RESULTS.md` — LLM router results
- `ai-service/tests/db_only_hybrid_questions.json` — HYBRID questions (34)
- `ai-service/test_v2/text2sql/benchmarks/hrm_db_only.jsonl` — DB_ONLY benchmark (187)
- `ai-service/src/chat/chat_service.py` — Main pipeline (5 routes, streaming, caching, memory, guard)
- `ai-service/src/utils/gemini_key_manager.py` — Centralized quota management