# HRM – Human Resource Management System

Hệ thống quản lý nhân sự toàn diện cho doanh nghiệp: quản lý nhân viên, chấm công
(nhận diện khuôn mặt), ca làm, nghỉ phép, tăng ca, tính lương, tài sản, IT ticket,
đánh giá KPI, thôi việc và trợ lý AI tra cứu quy chế nội bộ.

---

## Kiến trúc

```text
Next.js (HRM Website) ──REST/SSE──> Spring Boot API ──> PostgreSQL 17 + pgvector
                                            │            Redis 7
                                            │
Check Attendance (OpenCV) ──REST──> Spring Boot
        │
        └── đọc face_embedding (128d) trực tiếp từ PostgreSQL

Spring Boot ──REST/SSE (X-Internal-Secret)──> FastAPI AI Service
                                                    │
                                                    └──> pgvector (768d) + Hybrid Search
```

| Thành phần | Thư mục | Vai trò |
|---|---|---|
| Backend API | `backend/` | Nghiệp vụ HRM, xác thực, phân quyền, gateway cho AI service |
| Frontend | `HRM Website/` | Giao diện Next.js cho toàn bộ nghiệp vụ |
| AI Service | `ai-service/` | RAG pipeline: parse → chunk → embed → retrieve → rerank → LLM |
| Check Attendance | `Check Attendance/` | Kiosk chấm công bằng khuôn mặt (OpenCV + dlib) |
| Hạ tầng | `docker-compose.yml`, `init-db/`, `backups/` | PostgreSQL, Redis, n8n backup, Cloudflare tunnel |

---

## Tech Stack

### Backend
| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ / Framework | Java 21, Spring Boot 4.0.6 |
| Bảo mật | Spring Security, JWT (JJWT 0.11.5) – access 15 phút, refresh 7 ngày |
| ORM | Spring Data JPA / Hibernate, JPA Specification |
| Database | PostgreSQL 17 (pgvector, pg_trgm) |
| Cache / Session | Redis 7 (session blacklist, rate limiting) |
| File & báo cáo | Local storage (`./uploads/`), Apache POI (Excel), Thumbnailator (WebP) |
| Build | Maven 3.9+ |

### Frontend
| Thành phần | Công nghệ |
|---|---|
| Framework | Next.js 16.3.4 (App Router), React 19.2.8 |
| Ngôn ngữ / Style | TypeScript 5, Tailwind CSS 4, Lucide React |
| Thư mục | `HRM Website/` |

### AI Service
| Thành phần | Công nghệ |
|---|---|
| Framework | FastAPI, Python 3.10+ |
| Vector DB | PostgreSQL + pgvector, `VECTOR(768)`, HNSW cosine index |
| Embedding | `google/embeddinggemma-300m` (offline, GPU/CPU) |
| Retrieval | Hybrid Search (dense vector + full-text tiếng Việt), Cross-Encoder rerank `BAAI/bge-reranker-base` |
| LLM | Gemini, OpenAI hoặc Ollama (cấu hình qua `LLM_PROVIDER`) |
| Parser | PyMuPDF, python-docx, openpyxl, EasyOCR |

### Check Attendance
| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ | Python 3.10+ |
| Thư viện | OpenCV, face_recognition (dlib 128d), pygame, psycopg2 |
| Model | YuNet ONNX + Haar Cascade |

---

## Tính năng chính

