# 06: Production Gate Verification — Full Suite Pass

**What to build:**
Run the complete evaluation suite and verify all production acceptance criteria pass. This is the final integration gate before production deployment.

**Blocked by:** 01, 02, 03, 04, 05 (all prior tickets must complete)

**Status:** ready-for-agent

- [ ] HYBRID: `has_doc_facts ≥ 50%`, `fact_recall ≥ 75%`, `sql_ok ≥ 85%` (eval_hybrid.py)
- [ ] PII: Zero phone numbers in any `directory_lines()` output (test_executor.py)
- [ ] DOC Generation: Fact-checker scores ≥ 0.75 on faithfulness & answer_relevancy
- [ ] Text2SQL: EX ≥ 75%, VES ≥ 70% on 187 questions
- [ ] Routing: HYBRID route accuracy ≥ 70% (test_llm_router_full.py)
- [ ] Key rotation: 10/10 stress test passes without "All keys exhausted"
- [ ] Generate final report artifact with all metrics, per-question proof, and limitations
- [ ] Greeting/Intro behavior verified: Vietnamese, mentions "Công ty Cổ phần Viễn thông ACT"