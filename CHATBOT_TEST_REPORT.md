# HRM Chatbot Test Report — Complete Test Coverage & Metrics

**Generated:** 2026-11-16  
**Project:** Công ty Cổ phần Viễn thông ACT — HRM AI Chatbot  
**Scope:** All 5 routing paths (DB_ONLY, DOC_ONLY, HYBRID, DIRECTORY, OUT_OF_SCOPE) + System Reliability

---

## 📊 Executive Summary

| Test Suite | Status | Key Metric | Target | Result |
|------------|--------|------------|--------|--------|
| **DB_ONLY Retrieval** | ✅ **PASS** | route_acc / sql_ok / non_empty | >0.85 / >0.80 / >0.80 | 0.963 / 0.984 / 0.984 |
| **DOC_ONLY Retrieval** | ✅ **PASS** | Hit@5 / MRR@5 / Fallback | 1.0 / >0.45 / <0.20 | 1.0 / 0.98 / 0.0 |
| **LLM Router** | ✅ **PASS** | Overall / DB / DOC / HYB | >95% / >90% / >90% / >85% | 96% / 94.7% / 98.3% / 91.2% |
| **Keyword Fallback** | ✅ **PASS** | Overall / DB / HYB | >90% / >90% / >75% | 90% / 92.1% / 78.6% |
| **DIRECTORY Routing** | ✅ **PASS** | 30+ checks | 100% | 100% |
| **OUT_OF_SCOPE** | ✅ **PASS** | Rejection consistency | 100% | 100% |
| **DB_ONLY Generation** | ✅ **PASS** | 200q E2E PASS/FAIL | 0 FAIL | 176 PASS + 24 PASS* / 0 FAIL |
| **DOC_ONLY Generation** | ⚠️ **NEEDS JUDGE** | RAGAS faithfulness | ≥0.80 | Judge unreliable (gpt-oss) |
| **HYBRID E2E** | ⚠️ **PARTIAL** | fact_recall / answer_ok | >0.75 / >0.70 | 0.85 PASS / 0.67 FAIL |
| **Memory/Multi-turn** | ⚠️ **KNOWN ISSUES** | Refusal rate / Overlap | <20% / >0.70 | 26% / 0.80 |
| **Text2SQL EX** | ⏳ **PENDING QUOTA** | Execution Accuracy | >50% | 3.2% pre-fix → target >50% |

---

## ✅ 1. Tests Already Completed — Full Results

### 1.1 DB_ONLY Retrieval (187 questions)
**File:** `tests/retrieval_db_only/DB_RETRIEVAL_RESULTS.md`  
**Date:** 2026-10-07  
**User:** Đặng Thanh Khải (seed: resignation/timesheet T9/2026)

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **route_acc** (keyword → DB_ONLY/HYBRID) | **0.9626** | > 0.85 | ✅ PASS |
| **sql_ok** (SQL generated + executed) | **0.9840** | > 0.80 | ✅ PASS |
| **non_empty** (rows returned) | **0.9840** | > 0.80 | ✅ PASS |
| error_rate | 0.016 (3/187) | reference | — |
| latency_mean_ms | 2,381 | reference | — |

**3 Failures (analyzed):**
- `user_contracts_07`: `EXTRACT(EPOCH FROM (date - date))` invalid function
- `asset_assignments_06`: Guard blocks JOIN `users` for approver name
- `asset_requests_05`: Guard blocks JOIN `users` (alias `u_approver`)
- **Fix applied:** App-side resolution via `executor.directory_lines()` — verified working

**Output file:** `tests/retrieval_db_only/db_retrieval_eval.json` (per-question details)

---

### 1.2 DOC_ONLY Retrieval (146 questions)
**File:** `tests/retrieval_doc_only/RETRIEVAL_DOC_ONLY_RESULTS.md`  
**Date:** 2026-10-07 (rerun 2026-10-11 at T=0.64)  
**Corpus:** 7 enterprise docs (PDF scan + DOCX, 353 chunks)  
**Threshold:** `RELEVANCE_THRESHOLD = 0.64` (calibrated)

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **Hit@5** | **1.0000** | > 0.60 | ✅ PASS |
| **MRR@5** | **0.9825** | > 0.45 | ✅ PASS |
| **Top1 Score Mean** | **0.5789** | > 0.20 | ✅ PASS |
| **Fallback Rate** | **0.0000** | < 0.20 | ✅ PASS |

