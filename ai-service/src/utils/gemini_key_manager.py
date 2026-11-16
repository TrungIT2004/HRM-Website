"""
Centralized Gemini API Key Manager with per-model rotation.
Handles 6 API keys × 4 models (route, sql, ans, vision) with independent 429 handling.
Uses google.genai SDK (new) for proper per-client API key isolation.
"""
import os
import time
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from threading import Lock
from datetime import datetime, timezone, timedelta

try:
    from google import genai
    from google.genai.errors import ClientError
except ImportError:
    genai = None
    ClientError = Exception

# Persistence file for quota tracking
QUOTA_STATE_FILE = Path(__file__).resolve().parent.parent.parent / "test_v2" / "text2sql" / "quota_state.json"

# Vietnam timezone (UTC+7) - Google Free Tier resets at 08:00 UTC = 15:00 Vietnam time
VIETNAM_TZ = timezone(timedelta(hours=7))
GOOGLE_DAILY_RESET_HOUR_UTC = 8  # 08:00 UTC


def _get_next_reset_timestamp(now: float) -> float:
    """
    Calculate the next 08:00 UTC timestamp (Google Free Tier daily reset).
    ponytail: stdlib datetime.replace replaces manual field-by-field construction.
    """
    dt = datetime.fromtimestamp(now, tz=timezone.utc)
    today_reset = dt.replace(hour=GOOGLE_DAILY_RESET_HOUR_UTC, minute=0, second=0, microsecond=0)
    if dt < today_reset:
        return today_reset.timestamp()
    return (today_reset + timedelta(days=1)).timestamp()


def _get_day_start_timestamp(now: float) -> float:
    """
    Calculate the most recent 08:00 UTC timestamp (start of current quota day).
    ponytail: stdlib datetime.replace replaces manual field-by-field construction.
    """
    dt = datetime.fromtimestamp(now, tz=timezone.utc)
    today_reset = dt.replace(hour=GOOGLE_DAILY_RESET_HOUR_UTC, minute=0, second=0, microsecond=0)
    if dt >= today_reset:
        return today_reset.timestamp()
    return (today_reset - timedelta(days=1)).timestamp()