- **Nhân viên & tổ chức** – hồ sơ, hợp đồng, lương, tài khoản ngân hàng, phòng ban, chức vụ, điều chuyển.
- **Chấm công & ca làm** – clock in/out thủ công hoặc khuôn mặt, ca làm và lịch ca, tính đi muộn/về sớm, bảng công tháng, cron job chốt công hằng ngày.
- **Nghỉ phép** – đăng ký, phê duyệt nhiều cấp, trừ phép năm.
- **Tăng ca** – đăng ký, phê duyệt, tính giờ OT thực tế và quản lý ngày lễ.
- **Lương** – tính từ bảng công, thuế TNCN lũy tiến 7 bậc, bảo hiểm, xuất Excel.
- **Tài sản** – danh mục, cấp phát/thu hồi, bảo trì, kiểm kê.
- **IT ticket** – tạo và xử lý yêu cầu hỗ trợ nội bộ.
- **Đánh giá KPI** – phiếu đánh giá theo kỳ và phòng ban.
- **Thôi việc** – quy trình 2 cấp duyệt, bàn giao tài sản, khóa tài khoản.
- **Quản trị hệ thống** – duyệt tài khoản, khóa/mở khóa, reset mật khẩu, thu hồi phiên, phân quyền theo phòng ban/chức danh.
- **Trợ lý AI RAG** – hỏi đáp quy chế, streaming SSE, multi-turn, quản lý tài liệu PDF/DOCX/XLSX, phân quyền theo tài liệu (PBAC).
- **Dashboard** – tổng quan theo vai trò: nhân viên, quản lý, HR, ban giám đốc.
- **Backup & giám sát** – n8n workflow sao lưu PostgreSQL, kiểm tra container health.

---

## Cấu trúc repository

```text
HRM/
├── backend/                  # Spring Boot API
├── HRM Website/              # Next.js frontend
├── ai-service/               # FastAPI RAG service
├── Check Attendance/         # Kiosk chấm công khuôn mặt
├── init-db/                  # SQL dump nạp tự động khi tạo volume Postgres
├── backups/                  # n8n workflow backup / restore / monitoring
├── docs/                     # api-reference.md
├── diagrams/                 # Sơ đồ kiến trúc, ERD, luồng nghiệp vụ (HTML)
├── docker-compose.yml
└── postman.json
```

---

## Chạy nhanh bằng Docker Compose

Yêu cầu: Docker Desktop.

```bash
# 1. Tạo file môi trường và điền giá trị thật
cp .env.example .env

# 2. Khởi động toàn bộ hệ thống
docker compose up -d --build
```

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8080 |
| Swagger UI | http://localhost:8080/swagger-ui/index.html |
| AI Service | http://localhost:8001 (host) → 8000 (container) |
| n8n | http://localhost:5678 |

Lưu ý:
- Các file `.sql` trong `init-db/` bị ignore vì chứa dữ liệu nhạy cảm. Nếu cần dữ liệu mẫu, đặt dump vào `init-db/` trước lần khởi động đầu tiên; Hibernate sẽ tự tạo schema `hrm` khi DB trống (`ddl-auto=update`).
- AI service dùng database riêng `hrm_ai`. Tạo DB này và bật extension `vector`, `pg_trgm` (xem `ai-service/sql/init_db.sql` hoặc `init-db/02_hrm_ai.sql` nếu có).
- File `.env` không được commit. Dùng `.env.example` làm mẫu và đổi toàn bộ secret mặc định.

---

## Chạy từng service (môi trường dev)

### 1. Backend

Yêu cầu: JDK 21, Maven 3.9+, PostgreSQL 17, Redis 7.

```bash
cd backend
cp src/main/resources/application.properties.example src/main/resources/application.properties
```

Cấu hình tối thiểu trong `application.properties`:

```properties
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:5432/hrm
spring.datasource.username=postgres
spring.datasource.password=YOUR_PASSWORD
spring.data.redis.host=localhost
spring.data.redis.port=6379
jwt.secret.access=your-access-secret-at-least-32-chars
jwt.secret.refresh=your-refresh-secret-at-least-32-chars
file.upload-dir=./uploads
ai.service.base-url=http://localhost:8000
ai.service.internal-secret=YOUR_INTERNAL_SECRET
```

```bash
./mvnw spring-boot:run       # http://localhost:8080
./mvnw test                  # chạy test
```

### 2. Frontend

Yêu cầu: Node.js 20+.

```bash
cd "HRM Website"
npm install
```

Tạo `.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8080
INTERNAL_BACKEND_URL=http://localhost:8080
```

```bash
npm run dev                  # http://localhost:3000
npm run build                # build production
```

### 3. AI Service

Yêu cầu: Python 3.10+, PostgreSQL đã bật extension `vector`.

```bash
cd ai-service
python -m venv .venv
.venv\Scripts\activate       # Windows
pip install -r requirements.txt
cp .env.example .env         # điền DATABASE_URL, INTERNAL_API_SECRET, LLM_PROVIDER...
uvicorn main:app --reload --port 8000
pytest
```

