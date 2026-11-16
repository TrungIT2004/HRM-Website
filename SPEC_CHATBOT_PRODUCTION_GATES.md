# HRM Chatbot — Production Gates Specification

## Problem Statement

The HRM AI Chatbot (Công ty Cổ phần Viễn thông ACT) has completed several evaluation suites with strong core metrics, but **four critical gaps** block production readiness:

1. **HYBRID pipeline missing DOC retrieval** — The HYBRID route only queries DB (Text2SQL), never retrieves from DOC (RAG). 30 evaluation questions all show `has_doc_facts = 0%`.
2. **PII leak in DIRECTORY search** — `directory_lines()` returns employee phone numbers (SĐT) in chat responses.
3. **DOC_ONLY generation judge unreliable** — RAGAS evaluation uses `gpt-oss` as judge which produces inconsistent scores; needs deterministic fact-checker.
4. **Text2SQL EX evaluation pending quota reset** — Full 187-question benchmark hasn't run since key-rotation fixes.

## Solution

Fix all four gaps, then run the complete evaluation suite to produce a final report with verified metrics.

---

## User Stories

### HYBRID DOC Retrieval Integration
1. As an HRM employee, I want to ask "How many leave days do I have left according to policy?" and get both my personal balance (from DB) AND the company policy rules (from DOC), so that I understand my entitlement.
2. As an HRM employee, I want to ask "What's my overtime pay rate per policy?" and get my personal OT hours (from DB) AND the calculation formula (from DOC), so that I can verify my payslip.
3. As a QA engineer, I want the HYBRID evaluation to measure `has_doc_facts ≥ 50%`, so that we verify DOC retrieval actually works in mixed queries.

### PII Leak Fix — Directory Search
4. As an HRM employee, I want to look up a colleague's name and department via chat, so that I know who to contact.
5. As an HRM employee, I do NOT want phone numbers exposed in chat responses, so that personal contact info stays private.
6. As a security reviewer, I want `directory_lines()` to return only name, department, job title, and email — never phone numbers — so that PII is not leaked through the chatbot.

### DOC Generation Judge Replacement
7. As a QA engineer, I want generation quality measured by deterministic fact-checking (not LLM judge), so that scores are reproducible and CI/CD gates are reliable.
8. As a developer, I want the judge to verify: (a) every number in answer exists in retrieved context, (b) every policy reference matches DOC chunks, (c) no hallucinated facts, so that we catch real quality issues.

### Text2SQL EX Evaluation Execution
9. As a project stakeholder, I want the full 187-question Text2SQL benchmark run with EX (execution) metrics after quota reset, so that we have production-grade SQL correctness numbers.
10. As a QA engineer, I want the evaluation to use IBM text2sql-eval-toolkit with EX + VES metrics, so that results are comparable to published benchmarks.

---

## Implementation Decisions

### 1. HYBRID Pipeline — Add DOC Retrieval to `_answer_with_hybrid`

**Current flow (broken):**
```
User question → Router → HYBRID → generate_personal_rows (Text2SQL) → _answer_with_db → Answer
```
Missing: No DOC retrieval step.

**New flow:**
```
User question → Router → HYBRID → 
  ├─ generate_personal_rows (Text2SQL) → DB summary
  └─ retrieve_doc_context(question) → DOC chunks (HybridRetriever)
       ↓
  _answer_with_hybrid(question, db_summary, doc_chunks) → Answer
```

**Module changes:**
- `src/chat/chat_service.py`: Add `_answer_with_hybrid` method that accepts both DB summary and DOC chunks
- `src/retrievers/hybrid_retriever.py`: Ensure `retrieve()` returns chunks with metadata for citation
- `src/sql/router.py` / `router_v2.py`: Verify HYBRID route classification works for mixed-intent questions

**Key decision:** Reuse existing `HybridRetriever` (vector 0.7 + BM25 0.3 + CrossEncoder reranker) — already tested at 100% Hit@5 for DOC_ONLY. Just need to call it in HYBRID path.

### 2. PII Leak Fix — `directory_lines()` Sanitization

**Current code (executor.py:288-290):**
```python
lines.append(f"- {role}: {fn} {ln} ({dp or '?'} – {jb or '?'})"
             + (f", email: {em}" if em else "")
             + (f", SĐT: {ph}" if ph else ""))  # ← LEAKS PHONE
```

**Fix:** Remove phone number from output. Keep: name, department, job title, email.
```python
lines.append(f"- {role}: {fn} {ln} ({dp or '?'} – {jb or '?'})"
             + (f", email: {em}" if em else ""))
```

**Module:** `src/sql/executor.py` — single function change, no callers affected (returns `List[str]` for display only).

### 3. DOC Generation Judge — Deterministic Fact-Checker

**Replace:** `gpt-oss` LLM judge (in `tests/generation/doc_only/judge_gemma.py`, `judge_pairwise.py`, `rejudge7.py`)