def _load_quota_state() -> Dict:
    """Load persisted quota state from disk."""
    if QUOTA_STATE_FILE.exists():
        try:
            return json.loads(QUOTA_STATE_FILE.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def _save_quota_state(state: Dict) -> None:
    """Save quota state to disk."""
    try:
        QUOTA_STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        QUOTA_STATE_FILE.write_text(json.dumps(state, indent=2), encoding="utf-8")
    except Exception as e:
        print(f"[GeminiKeyManager] Failed to save quota state: {e}")


class GeminiKeyManager:
    """
    Manages 6 Gemini API keys with 4 models each (route, sql, ans, vision).

    Rotation logic:
    - Each model type (route/sql/ans/vision) has its own independent key rotation
    - If model X on key K gets 429, switch to key K+1 for model X only
    - Other models on key K continue working
    - Round-robin: key0 -> key1 -> key2 -> key3 -> key4 -> key5 -> key0
    """

    MODEL_TYPES = ["route", "sql", "ans", "vision"]

    def __init__(self):
        self._lock = Lock()
        self._clients: List[Dict] = []
        self._current_indices: Dict[str, int] = {"route": 0, "sql": 0, "ans": 0, "vision": 0}
        self._initialized = False

    def initialize(self) -> bool:
        """Initialize all clients from environment variables."""
        with self._lock:
            if self._initialized:
                return True

            if genai is None:
                print("[GeminiKeyManager] google.genai not available")
                return False

            # Load all 6 API keys
            api_keys = []
            for i in range(1, 7):  # GEMINI_API_KEY_1 through _6
                key = os.getenv(f"GEMINI_API_KEY_{i}")
                if key:
                    api_keys.append(key)
            # Add base key if not already present
            base_key = os.getenv("GEMINI_API_KEY")
            if base_key and base_key not in api_keys:
                api_keys.append(base_key)

            if not api_keys:
                print("[GeminiKeyManager] No GEMINI_API_KEY* found in environment")
                return False

            # Model names from env
            model_route = os.getenv("GEMINI_MODEL_ROUTE", "gemma-4-31b-it")
            model_sql = os.getenv("GEMINI_MODEL_SQL", "gemini-3.5-flash-lite")
            model_ans = os.getenv("GEMINI_MODEL_ANS", "gemini-3.5-flash-lite")
            model_vision = os.getenv("GEMINI_OCR_MODEL", "gemini-3.5-flash-lite")

            # Rate limits from env (per minute)
            rpm_route = int(os.getenv("GEMINI_RPM_ROUTE", "30"))
            rpm_sql = int(os.getenv("GEMINI_RPM_SQL", "15"))
            rpm_ans = int(os.getenv("GEMINI_RPM_ANS", "15"))
            rpm_vision = int(os.getenv("GEMINI_RPM_VISION", "10"))  # Vision is slower

            # Daily quotas from env
            daily_route = int(os.getenv("GEMINI_DAILY_ROUTE", "14000"))
            daily_sql = int(os.getenv("GEMINI_DAILY_SQL", "500"))
            daily_ans = int(os.getenv("GEMINI_DAILY_ANS", "500"))
            daily_vision = int(os.getenv("GEMINI_DAILY_VISION", "500"))

            # Build client pool - each key gets its own genai.Client instance
            for idx, key in enumerate(api_keys):
                client = genai.Client(api_key=key)
                key_short = f"key{idx}_{key[:8]}..."

                client_info = {
                    "key": key_short,
                    "full_key": key,
                    "client": client,
                    "model_names": {
                        "route": model_route,
                        "sql": model_sql,
                        "ans": model_ans,
                        "vision": model_vision,
                    },
                    "rpm_limits": {
                        "route": rpm_route,
                        "sql": rpm_sql,
                        "ans": rpm_ans,
                        "vision": rpm_vision,
                    },
                    "daily_quotas": {
                        "route": daily_route,
                        "sql": daily_sql,
                        "ans": daily_ans,
                        "vision": daily_vision,
                    },
                    # Per-model state
                    "last_minute": {"route": 0, "sql": 0, "ans": 0, "vision": 0},
                    "minute_start": {"route": time.time(), "sql": time.time(), "ans": time.time(), "vision": time.time()},
                    "daily_used": {"route": 0, "sql": 0, "ans": 0, "vision": 0},
                    "day_start": {"route": _get_day_start_timestamp(time.time()), "sql": _get_day_start_timestamp(time.time()), "ans": _get_day_start_timestamp(time.time()), "vision": _get_day_start_timestamp(time.time())},
                    "exhausted": {"route": False, "sql": False, "ans": False, "vision": False},
                    "exhausted_at": {"route": 0, "sql": 0, "ans": 0, "vision": 0},
                    "disabled": {"route": False, "sql": False, "ans": False, "vision": False},
                    "calls": {"route": 0, "sql": 0, "ans": 0, "vision": 0},
                }
                self._clients.append(client_info)

            # Initialize indices to 0
            for mtype in self.MODEL_TYPES:
                self._current_indices[mtype] = 0

            # Load persisted quota state
            persisted = _load_quota_state()
            for client_info in self._clients:
                key_id = client_info["key"]
                if key_id in persisted:
                    old_data = persisted[key_id]
                    for mtype in self.MODEL_TYPES:
                        daily_used_key = f"daily_used_{mtype}"
                        day_start_key = f"day_start_{mtype}"
                        exhausted_key = f"exhausted_{mtype}"
                        exhausted_at_key = f"exhausted_at_{mtype}"
                        disabled_key = f"disabled_{mtype}"
                        if daily_used_key in old_data:
                            client_info["daily_used"][mtype] = old_data[daily_used_key]
                            if day_start_key in old_data:
                                client_info["day_start"][mtype] = old_data[day_start_key]
                            if exhausted_key in old_data:
                                client_info["exhausted"][mtype] = old_data[exhausted_key]
                            if exhausted_at_key in old_data:
                                client_info["exhausted_at"][mtype] = old_data[exhausted_at_key]
                            if disabled_key in old_data:
                                client_info["disabled"][mtype] = old_data[disabled_key]
                        elif "daily_used" in old_data and mtype == "sql":
                            # Migrate from old format (single daily_used -> sql model ONLY)
                            client_info["daily_used"][mtype] = old_data["daily_used"]
                            if "day_start" in old_data:
                                client_info["day_start"][mtype] = old_data["day_start"]
                    print(f"[GeminiKeyManager] Loaded persisted state for {key_id}: "
                          f"route={client_info['daily_used']['route']}/{daily_route}, "
                          f"sql={client_info['daily_used']['sql']}/{daily_sql}, "
                          f"ans={client_info['daily_used']['ans']}/{daily_ans}, "
                          f"vision={client_info['daily_used']['vision']}/{daily_vision}")

            self._initialized = True
            print(f"[GeminiKeyManager] Initialized {len(self._clients)} key(s) for rotation")
            for c in self._clients:
                print(f"  {c['key']}: route_daily={daily_route}, sql_daily={daily_sql}, ans_daily={daily_ans}, vision_daily={daily_vision}")
            return True

    def _reset_windows(self, client_info: Dict, mtype: str, now: float) -> None:
        """Reset minute and daily windows if needed."""
        # Reset minute window
        if now - client_info["minute_start"][mtype] >= 60:
            client_info["last_minute"][mtype] = 0
            client_info["minute_start"][mtype] = now

        # Reset daily window at fixed 08:00 UTC (Google Free Tier reset)
        # Check if we've crossed the 08:00 UTC boundary since last reset
        current_day_start = _get_day_start_timestamp(now)
        if client_info["day_start"][mtype] < current_day_start:
            # New quota day started at 08:00 UTC
            client_info["daily_used"][mtype] = 0
            client_info["day_start"][mtype] = current_day_start
            client_info["exhausted"][mtype] = False
            client_info["exhausted_at"][mtype] = 0
            # Persist the reset state
            self._persist_state(client_info)

    def _is_quota_error(self, error: Exception) -> bool:
        """Check if exception is a quota/rate limit error (429)."""
        msg = str(error).lower()
        return any(kw in msg for kw in ("quota", "429", "rate limit", "resource exhausted", "too many requests"))

    def _is_auth_error(self, error: Exception) -> bool:
        """Check if exception is an authentication error (401) - service account deleted/disabled."""
        msg = str(error).lower()
        return any(kw in msg for kw in ("401", "unauthenticated", "account_state_invalid", "service account is deleted", "service account is disabled"))

    def _record_usage(self, client_info: Dict, mtype: str, prompt: str, response: str) -> None:
        """Update usage counters after successful LLM call."""
        # Estimate tokens (rough: ~4 chars/token)
        prompt_tokens = len(prompt) // 4
        completion_tokens = len(response) // 4

        client_info["last_minute"][mtype] += 1
        client_info["daily_used"][mtype] += 1
        client_info["calls"][mtype] += 1

        print(f"[LLM usage] {mtype} key={client_info['key']} calls={client_info['calls'][mtype]} "
              f"tokens_in={prompt_tokens} tokens_out={completion_tokens} "
              f"rpm={client_info['last_minute'][mtype]}/{client_info['rpm_limits'][mtype]} "
              f"daily={client_info['daily_used'][mtype]}/{client_info['daily_quotas'][mtype]}")

        # Persist state to disk
        self._persist_state(client_info)

    def _persist_state(self, client_info: Dict) -> None:
        """Persist quota state for a client to disk."""
        state = _load_quota_state()
        key_id = client_info["key"]
        if key_id not in state:
            state[key_id] = {}
        for mtype in self.MODEL_TYPES:
            state[key_id][f"daily_used_{mtype}"] = client_info["daily_used"][mtype]
            state[key_id][f"day_start_{mtype}"] = client_info["day_start"][mtype]
            state[key_id][f"exhausted_{mtype}"] = client_info["exhausted"][mtype]
            state[key_id][f"exhausted_at_{mtype}"] = client_info["exhausted_at"][mtype]
            state[key_id][f"disabled_{mtype}"] = client_info["disabled"][mtype]
        _save_quota_state(state)

    def _select_client(self, mtype: str) -> Optional[Tuple[Dict, str, object, int]]:
        """Select next available client for model type.
        Returns (client_info, model_name, client, selected_idx) or None.
        Does NOT advance index - caller must call _advance_index after successful use.
        """
        if not self._initialized:
            self.initialize()
        if not self._clients:
            return None

        with self._lock:
            now = time.time()
            start_idx = self._current_indices[mtype]
            num_clients = len(self._clients)

            # Reset windows for ALL clients
            for offset in range(num_clients):
                idx = (start_idx + offset) % num_clients
                client_info = self._clients[idx]
                self._reset_windows(client_info, mtype, now)

            # Find first available client
            for offset in range(num_clients):
                idx = (start_idx + offset) % num_clients
                client_info = self._clients[idx]

                if client_info["exhausted"][mtype] or client_info["disabled"][mtype]:
                    continue
                if client_info["last_minute"][mtype] >= client_info["rpm_limits"][mtype]:
                    continue
                if client_info["daily_used"][mtype] >= client_info["daily_quotas"][mtype]:
                    continue

                # Found available client - return selected index but DON'T advance yet
                # Caller will advance after successful API call to prevent race condition
                return client_info, client_info["model_names"][mtype], client_info["client"], idx

            # No client available
            self._current_indices[mtype] = 0
            return None

    def _advance_index(self, mtype: str, selected_idx: int) -> None:
        """Advance the rotation index after a successful API call."""
        with self._lock:
            # Only advance if we're still at the expected position (no other thread advanced it)
            if self._current_indices[mtype] == selected_idx:
                self._current_indices[mtype] = (selected_idx + 1) % len(self._clients)

    def _validate_model(self, mtype: str) -> None:
        """Validate model type and check Gemma restriction."""
        if mtype not in self.MODEL_TYPES:
            raise ValueError(f"Invalid model type: {mtype}. Must be one of {self.MODEL_TYPES}")
        if mtype in ("sql", "ans"):
            for c in self._clients:
                model_name = c["model_names"].get(mtype, "")
                if "gemma" in model_name.lower():
                    raise ValueError(
                        f"Gemma model ({model_name}) cannot be used for {mtype} generation. "
                        f"SQL/Answer generation requires Gemini 3.5 Flash-Lite (prompt ~24k tokens "
                        f"exceeds Gemma's 16k RPM limit). Set GEMINI_MODEL_{mtype.upper()}=gemini-3.5-flash-lite"
                    )

    def _call(self, mtype: str, system_prompt: str, user_prompt: str,
              temperature: float, stream: bool):
        """
        Unified completion/stream call with automatic key rotation.

        Args:
            mtype: Model type - "route", "sql", "ans", or "vision"
            system_prompt: System prompt
            user_prompt: User prompt
            temperature: Generation temperature
            stream: If True, yield chunks; if False, return full text
        """
        self._validate_model(mtype)

        if not self._initialized:
            self.initialize()
        if not self._clients:
            if stream:
                return
            return ""

        prompt = f"{system_prompt}\n\n{user_prompt}"
        num_clients = len(self._clients)
        max_attempts = num_clients * 3  # 3 full rotations (18 attempts for 6 keys) per CLAUDE.md spec

        for attempt in range(max_attempts):
            selected = self._select_client(mtype)
            if selected is None:
                break

            client_info, model_name, client, selected_idx = selected

            try:
                if stream:
                    stream_iter = client.models.generate_content_stream(
                        model=model_name,
                        contents=prompt,
                        config={"temperature": temperature}
                    )
                    parts = []
                    for chunk in stream_iter:
                        token = chunk.text or ""
                        if token:
                            parts.append(token)
                            yield token
                    full_text = "".join(parts)
                    if full_text:
                        self._record_usage(client_info, mtype, prompt, full_text)
                        self._advance_index(mtype, selected_idx)
                    return
                else:
                    resp = client.models.generate_content(
                        model=model_name,
                        contents=prompt,
                        config={"temperature": temperature}
                    )
                    text = (resp.text or "").strip()
                    if text:
                        self._record_usage(client_info, mtype, prompt, text)
                        self._advance_index(mtype, selected_idx)
                        return text

            except ClientError as e:
                if self._is_quota_error(e):
                    self.mark_exhausted(client_info, mtype)
                    time.sleep(0.2)
                    continue
                if self._is_auth_error(e):
                    self.mark_disabled(client_info, mtype)
                    err_msg = str(e).encode('ascii', 'replace').decode('ascii')
                    print(f"[GeminiKeyManager] {mtype} auth error - marking key disabled: {err_msg}")
                    continue
                err_msg = str(e).encode('ascii', 'replace').decode('ascii')
                print(f"[GeminiKeyManager] {mtype} {'stream' if stream else ''} error: {err_msg}")
            except Exception as e:
                if self._is_quota_error(e):
                    self.mark_exhausted(client_info, mtype)
                    time.sleep(0.2)
                    continue
                if self._is_auth_error(e):
                    self.mark_disabled(client_info, mtype)
                    err_msg = str(e).encode('ascii', 'replace').decode('ascii')
                    print(f"[GeminiKeyManager] {mtype} auth error - marking key disabled: {err_msg}")
                    continue
                err_msg = str(e).encode('ascii', 'replace').decode('ascii')
                print(f"[GeminiKeyManager] {mtype} {'stream' if stream else ''} error: {err_msg}")

            time.sleep(0.2)

        # All keys exhausted
        if stream:
            # Fallback to non-streaming for stream calls
            fallback = self._call(mtype, system_prompt, user_prompt, temperature, stream=False)
            if fallback:
                yield fallback
        return ""

    def complete(self, mtype: str, system_prompt: str, user_prompt: str,
                 temperature: float = 0.0) -> str:
        """Complete a prompt using the appropriate model with automatic key rotation."""
        # _call is a generator function; when stream=False, result is in StopIteration.value
        gen = self._call(mtype, system_prompt, user_prompt, temperature, stream=False)
        try:
            # Manually iterate to catch StopIteration.value
            while True:
                next(gen)
        except StopIteration as e:
            return e.value if e.value is not None else ""
        return ""

    def stream(self, mtype: str, system_prompt: str, user_prompt: str,
               temperature: float = 0.2):
        """Stream completion using the appropriate model with automatic key rotation."""
        yield from self._call(mtype, system_prompt, user_prompt, temperature, stream=True)

    def get_client_for_model(self, mtype: str) -> Optional[Tuple[Dict, str, object]]:
        """
        Get next available client for a specific model type.

        Returns: (client_dict, model_name, client_object) or None if all exhausted
        """
        if not self._initialized:
            self.initialize()

        if not self._clients:
            return None

        with self._lock:
            now = time.time()
            start_idx = self._current_indices[mtype]
            num_clients = len(self._clients)

            # First pass: reset windows for ALL clients (clears exhausted if day rolled over)
            for offset in range(num_clients):
                idx = (start_idx + offset) % num_clients
                client_info = self._clients[idx]
                self._reset_windows(client_info, mtype, now)

            # Second pass: find first available client
            for offset in range(num_clients):
                idx = (start_idx + offset) % num_clients
                client_info = self._clients[idx]

                # Skip if exhausted or disabled for this model type
                if client_info["exhausted"][mtype] or client_info["disabled"][mtype]:
                    continue

                # Check RPM limit
                if client_info["last_minute"][mtype] >= client_info["rpm_limits"][mtype]:
                    continue

                # Check daily quota
                if client_info["daily_used"][mtype] >= client_info["daily_quotas"][mtype]:
                    continue

                # Found available client - update index for NEXT call
                self._current_indices[mtype] = (idx + 1) % num_clients
                return client_info, client_info["model_names"][mtype], client_info["client"]

            # No client available - reset index to start for next call
            self._current_indices[mtype] = 0
            return None

    def mark_exhausted(self, client_info: Dict, mtype: str) -> None:
        """Mark a client as exhausted for a specific model type."""
        client_info["exhausted"][mtype] = True
        client_info["exhausted_at"][mtype] = time.time()
        print(f"[Quota] Key {client_info['key']} exhausted for {mtype}, rotating...")
        # Also persist the exhausted state
        self._persist_state(client_info)

    def mark_disabled(self, client_info: Dict, mtype: str) -> None:
        """Mark a client as permanently disabled for a specific model type (e.g., auth error)."""
        client_info["disabled"][mtype] = True
        print(f"[Auth] Key {client_info['key']} permanently disabled for {mtype} (service account invalid)")
        # Also persist the disabled state
        self._persist_state(client_info)


# Global singleton instance
_key_manager: Optional[GeminiKeyManager] = None


def get_key_manager() -> GeminiKeyManager:
    """Get the global GeminiKeyManager instance."""
    global _key_manager
    if _key_manager is None:
        _key_manager = GeminiKeyManager()
        _key_manager.initialize()
    return _key_manager


# Convenience functions for backward compatibility
def llm_route(system_prompt: str, user_prompt: str, temperature: float = 0.0) -> str:
    """Complete using the routing model."""
    return get_key_manager().complete("route", system_prompt, user_prompt, temperature)


def llm_sql(system_prompt: str, user_prompt: str, temperature: float = 0.0) -> str:
    """Complete using the SQL generation model."""
    return get_key_manager().complete("sql", system_prompt, user_prompt, temperature)


def llm_answer(system_prompt: str, user_prompt: str, temperature: float = 0.2) -> str:
    """Complete using the answer generation model."""
    return get_key_manager().complete("ans", system_prompt, user_prompt, temperature)


def llm_stream_answer(system_prompt: str, user_prompt: str, temperature: float = 0.2):
    """Stream using the answer generation model."""
    return get_key_manager().stream("ans", system_prompt, user_prompt, temperature)