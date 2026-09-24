# Project Context

## Overview & Architecture
- **System**: Enterprise Human Resource Management (HRM) platform integrating Core HR, Biometric Face Attendance, RAG AI Assistant, and Automated Data Backups.
- **Architectural Pattern**:
  - **Backend**: Layered Architecture (`Controller` -> `Service` -> `Repository` / `Entity`) in Spring Boot.
  - **Frontend**: Component-Driven Next.js App Router with dual service & context data layers.
  - **AI Microservice**: FastAPI service implementing a modular RAG pipeline (Parser -> Chunker -> Enricher -> pgvector -> HybridRetriever -> Reranker -> LLM).
  - **Edge Biometrics**: Standalone Python module running OpenCV camera capture and face recognition.
- **Inter-service Communication**:
  - `Next.js -> Spring Boot`: REST API + Server-Sent Events (SSE) for streaming AI chat (`/api/ai/chat/stream`).
  - `Spring Boot -> AI Service`: Synchronous REST and reactive streaming (`ResponseBodyEmitter` via `HttpClient`), authenticated via shared `X-Internal-Secret` header.
  - `Check Attendance -> Spring Boot`: HTTP REST calls (`PUT /api/attendances/{userId}`, `PUT /api/overtime/{userId}`) for clock-in/out, plus direct PostgreSQL connection for face embeddings.
  - `n8n`: Docker-compose automated workflows monitoring container health and PostgreSQL WAL/physical backups.

---

## Repository Structure (Monorepo)
```text
HRM/
├── backend/                  # Java 21 / Spring Boot 4 REST API
│   ├── src/main/java/com/minhtrung/hrm/
│   │   ├── admin/            # Account provisioning, session revocation
│   │   ├── ai/               # AI gateway client & SSE proxy
│   │   ├── attendance/       # Shift scheduling, daily check-in, timesheets
│   │   ├── auth/             # JWT auth, user sessions, client metadata
│   │   ├── common/           # RequestContext & ThreadLocal context holder
│   │   ├── configs/          # SecurityConfig, WebConfig
│   │   ├── dashboard/        # Executive & department metrics summary
│   │   ├── employees/        # Employee profiles, contracts, salary, org structure
│   │   ├── exceptions/       # GlobalExceptionHandler & typed domain errors
│   │   ├── filters/          # JwtAuthFilter, RateLimitFilter
│   │   ├── leave/            # Leave request workflows & approval chains
│   │   ├── overtime/         # Overtime records, approval, holiday management
│   │   ├── payroll/          # Monthly payroll calculations & payslips
│   │   ├── resignation/      # Resignation requests & asset transfer
│   │   └── services/         # FileStorageService (avatars)
│   └── pom.xml
├── HRM Website/              # Next.js 16 (React 19) Frontend
│   ├── src/app/              # Next.js App Router pages (admin, attendance, etc.)
│   ├── src/components/       # Layouts, AppShell, Navbar, Sidebar, Modals
│   ├── src/context/          # AuthContext, HRMDataContext
│   ├── src/services/         # apiClient.ts, domain service API wrappers
│   └── package.json
├── ai-service/               # Python FastAPI RAG Service
│   ├── main.py               # FastAPI entry point & PBAC document routes
│   ├── src/
│   │   ├── cache/            # Semantic caching (pgvector cosine search)
│   │   ├── chat/             # ChatService (Gemini, OpenAI, Ollama)
│   │   ├── chunkers/         # LegalChunker, TablePreserver
│   │   ├── embeddings/       # LocalEmbedder, GeminiEmbedder (768d)
│   │   ├── metadata/         # MetadataEnricher (LLM summary & hypothetical Qs)
│   │   ├── parsers/          # PDFParser, DOCXParser, ExcelParser
│   │   ├── rerankers/        # CrossEncoderReranker
│   │   └── retrievers/       # HybridRetriever (Vector + BM25/Fulltext)
│   ├── sql/                  # pgvector init scripts (chunks & semantic cache)
│   └── requirements.txt
├── Check Attendance/         # Edge Biometric Facial Attendance
│   ├── src/
│   │   ├── attendance.py     # Real-time webcam check-in with audio prompts
│   │   ├── register.py       # Employee face registration to PostgreSQL
│   │   └── cascades/         # YuNet ONNX & Haar Cascades models
│   └── requirements.txt
├── init-db/                  # Auto-init SQL scripts mounted in Docker
├── backups/                  # n8n backup/restore workflows & health scripts
├── docker-compose.yml        # Orchestration (DB, Redis, Backend, Web, n8n, Cloudflare)
└── postman.json              # Full API collection
```

