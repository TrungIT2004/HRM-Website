from pathlib import Path
from typing import Dict, List, Optional
import docx
from docx.text.paragraph import Paragraph
from docx.table import Table
import re

from src.models.schema import DocumentBlock, ParsedDocument
from src.chunkers.table_preserver import TablePreserver


class DOCXParser:
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
        # ponytail: .docx has no rendered layout; Word-COM pagination (Windows-only,
        # needs pywin32 — absent in Docker/Linux) deleted. page_number=None, not fake 1.

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
                        page_number=None,
                        heading_level=level
                    ))
                else:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=text,
                        page_number=None
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
                        page_number=None
                    ))

        clean_name = re.sub(r'^[a-fA-F0-9]{8,64}_', '', path.name)

        # OCR mọi ảnh embedded (hình chụp văn bản, con dấu kẹp giữa các đoạn).
        # ponytail: ảnh append cuối, mất vị trí tương đối với đoạn văn; xen đúng
        # chỗ cần parse document.xml order (w:drawing vs w:p). Chỉ quét main part,
        # ảnh logo ở header/footer tự loại.
        for blob in _embedded_images(doc):
            text = _ocr_image_bytes(blob)
            if text:
                blocks.append(DocumentBlock(
                    block_type="PARAGRAPH",
                    content=text,
                    page_number=None
                ))

        return ParsedDocument(
            document_name=clean_name,
            file_type="docx",
            blocks=blocks
        )


def _embedded_images(doc) -> list:
    """Bytes các ảnh embedded duy nhất trong main document part."""
    blobs, seen = [], set()
    for rel in doc.part.rels.values():
        if rel.is_external:
            continue
        part = rel.target_part
        if not part.content_type.startswith("image/"):
            continue
        if str(part.partname) in seen:
            continue
        seen.add(str(part.partname))
        blobs.append(part.blob)
    return blobs


def _ocr_image_bytes(data: bytes) -> str:
    try:
        import io
        from PIL import Image
        from src.parsers.pdf_parser import ocr_pil_image_to_text
    except ImportError:
        return ""
    try:
        return ocr_pil_image_to_text(Image.open(io.BytesIO(data)))
    except Exception:
        return ""
