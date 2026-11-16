"""
Shared LLM Completion Utilities

Single source of truth for all LLM completion calls across the codebase.
Eliminates duplicate code paths between standalone eval and chat service.
"""
from dotenv import load_dotenv
load_dotenv()

from src.utils.gemini_key_manager import get_key_manager

_key_manager = get_key_manager()


def complete_sql(system_prompt: str, user_prompt: str, temperature: float = 0.0, **kwargs) -> str:
    """Complete using the SQL generation model (gemini-3.5-flash-lite)."""
    return _key_manager.complete("sql", system_prompt, user_prompt, temperature=temperature)


def complete_answer(system_prompt: str, user_prompt: str, temperature: float = 0.2, **kwargs) -> str:
    """Complete using the answer generation model (gemini-3.5-flash-lite)."""
    return _key_manager.complete("ans", system_prompt, user_prompt, temperature=temperature)


def complete_router(system_prompt: str, user_prompt: str, temperature: float = 0.0, **kwargs) -> str:
    """Complete using the routing model (gemma-4-31b-it)."""
    return _key_manager.complete("route", system_prompt, user_prompt, temperature=temperature)


def stream_answer(system_prompt: str, user_prompt: str, temperature: float = 0.2, **kwargs):
    """Stream using the answer generation model."""
    yield from _key_manager.stream("ans", system_prompt, user_prompt, temperature=temperature)