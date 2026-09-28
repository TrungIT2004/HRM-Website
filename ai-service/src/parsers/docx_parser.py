from pathlib import Path
from typing import Dict, List, Optional
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

    WD_ACTIVE_END_PAGE = 3  # Word constant for the rendered page number of a range

    @staticmethod
    def _norm(text: str) -> str:
        return re.sub(r'\s+', ' ', text).strip()

    def _page_map(self, path: Path) -> List[tuple[str, int]]:
        """Let Word paginate the file, then read back each paragraph's real page number.

        .docx stores no rendered layout, so page numbers only exist after Word lays the
        document out. ponytail: requires Word + pywin32 on the host (Windows only);
        ceiling is per-paragraph Word COM latency. If Word is unavailable we return []
        and chunks fall back to page_number=None rather than a fake 1.
        """
        try:
            import win32com.client as win32
        except ImportError:
            return []

        word = None
        doc = None
        try:
            word = win32.DispatchEx("Word.Application")
            word.Visible = False
            word.DisplayAlerts = 0
            doc = word.Documents.Open(str(path.resolve()), ReadOnly=True)
            doc.Repaginate()
            pages = []
            for para in doc.Paragraphs:
                rng = para.Range
                text = self._norm(rng.Text.replace('\r', ' ').replace('\x07', ' '))
                if not text:
                    continue
                pages.append((text, int(rng.Information(self.WD_ACTIVE_END_PAGE))))
            return pages
        except Exception:
            return []
        finally:
            if doc is not None:
                doc.Close(False)
            if word is not None:
                word.Quit()

    def parse(self, file_path: Path | str) -> ParsedDocument:
        path = Path(file_path)
        doc = docx.Document(path)
        blocks: List[DocumentBlock] = []
        page_rows = self._page_map(path)
        cursor = 0

        def page_for(text: str) -> Optional[int]:
            """Advance through Word paragraphs until one matches, then return its page."""
            nonlocal cursor
            key = self._norm(text)
            for i in range(cursor, len(page_rows)):
                wt = page_rows[i][0]
                if wt == key or key.startswith(wt) or wt.startswith(key):
                    cursor = i + 1
                    return page_rows[i][1]
            return None

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
                        page_number=page_for(text),
                        heading_level=level
                    ))
                else:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=text,
                        page_number=page_for(text)
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
                        page_number=page_for(rows[0][0]) if rows else None
                    ))

        clean_name = re.sub(r'^[a-fA-F0-9]{8,64}_', '', path.name)
        known_pages = [b.page_number for b in blocks if b.page_number is not None]
        return ParsedDocument(
            document_name=clean_name,
            file_type="docx",
            total_pages=max(known_pages) if known_pages else 0,
            blocks=blocks
        )
