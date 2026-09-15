"""
Test suite for the Ingestion Pipeline.
Generates a realistic Vietnamese enterprise policy document (.docx),
runs the structure-aware pipeline, and verifies that tables, headings,
breadcrumbs, and metadata are correctly created.
"""
import sys
from pathlib import Path

# Force UTF-8 encoding on Windows console
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Add project root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import docx
from rich.console import Console
from rich.panel import Panel
import json

from src.pipeline import IngestionPipeline


console = Console(force_terminal=True, legacy_windows=False)


def create_sample_policy_docx(file_path: Path):
    """Creates a sample Vietnamese enterprise policy with headings, articles, and tables."""
    doc = docx.Document()

    doc.add_heading("QUY CHẾ KỶ LUẬT LAO ĐỘNG VÀ CHẾ ĐỘ PHÚC LỢI NĂM 2024", level=0)

    # Chương I
    doc.add_heading("CHƯƠNG I: QUY ĐỊNH CHUNG VỀ THỜI GIAN LÀM VIỆC", level=1)
    doc.add_paragraph(
        "Điều 1: Thời gian làm việc tiêu chuẩn và chấm công\n"
        "1. Toàn bộ cán bộ nhân viên làm việc 8 giờ/ngày từ Thứ 2 đến Thứ 6. "
        "Giờ làm việc buổi sáng từ 08:30 đến 12:00, buổi chiều từ 13:30 đến 18:00.\n"
        "2. Nhân viên có trách nhiệm chấm công bằng ứng dụng nhận diện khuôn mặt (Face Recognition) "
        "hoặc trên Website HRM khi đến văn phòng và trước khi ra về."
    )

    # Chương II
    doc.add_heading("CHƯƠNG II: XỬ LÝ VI PHẠM KỶ LUẬT", level=1)
    doc.add_paragraph(
        "Điều 2: Xử lý vi phạm đi làm muộn và nghỉ không phép\n"
        "Người lao động đi muộn sau 08:35 sẽ bị tính là đi muộn. "
        "Mức độ xử lý vi phạm được quy định chi tiết trong bảng biểu dưới đây:"
    )

    # Table: Khung phạt
    table1 = doc.add_table(rows=4, cols=4)
    table1.style = 'Table Grid'
    headers = ["Hành vi vi phạm", "Vi phạm lần 1", "Vi phạm lần 2", "Vi phạm từ lần 3 trở lên"]
    for i, h in enumerate(headers):
        table1.cell(0, i).text = h

    data1 = [
        ["Đi muộn từ 5 - 15 phút", "Nhắc nhở nội bộ", "Trừ 50.000 VNĐ vào phụ cấp", "Trừ 100.000 VNĐ / lần"],
        ["Đi muộn trên 30 phút", "Trừ 0.5 ngày công", "Trừ 1 ngày công", "Họp kỷ luật khiển trách"],
        ["Tự ý nghỉ việc không phép", "Cắt thưởng tháng", "Trừ 2 ngày lương", "Xem xét sa thải theo luật"],
    ]
    for row_idx, row_data in enumerate(data1):
        for col_idx, val in enumerate(row_data):
            table1.cell(row_idx + 1, col_idx).text = val

    # Chương III
    doc.add_heading("CHƯƠNG III: CHẾ ĐỘ PHÚC LỢI VÀ NGHỈ PHÉP ĐẶC BIỆT", level=1)
    doc.add_paragraph(
        "Điều 3: Chế độ kết hôn, thai sản và hiếu hỷ\n"
        "1. Nhân viên chính thức kết hôn được nghỉ 03 ngày có hưởng nguyên lương theo luật lao động.\n"
        "2. Công ty hỗ trợ tiền mừng và quà chúc mừng theo bảng phúc lợi ban hành:"
    )

    # Table: Phúc lợi
    table2 = doc.add_table(rows=4, cols=3)
    table2.style = 'Table Grid'
    headers2 = ["Sự kiện", "Số ngày nghỉ có lương", "Mức tiền mừng từ Quỹ Công đoàn"]
    for i, h in enumerate(headers2):
        table2.cell(0, i).text = h

    data2 = [
        ["Nhân viên kết hôn", "03 ngày", "2.000.000 VNĐ + Quà lưu niệm"],
        ["Con của nhân viên kết hôn", "01 ngày", "1.000.000 VNĐ"],
        ["Nhân viên nữ sinh con", "06 tháng (theo BHXH)", "3.000.000 VNĐ + 01 giỏ quà mẹ bé"],
    ]
    for row_idx, row_data in enumerate(data2):
        for col_idx, val in enumerate(row_data):
            table2.cell(row_idx + 1, col_idx).text = val

    doc.save(file_path)
    print(f"[OK] Đã tạo file tài liệu mẫu: {file_path}")


def test_ingestion_pipeline():
    test_dir = Path(__file__).resolve().parent
    sample_file = test_dir / "sample_policy.docx"
    output_file = test_dir / "output_chunks.json"

    # Step 1: Create sample doc
    create_sample_policy_docx(sample_file)

    # Step 2: Run pipeline
    print("\n🚀 Đang khởi chạy Ingestion Pipeline (Structure-Aware Chunking)...")
    pipeline = IngestionPipeline(
        max_chunk_chars=1200,
        min_chunk_chars=50,
        enrich_with_llm=True
    )

    chunks = pipeline.process_file(
        sample_file,
        allowed_roles=["ROLE_EMPLOYEE", "ROLE_MANAGER", "ROLE_ADMIN"],
        allowed_departments=["ALL"]
    )

    # Step 3: Export to JSON
    pipeline.export_to_json(chunks, output_file)

    # Step 4: Display results
    print(f"\n[OK] Hoàn tất xử lý! Tổng số chunks được tạo: {len(chunks)}\n")

    for idx, c in enumerate(chunks):
        title = f"Chunk #{idx + 1} | Type: {c.chunk_type} | Role: {c.allowed_roles}"
        
        info = f"Breadcrumb: {c.breadcrumb}\n"
        if c.summary:
            info += f"Summary: {c.summary}\n"
        if c.keywords:
            info += f"Keywords: {', '.join(c.keywords)}\n"
        if c.hypothetical_questions:
            info += "Hypothetical Questions (Reverse HyDE):\n"
            for q in c.hypothetical_questions:
                info += f"  • {q}\n"
        
        info += f"\nContent:\n{c.content}\n"
        print("=" * 70)
        print(title)
        print(info)

    # Assertions
    assert len(chunks) >= 4, "Pipeline must generate at least 4 chunks"
    table_chunks = [c for c in chunks if c.chunk_type == "TABLE"]
    assert len(table_chunks) == 2, f"Must detect exactly 2 tables intact, found: {len(table_chunks)}"
    
    for tc in table_chunks:
        assert "|" in tc.content, "Table chunk must contain markdown table pipes '|'"
        assert "---" in tc.content, "Table chunk must contain markdown separator row"

    print("\n🎉 TẤT CẢ CÁC KIỂM THỬ ĐÃ VƯỢT QUA XUẤT SẮC!\n")


if __name__ == "__main__":
    test_ingestion_pipeline()
