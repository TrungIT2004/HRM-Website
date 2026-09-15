from pathlib import Path
from typing import List
import openpyxl

from src.models.schema import DocumentBlock, ParsedDocument
from src.parsers.base_parser import BaseParser
from src.chunkers.table_preserver import TablePreserver


class ExcelParser(BaseParser):
    """
    Parser for Excel (.xlsx) files (salary tiers, KPI coefficients, leave matrices).
    Converts each sheet into structured markdown tables with sheet names as headers.
    """

    def parse(self, file_path: Path | str) -> ParsedDocument:
        path = Path(file_path)
        wb = openpyxl.load_workbook(path, data_only=True)
        blocks: List[DocumentBlock] = []

        for sheet_name in wb.sheetnames:
            sheet = wb[sheet_name]
            rows: List[List[str]] = []

            for row in sheet.iter_rows(values_only=True):
                # Convert row values to string
                str_row = [str(val).strip() if val is not None else "" for val in row]
                if any(val != "" for val in str_row):
                    rows.append(str_row)

            if rows:
                # Add sheet title as heading
                blocks.append(DocumentBlock(
                    block_type="HEADING",
                    content=f"Bảng dữ liệu: {sheet_name}",
                    page_number=1,
                    heading_level=1
                ))

                md_table = TablePreserver.to_markdown(rows, caption=f"Bảng tra cứu - {sheet_name}")
                if md_table:
                    blocks.append(DocumentBlock(
                        block_type="TABLE",
                        content=md_table,
                        page_number=1,
                        metadata={"sheet_name": sheet_name}
                    ))

        wb.close()
        return ParsedDocument(
            document_name=path.name,
            file_type="xlsx",
            total_pages=len(wb.sheetnames),
            blocks=blocks
        )
