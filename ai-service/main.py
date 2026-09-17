import os
import hashlib
from pathlib import Path
from typing import List, Optional
from pydantic import BaseModel, Field
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks, Query, Header, Security
from fastapi.staticfiles import StaticFiles

from dotenv import load_dotenv
load_dotenv()

from src.pipeline import IngestionPipeline
from src.embeddings.gemini_embedder import GeminiEmbedder
from src.chat.chat_service import ChatService
from src.db.session import get_db_connection

app = FastAPI(
    title="HRM AI RAG Service",
    description="Enterprise Document Ingestion, Management & Vector Search API",
    version="1.0.0"
)

# Internal security secret shared between Spring Boot & FastAPI
INTERNAL_API_SECRET = os.getenv("INTERNAL_API_SECRET", "hrm-internal-key-secure-2024")

async def verify_internal_secret(x_internal_secret: Optional[str] = Header(None)):
    """
    Ensures the request comes from our trusted Spring Boot Gateway.
    Rejects direct untrusted external calls with 403 Forbidden.
    """
    if INTERNAL_API_SECRET:
        if not x_internal_secret or x_internal_secret != INTERNAL_API_SECRET:
            raise HTTPException(
                status_code=403,
                detail="Truy cập bị từ chối: Thiếu hoặc sai header 'X-Internal-Secret'. Chỉ Spring Boot backend mới có quyền gọi API này."
            )

# Initialize AI components
pipeline = IngestionPipeline(enrich_with_llm=True)
embedder = GeminiEmbedder()
chat_service = ChatService()

# Setup Local Storage for documents
BASE_UPLOAD_DIR = Path("uploads")
DOCS_STORAGE_DIR = BASE_UPLOAD_DIR / "documents"
DOCS_STORAGE_DIR.mkdir(parents=True, exist_ok=True)

# Mount static files to serve original documents to frontend
app.mount("/static", StaticFiles(directory=str(BASE_UPLOAD_DIR)), name="static")


