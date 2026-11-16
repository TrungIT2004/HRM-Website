# 05: Fix Model Name Discrepancy (3.1 → 3.5 Flash-Lite)

**What to build:** All configuration files and defaults must reference `gemini-3.5-flash-lite` consistently for SQL, Answer, and Vision models — not `gemini-3.1-flash-lite`.

**Blocked by:** None (can start immediately) — overlaps with 02 but focused on version number fix

**Status:** ready-for-agent

- [ ] Fix `.env.example`: `GEMINI_MODEL_SQL=gemini-3.5-flash-lite` (currently `gemini-3.1-flash-lite`)
- [ ] Fix `gemini_key_manager.py:89`: default `model_sql = "gemini-3.5-flash-lite"`
- [ ] Verify `GEMINI_MODEL_ANS=gemini-3.5-flash-lite` in `.env.example` and key manager defaults
- [ ] Verify `GEMINI_MODEL_VISION=gemini-3.5-flash-lite` in `.env.example` and key manager defaults
- [ ] Verify `GEMINI_MODEL_ROUTE=gemma-4-31b-it` (or `gemma-4-31b`) is correct for route model
- [ ] Search codebase for any other hardcoded `3.1-flash-lite` references and fix
- [ ] Verify key manager loads model names from env vars with correct defaults