---

## Tech Stack (By Service)

| Component | Language / Runtime | Framework / Core Libs | Database & Cache | Build Tool |
| :--- | :--- | :--- | :--- | :--- |
| **Backend** | Java 21 | Spring Boot 4.0.6, Spring Security, Spring Data JPA, JJWT 0.11.5, Apache POI 5.2.5, Thumbnailator 0.4.20 | PostgreSQL 17, Redis 7 | Maven 3.9+ |
| **Frontend** | TypeScript 5, Node 20+ | Next.js 16.3.4 (App Router), React 19.2.8, Tailwind CSS v4, Lucide React | Browser LocalStorage / Cookies | npm |
| **AI Service** | Python 3.10+ | FastAPI, Pydantic 2.7+, PyMuPDF, python-docx, openpyxl, sentence-transformers, PyTorch | PostgreSQL (pgvector 768d) | pip |
| **Check Attendance** | Python 3.10+ | OpenCV, face_recognition (dlib 128d), pygame (audio) | PostgreSQL (users table) | pip |
| **Infra / Ops** | Docker / Compose | PostgreSQL 17 + pgvector, Redis 7-alpine, n8n, cloudflared | Volume mounts | docker compose |

---

## Key Data Flows

### 1. Authentication & Token Refresh Flow
```text
[Client: Next.js] ---> POST /auth/login ---> [Spring Boot: AuthController]
                                                  │
                                                  ▼
                                            [AuthService] -> Verify BCrypt Password
                                                  │
                ◄--- Set-Cookie: refreshToken ────┼─── Return: { accessToken, ... }
                     (HttpOnly, 7 days)           │    (Validity: 15 mins)
                                                  ▼
                                            [UserSession] -> Stored in PostgreSQL
[Subsequent Requests]
Client (Bearer Token) ---> [JwtAuthFilter] ---> Verify JWT signature & Check Redis Blacklist
                             │
                             ├─ If Expired (401) ---> Client Interceptor triggers POST /auth/auto-login
                             └─ If Valid        ---> Set RequestContextHolder & proceed to Controller
```

### 2. AI Document Ingestion & RAG Query Flow
```text
[Document Upload (.pdf, .docx, .xlsx)]
     │
     ▼
[Spring Boot: AiController] --(X-Internal-Secret)--> [FastAPI: /api/v1/documents/upload]
                                                              │
   ┌──────────────────────────────────────────────────────────┘
   ▼
[IngestionPipeline]
   ├── 1. BaseParser (fitz, python-docx, openpyxl)
   ├── 2. LegalChunker (Table preserving & structural hierarchy)
   ├── 3. MetadataEnricher (LLM generates Summary, Keywords & Hypothetical Qs)
   └── 4. LocalEmbedder (Produces 768d vector)
   │
   ▼
[PostgreSQL: document_chunks] (pgvector HNSW index + GIN index for PBAC allowed_jobs/depts)

[User Chat Query (Streaming)]
Client ---> Spring Boot ---> FastAPI (/api/v1/chat/stream)
                               │
                               ├── 1. Check Semantic Cache (Cosine distance < threshold)
                               ├── 2. HybridRetriever (Dense Vector + Keyword Search with PBAC)
                               ├── 3. CrossEncoder Reranker
                               └── 4. LLM Generation (Gemini / OpenAI / Ollama)
                               │
                ◄── SSE Stream ┴── Spring Boot ResponseBodyEmitter ◄── FastAPI SSE
```

