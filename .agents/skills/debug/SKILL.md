---
name: debug
description: Truy vết và giải quyết nguyên nhân gốc rễ (root cause) của lỗi. Dùng khi code bị crash, lỗi UI hoặc không chạy đúng chức năng.
---

# Debug

Truy vết và giải quyết nguyên nhân gốc rễ (root cause) của lỗi.

## When to Use

- Khi app bị crash, có lỗi logic, hoặc giao diện không chạy đúng chức năng.
- Khi user gửi log lỗi và yêu cầu fix bug.

## Steps

1. **KHÔNG sửa mò (vibes debugging). KHÔNG đề xuất file code mới ngay lập tức.**
2. Đọc lỗi và yêu cầu user cung cấp cách tái hiện lỗi (reproduce step by step).
3. Cô lập vùng code gây ra lỗi. Chỉ đặt 1 giả thuyết duy nhất về nguyên nhân gốc rễ.
4. Chỉ sửa 1 điểm liên quan đến giả thuyết đó. Đề xuất cách test để kiểm chứng xem lỗi đã hết chưa.
5. Nếu user báo vẫn lỗi, **vứt bỏ hoàn toàn bản sửa đó** và đưa ra giả thuyết thứ 2. Tuyệt đối không sửa đắp thêm code mới lên bản code đang lỗi.