def process_document_background(
    document_id: str,
    file_path: Path,
    filename: str,
    roles: List[str],
    depts: List[str],
    old_file_path: Optional[str] = None
):
    """
    Background worker:
    1. Cleans up old physical file if replacing
    2. Clears old chunks from database
    3. Runs Document Parser & Legal Chunker
    4. Runs Ollama Cloud for Summaries & Reverse HyDE Questions
    5. Runs Google Gemini for 768d Vector Embeddings
    6. Inserts new Chunks + Vectors into PostgreSQL
    7. Updates Document status to COMPLETED / FAILED
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        print(f"[Worker] Starting background processing for: {filename} (ID: {document_id})...")

        # Step 0: Remove old physical file if replacing
        if old_file_path and os.path.exists(old_file_path):
            try:
                os.remove(old_file_path)
                print(f"[Worker] Removed old physical file: {old_file_path}")
            except Exception as e:
                print(f"[Worker] Warning: could not remove old file {old_file_path}: {e}")

        # Clear any existing chunks for this document (ensures clean replacement, no obsolete chunks!)
        cursor.execute("DELETE FROM document_chunks WHERE document_id = %s;", (document_id,))
        conn.commit()

        # Step 1 & 2: Parse, Chunk, and Enrich with Ollama
        chunks = pipeline.process_file(
            file_path=file_path,
            allowed_roles=roles,
            allowed_departments=depts
        )
        print(f"[Worker] Extracted & enriched {len(chunks)} chunks for {filename}.")

        # Step 3 & 4: Embed with Gemini & Save into document_chunks
        print(f"[Worker] Generating Gemini 768d vectors and saving to database...")
        for i, chunk in enumerate(chunks):
            chunk = embedder.embed_chunk(chunk)

            cursor.execute(
                """
                INSERT INTO document_chunks (
                    document_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                    summary, keywords, hypothetical_questions, allowed_roles, allowed_departments,
                    content_vector, questions_vector
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                );
                """,
                (
                    document_id, i + 1, chunk.chunk_type, chunk.breadcrumb, chunk.content, chunk.page_number,
                    chunk.summary, chunk.keywords, chunk.hypothetical_questions,
                    chunk.allowed_roles, chunk.allowed_departments,
                    chunk.content_vector, chunk.questions_vector
                )
            )

        # Step 5: Update knowledge_documents to COMPLETED
        cursor.execute(
            "UPDATE knowledge_documents SET status = 'COMPLETED', updated_at = NOW() WHERE id = %s;",
            (document_id,)
        )
        conn.commit()
        print(f"[Worker] ✅ Successfully finished processing {filename} ({len(chunks)} chunks).")

    except Exception as e:
        conn.rollback()
        print(f"[Worker] ❌ Failed to process {filename}: {e}")
        cursor.execute(
            "UPDATE knowledge_documents SET status = 'FAILED', error_message = %s, updated_at = NOW() WHERE id = %s;",
            (str(e), document_id)
        )
        conn.commit()
    finally:
        cursor.close()
        conn.close()


# ==========================================
# 1. DOCUMENT INGESTION (UPLOAD) API
# ==========================================
@app.post("/api/v1/documents/upload")
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    allowed_roles: str = Form("ROLE_EMPLOYEE,ROLE_MANAGER"),
    allowed_departments: str = Form("ALL"),
    uploaded_by: str = Form("ADMIN"),
    overwrite: bool = Form(False)
):
    """
    Receives file, verifies SHA-256 for deduplication, stores file locally,
    registers DB record, and dispatches background worker.
    """
    contents = await file.read()
    file_size = len(contents)

    # 1. Calculate SHA-256 hash
    hasher = hashlib.sha256()
    hasher.update(contents)
    file_hash = hasher.hexdigest()

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # 2. Check for duplicates
        cursor.execute(
            "SELECT id, file_name, status, file_path FROM knowledge_documents WHERE file_hash = %s;",
            (file_hash,)
        )
        existing = cursor.fetchone()

        if existing and not overwrite:
            return {
                "status": "DUPLICATE",
                "message": f"Tài liệu '{existing[1]}' đã tồn tại trong hệ thống (Trùng mã SHA-256)!",
                "document_id": str(existing[0]),
                "current_status": existing[2],
                "file_hash": file_hash
            }

        # If overwriting, remove existing entry and file
        if existing and overwrite:
            old_id, _, _, old_path = existing
            cursor.execute("DELETE FROM knowledge_documents WHERE id = %s;", (old_id,))
            conn.commit()
            if old_path and os.path.exists(old_path):
                try:
                    os.remove(old_path)
                except Exception:
                    pass

        # 3. Save file permanently in local storage
        safe_filename = f"{file_hash[:12]}_{file.filename}"
        saved_file_path = DOCS_STORAGE_DIR / safe_filename
        with open(saved_file_path, "wb") as f:
            f.write(contents)

        file_type = file.filename.split(".")[-1].lower()

        roles = [r.strip() for r in allowed_roles.split(",") if r.strip()]
        depts = [d.strip() for d in allowed_departments.split(",") if d.strip()]

        # 4. Insert into knowledge_documents with status PROCESSING
        cursor.execute(
            """
            INSERT INTO knowledge_documents (
                file_name, file_type, file_hash, file_path, file_size, uploaded_by, status,
                allowed_roles, allowed_departments
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id;
            """,
            (file.filename, file_type, file_hash, str(saved_file_path), file_size, uploaded_by, "PROCESSING", roles, depts)
        )
        document_id = str(cursor.fetchone()[0])
        conn.commit()

        # 5. Dispatch background task

        background_tasks.add_task(
            process_document_background,
            document_id=document_id,
            file_path=saved_file_path,
            filename=file.filename,
            roles=roles,
            depts=depts
        )

        return {
            "status": "PROCESSING",
            "message": "Tài liệu đã được tiếp nhận và đang được xử lý ngầm (Background Task).",
            "document_id": document_id,
            "file_name": file.filename,
            "file_size": file_size,
            "file_hash": file_hash,
            "file_url": f"/static/documents/{safe_filename}"
        }

    finally:
        cursor.close()
        conn.close()


@app.put("/api/v1/documents/{document_id}")
async def update_document(
    document_id: str,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    allowed_roles: Optional[str] = Form(None),
    allowed_departments: Optional[str] = Form(None),
    updated_by: Optional[str] = Form("ADMIN")
):
    """
    In-place update for an existing document (Cách 1):
    1. Kiểm tra tài liệu tồn tại trong CSDL.
    2. Đọc file mới và tính mã SHA-256.
    3. Nếu file giống 100% (SHA-256 không đổi) -> Báo UNCHANGED không cần chạy lại.
    4. Nếu nội dung mới:
       - Lưu file mới vào ổ cứng.
       - Cập nhật thông tin file_name, file_hash, file_path, status='PROCESSING'.
       - Chạy Background Task: Xóa file cũ, Xóa toàn bộ vector/chunk cũ, 
         chạy Ollama + Gemini nạp vector mới toanh.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT id, file_name, file_hash, file_path, allowed_roles, allowed_departments FROM knowledge_documents WHERE id = %s;",
            (document_id,)
        )
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu cần cập nhật!")

        _, old_file_name, old_hash, old_path, old_roles, old_depts = existing

        contents = await file.read()
        file_size = len(contents)

        # 2. Tính mã SHA-256 mới
        hasher = hashlib.sha256()
        hasher.update(contents)
        new_hash = hasher.hexdigest()

        # 3. Kiểm tra xem nội dung có thay đổi không
        if new_hash == old_hash:
            return {
                "status": "UNCHANGED",
                "message": f"Nội dung file mới hoàn toàn trùng khớp với phiên bản hiện tại (SHA-256 không đổi). Không cần cập nhật!",
                "document_id": document_id,
                "file_name": old_file_name
            }

        # 4. Lưu file mới vào thư mục lưu trữ
        safe_filename = f"{new_hash[:12]}_{file.filename}"
        new_file_path = DOCS_STORAGE_DIR / safe_filename
        with open(new_file_path, "wb") as f:
            f.write(contents)

        file_type = file.filename.split(".")[-1].lower()

        roles = [r.strip() for r in allowed_roles.split(",") if r.strip()] if allowed_roles else (old_roles or ["ROLE_EMPLOYEE", "ROLE_MANAGER"])
        depts = [d.strip() for d in allowed_departments.split(",") if d.strip()] if allowed_departments else (old_depts or ["ALL"])

        # 5. Cập nhật bản ghi knowledge_documents
        cursor.execute(
            """
            UPDATE knowledge_documents
            SET file_name = %s,
                file_type = %s,
                file_hash = %s,
                file_path = %s,
                file_size = %s,
                uploaded_by = %s,
                allowed_roles = %s,
                allowed_departments = %s,
                status = 'PROCESSING',
                error_message = NULL,
                updated_at = NOW()
            WHERE id = %s;
            """,
            (file.filename, file_type, new_hash, str(new_file_path), file_size, updated_by or "ADMIN", roles, depts, document_id)
        )
        conn.commit()

        # 6. Kích hoạt Worker ngầm để dọn chunk cũ & nạp chunk mới
        background_tasks.add_task(
            process_document_background,
            document_id=document_id,
            file_path=new_file_path,
            filename=file.filename,
            roles=roles,
            depts=depts,
            old_file_path=old_path if old_path != str(new_file_path) else None
        )

        return {
            "status": "PROCESSING",
            "message": f"Tài liệu '{file.filename}' đang được thay thế và cập nhật lại toàn bộ vector ngầm.",
            "document_id": document_id,
            "old_file_name": old_file_name,
            "new_file_name": file.filename,
            "new_file_size": file_size,
            "new_file_hash": new_hash,
            "new_file_url": f"/static/documents/{safe_filename}"
        }

    finally:
        cursor.close()
        conn.close()