### 3. Biometric Attendance Flow
```text
[Webcam Stream] ---> [OpenCV + YuNet / Haar Cascade] ---> Detect Bounding Box
                                                              │
                                                              ▼
                                            [face_recognition: 128d vector]
                                                              │
                                                              ▼
                                            Compare Cosine Distance against users.face_embedding
                                                              │
                            ┌─────────────────────────────────┴─────────────────────────────────┐
                            ▼ Match (Distance < 0.40)                                           ▼ Unknown
                 PUT /api/attendances/{userId}                                              Play audio:
                 (Bypasses JWT filter)                                                      "face_not_registered.mp3"
                            │
                            ▼
                 [Spring Boot: AttendanceService]
                 ├── Validate active shift & working day
                 ├── Calculate late/early duration
                 └── Save Attendance entity
                            │
                            ▼
                 Play audio: "clock_in.mp3" / "clock_out.mp3"
```

---

## Database & Storage
- **PostgreSQL 17**:
  - **Extensions**: `vector` (pgvector), `pg_trgm` (fuzzy keyword search).
  - **Core Business Entities**: `users`, `user_profiles`, `user_contracts`, `salaries`, `user_bank_accounts`, `departments`, `jobs`, `work_shifts`, `work_shift_schedules`, `attendances`, `monthly_timesheets`, `leave_requests`, `holidays`, `overtime_records`, `payrolls`, `monthly_payroll_summaries`, `resignation_requests`, `pending_users`, `user_sessions`.
  - **AI Vector Tables**:
    - `knowledge_documents`: File metadata, status, PBAC rules.
    - `document_chunks`: Structural chunk content, metadata, `content_vector VECTOR(768)`, `questions_vector VECTOR(768)`, HNSW cosine index.
    - `semantic_cache`: `query_vector VECTOR(768)`, cached response, hit counter.
  - **Biometric Field**: `users.face_embedding` (128-dimensional float array).
- **Redis 7**:
  - Key `rate_limit:auth:<ip>`: Sliding rate limiting window for sensitive endpoints.
  - Key `blacklist:session:<sessionId>`: Active session invalidation on logout or admin revocation.
- **File System Storage**:
  - `./uploads/avatars/`: Compressed 500x500 WebP user profile pictures.
  - `./uploads/documents/`: Knowledge base documents uploaded for AI ingestion.

---

## API Conventions & Inter-service Communication
- **Base Paths**:
  - Auth: `/auth/**` (`/auth/login`, `/auth/auto-login`, `/auth/logout`, `/auth/change-password`)
  - Domain APIs: `/api/attendances`, `/api/work-shifts`, `/api/employees`, `/api/leave`, `/api/overtime`, `/api/payrolls`, `/api/resignations`, `/api/departments`, `/api/jobs`, `/api/dashboard`, `/api/admin`, `/api/ai`.
- **Headers & Security**:
  - External requests require `Authorization: Bearer <JWT>`.
  - Internal Spring Boot -> FastAPI requests require `X-Internal-Secret: <INTERNAL_API_SECRET>`.
  - Camera bypass: `PUT /api/attendances/{userId}` and `PUT /api/overtime/{userId}` bypass JWT filter for device-level automated clocking.
- **Response Format**:
  - Single Object: Standard JSON serialization of DTO.
  - Paginated: `{ "content": [...], "totalElements": N, "totalPages": M, "size": S, "number": P }`.
  - Errors: `{ "errorCode": "<CODE_STRING>", "msg": "<User-friendly explanation>", "errors": { "<field>": "<detail>" } }`.

---

## Coding Conventions
- **Backend**:
  - Domain-based packaging: `com.minhtrung.hrm.<module>.{controllers, services, repositories, entities, dtos, enums, exceptions}`.
  - Explicit constructor dependency injection via Lombok `@RequiredArgsConstructor` (no `@Autowired` field injection).
  - Strict input validation via Jakarta `@Valid`, `@NotBlank`, `@NotNull`, `@Min`.
  - Custom domain exceptions extending `RuntimeException` (e.g. `AttendanceException`, `PayrollException`) handled centrally in `GlobalExceptionHandler`.
- **Frontend**:
  - Strictly typed TypeScript definitions in `src/types/index.ts`.
  - Modular API clients centralized in `src/services/` wrapping `apiClient.ts`.
  - Semantic role checks (`isHR`, `isManager`, `isExecutive`, `isAdmin`) derived from `currentUser.department` and `currentUser.job`.
- **AI Service**:
  - Pydantic models for request/response serialization in `src/models/schema.py`.
  - Decoupled pipeline components with explicit interfaces (`BaseParser`, `LegalChunker`).

