# HRM — AI Service Rules

## key-rotation (always-loaded)
- 6 keys: `GEMINI_API_KEY_1..5` + `GEMINI_API_KEY` → round-robin on 429
- Shared RPM: 15 (Flash-Lite), 30 (Gemma) — **global across all keys**
- Daily quota: 500/key → project-level cooldown 60s → wait `retry_delay` (max 4.5h) → reset ALL
- Max 3 full rotations (18 attempts) then fail
- State persisted: `test_v2/text2sql/quota_state.json`
- **Details**: `key-rotation-algo` → `ai-service/docs/key-rotation.md`

## test-commands (always-loaded)
- Text2SQL: `python -m test_v2.text2sql.run_hrm_evaluation_fixed`
- Router: `python -m test_v2.routers.test_llm_router_full`
- Retrieval: `python -m test_v2.rag.retrieval.eval_retrieval`
- DB Retrieval: `python -m test_v2.db_only.retrieval.eval_db_retrieval`
- DB Generation: `python -m test_v2.db_only.retrieval.eval_db_generation`
- Hybrid: `python -m test_v2.hybrid.eval_hybrid`

## known-regressions (always-loaded)
- ✅ DB Retrieval/Generation/Hybrid: FIXED — 92.5%/90%/100% SQL OK
- ✅ DOC_ONLY Routing: 93.33% (was 40%) via keyword_fallback
- ✅ Retrieval Fallback: 3.33% (was 47.9%) via threshold 0.76→0.65
- ⚠️ HYBRID Routing: 5.88% — LLM routes self-anchored+policy to DB_ONLY

## llm-models (disclosed)
- **Details**: `llm-models` → `ai-service/docs/llm-models.md` — model specs, effective quotas ×6, env var mapping

## troubleshooting (disclosed)
- **Details**: `troubleshooting` → `ai-service/docs/troubleshooting.md` — "All keys exhausted", 429 retry_delay, RPM limit