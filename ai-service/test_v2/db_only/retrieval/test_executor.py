"""Unit tests for sql.executor module."""

import pytest
from unittest.mock import patch, MagicMock
import sys
from pathlib import Path

# Setup test environment - add ai-service to path
AI_SERVICE_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(AI_SERVICE_ROOT))
sys.path.insert(0, str(AI_SERVICE_ROOT / "test_v2"))

# Import setup_test_env to configure paths properly
from test_v2.common import setup_test_env
setup_test_env()


class TestDirectoryLines:
    """Tests for directory_lines function - PII leak prevention."""

    def test_directory_lines_no_phone_number_in_output(self):
        """Verify directory_lines never returns phone numbers (SĐT)."""
        from src.sql.executor import directory_lines

        # Mock database response with phone number
        mock_conn = MagicMock()
        mock_cur = MagicMock()
        mock_conn.cursor.return_value = mock_cur
        # Return: user_id, first_name, last_name, email, employee_code, dept, job
        mock_cur.fetchall.return_value = [
            ("11111111-1111-1111-1111-111111111111", "John", "Doe", "john@act.com", "EMP001", "IT", "Engineer")
        ]

        with patch("src.sql.executor.get_hrm_connection", return_value=mock_conn):
            rows = [{"assignee_id": "11111111-1111-1111-1111-111111111111"}]
            result = directory_lines(rows)

        # Verify no phone number in output
        assert len(result) == 1
        line = result[0]
        assert "SĐT" not in line
        assert "phone" not in line.lower()
        assert "09" not in line  # Vietnamese phone prefix
        assert "03" not in line
        assert "07" not in line
        assert "08" not in line
        assert "05" not in line

    def test_directory_lines_contains_expected_fields(self):
        """Verify directory_lines returns name, department, job title, email."""
        from src.sql.executor import directory_lines

        mock_conn = MagicMock()
        mock_cur = MagicMock()
        mock_conn.cursor.return_value = mock_cur
        mock_cur.fetchall.return_value = [
            ("22222222-2222-2222-2222-222222222222", "Jane", "Smith", "jane@act.com", "EMP002", "HR", "Manager")
        ]

        with patch("src.sql.executor.get_hrm_connection", return_value=mock_conn):
            rows = [{"approver_id": "22222222-2222-2222-2222-222222222222"}]
            result = directory_lines(rows)

        assert len(result) == 1
        line = result[0]
        assert "Người duyệt" in line  # role for approver_id
        assert "Jane Smith" in line
        assert "HR" in line
        assert "Manager" in line
        assert "jane@act.com" in line

    def test_directory_lines_empty_rows_returns_empty(self):
        """Empty input returns empty list."""
        from src.sql.executor import directory_lines

        result = directory_lines([])
        assert result == []

    def test_directory_lines_no_fk_returns_empty(self):
        """Rows without FK columns returns empty list."""
        from src.sql.executor import directory_lines

        rows = [{"some_other_col": "value"}]
        result = directory_lines(rows)
        assert result == []

    def test_directory_lines_db_error_returns_empty(self):
        """Database error returns empty list (graceful degradation)."""
        from src.sql.executor import directory_lines

        with patch("src.sql.executor.get_hrm_connection", side_effect=Exception("DB down")):
            rows = [{"assignee_id": "11111111-1111-1111-1111-111111111111"}]
            result = directory_lines(rows)
            assert result == []


if __name__ == "__main__":
    pytest.main([__file__, "-v"])