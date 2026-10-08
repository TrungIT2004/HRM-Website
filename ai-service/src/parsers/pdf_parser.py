from pathlib import Path
from typing import List
import re

from src.models.schema import DocumentBlock, ParsedDocument
from src.chunkers.table_preserver import TablePreserver

import fitz  # PyMuPDF (requirements.txt pins pymupdf — no fallback needed)


class PDFParser:
    """
    Advanced PDF parser that preserves headings, paragraphs, and tables intact.
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
        return self._parse_with_pymupdf(Path(file_path))

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
                                page_number=page_num
                            ))
            except Exception:
                pass

            # 2. Extract text blocks
            text_page = page.get_text("blocks")
            page_blocks = 0
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
                page_blocks += 1

            # 3. OCR fallback cho trang scan (không bóc được chữ nào nhưng có ảnh)
            if page_blocks == 0 and page.get_images():
                ocr_text = _ocr_page_to_text(page)
                if ocr_text:
                    blocks.append(DocumentBlock(
                        block_type="PARAGRAPH",
                        content=ocr_text,
                        page_number=page_num
                    ))

        doc.close()
        clean_name = re.sub(r'^[a-fA-F0-9]{8,64}_', '', path.name)
        return ParsedDocument(
            document_name=clean_name,
            file_type="pdf",
            blocks=blocks
        )


def _ocr_page_to_text(page) -> str:
    """OCR một trang scan bằng Tesseract local (vie+eng). Cải thiện: psm 6, dpi 400, config tiếng Việt."""
    try:
        import io
        import os
        import shutil
        import pytesseract
        from PIL import Image, ImageFilter, ImageEnhance
    except ImportError:
        return ""
    if not shutil.which("tesseract"):
        win_default = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
        if os.path.exists(win_default):
            pytesseract.pytesseract.tesseract_cmd = win_default
        else:
            return ""
    try:
        # DPI 400 cho chất lượng tốt hơn
        png = page.get_pixmap(dpi=400).tobytes("png")
        img = Image.open(io.BytesIO(png))
        
        # Tiền xử lý nhẹ: tăng độ tương phản, làm nét
        img = ImageEnhance.Contrast(img).enhance(1.2)
        img = ImageEnhance.Sharpness(img).enhance(1.5)
        
        # Config Tesseract tối ưu tiếng Việt:
        # --psm 6: Assume a single uniform block of text
        # --oem 1: LSTM engine only (tốt hơn cho tiếng Việt)
        # -c preserve_interword_spaces=1: Giữ khoảng cách từ
        config = "--psm 6 --oem 1 -c preserve_interword_spaces=1"
        
        return (
            pytesseract.image_to_string(img, lang="vie", config=config)
            or ""
        ).strip()
    except Exception:
        return ""
