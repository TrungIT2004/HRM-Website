from pathlib import Path
from typing import List
import re

from src.models.schema import DocumentBlock, ParsedDocument
from src.parsers.base_parser import BaseParser
from src.chunkers.table_preserver import TablePreserver

try:
    import fitz  # PyMuPDF
    HAS_PYMUPDF = True
except ImportError:
    HAS_PYMUPDF = False

try:
    import pypdf
    HAS_PYPDF = True
except ImportError:
    HAS_PYPDF = False


class PDFParser(BaseParser):
    """
    Advanced PDF parser that preserves headings, paragraphs, and tables intact.
    Supports PyMuPDF (fitz) for table detection and pypdf as a reliable fallback.
    """

    HEADING_PATTERNS = [
        (re.compile(r'^(CHƯƠNG|Chương)\s+([IVXLCDM\d]+)[:\.\s]*(.*)$', re.IGNORECASE), 1),
        (re.compile(r'^(PHẦN|Phần)\s+([IVXLCDM\d]+)[:\.\s]*(.*)$', re.IGNORECASE), 1),
        (re.compile(r'^(MỤC|Mục)\s+(\d+)[:\.\s]*(.*)$', re.IGNORECASE), 2),
        (re.compile(r'^(ĐIỀU|Điều)\s+(\d+)[:\.\s]*(.*)$', re.IGNORECASE), 2),
        (re.compile(r'^(Khoản|\d+)\.\s+(.*)$'), 3),
    ]

    def _is_heading(self, text: str, font_size: float = 0.0) -> tuple[bool, int]:
        stripped = text.strip()
        for pattern, level in self.HEADING_PATTERNS:
            if pattern.match(stripped):
                return True, level
        if font_size >= 14 and len(stripped) < 120 and not stripped.endswith('.'):
            return True, 1
        return False, 0

    def parse(self, file_path: Path | str) -> ParsedDocument:
        path = Path(file_path)

        if HAS_PYMUPDF:
            return self._parse_with_pymupdf(path)
        elif HAS_PYPDF:
            return self._parse_with_pypdf(path)
        else:
            raise ImportError("Neither PyMuPDF nor pypdf is installed. Please install pypdf or PyMuPDF.")

    def _parse_with_pymupdf(self, path: Path) -> ParsedDocument:
        doc = fitz.open(path)
        blocks: List[DocumentBlock] = []

        for page_idx in range(len(doc)):
            page = doc[page_idx]
            page_num = page_idx + 1

            # 1. Extract and preserve tables
            table_bboxes = []
            try:
                tables = page.find_tables()
                for table in tables:
                    table_bboxes.append(fitz.Rect(table.bbox))
                    extracted_data = table.extract()
                    if extracted_data and len(extracted_data) > 0:
                        md_table = TablePreserver.to_markdown(
                            extracted_data, 
                            caption=f"Bảng biểu (Trang {page_num})"
                        )
                        if md_table:
                            blocks.append(DocumentBlock(
                                block_type="TABLE",
                                content=md_table,
                                page_number=page_num,
                                metadata={"bbox": list(table.bbox)}
                            ))
            except Exception:
                pass

            # 2. Extract text blocks
            text_page = page.get_text("blocks")
            for b in text_page:
                x0, y0, x1, y1, text, block_no, block_type = b
                if block_type != 0:
                    continue

                rect = fitz.Rect(x0, y0, x1, y1)
                if any(rect.intersects(tbox) for tbox in table_bboxes):
                    continue

                cleaned_text = text.strip()
                if not cleaned_text:
                    continue

                is_head, level = self._is_heading(cleaned_text)
                if is_head:
                    blocks.append(DocumentBlock(
                        block_type="HEADING",
                        content=cleaned_text,
                        page_number=page_num,
                        heading_level=level
                    ))
                else:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=cleaned_text,
                        page_number=page_num
                    ))

        total_pages = len(doc)
        doc.close()
        clean_name = re.sub(r'^[a-fA-F0-9]{8,64}_', '', path.name)
        return ParsedDocument(
            document_name=clean_name,
            file_type="pdf",
            total_pages=total_pages,
            blocks=blocks
        )

    def _parse_with_pypdf(self, path: Path) -> ParsedDocument:
        reader = pypdf.PdfReader(path)
        blocks: List[DocumentBlock] = []

        for page_idx, page in enumerate(reader.pages):
            page_num = page_idx + 1
            raw_text = page.extract_text() or ""
            paragraphs = raw_text.split("\n\n")

            for p in paragraphs:
                cleaned = p.strip()
                if not cleaned:
                    continue

                is_head, level = self._is_heading(cleaned)
                if is_head:
                    blocks.append(DocumentBlock(
                        block_type="HEADING",
                        content=cleaned,
                        page_number=page_num,
                        heading_level=level
                    ))
                else:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=cleaned,
                        page_number=page_num
                    ))

        clean_name = re.sub(r'^[a-fA-F0-9]{8,64}_', '', path.name)
        return ParsedDocument(
            document_name=clean_name,
            file_type="pdf",
            total_pages=len(reader.pages),
            blocks=blocks
        )
