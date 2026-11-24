# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HRM – Human Resource Management System** is a comprehensive enterprise HR system built as a microservices architecture:

- **Backend API**: Spring Boot 4.0.6 (Java 21) – core business logic, auth, gateway for AI
- **Frontend**: Next.js 16.3.4 (App Router, React 19, TypeScript, Tailwind CSS 4)
- **AI Service**: FastAPI (Python 3.10+) – RAG pipeline with hybrid search, streaming chat
- **Check Attendance**: Python kiosk (OpenCV + dlib 128d face embeddings) for face-recognition clock-in
- **Infrastructure**: Docker Compose (PostgreSQL 17 + pgvector, Redis 7, n8n, Cloudflare tunnels)

---

## Key Commands

### Docker Compose (Full Stack)
```bash
# 1. Copy env template and fill in real values
cp .env.example .env

# 2. Start all services
docker compose up -d --build

# Services:
# Frontend:      http://localhost:3000
# Backend API:   http://localhost:8080
# Swagger UI:    http://localhost:8080/swagger-ui/index.html
# AI Service:    http://localhost:8001 (host) → 8000 (container)
# n8n:           http://localhost:5678
```

### Backend (Spring Boot)
```bash
cd backend
cp src/main/resources/application.properties.example src/main/resources/application.properties
# Edit application.properties with DB/Redis/JWT/AI config
./mvnw spring-boot:run          # http://localhost:8080
./mvnw test                     # run tests
./mvnw clean package -DskipTests # build JAR
```

### Frontend (Next.js)
```bash
cd "HRM Website"
npm install
# Create .env.local with NEXT_PUBLIC_API_URL, INTERNAL_BACKEND_URL
npm run dev                     # http://localhost:3000
npm run build                   # production build
npm run lint                    # eslint
```

### AI Service (FastAPI)
```bash
cd ai-service
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
cp .env.example .env            # fill DATABASE_URL, INTERNAL_API_SECRET, LLM_PROVIDER...
uvicorn main:app --reload --port 8000
pytest                          # run tests
```

### Check Attendance (Face Recognition Kiosk)
```bash
cd "Check Attendance"
pip install -r requirements.txt
python src/register.py          # register face → users.face_embedding
python src/attendance.py        # open webcam for clock-in
# Kiosk calls PUT /api/attendances/{userId} and PUT /api/overtime/{userId} (no JWT required)
```

### Database Setup (AI Service)
```bash
# Run SQL files in order:
psql -d hrm_ai -f ai-service/sql/init_db.sql
psql -d hrm_ai -f ai-service/sql/create_semantic_cache.sql
psql -d hrm_ai -f ai-service/sql/add_tsv_column.sql
psql -d hrm_ai -f ai-service/sql/readonly_role.sql
```

---

## Architecture & Data Flow

```
Next.js (HRM Website) ──REST/SSE──> Spring Boot API ──> PostgreSQL 17 + pgvector
                                            │            Redis 7
                                            │
Check Attendance (OpenCV) ──REST──> Spring Boot
        │
        └── reads face_embedding (128d) directly from PostgreSQL

Spring Boot ──REST/SSE (X-Internal-Secret)──> FastAPI AI Service
                                                    │
                                                    └──> pgvector (768d) + Hybrid Search
```

### Database Separation
- **hrm** (PostgreSQL): Main business data (employees, attendance, payroll, assets, etc.)
- **hrm_ai** (PostgreSQL + pgvector): RAG knowledge base – `knowledge_documents`, `document_chunks`, `semantic_cache`

### Authentication & Authorization
- **Spring Boot**: JWT (JJWT 0.11.5) – access 15 min, refresh 7 days
- **Roles derived dynamically** from `department` + `job` (not stored in user table):
  - Employee: any authenticated user
  - Manager: job starts with "Department Head"
  - HR: department = "Human Resources"
  - HR Head/Trưởng phòng: job contains "Head", "Chief", or "Manager"
  - System Admin: department = "Information Technology" + job contains "System Administrator"/"Admin"
  - Executive: department = "Executive Leadership"
  - Accounting: finance-related dept/job
- **PBAC (Policy-Based Access Control)** on AI documents via `allowed_departments` array
- **Internal API Secret**: `X-Internal-Secret` header between Spring Boot ↔ FastAPI

---

## Important Files & Config

| File | Purpose |
|------|---------|
| `.env` | Docker Compose secrets (DB, Redis, AI keys, ports) |
| `.env.example` | Template for `.env` |
| `backend/src/main/resources/application.properties` | Spring Boot config |
| `backend/src/main/resources/application.properties.example` | Template |
| `ai-service/.env` | FastAPI config (DATABASE_URL, LLM_PROVIDER, INTERNAL_API_SECRET) |
| `ai-service/.env.example` | Template |
| `HRM Website/.env.local` | Next.js config (NEXT_PUBLIC_API_URL) |
| `docker-compose.yml` | Full stack orchestration |
| `init-db/01_hrm.sql` | Main DB schema + seed data |
| `init-db/02_hrm_ai.sql` | AI DB schema (pgvector, pg_trgm) |
| `ai-service/sql/*.sql` | AI service migrations |
| `postman.json` | Full API collection |
| `HRM_AI_Postman_Collection.json` | AI service specific collection |

---

## AI Service (RAG Pipeline) Details

