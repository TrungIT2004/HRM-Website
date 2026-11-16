"""Self-check: tách bảng Excel theo nhóm dòng + định dạng số. Chạy: python tests/test_excel_slice.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.chunkers.table_preserver import TablePreserver
from src.parsers.excel_parser import ExcelParser


def test_short_table_unchanged():
    rows = [["STT", "Mã NV"], ["1", "EMP001"], ["2", "EMP002"]]
    assert len(TablePreserver.to_markdown_slices(rows, "B")) == 1
    assert TablePreserver.to_markdown_slices(rows, "B") == [TablePreserver.to_markdown(rows, "B")]


def test_header_only():
    assert len(TablePreserver.to_markdown_slices([["A", "B"]], "cap")) == 1


def test_empty():
    assert TablePreserver.to_markdown_slices([], "cap") == []
    assert TablePreserver.to_markdown_slices([["", ""], ["", ""]], "cap") == []


def test_slices_repeat_header_and_cover_all_rows():
    header = ["STT", "Mã NV", "Lương"]
    rows = [header] + [[str(i), f"EMP{i:03d}", str(i * 1000)] for i in range(1, 46)]
    parts = TablePreserver.to_markdown_slices(rows, "Bảng lương", max_data_rows=20)

    assert len(parts) == 3                                   # 45 dòng / 20 = 3 phần
    for p in parts:
        assert "| STT | Mã NV | Lương |" in p                # header lặp ở mọi phần
        assert "phần" in p
    # 20 + 20 + 5 dòng dữ liệu (đếm theo mã NV, không đụng hàng separator)
    assert parts[0].count("EMP") == 20
    assert parts[1].count("EMP") == 20
    assert parts[2].count("EMP") == 5
    for i in range(1, 46):                                   # không mất dòng nào
        assert any(f"EMP{i:03d}" in p for p in parts)
    # Dòng thiếu ô phải được đệm cho bảng vuông (không vỡ số cột)
    ragged = [["A", "B", "C"], ["1", "2"], ["3", "4", "5", "6"]]
    lines = TablePreserver.to_markdown(ragged, None).splitlines()
    assert len(lines) == 4                                  # header + separator + 2 dòng
    assert len({line.count("|") for line in lines}) == 1    # mọi dòng cùng số cột


def test_cell_number_formatting():
    f = ExcelParser._cell
    assert f(None) == ""
    assert f(21.0) == "21"          # openpyxl trả int qua float -> không được ra '21.0'
    assert f(30000000.0) == "30000000"
    assert f(1.5) == "1.5"
    assert f(7) == "7"
    assert f(" Phạm Thị Cúc ") == "Phạm Thị Cúc"


if __name__ == "__main__":
    for name, fn in sorted(globals().items()):
        if name.startswith("test_"):
            fn()
            print(f"  ok  {name}")
    print("all passed")
