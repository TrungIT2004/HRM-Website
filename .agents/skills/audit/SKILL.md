---
name: audit
description: Quét codebase hiện tại để khởi tạo file ngữ cảnh AGENTS.md. Dùng khi user muốn tạo tài liệu lưu trữ ngữ cảnh kiến trúc, tech stack và luồng dữ liệu cho dự án đang phát triển.
---

# Audit

Quét codebase hiện tại để khởi tạo file ngữ cảnh AGENTS.md.

## When to Use

- Khi bắt đầu làm việc với một codebase có sẵn nhưng chưa có file cấu hình.
- Khi cần tạo hoặc làm mới tài liệu lưu trữ ngữ cảnh kiến trúc, tech stack và luồng dữ liệu.

## Steps

1. **Không viết code.** Hãy quét toàn bộ thư mục và các file code chính yếu của dự án.
2. Phân tích tech stack, kiến trúc tổng thể, luồng dữ liệu (data flow) và các quy ước (coding conventions) đang có.
3. Viết đúc kết súc tích lại và lưu thẳng vào file `AGENTS.md` ở thư mục gốc.
4. Thông báo cho người dùng biết file đã được tạo và cập nhật thành công.