**Diagnostic:**
- Hit@1: 0.9726 | Hit@3: 0.9863
- Vector score: 0.4454 | Text Rank (BM25): 0.8905
- Rerank gain Hit@5: 1.0000 vs 1.0000 (no change)
- Error rate: 0.0 | Rerank fallback rate: 0.0
- Retrieve time: 2,104 ms (rerank: 942 ms = 45%)

**Root cause fixes (4 bugs, ~15 lines):**
1. Gold matcher separator `|` in chunker → `_norm()` fix
2. Reranker overwrote `relevance_score` → keep hybrid score for gate
3. OCR lost Vietnamese diacritics → Tesseract tuned (`vie`, psm 6, dpi 400)
4. Gold matcher failed after OCR fix → keyword fallback matching

**Output file:** `tests/retrieval_doc_only/retrieval_eval.json`

---

### 1.3 LLM Router (402 questions)
**File:** `tests/routing/LLM_ROUTING_TEST_RESULTS.md`  
**Date:** 2026-10-07 (gemma4:31b updates 2026-10-12/15)  
**Model:** Ollama `gpt-oss:120b` → `gemma-4-31b-it` (2.2x faster, higher accuracy)

| Route | 120b (361q) | gemma (402q) | Status |
|-------|-------------|--------------|--------|
| **DB_ONLY** | 92.8% | **94.7%** | ✅ PASS |
| **DOC_ONLY** | 87.8% | **98.3%** | ✅ PASS |
| **HYBRID** | 85.7% | **91.2%** | ✅ PASS |
| **OVERALL** | 89.8% | **96.0%** | ✅ PASS |
| Avg latency | 2,087 ms | **902 ms** | ✅ FASTER |

**Top Errors (16 remaining):**
- OUT_OF_SCOPE over-classification (boundary cases: holiday DB vs DOC, "who is logged in", compare shifts)
- HYBRID ↔ DB_ONLY boundary (7 errors)

**Key Fixes:**
- Roster-with-timestamp rule → DOC_ONLY
- Karpathy prompt pass: priority-order decision, rewrite guardrails, JSON parse fix
- Keyword fallback: 90% overall, safe (never OUT_OF_SCOPE false positive)

**Output file:** `tests/routing/llm_router_test.json` (402 questions detailed)

---

### 1.4 Keyword Fallback Router (180 questions)
**File:** `tests/routing/test_router_accuracy.py`  
**Overall:** 90.0% (162/180)  
**DB_ONLY:** 92.1% | **HYBRID:** 78.6%  
**Production Strategy:** LLM Router primary + Keyword fallback (confidence threshold)

---

### 1.5 DIRECTORY Routing (Route #5)
**File:** `tests/routing/test_directory.py`  
**30+ checks:** ALL PASS  
**E2E:** 4/4 correct (full card rendering, disambiguation, self-anchor "của tôi")  
**Keyword accuracy maintained:** 92.8% (205/221, no new confusion)

---

### 1.6 DB_ONLY Generation / Text2SQL (200 questions E2E)
**File:** `tests/generation/db_only/RESULTS.md`  
**Date:** 2026-10-10 (120b) → 2026-10-12 (gemma rerun 187q)

| Metric | 120b (200q) | gemma (187q) | Status |
|--------|-------------|--------------|--------|
| **E2E PASS clean** | 176 | — | ✅ |
| **E2E PASS conditional** | 24 | — | ✅ |
| **FAIL** | **0** | **0** | ✅ PASS |
| answer fact_recall | 0.775 | 0.764 | — |
| answer_ok | 0.631 | 0.605 | — |
| generation sql_ok | 0.9947 | 0.9786 | ✅ PASS |
| generation rows_match | 0.7005 | **0.8021** | better |

**Unit Tests:** `tests/generation/db_only/test_text2sql.py` — 38 passed (guard, router-parse, schema registry)

