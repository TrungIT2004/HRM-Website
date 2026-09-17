from pathlib import Path
from typing import List
import docx
from docx.text.paragraph import Paragraph
from docx.table import Table
import re

from src.models.schema import DocumentBlock, ParsedDocument
from src.parsers.base_parser import BaseParser
from src.chunkers.table_preserver import TablePreserver


class DOCXParser(BaseParser):
    """
    Parser for Word (.docx) documents.
    Preserves heading hierarchy, tables, and paragraphs in their natural order.
    """

    HEADING_PATTERNS = [
        (re.compile(r'^(CHƯƠNG|Chương)\s+([IVXLCDM\d]+)[:\.\s]*(.*)$', re.IGNORECASE), 1),
        (re.compile(r'^(PHẦN|Phần)\s+([IVXLCDM\d]+)[:\.\s]*(.*)$', re.IGNORECASE), 1),
        (re.compile(r'^(MỤC|Mục)\s+(\d+)[:\.\s]*(.*)$', re.IGNORECASE), 2),
        (re.compile(r'^(ĐIỀU|Điều)\s+(\d+)[:\.\s]*(.*)$', re.IGNORECASE), 2),
    ]

    def _is_heading(self, text: str, style_name: str) -> tuple[bool, int]:
        style = style_name.lower()
        if "heading 1" in style or "tiêu đề 1" in style:
            return True, 1
        if "heading 2" in style or "tiêu đề 2" in style:
            return True, 2
        if "heading 3" in style or "tiêu đề 3" in style:
            return True, 3

        stripped = text.strip()
        # Headings that are not explicitly styled should be concise (title-like, <= 100 chars)
        # If longer, it's a paragraph that starts with 'Điều X...' containing actual policy text
        if len(stripped) > 100 and not ("heading" in style or "tiêu đề" in style):
            return False, 0

        for pattern, level in self.HEADING_PATTERNS:
            if pattern.match(stripped):
                return True, level
        return False, 0

    def parse(self, file_path: Path | str) -> ParsedDocument:
        path = Path(file_path)
        doc = docx.Document(path)
        blocks: List[DocumentBlock] = []

        # Iterate through document body elements in document order
        for element in doc.element.body:
            if element.tag.endswith('p'):
                p = Paragraph(element, doc)
                text = p.text.strip()
                if not text:
                    continue

                is_head, level = self._is_heading(text, p.style.name)
                if is_head:
                    blocks.append(DocumentBlock(
                        block_type="HEADING",
                        content=text,
                        page_number=1,
                        heading_level=level
                    ))
                else:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=text,
                        page_number=1
                    ))
            elif element.tag.endswith('tbl'):
                t = Table(element, doc)
                rows = []
                for row in t.rows:
                    cells = [cell.text.strip() for cell in row.cells]
                    rows.append(cells)
                md_table = TablePreserver.to_markdown(rows, caption="Bảng biểu quy định")
                if md_table:
                    blocks.append(DocumentBlock(
                        block_type="TABLE",
                        content=md_table,
                        page_number=1
                    ))

        return ParsedDocument(
            document_name=path.name,
            file_type="docx",
            total_pages=1,
            blocks=blocks
        )
