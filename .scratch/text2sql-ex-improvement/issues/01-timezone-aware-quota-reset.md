# 01: Timezone-Aware Quota Reset (Vietnam UTC+7)

**What to build:** The `GeminiKeyManager` must reset daily quotas at exactly 08:00 UTC (3:00 PM Vietnam time) instead of using rolling 24-hour windows from first API call. Google Free Tier resets at 08:00 UTC daily — the key manager must align to this fixed reset time.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Modify `_reset_windows()` in `gemini_key_manager.py` to calculate next reset at 08:00 UTC
- [ ] Persist `day_start_*` as the timestamp of the last 08:00 UTC boundary, not `time.time()` on first call
- [ ] On startup, compute elapsed days since last reset and zero counters accordingly
- [ ] Verify: quota resets at 08:00 UTC sharp across restarts; no drift over multiple days
- [ ] Add test: simulate midnight UTC vs 08:00 UTC reset boundary