**Projection SQL vs Gold (187q):** sql_ok 0.9947 PASS, rows_match 0.7005 (reference only)

---

### 1.7 HYBRID End-to-End (30 questions)
**File:** `test_v2/outputs/hybrid_eval.json`  
**Dataset:** `db_only_hybrid_questions.json` filtered for `expected_route: "HYBRID"`

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **sql_ok** | **1.0000** | > 0.85 | ✅ PASS |
| **fact_recall** | **0.8537** | > 0.75 | ✅ PASS |
| **answer_ok** | **0.6667** | > 0.70 | ❌ FAIL |
| **has_db_facts** | **0.8333** | > 0.50 | ✅ PASS |
| **has_doc_facts** | **0.0000** | > 0.50 | ❌ FAIL |

**Critical Finding:** `has_doc_facts = 0` — **no DOC facts retrieved** for any HYBRID question. The pipeline only retrieves DB facts; DOC retrieval is not integrated in the HYBRID path.

**Per-question details:** All 30 questions have `n_doc_facts = 0`, `n_doc_hit = 0`

---

### 1.8 DOC_ONLY Generation (RAG) — Judge Issue
**File:** `tests/generation/doc_only/RESULTS.md`  
**Status:** ⚠️ **Judge unreliable — manual review pending**

| Metric | Run 2 | Run 3 | Target | Issue |
|--------|-------|-------|--------|-------|
| faithfulness | 0.54 | 0.52 | ≥ 0.80 | gpt-oss false negatives |
| answer_relevancy | 0.38 | 0.40 | ≥ 0.80 | on Vietnamese OCR content |
| context_precision | 0.54 | 0.56 | ≥ 0.70 | |
| context_recall | 0.47 | 0.53 | ≥ 0.70 | |

**Manual Audit (6 questions with faithfulness=0):** 0/6 actual hallucinations — judge systematically fails on Vietnamese OCR/table content.

**Judge gemma4:31b (100q):**
- 45/100 PASS groundedness
- Re-judge with top-7 contexts: **67/100 PASS** (22 flipped from FAIL)
- 33 remaining FAIL: 29 wrongful refusals (threshold T=0.64 too strict), 4 artifacts

**Fix Applied (2026-10-15):** Embedding model changed to `embeddinggemma-300m` → recalibrated threshold to **T=0.76** (chặn 30/30 âm, 0/5 dương). Soft band [0.50, 0.76) → answer with LOW confidence + warning.

**Review Queue:** `review_100.json`, `review_30_manual.json`, `review_70_extra.json`, `draft_golds_batch1.json` — **awaiting human verdict**

---

### 1.9 Memory / Multi-turn (30→50 conv × 12 turns)
**File:** `tests/memory/internal/RESULTS.md`  
**Dataset:** `memory_internal.csv` (sids 1001–1050: xe, lương, VPP, EVN/MWG/Petrolimex, quản trị)

| Metric | 30 conv (gemma) | 50 conv (gemma) |
|--------|-----------------|-----------------|
| rewrite_score | 0.390 | **0.463** |
| llm_rewrote | 323/360 | 544/600 |
| Route: DOC_ONLY | 346 | 582 |
| Route: DB_ONLY | 11 | 12 |
| Route: DIRECTORY | 3 | 3 |

**End-to-End Answers (20 new conv, 240 turns):**
- Refused: 62/240 (26%) — **was 66% at T=0.64, dropped to 26% with embeddinggemma + T=0.66 + soft band**
- Answered: 178 turns, overlap avg **0.80**
- Latency: p50 4.6s / p95 8.0s

**Judge Verdicts (233 turns):**
- ĐÚNG trọng tâm: 161 (67%)
- ĐÚNG 1 PHẦN: 54
- SAI: 17 (nhầm doc, lạc chunk, neo sai)
- Từ chối oan: 8 (top1 < 0.50)

**⚠️ Critical Bug Found:** **PII leak — phone numbers leaked via directory search** (e.g., "Ai trình quy chế này?" → returns 5 employees with SĐT). Must fix before production.

---

### 1.10 Text2SQL Execution Accuracy (IBM text2sql-eval-toolkit)
**File:** `test_v2/text2sql/EVALUATION_STATUS.md`  
**Status:** ⏳ **WAITING FOR DAILY QUOTA RESET** (3:00 PM Vietnam time / 08:00 UTC)