Thiết lập DB: chạy lần lượt các file trong `ai-service/sql/` (`init_db.sql`, `create_semantic_cache.sql`, `add_tsv_column.sql`, `readonly_role.sql`).

### 4. Check Attendance

```bash
cd "Check Attendance"
pip install -r requirements.txt
python src/register.py       # đăng ký khuôn mặt → users.face_embedding
python src/attendance.py     # mở webcam chấm công
```

Kiosk gọi trực tiếp `PUT /api/attendances/{userId}` và `PUT /api/overtime/{userId}` (không yêu cầu JWT).

---

## Biến môi trường

### Docker Compose (`.env`)

| Biến | Mô tả |
|---|---|
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | Thông tin PostgreSQL |
| `REDIS_PORT`, `BACKEND_PORT`, `FRONTEND_PORT`, `AI_SERVICE_PORT`, `N8N_PORT` | Port publish ra host |
| `AI_SERVICE_SECRET` | Secret nội bộ giữa backend và AI service |
| `LLM_PROVIDER`, `OLLAMA_*`, `GEMINI_*`, `OPENAI_*` | Cấu hình LLM |

### Backend (`application.properties`)

| Biến | Mô tả |
|---|---|
| `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` | Kết nối DB |
| `SPRING_DATA_REDIS_HOST`, `SPRING_DATA_REDIS_PORT` | Kết nối Redis |
| `jwt.secret.access`, `jwt.secret.refresh` | Khóa ký JWT |
| `ai.service.base-url`, `ai.service.internal-secret` | Kết nối AI service |
| `file.upload-dir` | Thư mục lưu file upload |

### AI Service (`.env`)

| Biến | Mô tả |
|---|---|
| `DATABASE_URL` | PostgreSQL chứa `knowledge_documents`, `document_chunks`, `semantic_cache` |
| `HRM_DATABASE_URL` | Kết nối read-only cho Text-to-SQL |
| `INTERNAL_API_SECRET` | Phải khớp `ai.service.internal-secret` của backend |
| `LLM_PROVIDER`, `OLLAMA_MODEL`, `GEMINI_MODEL`, `OPENAI_MODEL` | Chọn LLM |
| `LOCAL_EMBEDDING_MODEL` | Model embedding 768 chiều |

---

## Phân quyền

Vai trò được suy ra động từ `department` và `job`, không lưu cứng trong bảng user:

| Vai trò | Điều kiện |
|---|---|
| Nhân viên | Mọi user đã đăng nhập |
| Manager | `job` bắt đầu bằng `Department Head` |
| HR | `department = Human Resources` |
| HR Head / Trưởng phòng | Chức danh chứa `Head`, `Chief` hoặc `Manager` |
| System Admin | `department = Information Technology` + `job` chứa `System Administrator` hoặc `Admin` |
| Executive | `department = Executive Leadership` |
| Accounting | Phòng ban/chức danh thuộc kế toán – tài chính |

Ngoài ra hệ thống có bảng `user_permission_grants` để cấp quyền bổ sung ngoài vai trò.

---

## Tài liệu

| Tài liệu | Link |
|---|---|
| API Reference | [docs/api-reference.md](./docs/api-reference.md) |
| Cấu hình mẫu backend | [application.properties.example](./backend/src/main/resources/application.properties.example) |
| Postman collection | [postman.json](./postman.json), [HRM_AI_Postman_Collection.json](./HRM_AI_Postman_Collection.json) |
| Sơ đồ kiến trúc / ERD | [diagrams/](./diagrams/) |
| Quy ước & ngữ cảnh codebase | [AGENTS.md](./AGENTS.md) |

---

## Lưu ý vận hành

- Endpoint chấm công bằng camera (`PUT /api/attendances/{userId}`, `PUT /api/overtime/{userId}`) bỏ qua JWT để kiosk hoạt động tự động. Chỉ expose trong mạng nội bộ.
- `spring.jpa.hibernate.ddl-auto=update` chỉ phù hợp môi trường dev; production nên dùng migration.
- Log ghi ra console và `logs/myapp.log`; package `com.minhtrung.hrm` ở mức `DEBUG`.
- Không commit `.env`, `application.properties`, dump SQL hay thư mục `uploads/`.
