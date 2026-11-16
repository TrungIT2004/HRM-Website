"""OCR review: render 6 PDF RAG-Test-Docs (dpi=300 giong pipeline) -> EasyOCR -> 1 .txt/doc.
Khong ghi DB. De nguoi doc tay truoc khi ingest lai.
Chay: python tests/retrieval_doc_only/ocr_easyocr_review.py
Output: tests/retrieval_doc_only/ocr_review/<ten-file>.txt (ngan trang).
"""
import io
import sys
import time
from pathlib import Path

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

DOCS_DIR = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế")
OUT_DIR = Path(__file__).resolve().parent / "ocr_review"
PDFS = [
    "214.HD-ACT-HC Hướng dẫn vv Đăng ký xe đi công tác.pdf",
    "917.QĐ-ACT_Quyết định ban hành Quy định về công tác đăng ký, điều phối xe và sử dụng xe trong Công ty Cổ phần Viễn thông ACT.pdf",
    "QT.ACT.HC-05 Quy trình quản lý văn phòng phẩm, vệ sinh phẩm và mực in.pdf",
    "QuyCheQuanTri-EVNFinance.pdf",
    "QuyCheQuanTri-MWG.pdf",
    "QuyCheQuanTri-Petrolimex-PMSC.pdf",
]


def main() -> None:
    import fitz
    from PIL import Image
    from src.parsers.pdf_parser import _easyocr_pil_image

    OUT_DIR.mkdir(exist_ok=True)
    for name in PDFS:
        out = OUT_DIR / (Path(name).stem + ".txt")
        if out.exists():  # chay lai bo qua file xong (timeout giua chung khong mat cong)
            print(f"SKIP (da co): {out.name}")
            continue
        doc = fitz.open(DOCS_DIR / name)
        t0 = time.time()
        parts = []
        for i, page in enumerate(doc):
            png = page.get_pixmap(dpi=300).tobytes("png")
            img = Image.open(io.BytesIO(png))
            text = _easyocr_pil_image(img)
            parts.append(f"===== Trang {i + 1}/{len(doc)} =====\n{text}")
            print(f"[{name[:30]}] trang {i + 1}/{len(doc)} ({len(text)} chars)", flush=True)
        out.write_text("\n\n".join(parts), encoding="utf-8")
        print(f"-> {out} ({len(doc)} trang, {time.time()-t0:.0f}s)")


if __name__ == "__main__":
    main()