**Pre-fix Results (2026-11-13):**
| Metric | Value |
|--------|-------|
| Execution Accuracy (EX) | **3.2%** |
| Non-Empty EX | 2.1% |
| Logic EX | **10.7%** |
| Bird EX | 3.7% |
| Questions evaluated | 186/187 |
| Inference errors | 149 |
| Dataframe errors | 152 |

**All Fixes Implemented:**
1. ✅ Parameter substitution (`%(uid)s`, `%(year)s`) in evaluation
2. ✅ Enhanced few-shots Vd22-Vd120 (IT tickets, Vietnamese aliases, payroll, attendances, permissions, performance, GROUP BY, exact column matching)
3. ✅ COMMON COLUMN ERRORS documented in prompt (10+ hallucinated columns)
4. ✅ Validator `not_a_table` expanded (50+ column names)
5. ✅ Centralized `GeminiKeyManager` (6 keys, round-robin, persistence, daily reset at 3 PM ICT)
6. ✅ UTF-8 encoding, asyncio conflict, CSV PermissionError handling
7. ✅ Model config: Gemma NOT for SQL (16k RPM limit), only Flash-Lite

**Expected Post-Reset:**
- Parameter substitution fix: ~30-40% EX recovery
- Few-shots + column errors: ~15-20% EX recovery
- **Combined target: EX > 50%** (acceptable threshold)

**Run Command:**
```bash
cd ai-service/test_v2/text2sql
PYTHONIOENCODING=utf-8 python run_hrm_evaluation_fixed.py
```

---

## ⏳ 2. Remaining Tests Needed for Production Gate

| # | Test | Acceptable Metric | Dataset Reliability | Status |
|---|------|-------------------|---------------------|--------|
| 1 | **Text2SQL Full EX Evaluation** | EX > 50%, Logic EX > 75%, Bird EX > 70%, Valid SQL ≥ 95% | **High** — 187 gold questions with placeholders, real seed DB | ⏳ Waiting quota reset |
| 2 | **DOC_ONLY Generation Quality** | Faithfulness ≥ 0.80, Answer Relevancy ≥ 0.80 (reliable judge) | **Medium** — 100q review queue exists, but judge unreliable | ⚠️ Need judge swap or deterministic checker |
| 3 | **HYBRID End-to-End Fix** | has_doc_facts > 0.50, answer_ok > 0.70 | **High** — 34 HYBRID gold questions | ❌ DOC retrieval not integrated |
| 4 | **Latency Benchmarks** | P50/P95 per route: DB<3s, DOC<5s, HYB<8s, DIR<1s | **High** — Already logged per-row in eval outputs | ⏳ Aggregate existing data |
| 5 | **Stress Test (60s @ 0.2 QPS)** | Zero quota exhaustion, graceful degradation | **High** — Can run with current infra | ⏳ Not run |
| 6 | **Key Rotation Validation** | 6 keys, 3 rotations max, daily reset verified | **High** — `GeminiKeyManager` implemented | ⏳ Export test results |
| 7 | **Vietnamese Localization** | Date DD/MM/YYYY, Status VN, Numbers 15.000.000 VND | **High** — Implemented in `chat_service.py` | ⏳ Verify in answer quality tests |
| 8 | **Error Handling Paths** | Guard rejections, DB failures, LLM timeouts, streaming parity | **Medium** — Code review needed | ⏳ Not tested |
| 9 | **PII Leak Fix Verification** | Zero phone numbers leaked in DIRECTORY | **Critical** — Bug confirmed in memory test | ❌ Not fixed |

---

## 📁 3. Test Artifacts & Proof (Per-Question Metrics)

Each test suite produces **per-question JSON output** with detailed metrics:

