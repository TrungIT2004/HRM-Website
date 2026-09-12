# Thư mục khởi tạo Cơ sở dữ liệu tự động (Init DB)

Bạn hãy đặt file backup của mình (ví dụ: `backup.sql` hoặc bất kỳ file `.sql` nào) vào thư mục này:

```text
init-db/
  └── backup.sql
```

## Cách hoạt động:
* Khi bạn chạy `docker compose up -d` lần đầu tiên (khi volume `postgres_data` chưa có dữ liệu), PostgreSQL sẽ tự động quét thư mục này và nạp toàn bộ cấu trúc bảng, dữ liệu và vector khuôn mặt từ file `.sql` của bạn vào database.
* **Lưu ý**: Các file `.sql` trong thư mục này đã được cấu hình trong `.gitignore` để tránh bị vô tình commit dữ liệu nhạy cảm lên Git.
