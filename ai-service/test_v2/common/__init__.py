"""Common test utilities and paths for test_v2."""

from pathlib import Path

# Root directory of ai-service (where src/ lives)
AI_SERVICE_ROOT = Path(__file__).resolve().parent.parent.parent

# Test data files (located in original tests/ directory)
TESTS_DIR = AI_SERVICE_ROOT / "tests"

DB_ONLY_HYBRID_QUESTIONS = TESTS_DIR / "db_only_hybrid_questions.json"
DB_ONLY_HYBRID_QUESTIONS_WITH_ANSWERS = TESTS_DIR / "db_only_hybrid_questions_with_answers.json"
DOC_ONLY_DATASET = TESTS_DIR / "DOC_ONLY" / "datasets" / "doc_only_120.csv"
DOC_ONLY_MEMORY_DATASET = TESTS_DIR / "DOC_ONLY" / "datasets" / "doc_only_memory_20x12.json"

# Benchmarks for text2sql evaluation
BENCHMARKS_DIR = AI_SERVICE_ROOT / "test_v2" / "text2sql" / "benchmarks"
HRM_DB_ONLY_BENCHMARK = BENCHMARKS_DIR / "hrm_db_only.jsonl"
HRM_DB_ONLY_SCHEMA = BENCHMARKS_DIR / "hrm_db_only-schema.json"

# Output directories
OUTPUT_DIR = AI_SERVICE_ROOT / "test_v2" / "outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def get_output_path(name: str) -> Path:
    """Get output file path in test_v2/outputs/"""
    return OUTPUT_DIR / name


def setup_test_env():
    """Setup common test environment: add ai-service to path, load .env, configure UTF-8."""
    import sys
    import os
    from dotenv import load_dotenv

    # Add ai-service root to Python path
    sys.path.insert(0, str(AI_SERVICE_ROOT))

    # Add test_v2 to Python path so `from common import ...` works
    sys.path.insert(0, str(AI_SERVICE_ROOT / "test_v2"))

    # Load environment variables
    load_dotenv(AI_SERVICE_ROOT / ".env")

    # Configure UTF-8 on Windows
    if sys.platform == "win32":
        try:
            sys.stdout.reconfigure(encoding="utf-8")
            sys.stderr.reconfigure(encoding="utf-8")
        except Exception:
            pass


# Test user ID for DB_ONLY evaluations
TEST_UID = "d47d452a-3459-4e3f-84f5-e9df27f9125b"  # Dang Thanh Khai, joined 2026-01-02

# Gold UID used in gold SQL queries (literal UUID)
GOLD_UID = "35337165-e0d0-4dd1-9c67-cc48180363af"

# Evaluation user for RAG tests
EVAL_USER = "EVAL_RAGAS"

# Thresholds for retrieval evaluation (updated 2026-11-15 for embeddinggemma-300m)
RELEVANCE_THRESHOLD = 0.65  # from chat_service.py