**With:** Deterministic verifier that checks:
- **Numeric fidelity:** Every number in answer must appear in retrieved chunks (allow ±1% tolerance for rates)
- **Policy grounding:** Every policy/article reference must match a DOC chunk title or content
- **No hallucination:** Answer tokens not in (question + retrieved context) flagged
- **Refusal correctness:** "I don't know" responses allowed only when no relevant chunks retrieved

**Module:** New file `tests/generation/doc_only/fact_checker.py` with `verify_answer(answer, chunks, question) -> Dict[str, float]` returning `faithfulness`, `answer_relevancy`, `context_precision` scores.

### 4. Text2SQL EX Evaluation — Quota-Aware Runner

**Current:** `test_v2/text2sql/run_hrm_evaluation_fixed.py` — already has all fixes (key rotation, fallbacks, EX metrics via IBM toolkit)

**Action:** Run after daily quota reset (3 PM ICT / 08:00 UTC). Command:
```bash
python -m test_v2.text2sql.run_hrm_evaluation_fixed
```

**Expected output:** `test_v2/outputs/hrm_text2sql_eval.json` with EX accuracy, VES, and per-question breakdown.

---

## Testing Decisions

| Test | What Makes It Good | Module | Prior Art |
|------|-------------------|--------|-----------|
| HYBRID E2E | 30 mixed-intent questions; `has_doc_facts ≥ 50%`, `fact_recall ≥ 75%` | `test_v2/hybrid/eval_hybrid.py` | Already exists, needs DOC retrieval wired |
| PII Leak | Unit test: `directory_lines()` output never contains "SĐT" or phone regex | `tests/sql/test_executor.py` (new) | Pattern: `tests/retrieval_db_only/` |
| DOC Fact-Checker | Golden set: 20 Q/A pairs with known correct/incorrect answers; verifier matches human labels ≥ 95% | `tests/generation/doc_only/fact_checker.py` | Pattern: `eval_retrieval.py` |
| Text2SQL EX | 187 questions; EX ≥ 75%, VES ≥ 70% | `test_v2/text2sql/run_hrm_evaluation_fixed.py` | Already implemented |

**Test data sources:**
- HYBRID: `test_v2/common.py` → `DB_ONLY_HYBRID_QUESTIONS_WITH_ANSWERS` (30 HYBRID questions)
- DOC generation: `tests/DOC_ONLY/datasets/doc_only_120.csv` + generated Q/A pairs
- Text2SQL: `test_v2/text2sql/benchmarks/hrm_db_only.jsonl` (187 questions)

---

## Out of Scope

- Frontend/UI changes (HRM Website)
- Backend Java services (employee directory API)
- Multi-turn conversation memory (already works, tested separately)
- Semantic cache optimization
- Streaming SSE improvements
- Key rotation algorithm changes (already working)

---

## Further Notes

### Quota Management Context
- 6 Gemini keys: `GEMINI_API_KEY_1..5` + `GEMINI_API_KEY`
- Round-robin on 429; shared RPM: 15 (Flash-Lite), 30 (Gemma)
- Daily quota: 500/key; project cooldown 60s; max 3 full rotations (18 attempts)
- State persisted: `test_v2/text2sql/quota_state.json`
- **Run Text2SQL eval after 3 PM ICT daily reset**

### Known Fixed Regressions (Verified)
- ✅ DB Retrieval: 92.5% SQL OK (was broken)
- ✅ DB Generation: 90% SQL OK (was broken)
- ✅ Hybrid SQL: 100% OK (was broken)
- ✅ DOC_ONLY Routing: 93.33% (was 40%) — fixed via `keyword_fallback` in router
- ✅ Retrieval Fallback: 3.33% (was 47.9%) — threshold 0.76 → 0.65

### Remaining HYBRID Routing Issue
- HYBRID route accuracy: 5.88% — LLM routes self-anchored+policy questions to DB_ONLY
- **Root cause:** Router prompt doesn't clearly distinguish "personal data + policy" (HYBRID) from "personal data only" (DB_ONLY)
- **Fix needed:** Update router prompt / add HYBRID training examples / tune threshold

### Greeting/Intro Behavior (Already Implemented ✅)
- `chat_service.py:1588-1632` — `_is_greeting()`, `_is_intro_question()`, `_get_greeting_response()`, `_get_intro_response()`
- Vietnamese responses mentioning "Công ty Cổ phần Viễn thông ACT"
- Hello → greeting + capabilities; "What can you do" → intro with ACT, docs + personal info

### Acceptance Criteria for Production Gate
All must pass:
1. HYBRID: `has_doc_facts ≥ 50%`, `fact_recall ≥ 75%`, `sql_ok ≥ 85%`
2. PII: Zero phone numbers in any `directory_lines()` output
3. DOC Generation: Fact-checker scores ≥ 0.75 on faithfulness & answer_relevancy
4. Text2SQL: EX ≥ 75%, VES ≥ 70% on 187 questions
5. Routing: HYBRID route accuracy ≥ 70% (currently 5.88%)
6. Key rotation: 10/10 stress test passes without "All keys exhausted"