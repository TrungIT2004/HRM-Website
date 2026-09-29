"""
Table Preserver: Ensures tables from PDF, Word, and Excel are preserved intact as Markdown tables.
Prevents tabular policy data (salary tiers, leave matrix, penalty fees) from being sliced and broken.
"""
from typing import List, Optional
import re


class TablePreserver:
    @staticmethod
    def clean_cell(cell: Optional[str]) -> str:
        """Sanitizes text inside a table cell to avoid breaking Markdown table format."""
        if cell is None:
            return ""
        text = str(cell).strip()
        # Replace newlines with space or <br>
        text = re.sub(r'\s*\n\s*', ' ', text)
        # Escape pipe characters
        text = text.replace('|', '\\|')
        return text

    @classmethod
    def _clean_rows(cls, rows: List[List[str]]):
        """Bỏ dòng rỗng + cân bằng số cột. Trả về (cleaned_rows, max_cols)."""
        cleaned_rows = []
        for row in rows:
            cleaned_row = [cls.clean_cell(cell) for cell in row]
            if any(cell != "" for cell in cleaned_row):
                cleaned_rows.append(cleaned_row)

        if not cleaned_rows:
            return [], 0

        max_cols = max(len(r) for r in cleaned_rows)
        for r in cleaned_rows:
            while len(r) < max_cols:
                r.append("")
        return cleaned_rows, max_cols

    @classmethod
    def _render(cls, header_row: List[str], max_cols: int, data_rows: List[List[str]], caption: Optional[str]) -> str:
        md_lines = []
        if caption:
            md_lines.append(f"**{caption.strip()}**\n")
        md_lines.append("| " + " | ".join(header_row) + " |")
        md_lines.append("| " + " | ".join(["---"] * max_cols) + " |")
        for row in data_rows:
            md_lines.append("| " + " | ".join(row) + " |")
        return "\n".join(md_lines)

    @classmethod
    def to_markdown(cls, rows: List[List[str]], caption: Optional[str] = None) -> str:
        """
        Converts 2D array of strings into a clean Markdown table with optional caption.
        """
        cleaned_rows, max_cols = cls._clean_rows(rows)
        if not cleaned_rows:
            return ""

        header_row = cleaned_rows[0]
        data_rows = cleaned_rows[1:] if len(cleaned_rows) > 1 else []
        return cls._render(header_row, max_cols, data_rows, caption)

    @classmethod
    def to_markdown_slices(
        cls,
        rows: List[List[str]],
        caption: Optional[str] = None,
        max_data_rows: int = 20
    ) -> List[str]:
        """
        Cắt bảng dài thành nhiều bảng con, mỗi bảng con LẶP LẠI hàng header.

        Vì sao: một bảng 500 dòng nguyên khối tạo ra đúng 1 vector, nên cả chân
        cosine lẫn ts_rank_cd đều bị loãng và không câu hỏi nào có định danh cụ thể
        (mã NV, tên, kỳ lương) chạm được vào đúng chunk.

        Bảng ngắn (<= max_data_rows) vẫn trả về đúng 1 phần như cũ, nên không đổi hành vi.
        """
        cleaned_rows, max_cols = cls._clean_rows(rows)
        if not cleaned_rows:
            return []

        header_row = cleaned_rows[0]
        data_rows = cleaned_rows[1:] if len(cleaned_rows) > 1 else []

        if not data_rows or max_data_rows <= 0 or len(data_rows) <= max_data_rows:
            return [cls._render(header_row, max_cols, data_rows, caption)]

        total = (len(data_rows) + max_data_rows - 1) // max_data_rows
        slices: List[str] = []
        for i in range(0, len(data_rows), max_data_rows):
            part_no = i // max_data_rows + 1
            label = f"phần {part_no}/{total}"
            part_caption = f"{caption} ({label})" if caption else f"({label})"
            slices.append(cls._render(header_row, max_cols, data_rows[i:i + max_data_rows], part_caption))
        return slices