---

## Build, Run & Test Commands

### 1. Infrastructure (Docker)
```bash
# Start DB (Postgres + pgvector), Redis, and supporting containers
docker compose up -d hrm-database hrm-cache
```

### 2. Backend (Spring Boot)
```bash
cd backend
# Build without tests
mvn clean compile -DskipTests
# Run development server (Port 8080)
mvn spring-boot:run
# Run unit & integration tests
mvn test
```

### 3. Frontend (Next.js)
```bash
cd "HRM Website"
# Install dependencies
npm install
# Run development server (Port 3000)
npm run dev
# Build production bundle
npm run build
```

### 4. AI Service (FastAPI)
```bash
cd ai-service
# Install Python dependencies
pip install -r requirements.txt
# Run FastAPI server (Port 8000)
uvicorn main:app --reload --port 8000
# Run test suite
pytest
```

### 5. Check Attendance (Python)
```bash
cd "Check Attendance"
# Install requirements
pip install -r requirements.txt
# Run attendance camera listener
python src/attendance.py
```

---

## Environment Variables & Ports

| Service | Port | Configuration Files | Mandatory Variables (No Secrets) |
| :--- | :--- | :--- | :--- |
| **PostgreSQL** | `5432` | `.env.example`, `docker-compose.yml` | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| **Redis** | `6379` | `docker-compose.yml` | `REDIS_PORT` |
| **Backend** | `8080` | `application.properties`, `.env` | `server.port`, `spring.datasource.url`, `spring.data.redis.host`, `jwt.secret.access`, `jwt.secret.refresh`, `ai.service.base-url`, `ai.service.internal-secret` |
| **Frontend** | `3000` | `.env.local` | `NEXT_PUBLIC_API_URL`, `INTERNAL_BACKEND_URL` |
| **AI Service** | `8000` | `ai-service/.env.example` | `DATABASE_URL`, `INTERNAL_API_SECRET`, `LLM_PROVIDER`, `GEMINI_API_KEY`, `OLLAMA_BASE_URL`, `OPENAI_API_KEY` |
| **n8n** | `5678` | `docker-compose.yml` | `N8N_PORT`, `WEBHOOK_URL` |

---

## Important Constraints
1. **Dynamic Role Mapping**: Role hierarchy is derived dynamically from `department` and `job` (e.g., `Executive Leadership` = EXECUTIVE, `Human Resources` = HR, `Department Head` = MANAGER, `IT` + `System Administrator` = ADMIN). Code changes to user models must preserve this contract.
2. **Fixed Vector Dimensions**:
   - AI Document / Semantic Cache vectors: strictly **768 dimensions** (`VECTOR(768)`).
   - Biometric face vectors: strictly **128 dimensions** (dlib float array).
3. **PBAC Isolation for AI Knowledge Base**: Document chunks must always be filtered against `allowed_jobs` and `allowed_departments` arrays to prevent unauthorized data exposure across organizational boundaries.
4. **Camera Endpoint Exclusion**: Attendance check-in via camera must not require user JWT tokens to enable autonomous kiosk operation.
5. **Session Invalidation**: Password changes or administrative lock actions must synchronously write revoked status to DB `user_sessions` and write the session ID to Redis blacklist.

---

## Known Issues / Tech Debt
1. **Dual Frontend Data Layer**: `HRMDataContext.tsx` still maintains static mock fallback data (`MOCK_ATTENDANCES`, `MOCK_LEAVE_REQUESTS`, etc.) alongside live API services (`services/*.ts`), which can lead to UI divergence if API calls fail silently.
2. **Missing Entity Mapping for Biometrics**: The `face_embedding` column on the `users` table is not mapped in `User.java` (JPA Entity); it is currently read and updated only via raw SQL queries by the Python scripts.
3. **Heavy User-Agent Dependency**: `ClientInfoService` uses `nl.basjes.parse.useragent:yauaa` (15MB+ dependency, heavy startup memory) solely to extract browser and OS strings.
4. **Docker CLI Mount in n8n**: `docker-compose.yml` mounts `./bin/docker:/usr/bin/docker:ro` for container health monitoring, requiring a pre-existing host binary instead of packaging `docker-cli` inside a custom container image.
