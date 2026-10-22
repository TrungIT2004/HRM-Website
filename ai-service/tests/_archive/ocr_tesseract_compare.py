"""Test Tesseract cải tiến trên 1 file PDF."""
import sys
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

PDF_PATH = Path(r"C:\Users\ad\Desktop\RAG-Test-Docs\Tài liệu doanh nghiệp thực tế\214.HD-ACT-HC Hướng dẫn vv Đăng ký xe đi công tác.pdf")

print("[Tesseract Improved] Testing...")

import fitz
doc = fitz.open(PDF_PATH)
page = doc[0]

import io, os, shutil, pytesseract
from PIL import Image, ImageFilter, ImageEnhance

if not shutil.which("tesseract"):
    win_default = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(win_default):
        pytesseract.pytesseract.tesseract_cmd = win_default

png = page.get_pixmap(dpi=400).tobytes("png")
img = Image.open(io.BytesIO(png))
img = ImageEnhance.Contrast(img).enhance(1.2)
img = ImageEnhance.Sharpness(img).enhance(1.5)

config = "--psm 6 --oem 1 -c preserve_interword_spaces=1"
text = pytesseract.image_to_string(img, lang="vie", config=config).strip()

print("=== PAGE 1 (improved Tesseract) ===")
print(text[:3000])
print(f"\nTotal chars: {len(text)}")

# So sánh với Tesseract cũ (dpi 300, vie+eng, no config)
png_old = page.get_pixmap(dpi=300).tobytes("png")
img_old = Image.open(io.BytesIO(png_old))
text_old = pytesseract.image_to_string(img_old, lang="vie+eng").strip()
print("\n=== PAGE 1 (OLD Tesseract) ===")
print(text_old[:3000])
print(f"\nTotal chars: {len(text_old)}")

# So sánh từ khóa quan trọng
for kw in ["đăng ký", "công tác", "xe", "phòng hành chính", "quy trình"]:
    c_new = text.lower().count(kw)
    c_old = text_old.lower().count(kw)
    print(f"  '{kw}': improved={c_new}, old={c_old}")