# ==========================================
# 2. DOCUMENT MANAGEMENT (CRUD) APIS
# ==========================================
@app.get("/api/v1/documents")
async def list_documents(
    status: Optional[str] = Query(None, description="Filter by status (PROCESSING, COMPLETED, FAILED)"),
    search: Optional[str] = Query(None, description="Search by document name")
):
    """List all ingested documents with chunk counts and download URLs."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            SELECT 
                d.id, d.file_name, d.file_type, d.file_size, d.file_hash, 
                d.uploaded_by, d.status, d.file_path, d.error_message, 
                d.created_at, d.updated_at,
                COUNT(c.id) as chunk_count
            FROM knowledge_documents d
            LEFT JOIN document_chunks c ON d.id = c.document_id
            WHERE 1=1
        """
        params = []
        if status:
            query += " AND d.status = %s"
            params.append(status.upper())
        if search:
            query += " AND d.file_name ILIKE %s"
            params.append(f"%{search}%")

        query += " GROUP BY d.id ORDER BY d.created_at DESC;"

        cursor.execute(query, tuple(params))
        rows = cursor.fetchall()

        docs = []
        for r in rows:
            file_path = r[7]
            safe_name = Path(file_path).name if file_path else ""
            docs.append({
                "id": str(r[0]),
                "file_name": r[1],
                "file_type": r[2],
                "file_size": r[3],
                "file_hash": r[4],
                "uploaded_by": r[5],
                "status": r[6],
                "file_url": f"/static/documents/{safe_name}" if safe_name else None,
                "error_message": r[8],
                "created_at": r[9].isoformat() if r[9] else None,
                "updated_at": r[10].isoformat() if r[10] else None,
                "chunk_count": r[11]
            })

        return {"total": len(docs), "documents": docs}
    finally:
        cursor.close()
        conn.close()


