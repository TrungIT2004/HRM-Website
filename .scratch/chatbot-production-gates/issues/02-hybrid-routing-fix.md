# 02: HYBRID Routing Fix — Prompt & Threshold Tuning

**What to build:**
Fix the LLM router so self-anchored + policy questions (e.g., "How many leave days do I have left according to policy?") route to HYBRID instead of DB_ONLY. Current accuracy: 5.88%. Target: ≥ 70%.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Router prompt updated with clear HYBRID vs DB_ONLY distinction
- [ ] Added HYBRID training examples to router prompt/few-shot
- [ ] Threshold tuned (if using confidence-based routing)
- [ ] Router eval: `python -m test_v2.routers.test_llm_router_full` shows HYBRID accuracy ≥ 70%
- [ ] No regression: DB_ONLY routing stays ≥ 90%, DOC_ONLY stays ≥ 70%