### Ingestion Flow (`ai-service/src/pipeline.py`)
1. **Parse** by extension: PDF (PyMuPDF), DOCX (python-docx), XLSX (openpyxl), OCR fallback (EasyOCR)
2. **Chunk** with `LegalChunker` – structure-aware, preserves tables & hierarchy (~1500 chars)
3. **Enrich** with LLM (Ollama Cloud): summary, keywords, hypothetical questions
4. **Embed** with `LocalEmbedder` (google/embeddinggemma-300m, 768d, offline GPU/CPU)
5. **Store** in PostgreSQL: `document_chunks` with `content_vector` + `questions_vector` (HNSW cosine index)

### Retrieval & Chat (`ai-service/src/chat/chat_service.py`)
- **Hybrid Search**: Dense vector (Gemini 768d) + Full-text search (tsvector Vietnamese)
- **Rerank**: Cross-Encoder `BAAI/bge-reranker-base`
- **LLM Providers**: Gemini, OpenAI, or Ollama (config via `LLM_PROVIDER`)
- **Streaming SSE**: Real-time token streaming with citations
- **Conversational Memory**: Context summary + last 6 messages, auto-title generation

### Key AI Service Endpoints
| Endpoint | Auth | Description |
|----------|------|-------------|
| `POST /api/v1/documents/upload` | X-Internal-Secret | Upload document → background processing |
| `PUT /api/v1/documents/{id}` | X-Internal-Secret | Update/replace document |
| `GET /api/v1/documents` | X-Internal-Secret | List with PBAC filtering |
| `GET /api/v1/documents/{id}/download` | X-Internal-Secret + PBAC | Secure download via Spring Boot gateway |
| `POST /api/v1/chat/query` | X-Internal-Secret | Non-streaming RAG query |
| `POST /api/v1/chat/stream` | X-Internal-Secret | Streaming SSE RAG query |
| `GET/POST/PUT/DELETE /api/v1/chat/conversations/*` | X-Internal-Secret | Conversation CRUD |

---

## Check Attendance (Face Recognition) Details

- **Model**: dlib ResNet-34 (128-dim embeddings) + HOG face detector
- **Face detection**: YuNet ONNX + Haar Cascade
- **Registration**: `src/register.py` → stores 128d vector in `users.face_embedding`
- **Attendance**: `src/attendance.py` → webcam, compares against DB embeddings
- **Threshold (Tolerance)**:
  - < 50 employees: **0.55** (balance)
  - ≥ 100 employees: **0.50** (security priority, prevent buddy-punching)
- **Kiosk endpoints** (no JWT, internal network only):
  - `PUT /api/attendances/{userId}`
  - `PUT /api/overtime/{userId}`

---

## Development Notes

### Ponytail Mode
This project uses **ponytail** (lazy senior dev mode) – smallest complete change that fully solves the task. See `.claude/rules/ponytail.md` for rules.

### CodeGraph
The repo is indexed by CodeGraph (`.codegraph/` exists). Use `codegraph_explore` tool for code questions – returns verbatim source + call paths + blast radius.

### RTK (Rust Token Killer)
CLI proxy cuts ~90% bash output. Commands auto-rewritten via hook: `git status` → `rtk git status`.
Meta commands: `rtk gain`, `rtk discover`, `rtk proxy <cmd>`.

### Testing
- **Backend**: `./mvnw test`
- **AI Service**: `pytest` (various test suites in `ai-service/tests/`)
- **Frontend**: `npm run lint` (no unit test config found)

### Common Patterns
- **Background tasks**: FastAPI `BackgroundTasks` for async document processing
- **Internal secret verification**: Dependency `verify_internal_secret` on all AI endpoints
- **PBAC enforcement**: `allowed_departments` array + `user_dept` query param
- **Atomic document update**: Delete old chunks → insert new chunks in single transaction
- **Auto-recovery**: On startup, resumes `PROCESSING` documents left from crashes

---

## Environment Variables Quick Reference

### Docker Compose (`.env`)
```
POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
REDIS_PORT, BACKEND_PORT, FRONTEND_PORT, AI_SERVICE_PORT, N8N_PORT
AI_SERVICE_SECRET          # Shared Spring Boot ↔ FastAPI
LLM_PROVIDER, OLLAMA_*, GEMINI_*, OPENAI_*
```

### Backend (`application.properties`)
```
SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD
SPRING_DATA_REDIS_HOST, SPRING_DATA_REDIS_PORT
jwt.secret.access, jwt.secret.refresh
ai.service.base-url, ai.service.internal-secret
file.upload-dir
```

### AI Service (`.env`)
```
DATABASE_URL              # postgresql://.../hrm_ai (pgvector)
HRM_DATABASE_URL          # read-only for Text-to-SQL (hrm DB)
INTERNAL_API_SECRET       # Must match backend's ai.service.internal-secret
LLM_PROVIDER, OLLAMA_MODEL, GEMINI_MODEL, OPENAI_MODEL
LOCAL_EMBEDDING_MODEL     # 768-dim model name
```

### Frontend (`.env.local`)
```
NEXT_PUBLIC_API_URL       # http://localhost:8080
INTERNAL_BACKEND_URL      # http://localhost:8080
```

---

## Operational Notes

- **Do not commit**: `.env`, `application.properties`, SQL dumps, `uploads/`
- **Clock-in endpoints** bypass JWT for kiosk – only expose on internal network
- **`spring.jpa.hibernate.ddl-auto=update`** dev only; production needs migrations
- **Logs**: Console + `logs/myapp.log`; `com.minhtrung.hrm` at DEBUG
- **n8n workflows** in `backups/` handle PostgreSQL backup/restore/monitoring
- **Cloudflare tunnels** (`cloudflared-*` services) expose services publicly via random URLs – check `docker logs hrm-cloudflared-web|api|ai` for URLs