@app.get("/api/v1/documents/{document_id}")
async def get_document_detail(document_id: str):
    """Get detail and processing status of a single document."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """
            SELECT 
                d.id, d.file_name, d.file_type, d.file_size, d.file_hash,
                d.uploaded_by, d.status, d.file_path, d.error_message, 
                d.created_at, d.updated_at,
                COUNT(c.id) as chunk_count
            FROM knowledge_documents d
            LEFT JOIN document_chunks c ON d.id = c.document_id
            WHERE d.id = %s
            GROUP BY d.id;
            """,
            (document_id,)
        )
        r = cursor.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu!")

        file_path = r[7]
        safe_name = Path(file_path).name if file_path else ""

        return {
            "id": str(r[0]),
            "file_name": r[1],
            "file_type": r[2],
            "file_size": r[3],
            "file_hash": r[4],
            "uploaded_by": r[5],
            "status": r[6],
            "file_url": f"/static/documents/{safe_name}" if safe_name else None,
            "error_message": r[8],
            "created_at": r[9].isoformat() if r[9] else None,
            "updated_at": r[10].isoformat() if r[10] else None,
            "chunk_count": r[11]
        }
    finally:
        cursor.close()
        conn.close()


@app.get("/api/v1/documents/{document_id}/chunks")
async def get_document_chunks(document_id: str):
    """Audit API: View all chunks, summaries, tables, and hypothetical questions for a document."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """
            SELECT 
                id, chunk_index, chunk_type, breadcrumb, content, page_number,
                summary, keywords, hypothetical_questions, allowed_roles, allowed_departments
            FROM document_chunks
            WHERE document_id = %s
            ORDER BY chunk_index ASC;
            """,
            (document_id,)
        )
        rows = cursor.fetchall()
        chunks = []
        for r in rows:
            chunks.append({
                "id": str(r[0]),
                "chunk_index": r[1],
                "chunk_type": r[2],
                "breadcrumb": r[3],
                "content": r[4],
                "page_number": r[5],
                "summary": r[6],
                "keywords": r[7],
                "hypothetical_questions": r[8],
                "allowed_roles": r[9],
                "allowed_departments": r[10]
            })

        return {
            "document_id": document_id,
            "total_chunks": len(chunks),
            "chunks": chunks
        }
    finally:
        cursor.close()
        conn.close()


@app.delete("/api/v1/documents/{document_id}")
async def delete_document(document_id: str):
    """
    Deletes document record.
    PostgreSQL CASCADE automatically deletes all associated document_chunks and vectors!
    Also removes the physical file stored on disk.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT file_path, file_name FROM knowledge_documents WHERE id = %s;", (document_id,))
        doc = cursor.fetchone()
        if not doc:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu để xóa!")

        file_path, file_name = doc[0], doc[1]

        # Delete from DB (CASCADE cleans up chunks)
        cursor.execute("DELETE FROM knowledge_documents WHERE id = %s;", (document_id,))
        conn.commit()

        # Delete physical file on disk
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as err:
                print(f"[Warning] Could not remove physical file {file_path}: {err}")

        return {
            "status": "success",
            "message": f"Đã xóa vĩnh viễn tài liệu '{file_name}' và toàn bộ các vector liên quan khỏi CSDL!"
        }
    finally:
        cursor.close()
        conn.close()


# ==========================================
# 3. CHATBOT REASONING & QUERY API
# ==========================================
class ChatQueryRequest(BaseModel):
    question: str = Field(..., description="Câu hỏi của nhân viên")
    user_roles: Optional[List[str]] = Field(default_factory=lambda: ["ROLE_EMPLOYEE"])
    department: Optional[str] = Field(default="ALL")
    top_k: int = Field(default=3, ge=1, le=10)


@app.post("/api/v1/chat/query", dependencies=[Security(verify_internal_secret)])
async def chat_query(request: ChatQueryRequest):
    """
    RAG Chatbot query API:
    1. Validates X-Internal-Secret from Spring Boot.
    2. Runs Hybrid Search (Cosine Vector + Reverse HyDE Questions + Keywords + RBAC).
    3. Prompts Ollama Cloud (gpt-oss-safeguard:120b) to synthesize grounded answer.
    4. Returns answer + citations (document name, breadcrumb, page, link).
    """
    try:
        roles = request.user_roles or ["ROLE_EMPLOYEE"]
        depts = [request.department] if request.department else ["ALL"]

        result = chat_service.answer_query(
            question=request.question,
            roles=roles,
            departments=depts,
            top_k=request.top_k
        )
        return result
    except Exception as e:
        print(f"[chat_query] Error: {e}")
        raise HTTPException(status_code=500, detail=f"Lỗi khi xử lý câu hỏi: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
