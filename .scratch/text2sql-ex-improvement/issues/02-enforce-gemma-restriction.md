# 02: Enforce Gemma 4 31B Restriction — Route/Rewrite/Summary ONLY

**What to build:** The system must **never** use Gemma 4 31B (`gemma-4-31b-it`) for SQL generation or Answer generation. It must only be used for:
- Query routing/classification (`route` model type)
- Query rewriting/condensing (`rewrite_route` tag)
- Summarization (`ensure_summary`, `condense` tags)
- Metadata enrichment (small prompts < 2k tokens)

SQL generation must use Gemini 3.5 Flash-Lite (`gemini-3.5-flash-lite`) — the full Text2SQL prompt is ~24k tokens, exceeding Gemma's 16k RPM input token limit. Answer generation must also use Flash-Lite.

**Current state analysis:**
| Location | Model Type | Current Behavior | Required |
|----------|------------|------------------|----------|
| `chat_service.py:_llm_complete()` | `tag in ("text2sql",)` → `mtype="sql"` | ✅ Uses SQL model | Keep |
| `chat_service.py:_llm_complete()` | `tag in ("answer", "db_stream")` → `mtype="ans"` | ✅ Uses Answer model | Keep |
| `chat_service.py:_llm_complete()` | other tags (condense, rewrite, summary, smart-title) → `mtype="route"` | ✅ Uses Route model (Gemma) | Keep |
| `metadata_enricher.py:161` | `key_manager.complete("route", ...)` | ✅ Uses Route model | Keep |
| `router.py:405-409` | `llm_complete(REWRITE_ROUTE_PROMPT, ...)` | Routes via `chat_service._llm_complete` → Route model | Keep |
| `.env.example:12` | `GEMINI_MODEL_SQL=gemini-3.1-flash-lite` | ❌ Wrong version | Fix to 3.5 |
| `gemini_key_manager.py:89` | Default `model_sql = "gemini-3.1-flash-lite"` | ❌ Wrong version | Fix to 3.5 |

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Fix `.env.example`: `GEMINI_MODEL_SQL=gemini-3.5-flash-lite`
- [ ] Fix `gemini_key_manager.py:89`: default `model_sql = "gemini-3.5-flash-lite"`
- [ ] Add runtime guard in `GeminiKeyManager.complete()`: if `mtype=="sql"` and model name contains "gemma", raise `ValueError` with clear message
- [ ] Verify no code path passes `"route"` model type to SQL or Answer generation
- [ ] Verify `GEMINI_MODEL_ANS=gemini-3.5-flash-lite` in `.env.example` and key manager defaults
- [ ] Add integration test: attempt SQL generation with Gemma model → fails with clear error