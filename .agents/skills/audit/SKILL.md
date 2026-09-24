---
name: audit
description: Quét và phân tích codebase hiện tại để khởi tạo hoặc cập nhật file ngữ cảnh AGENTS.md, bao gồm cấu trúc project, tech stack, kiến trúc, data flow, coding conventions, cách chạy/test và các ràng buộc quan trọng.
---

# Audit

Quét codebase hiện tại để khởi tạo hoặc cập nhật file `AGENTS.md` tại thư mục gốc.

## Core Rules

1. **Read-only**: Tuyệt đối không sửa code, refactor hay migrate database trong quá trình audit. Chỉ tạo hoặc cập nhật `AGENTS.md`.
2. **Fact-driven**: Chỉ ghi nhận thông tin có bằng chứng từ code/config thực tế. Không suy đoán, không tin vẹt README. Nếu thiếu dữ liệu, ghi `Unknown`.
3. **No secrets**: Tuyệt đối không đưa mật khẩu, JWT secret, API key hay private tokens vào `AGENTS.md`.
4. **Preserve context**: Giữ lại các ghi chú viết tay còn đúng trong `AGENTS.md` hiện tại (nếu có).

## Scope & Exclusions

Bỏ qua các thư mục build, dependencies và dữ liệu tạm:
* `target/`, `build/`, `dist/`, `.next/`, `bin/`
* `node_modules/`, `venv/`, `.venv/`, `__pycache__/`
* `uploads/`, `backups/`, `logs/`, `.git/`, file nén (`.rar`, `.zip`)

## Workflow & Output Structure

Đọc code/config thực tế và tạo/cập nhật `AGENTS.md` tại root (~150 – 350 dòng) theo khung sau:

```markdown
# Project Context

## Overview & Architecture
- Tóm tắt hệ thống và architectural pattern (Layered, Clean, Hexagonal...).
- Giao tiếp giữa các service (REST API, SSE, Queue...).

## Repository Structure (Monorepo)
- Cây thư mục rút gọn cấp cao cho các sub-modules/services và entry points.

## Tech Stack (By Service)
- Liệt kê theo từng service: Language/Runtime version, Framework, Database, Cache, Build tool (dựa trên pom.xml, requirements.txt, package.json, docker-compose.yml).

## Key Data Flows
- Sơ đồ text/ASCII cho flow nghiệp vụ chính và các flow đặc thù (Auth/JWT, AI RAG, Attendance, SSE Streaming).

## Database & Storage
- RDBMS, NoSQL, Vector DB (pgvector), cơ chế migration (init-db, Flyway, Hibernate), các bảng/entity cốt lõi.

## API Conventions & Inter-service Communication
- Base path, routing, request/response format chuẩn, cơ chế phân quyền, giao tiếp nội bộ giữa các service.

## Coding Conventions
- Quy ước đặt tên, DTO/Entity, Dependency Injection, Validation, Exception handling.

## Build, Run & Test Commands
- Lệnh install, run dev, test của từng service và các container cần start trước.

## Environment Variables & Ports
- File cấu hình mẫu (.env.example), biến môi trường bắt buộc và port cục bộ của từng service (không ghi giá trị bí mật).

## Important Constraints
- Ràng buộc bất di bất dịch (API backward compatibility, vector dimension, logic phân quyền, transaction).

## Known Issues / Tech Debt
- Các vấn đề quan sát thấy trong thực tế (Fact-based).
```

Sau khi hoàn tất, ghi ra file `AGENTS.md` ở thư mục gốc và gửi tóm tắt ngắn cho user.
