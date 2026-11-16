# 03: HYBRID Pipeline — DOC Retrieval Integration

**What to build:**
Wire DOC retrieval into the HYBRID answer path. Currently HYBRID only runs Text2SQL (DB) and calls `_answer_with_db`. New flow: run Text2SQL → get DB summary → retrieve DOC chunks via `HybridRetriever` → call new `_answer_with_hybrid(question, db_summary, doc_chunks)` → answer.

**Blocked by:** 02 (HYBRID Routing Fix) — ensures evaluation questions actually reach HYBRID path

**Status:** ready-for-agent

- [ ] New method `_answer_with_hybrid(question, db_summary, doc_chunks)` in `chat_service.py`
- [ ] HYBRID path calls `HybridRetriever.retrieve(question)` for DOC context
- [ ] `_answer_with_hybrid` composes answer from both DB summary and DOC chunks
- [ ] Citations include both DB tables and DOC chunk references
- [ ] HYBRID eval: `python -m test_v2.hybrid.eval_hybrid --n 30` shows:
  - `has_doc_facts ≥ 50%`
  - `fact_recall ≥ 75%`
  - `sql_ok ≥ 85%`
- [ ] No regression: DB_ONLY and DOC_ONLY paths unchanged