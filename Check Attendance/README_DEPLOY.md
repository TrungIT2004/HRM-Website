# Hướng dẫn chạy Script Chấm công trên Thiết bị ngoài (Edge Device)

Script này được thiết kế để chạy trên một máy tính có kết nối **Webcam** và **Loa** (ví dụ: máy tính bàn quầy lễ tân, laptop hoặc Raspberry Pi).

## 1. Yêu cầu môi trường
* Python 3.10 hoặc 3.11
* Cài đặt các thư viện trong `requirements.txt`:
  ```bash
  pip install -r requirements.txt
  ```

## 2. Cấu hình kết nối tới Server
Khi hệ thống Server đã bật qua Cloudflare Tunnel, bạn lấy đường link HTTPS từ log của container `cloudflared` (ví dụ: `https://cool-forest-123.trycloudflare.com`).

Trong file `src/attendance.py`:
Cập nhật 2 đường dẫn API trỏ tới domain Cloudflare của Server:
```python
# Thay vì localhost, trỏ tới domain Cloudflare:
SERVER_URL = "https://cool-forest-123.trycloudflare.com"

ATTENDANCE_API_URL = f"{SERVER_URL}/api/attendances"
OVERTIME_API_URL = f"{SERVER_URL}/api/overtime"
```

## 3. Chạy script
```bash
python src/attendance.py
```
* Bấm phím `m` để đổi chế độ (VÀO / RA / TĂNG CA).
* Bấm phím `q` để thoát chương trình.