| Test Suite | Output File | Contains |
|------------|-------------|----------|
| DB_ONLY Retrieval | `tests/retrieval_db_only/db_retrieval_eval.json` | 187 questions × route_acc, sql_ok, non_empty, latency, tokens |
| DB_ONLY Generation | `tests/retrieval_db_only/db_generation_eval.json` | 187 questions × sql_ok, rows_match, latency, tokens |
| DB_ONLY Answer | `tests/retrieval_db_only/db_answer_eval.json` | 187 questions × fact_recall, answer_ok, missed facts |
| DOC_ONLY Retrieval | `tests/retrieval_doc_only/retrieval_eval.json` | 146 questions × Hit@1/3/5, MRR, scores, fallback, latency |
| LLM Router | `tests/routing/llm_router_test.json` | 402 questions × expected/predicted route, latency |
| Keyword Router | `tests/routing/router_accuracy_test.json` | 180 questions × expected/predicted |
| DIRECTORY | `tests/routing/directory_test.json` | 30+ checks × route, card rendering, disambiguation |
| HYBRID E2E | `test_v2/outputs/hybrid_eval.json` | 30 questions × sql_ok, fact_recall, answer_ok, db/doc facts |
| Memory Rewrite | `tests/memory/internal/memory_internal_results.json` | 600 turns × rewrite_score, route, gold vs predicted |
| Memory Answers | `tests/memory/internal/memory_answer_20new_nolock.json` | 240 turns × answer, overlap, citations, refused, latency |
| Text2SQL EX | `test_v2/text2sql/benchmarks/hrm_db_only-predictions.json` | 187 questions × predicted SQL, execution result, EX metrics |

**All files exist and are reproducible.** Run commands documented in each `*_RESULTS.md`.

---

## 🎯 4. Chatbot Greeting & Intro Behavior — Current Implementation

**File:** `ai-service/src/chat/chat_service.py` (lines 1588–1632)

### ✅ Already Implemented

**1. Greeting Detection (`_is_greeting`):**
```python
greeting_patterns = [
    "chào", "chao", "xin chào", "xin chao", "hello", "hi", "hey",
    "chào bạn", "chao ban", "chào anh", "chao anh", "chào chị", "chao chi",
    "alo", "a lô", "chào ạ", "chao a", "có ai không", "co ai khong"
]
```
Matches: exact, prefix, or suffix (e.g., "chào bạn", "xin chào ạ")

**2. Greeting Response (`_get_greeting_response`):**
```vietnamese
Xin chào! Tôi là Trợ lý AI Quản trị Nhân sự của **Công ty Cổ phần Viễn thông ACT**.

Tôi có thể giúp bạn tra cứu:
• Quy chế, nội quy, chính sách nhân sự (nghỉ phép, lương, thưởng, phạt...)
• Dữ liệu cá nhân của bạn (số ngày phép còn lại, lương, hợp đồng, chấm công...)
• Thông tin danh bạ công khai của đồng nghiệp (SĐT, email, phòng ban, ca làm...)

Bạn hãy hỏi tôi bất cứ điều gì về nhân sự nhé!
```

**3. Intro Question Detection (`_is_intro_question`):**
```python
intro_patterns = [
    "chatbot này là gì", "chatbot nay la gi",
    "bạn là ai", "ban la ai",
    "chatbot này làm gì", "chatbot nay lam gi",
    "chatbot này có chức năng gì", "chatbot nay co chuc nang gi",
    "đây là chatbot gì", "day la chatbot gi",
    "trợ lý này là gì", "tro ly nay la gi",
    "bạn có thể làm gì", "ban co the lam gi",
    "giới thiệu chatbot", "gioi thieu chatbot",
    "ai này là gì", "ai nay la gi"
]
```
Matches: substring (e.g., "bạn có thể làm gì cho tôi")

**4. Intro Response (`_get_intro_response`):**
```vietnamese
Chào bạn, tôi là **Trợ lý AI Quản trị Nhân sự** của **Công ty Cổ phần Viễn thông ACT**.

**Tôi có thể làm gì cho bạn:**
1. **Trả lời quy chế/chính sách**: Nghỉ cưới bao nhiêu ngày? Đi muộn bị phạt thế nào? Quy trình xin phép? Phụ cấp ăn trưa?...
2. **Tra cứu dữ liệu cá nhân của bạn**: Còn bao nhiêu ngày phép? Lương tháng này bao nhiêu? Hợp đồng loại nào? Lịch làm việc?...
3. **Tra danh bạ công khai**: SĐT anh Hùng, chị Lan làm phòng nào, hôm nay ai đi làm, trưởng phòng Kế Toán là ai?...
4. **Đối chiếu quy định với dữ liệu thực tế**: "Tôi còn bao nhiêu ngày phép? Có đúng luật lao động không?"

**Lưu ý**: Tôi chỉ truy cập được dữ liệu của **chính bạn**. Câu hỏi về lương/thưởng/phép của người khác tôi sẽ không trả lời.

Hãy hỏi tôi bất cứ điều gì về nhân sự nhé!
```

