---
name: architect
description: Thiết kế kiến trúc và giới hạn phạm vi tính năng mới. Dùng khi user yêu cầu phát triển tính năng mới nhưng cần chốt luồng xử lý và kế hoạch trước khi code thực tế.
---

# Architect

Thiết kế kiến trúc và giới hạn phạm vi tính năng mới trước khi viết code.

## When to Use

- Khi user đưa ra ý tưởng hoặc yêu cầu phát triển tính năng mới.
- Khi cần chốt luồng xử lý, cấu trúc dữ liệu và kế hoạch trước khi code thực tế.

## Steps

1. **Dừng lại, KHÔNG viết code ngay.**
2. Đọc file `AGENTS.md` (nếu có) để nắm vững bối cảnh hệ thống hiện tại.
3. Phỏng vấn user tối đa 3 câu hỏi ngắn gọn để làm rõ:
   - Đối tượng dùng là ai?
   - Phiên bản V1 (nhỏ nhất) có những gì?
   - Nguồn dữ liệu lấy từ đâu?
4. Chờ user trả lời. Sau đó đưa ra phương án thiết kế tốt nhất (database, logic) đồng bộ với hệ thống hiện tại.
5. Xác nhận lại với user. Chỉ bắt đầu code sau khi user duyệt bản thiết kế (hoặc khi user tự chuyển sang lệnh code bình thường).
