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
    def to_markdown(cls, rows: List[List[str]], caption: Optional[str] = None) -> str:
        """
        Converts 2D array of strings into a clean Markdown table with optional caption.
        """
        if not rows or len(rows) == 0:
            return ""

        # Filter out completely empty rows
        cleaned_rows = []
        for row in rows:
            cleaned_row = [cls.clean_cell(cell) for cell in row]
            if any(cell != "" for cell in cleaned_row):
                cleaned_rows.append(cleaned_row)

        if not cleaned_rows:
            return ""

        # Normalize column count across all rows
        max_cols = max(len(r) for r in cleaned_rows)
        for r in cleaned_rows:
            while len(r) < max_cols:
                r.append("")

        header_row = cleaned_rows[0]
        separator_row = ["---"] * max_cols
        data_rows = cleaned_rows[1:] if len(cleaned_rows) > 1 else []

        md_lines = []
        if caption:
            md_lines.append(f"**{caption.strip()}**\n")

        md_lines.append("| " + " | ".join(header_row) + " |")
        md_lines.append("| " + " | ".join(separator_row) + " |")

        for row in data_rows:
            md_lines.append("| " + " | ".join(row) + " |")

        return "\n".join(md_lines)
