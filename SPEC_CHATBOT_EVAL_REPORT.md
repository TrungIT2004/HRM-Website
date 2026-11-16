# HRM Chatbot Evaluation Report - Specification

## Objective
Generate a comprehensive evaluation report for the HRM AI Chatbot suitable for a school project, demonstrating:
- Strong core metrics (Text2SQL, Retrieval, Routing)
- Fixed integration issues
- Proper quota management with 6 API keys
- Clear action items for remaining weaknesses

## Scope

### 1. Run Missing Evaluations
- [ ] **RAGAS Generation Quality** - Run on 30 questions (faithfulness, answer_relevancy, context_precision, context_recall)
- [ ] **Latency Benchmarks** - P50/P95 per route (DB_ONLY, DOC_ONLY, HYBRID, DIRECTORY)
- [ ] **Stress Test** - 60s at 0.2 QPS to show Free Tier quota handling
- [ ] **Key Rotation Validation** - Export test results proving rotation works

### 2. Fix Critical Issues (P0)
- [ ] **DOC_ONLY Routing: 40% → >70%**
  - Root cause: Router prompt confusion between policy questions (DOC_ONLY) and personal data queries (DB_ONLY)
  - Fix: Adjust router prompt, add more DOC_ONLY training examples, tune threshold
  - Files: `src/sql/router.py`, `src/sql/router_v2.py`

- [ ] **Retrieval Fallback Rate: 47.9% → <20%**
  - Root cause: RELEVANCE_THRESHOLD=0.76 too high for embeddinggemma-300m
  - Fix: Lower threshold to 0.65, adjust SOFT_THRESHOLD
  - Files: `src/chat/chat_service.py`

### 3. Generate Report Artifact
- [ ] Interactive HTML report with:
  - Metric tables with PASS/FAIL status
  - Per-route breakdown charts
  - Quota management visualization
  - Latency distributions
  - Comparison with benchmarks
  - Limitations & future work section

## Test Datasets
| Suite | Questions | Source |
|-------|-----------|--------|
| Text2SQL | 187 | `test_v2/text2sql/benchmarks/hrm_db_only.jsonl` |
| LLM Router | 341 | `tests/DOC_ONLY/datasets/doc_only_120.csv` + `db_only_hybrid_questions.json` |
| Retrieval | 48 | DOC_ONLY subset (keyword fallback) |
| Integrated DB | 40 | `test_v2/db_only/retrieval/` |
| Integrated Hybrid | 30 | `test_v2/hybrid/` |

## Current Best Metrics (to update after fixes)
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Text2SQL EX | 78.07% | >75% | ✅ PASS |
| Router Overall | 74.19% | >80% | ⚠️ NEEDS FIX |
| Router DB_ONLY | 93.58% | >90% | ✅ PASS |
| Router DOC_ONLY | 40.00% | >70% | ❌ FAIL |
| Retrieval Hit@5 | 100% | >90% | ✅ PASS |
| Retrieval Fallback | 47.92% | <20% | ❌ FAIL |
| Hybrid Fact Recall | 85.4% | >80% | ✅ PASS |

## Success Criteria
1. All P0 fixes implemented and verified
2. RAGAS scores > 0.75 on faithfulness & answer_relevancy
3. Report artifact renders correctly with all metrics
4. Key rotation test passes 10/10 tests