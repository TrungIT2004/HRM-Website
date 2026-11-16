# 04: DOC Generation — Deterministic Fact-Checker

**What to build:**
Replace the unreliable `gpt-oss` LLM judge with a deterministic fact-checker for DOC_ONLY generation quality. New module `tests/generation/doc_only/fact_checker.py` with `verify_answer(answer, chunks, question) -> Dict[str, float]` returning `faithfulness`, `answer_relevancy`, `context_precision` scores.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `fact_checker.py` implements:
  - Numeric fidelity: every number in answer appears in retrieved chunks (±1% tolerance)
  - Policy grounding: every policy/article reference matches a DOC chunk
  - Hallucination check: answer tokens not in (question + context) flagged
  - Refusal correctness: "I don't know" only allowed when no relevant chunks
- [ ] Golden set: 20 Q/A pairs with known correct/incorrect answers
- [ ] Verifier matches human labels ≥ 95% on golden set
- [ ] Integration: replaces `judge_gemma.py`, `judge_pairwise.py`, `rejudge7.py` in evaluation pipeline
- [ ] DOC generation eval scores ≥ 0.75 on faithfulness & answer_relevancy