# Key Rotation Algorithm — Implementation Reference

## Rotation Logic

**File**: `ai-service/src/utils/gemini_key_manager.py` → `GeminiKeyManager.get_next_key()`

```
1. Load quota_state.json (persisted daily counters per key)
2. Filter keys: exclude exhausted (daily >= 500) + on cooldown
3. Round-robin pick next key from available pool
4. On 429:
   a. Mark key cooldown = now + 60s (project-level)
   b. Increment key's daily counter
   c. Persist quota_state.json
   d. Rotate to next key
   e. If all keys exhausted → wait retry_delay (capped 4.5h) → reset ALL daily counters → retry
5. Max 3 full rotations (18 attempts) → raise AllKeysExhausted
```

## Quota State Schema

`test_v2/text2sql/quota_state.json`:

```json
{
  "GEMINI_API_KEY_1": {"daily_count": 42, "last_reset": "2025-11-15", "cooldown_until": 0},
  "GEMINI_API_KEY_2": {"daily_count": 38, "last_reset": "2025-11-15", "cooldown_until": 0},
  "GEMINI_API_KEY_3": {"daily_count": 500, "last_reset": "2025-11-15", "cooldown_until": 1731686400},
  "GEMINI_API_KEY_4": {"daily_count": 12, "last_reset": "2025-11-15", "cooldown_until": 0},
  "GEMINI_API_KEY_5": {"daily_count": 7, "last_reset": "2025-11-15", "cooldown_until": 0},
  "GEMINI_API_KEY":  {"daily_count": 0,  "last_reset": "2025-11-15", "cooldown_until": 0}
}
```

- `daily_count`: requests today (resets at 00:00 UTC)
- `cooldown_until`: unix timestamp, 0 = no cooldown
- `last_reset`: ISO date for daily reset detection

## Effective Quotas (×6 Keys)

| Model | RPM/key | Daily/key | Effective RPM | Effective Daily |
|-------|---------|-----------|---------------|-----------------|
| Gemma 4 31B | 30 | 14,000 | 180 | 84,000 |
| Gemini 3.5 Flash-Lite (SQL) | 15 | 500 | 90 | 3,000 |
| Gemini 3.5 Flash-Lite (Answer) | 15 | 500 | 90 | 3,000 |

## Env Config (`.env`)

```bash
GEMINI_API_KEY_1=...
GEMINI_API_KEY_2=...
GEMINI_API_KEY_3=...
GEMINI_API_KEY_4=...
GEMINI_API_KEY_5=...
GEMINI_API_KEY=...

# RPM limits (shared across ALL keys per model)
GEMINI_RPM_FLASH_LITE=15
GEMINI_RPM_GEMMA=30

# Daily limits (per key)
GEMINI_DAILY_FLASH_LITE=500
GEMINI_DAILY_GEMMA=14000
```

## Call Sites

1. `ai-service/src/sql/executor.py` → `get_llm_complete()` — SQL generation
2. `ai-service/test_v2/text2sql/run_hrm_evaluation_fixed.py` → `get_llm_complete()` — evaluation

Both use `GeminiKeyManager` singleton.

## Common Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| "All keys exhausted" | Daily quota hit (500 × 6 = 3000) | Wait for 00:00 UTC reset OR upgrade to paid tier |
| 429 with `retry_delay > 3600` | Project-level daily quota exceeded | Pipeline auto-waits `retry_delay` (capped 4.5h), resets all keys |
| RPM limit hit | Parallel evals sharing 15 RPM | Run evals sequentially |