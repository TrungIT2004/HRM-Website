# HRM – Human Resource Management System

Hệ thống quản lý nhân sự toàn diện dành cho doanh nghiệp, bao gồm quản lý nhân viên, chấm công, nghỉ phép, tăng ca, tính lương và quy trình thôi việc.

---

## Tổng quan hệ thống

```
┌─────────────────────────────────────────────────────┐
│                   HRM System                        │
│                                                     │
│  ┌──────────────┐    ┌──────────────────────────┐  │
│  │  HRM Website │    │  Check Attendance        │  │
│  │  (Frontend)  │    │  (Face Recognition)      │  │
│  │  React/Next  │    │  Python + OpenCV         │  │
│  └──────┬───────┘    └────────────┬─────────────┘  │
│         │                         │                 │
│         └──────────┬──────────────┘                 │
│                    ▼                                 │
│         ┌──────────────────┐                        │
│         │   Backend API    │                        │
│         │  Spring Boot 3   │                        │
│         │  Java 17 · JWT   │                        │
│         └────┬────────┬────┘                        │
│              │        │                             │
│    ┌─────────▼──┐  ┌──▼──────┐                     │
│    │ PostgreSQL │  │  Redis  │                     │
│    │  Database  │  │ Cache   │                     │
│    └────────────┘  └─────────┘                     │
└─────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Backend
| Thành phần | Công nghệ |
|---|---|
| Framework | Spring Boot 3, Java 17 |
| Database | PostgreSQL |
| Cache / Session | Redis |
| Authentication | JWT (HS256) – Access Token 15 phút · Refresh Token 7 ngày |
| ORM | Spring Data JPA / Hibernate |
| Build tool | Maven |
| File storage | Local file system (`./uploads/`) |

### Frontend
| Thành phần | Công nghệ |
|---|---|
| Framework | React / Next.js |
| Thư mục | `HRM Website/` |

### Face Recognition (Chấm công nhận diện khuôn mặt)
| Thành phần | Công nghệ |
|---|---|
| Language | Python |
| Library | OpenCV, face_recognition |
| Thư mục | `Check Attendance/` |

---

## Tính năng chính

- 👤 **Quản lý nhân viên** – Hồ sơ, hợp đồng, lương, phân công phòng ban & ca làm
- 🕐 **Chấm công** – Clock in/out thủ công hoặc nhận diện khuôn mặt, tổng hợp bảng công tháng
- 🏖️ **Nghỉ phép** – Đăng ký, phê duyệt, trừ phép năm tự động
- ⏰ **Tăng ca** – Đăng ký, phê duyệt, tính giờ OT thực tế
- 💰 **Lương** – Tính lương tự động từ bảng công, thuế TNCN lũy tiến 7 bậc, bảo hiểm
- 📝 **Thôi việc** – Quy trình 2 cấp duyệt, tự động khóa tài khoản
- 📊 **Dashboard** – Tổng quan theo vai trò (nhân viên / quản lý / HR / Ban Giám Đốc)

---

## Cài đặt & Chạy Backend

### Yêu cầu hệ thống

| Phần mềm | Phiên bản tối thiểu |
|---|---|
| Java JDK | 17+ |
| Maven | 3.8+ |
| PostgreSQL | 13+ |
| Redis | 6+ |

---

### Bước 1 – Clone & cấu hình

```bash
# Vào thư mục backend
cd backend

# Copy file cấu hình mẫu
cp src/main/resources/application.properties.example \
   src/main/resources/application.properties
```

Mở `application.properties` và điền thông tin thực tế:

```properties
# Server
server.port=8080

# Database PostgreSQL
spring.datasource.url=jdbc:postgresql://localhost:5432/hrm_db
spring.datasource.username=postgres
spring.datasource.password=YOUR_PASSWORD

# Redis
spring.data.redis.host=localhost
spring.data.redis.port=6379

# JWT Secrets (tối thiểu 32 ký tự)
jwt.secret.access=your-super-long-access-secret-key-here
jwt.secret.refresh=your-super-long-refresh-secret-key-here

# File upload
file.upload-dir=./uploads
```

---

### Bước 2 – Tạo database

```sql
CREATE DATABASE hrm_db;
```

> Hibernate sẽ tự tạo bảng khi chạy lần đầu (`spring.jpa.hibernate.ddl-auto=update`).

---

### Bước 3 – Build & Chạy

```bash
# Chạy với Maven Wrapper (khuyến nghị)
./mvnw spring-boot:run

# Hoặc build trước rồi chạy
./mvnw clean package -DskipTests
java -jar target/hrm-*.jar
```

Server khởi động tại: **`http://localhost:8080`**

---

### Bước 4 – Seed dữ liệu mẫu (tuỳ chọn)

```bash
curl -X POST "http://localhost:8080/api/seeder/mock-data?year=2026&fromMonth=1&toMonth=8"
```

---

### Bước 5 – Kiểm tra

```bash
# Health check
curl http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@company.com","password":"password"}'
```

---

## Cấu trúc thư mục Backend

```
backend/src/main/java/com/minhtrung/hrm/
│
├── auth/                    # Đăng nhập, JWT, session
├── attendance/              # Chấm công, ca làm việc, bảng công tháng
├── leave/                   # Nghỉ phép
├── overtime/                # Tăng ca
├── payroll/                 # Bảng lương
├── resignation/             # Thôi việc
├── employees/               # Nhân viên, phòng ban, chức vụ
├── dashboard/               # Dashboard tổng quan
├── seeder/                  # Seed dữ liệu mẫu (dev)
│
├── configs/                 # Security, CORS, Web config
├── filters/                 # JWT filter, Rate limit filter
├── exceptions/              # Global exception handler
└── services/                # Shared services (file storage, ...)
```

---

## Phân quyền hệ thống

| Vai trò | Định nghĩa |
|---|---|
| **Nhân viên** | Tất cả user đã đăng nhập |
| **Manager** | `job` bắt đầu bằng `"Department Head"` |
| **HR** | `department = "Human Resources"` |
| **HR Head** | HR + `job` chứa `"Head"` |
| **Executive** | `department = "Executive Leadership"` |
| **Accounting** | `department` hoặc `job` chứa từ khóa kế toán/tài chính |

---

## Tài liệu

| Tài liệu | Link |
|---|---|
| 📄 **API Reference** | [docs/api-reference.md](./docs/api-reference.md) |
| ⚙️ **Cấu hình mẫu** | [application.properties.example](./backend/src/main/resources/application.properties.example) |

---

## Môi trường phát triển

### Chạy với Docker (tuỳ chọn)

```bash
# Khởi động PostgreSQL + Redis
docker run -d --name hrm-postgres \
  -e POSTGRES_DB=hrm_db \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 postgres:15

docker run -d --name hrm-redis \
  -p 6379:6379 redis:7
```

### Logging

Log được ghi ra console và file `logs/myapp.log`. Level mặc định:
- Root: `INFO`
- `com.minhtrung.hrm`: `DEBUG`

---

## Lưu ý

> ⚠️ **`/api/seeder/mock-data`** không có kiểm tra xác thực – chỉ dùng ở môi trường **development**. Tắt hoặc xóa endpoint này trước khi deploy production.