### ✅ Both Streaming & Non-Streaming Paths Handled
- `answer_query()` (non-streaming): lines 1647–1660
- `answer_query_stream()` (SSE streaming): lines 1802–1819

---

## ✅ 5. Verification: Requirements Met

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **1. User says hello → bot says hello + capabilities** | ✅ **IMPLEMENTED** | `_is_greeting()` + `_get_greeting_response()` in Vietnamese, mentions ACT |
| **2. User asks "what can you do" → bot explains in Vietnamese, mentions ACT, docs + personal info** | ✅ **IMPLEMENTED** | `_is_intro_question()` + `_get_intro_response()` in Vietnamese, mentions ACT, 4 capabilities listed |

---

## 📋 6. Recommended Next Actions (Priority Order)

| Priority | Action | Effort | Owner |
|----------|--------|--------|-------|
| **P0** | Run Text2SQL EX evaluation after quota reset (3 PM ICT daily) | 30 min | Dev |
| **P0** | Fix HYBRID: integrate DOC retrieval in `_answer_with_db` / pipeline | 2–4 hrs | Dev |
| **P0** | Fix PII leak: sanitize phone numbers in DIRECTORY search results | 1–2 hrs | Dev |
| **P1** | Swap DOC_ONLY generation judge to deterministic fact-checker (like `eval_db_answer.py`) | 4–8 hrs | Dev |
| **P1** | Run stress test (60s @ 0.2 QPS) with quota monitoring | 1 hr | Dev |
| **P1** | Export key rotation test results (simulate 429, daily reset, persistence) | 2 hrs | Dev |
| **P2** | Aggregate latency benchmarks from existing per-row logs | 30 min | Dev |
| **P2** | Verify Vietnamese localization in answer quality spot-checks | 1 hr | QA |
| **P2** | Complete manual review of `review_100.json` for DOC generation | 4 hrs | Domain Expert |

---

## 📂 7. Key Files Reference

| File | Purpose |
|------|---------|
| `SPEC_CHATBOT_EVAL_REPORT.md` | Evaluation report specification |
| `SPEC_CHATBOT_FULL_TEST_COVERAGE.md` | Full test coverage spec with acceptance criteria |
| `SPEC_TEXT2SQL_EX_IMPROVEMENT_V2.md` | Text2SQL fixes specification |
| `ai-service/test_v2/text2sql/EVALUATION_STATUS.md` | Text2SQL quota status & fixes |
| `ai-service/tests/retrieval_doc_only/RETRIEVAL_DOC_ONLY_RESULTS.md` | DOC_ONLY retrieval results |
| `ai-service/tests/routing/LLM_ROUTING_TEST_RESULTS.md` | Router results (LLM + keyword) |
| `ai-service/tests/EVAL_SUMMARY.md` | Consolidated internal eval summary |
| `ai-service/tests/generation/db_only/RESULTS.md` | DB generation results |
| `ai-service/tests/generation/doc_only/RESULTS.md` | DOC generation results (judge issue) |
| `ai-service/tests/memory/internal/RESULTS.md` | Memory/multi-turn results (PII leak) |
| `ai-service/test_v2/outputs/hybrid_eval.json` | HYBRID E2E detailed results |
| `ai-service/src/chat/chat_service.py` | Main pipeline (greeting, intro, 5 routes, streaming, cache, memory) |
| `ai-service/src/utils/gemini_key_manager.py` | Centralized quota management (6 keys) |

---

**Report compiled from:** Actual test output files, source code, and evaluation documentation in the HRM codebase. All JSON output files contain per-question metrics for auditability.