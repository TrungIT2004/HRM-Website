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

            # 3. OCR mọi trang có ảnh (kể cả trang đã bóc được chữ:
            # chữ trong ảnh/con dấu/chữ ký chỉ OCR mới đọc được).
            # ponytail: logo/header/footer mỗi trang tốn 1 Vision call + text trùng lặp;
            # lọc ảnh decorative theo bbox-area nếu bill đau.
            if page.get_images():
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


_VISION_PROMPT = (
    "Transcribe văn bản tiếng Việt trong ảnh này CHÍNH XÁC từng ký tự. "
    "Giữ nguyên dấu thanh điệu, số hiệu văn bản, ngày tháng, mã biểu mẫu. "
    "Chữ viết tay cũng đọc cho đúng. Giữ cấu trúc đoạn văn. "
    "Chỉ trả về nội dung transcription, không thêm lời bình nào."
)


def _ocr_page_to_text(page) -> str:
    """Render trang PDF thành ảnh rồi OCR (Vision chính, EasyOCR fallback)."""
    try:
        import io
        from PIL import Image
    except ImportError:
        return ""
    try:
        png = page.get_pixmap(dpi=300).tobytes("png")
        img = Image.open(io.BytesIO(png))
    except Exception:
        return ""
    return ocr_pil_image_to_text(img)


def ocr_pil_image_to_text(img) -> str:
    """OCR 1 ảnh PIL bất kỳ (trang PDF render hay ảnh embedded DOCX).
    Dùng chung cho PDF/DOCX nên để public trong module này, không file mới.
    ponytail: cache Vision theo hash ảnh (uploads/.ocr_cache, đã gitignore) —
    quota chỉ đốt 1 lần duy nhất cho mỗi ảnh, ingest sau reuse miễn phí/tức thì.
    EasyOCR chạy local/miễn phí nên cache luôn (deterministic, ingest lại không tốn)."""
    import hashlib
    import io as _io
    import os
    digest = ""
    try:
        buf = _io.BytesIO()
        img.save(buf, format="PNG")
        digest = hashlib.sha256(buf.getvalue()).hexdigest()
    except Exception:
        pass
    if digest:
        try:
            hit = _ocr_cache_path(digest).read_text(encoding="utf-8").strip()
            if hit:
                return hit
        except Exception:
            pass
    text = _vision_ocr(img)
    # ponytail: OCR_ONLY_GEMINI=1 -> chi Gemini 3.5 Flash Lite, khong EasyOCR (test quota tinh).
    if not text and not os.getenv("OCR_ONLY_GEMINI"):
        text = _easyocr_pil_image(img)
    if text:
        if digest:
            try:
                _ocr_cache_path(digest).write_text(text, encoding="utf-8")
            except Exception:
                pass
        return text
    return ""


def _ocr_cache_path(digest: str):
    import os
    from pathlib import Path
    d = Path(os.getenv("OCR_CACHE_DIR", "uploads/.ocr_cache"))
    d.mkdir(parents=True, exist_ok=True)
    return d / f"{digest}.txt"


# Free-tier Vision: goi thua thi chet, goi le thi song (do duoc: pace 20s van
# 429 hang loat, single probe thi qua). Pace 45s chu khong dam chac 100% —
# transient server-error khong ai bao dam duoc; day la leo thang tu bang chung.
# Chinh qua env VISION_MIN_GAP khi doi goi. ponytail: pace chu dong thay vi ban
# don roi retry — retry ben duoi chi con la luoi an toan. Ceiling: full 7 file
# ~140 anh x 45s ~= 105 phut, chia nhieu lan chay (ingest idempotent + cache
# giu tien do). Muon nhanh: tra phi hoac song song hoa theo key (viec khac).
_VISION_MIN_GAP = 45.0
_last_vision_ts = 0.0


def _vision_ocr(img) -> str:
    """Gemini Vision, trả "" khi lỗi để caller fallback. Model qua env
    GEMINI_OCR_MODEL vì tên model Gemini đổi liên tục.
    ponytail: retry 429 (rate-limit free tier theo phút) với backoff, tối đa
    ~1 phút/page; lỗi khác fail-fast. Muốn ingest nhanh hơn thì nâng gói
    trả phí hoặc giảm dpi render ở caller."""
    import os
    import time

    import google.generativeai as genai

    key = os.getenv("GEMINI_API_KEY")
    if not key:
        print("[OCR] Vision failed (thieu GEMINI_API_KEY), fallback EasyOCR.")
        return ""
    genai.configure(api_key=key)
    model_name = os.getenv("GEMINI_OCR_MODEL", "models/gemini-flash-latest")
    try:
        from google.generativeai.types import HarmCategory, HarmBlockThreshold
        _safety = [{"category": c, "threshold": HarmBlockThreshold.BLOCK_NONE}
                   for c in (
                       HarmCategory.HARM_CATEGORY_HARASSMENT,
                       HarmCategory.HARM_CATEGORY_HATE_SPEECH,
                       HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
                       HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT)]
    except Exception:
        _safety = None
    model = genai.GenerativeModel(model_name, safety_settings=_safety)
    min_gap = float(os.getenv("VISION_MIN_GAP", str(_VISION_MIN_GAP)))
    global _last_vision_ts
    # ponytail: toi da 1 retry sau 90s (transient 429). Retry them chi them
    # failed-reqs len dashboard ma khong cuu duoc page; loi khac fail-fast.
    for attempt, wait in ((1, 0), (2, 90)):
        try:
            if wait:
                time.sleep(wait)
            gap = min_gap - (time.monotonic() - _last_vision_ts)
            if gap > 0:
                time.sleep(gap)
            _last_vision_ts = time.monotonic()
            res = model.generate_content(
                [_VISION_PROMPT, img], request_options={"timeout": 180})
            text = (res.text or "").strip()
            if text:
                print(f"[OCR] Vision OK in {time.monotonic() - _last_vision_ts:.1f}s ({len(text)} chars).")
            return text
        except Exception as e:  # noqa: BLE001
            err = str(e)
            if "429" not in err or attempt == 2:
                print(f"[OCR] Vision failed ({err}), fallback EasyOCR.")
                return ""
            print(f"[OCR] Vision 429, retry sau {wait}s (lan {attempt}/2)...")


_easyocr_reader = None
_easyocr_gpu = True


def _easyocr_pil_image(img) -> str:
    """Fallback offline khi Vision lỗi: EasyOCR tiếng Việt (local, miễn phí).
    ponytail: singleton Reader (nap 1 lan cho ca batch); het VRAM thi rebuild
    CPU 1 lan roi chay tiep thay vi chet page. Ceiling: CPU cham gap 5-10x."""
    global _easyocr_reader, _easyocr_gpu
    try:
        import easyocr
        import numpy as np
    except ImportError:
        return ""
    for _ in range(2):
        try:
            if _easyocr_reader is None:
                _easyocr_reader = easyocr.Reader(["vi", "en"], gpu=_easyocr_gpu)
            arr = np.array(img.convert("RGB"))
            out = _easyocr_reader.readtext(arr)
            return "\n".join(t.strip() for _, t, _ in out if t and t.strip()).strip()
        except Exception as e:
            print(f"[OCR] EasyOCR failed (gpu={_easyocr_gpu}): {e}.")
            _easyocr_reader, _easyocr_gpu = None, False
    return ""
