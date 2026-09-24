import os
import sys
import hashlib
from pathlib import Path
from typing import List, Optional
import urllib.parse

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass
from pydantic import BaseModel, Field
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks, Query, Header, Security
from fastapi.responses import StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles

from dotenv import load_dotenv
load_dotenv()

from src.pipeline import IngestionPipeline
from src.embeddings.local_embedder import LocalEmbedder
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
embedder = LocalEmbedder()
chat_service = ChatService()

# Setup Local Storage for documents
BASE_UPLOAD_DIR = Path("uploads")
DOCS_STORAGE_DIR = BASE_UPLOAD_DIR / "documents"
DOCS_STORAGE_DIR.mkdir(parents=True, exist_ok=True)

# Disabled public static mount to protect confidential documents from unauthorized downloads.
# All document downloads must pass through Spring Boot Gateway with PBAC authorization.
# app.mount("/static", StaticFiles(directory=str(BASE_UPLOAD_DIR)), name="static")


def get_unique_filename(directory: Path, original_filename: str, current_hash: str) -> str:
    """
    Giữ nguyên tên file gốc khi upload vào thư mục lưu trữ.
    Nếu file cùng tên đã tồn tại trên đĩa mà khác file_hash:
    Tự động gắn thêm hậu tố _v2, _v3,... trước đuôi file (extension).
    Nếu cùng tên và cùng hash: giữ nguyên để overwrite/tái sử dụng.
    """
    clean_name = Path(original_filename).name
    path_obj = Path(clean_name)
    stem = path_obj.stem
    suffix = path_obj.suffix

    candidate_name = clean_name
    target_path = directory / candidate_name

    # Nếu file chưa tồn tại trong thư mục, dùng tên gốc
    if not target_path.exists():
        return candidate_name

    # Nếu file đã tồn tại, kiểm tra xem có cùng nội dung (hash) không
    try:
        with open(target_path, "rb") as f:
            existing_hash = hashlib.sha256(f.read()).hexdigest()
        if existing_hash == current_hash:
            return candidate_name
    except Exception:
        pass

    # Nếu trùng tên nhưng khác nội dung (khác file_hash), tìm hậu tố _v2, _v3,...
    version = 2
    while True:
        candidate_name = f"{stem}_v{version}{suffix}"
        candidate_path = directory / candidate_name
        if not candidate_path.exists():
            return candidate_name
        try:
            with open(candidate_path, "rb") as f:
                cand_hash = hashlib.sha256(f.read()).hexdigest()
            if cand_hash == current_hash:
                return candidate_name
        except Exception:
            pass
        version += 1


def process_document_background(
    document_id: str,
    file_path: Path,
    filename: str,
    jobs: Optional[List[str]] = None,
    depts: Optional[List[str]] = None,
    old_file_path: Optional[str] = None,
    roles: Optional[List[str]] = None
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
    effective_jobs = jobs or roles or ["ALL"]
    effective_depts = depts or ["ALL"]

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        print(f"[Worker] Starting background processing for: {filename} (ID: {document_id})...")

        # Step 1 & 2: Parse, Chunk, and Enrich with Ollama FIRST (Tránh mất chunk cũ nếu file mới lỗi)
        chunks = pipeline.process_file(
            file_path=file_path,
            allowed_jobs=effective_jobs,
            allowed_departments=effective_depts
        )
        print(f"[Worker] Extracted & enriched {len(chunks)} chunks for {filename}.")

        # Step 3 & 4: Embed with LocalEmbedder on GPU/CPU
        print(f"[Worker] Generating local 768d vectors (Offline CUDA Batch mode)...")
        chunks = embedder.embed_chunks(chunks, batch_size=32)

        # Step 5: Sau khi sinh vector mới thành công 100% mới xóa chunk cũ và ghi chunk mới (Atomic Transaction)
        cursor.execute("DELETE FROM document_chunks WHERE document_id = %s;", (document_id,))

        print(f"[Worker] Saving {len(chunks)} chunks to PostgreSQL...")
        from psycopg2.extras import execute_values
        chunk_records = [
            (
                document_id, i + 1, chunk.chunk_type, chunk.breadcrumb, chunk.content, chunk.page_number,
                chunk.summary, chunk.keywords, chunk.hypothetical_questions,
                chunk.allowed_jobs, chunk.allowed_departments,
                chunk.content_vector, chunk.questions_vector
            )
            for i, chunk in enumerate(chunks)
        ]
        execute_values(
            cursor,
            """
            INSERT INTO document_chunks (
                document_id, chunk_index, chunk_type, breadcrumb, content, page_number,
                summary, keywords, hypothetical_questions, allowed_jobs, allowed_departments,
                content_vector, questions_vector
            ) VALUES %s;
            """,
            chunk_records
        )

        # Step 6: Update knowledge_documents to COMPLETED
        cursor.execute(
            "UPDATE knowledge_documents SET status = 'COMPLETED', error_message = NULL, updated_at = NOW() WHERE id = %s;",
            (document_id,)
        )
        conn.commit()

        # Step 7: Dọn dẹp file vật lý cũ chỉ khi đã nạp thành công toàn bộ
        if old_file_path and os.path.exists(old_file_path) and old_file_path != str(file_path):
            try:
                os.remove(old_file_path)
                print(f"[Worker] Removed old physical file: {old_file_path}")
            except Exception as e:
                print(f"[Worker] Warning: could not remove old file {old_file_path}: {e}")

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


@app.on_event("startup")
async def resume_interrupted_documents():
    """
    On startup, inspect if any documents were left in 'PROCESSING' state
    (e.g., if the server was restarted or reloaded during an upload).
    Automatically finishes them in the background.
    """
    import threading, time
    def _recover():
        time.sleep(3)
        try:
            c = get_db_connection()
            cur = c.cursor()
            cur.execute("SELECT id, file_path, file_name, allowed_departments FROM knowledge_documents WHERE status = 'PROCESSING';")
            stuck_docs = cur.fetchall()
            cur.close()
            c.close()
            if stuck_docs:
                print(f"[AutoRecovery] Phát hiện {len(stuck_docs)} tài liệu chưa hoàn tất. Tự động tiếp tục xử lý ngầm...")
                for doc in stuck_docs:
                    d_id, f_path, f_name, depts = doc
                    if f_path and os.path.exists(f_path):
                        process_document_background(
                            document_id=str(d_id),
                            file_path=Path(f_path),
                            filename=f_name,
                            jobs=["ALL"],
                            depts=depts or ["ALL"]
                        )
                    else:
                        print(f"[AutoRecovery] File không tồn tại: {f_path}. Đánh dấu FAILED.")
                        c2 = get_db_connection()
                        cur2 = c2.cursor()
                        cur2.execute("UPDATE knowledge_documents SET status = 'FAILED', error_message = 'File không tồn tại trên ổ cứng' WHERE id = %s;", (d_id,))
                        c2.commit()
                        cur2.close()
                        c2.close()
        except Exception as err:
            print(f"[AutoRecovery] Lỗi khi kiểm tra khôi phục tài liệu: {err}")

    threading.Thread(target=_recover, daemon=True).start()


# ==========================================
# 1. DOCUMENT INGESTION (UPLOAD) API
# ==========================================
@app.post("/api/v1/documents/upload")
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    allowed_jobs: Optional[str] = Form(None),
    allowed_roles: Optional[str] = Form(None),
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

        # 3. Lưu file vào thư mục lưu trữ (giữ nguyên tên gốc, tự thêm _v2 nếu trùng tên mà khác hash)
        saved_filename = get_unique_filename(DOCS_STORAGE_DIR, file.filename, file_hash)
        saved_file_path = DOCS_STORAGE_DIR / saved_filename
        with open(saved_file_path, "wb") as f:
            f.write(contents)

        file_type = saved_filename.split(".")[-1].lower() if "." in saved_filename else ""

        depts = [d.strip() for d in allowed_departments.split(",") if d.strip()] or ["ALL"]

        # 4. Insert into knowledge_documents with status PROCESSING (allowed_jobs removed)
        cursor.execute(
            """
            INSERT INTO knowledge_documents (
                file_name, file_type, file_hash, file_path, file_size, uploaded_by, status,
                allowed_departments
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id;
            """,
            (saved_filename, file_type, file_hash, str(saved_file_path), file_size, uploaded_by, "PROCESSING", depts)
        )
        document_id = str(cursor.fetchone()[0])
        conn.commit()

        # 5. Dispatch background task
        background_tasks.add_task(
            process_document_background,
            document_id=document_id,
            file_path=saved_file_path,
            filename=saved_filename,
            jobs=["ALL"],
            depts=depts
        )

        return {
            "status": "PROCESSING",
            "message": "Tài liệu đã được tiếp nhận và đang được xử lý ngầm (Background Task).",
            "document_id": document_id,
            "file_name": saved_filename,
            "file_size": file_size,
            "file_hash": file_hash,
            "file_url": f"/api/ai/documents/{document_id}/download"
        }

    finally:
        cursor.close()
        conn.close()


@app.put("/api/v1/documents/{document_id}")
async def update_document(
    document_id: str,
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    allowed_jobs: Optional[str] = Form(None),
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
            "SELECT id, file_name, file_hash, file_path, allowed_departments FROM knowledge_documents WHERE id = %s;",
            (document_id,)
        )
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu cần cập nhật!")

        _, old_file_name, old_hash, old_path, old_depts = existing

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

        # 4. Lưu file mới vào thư mục lưu trữ (giữ nguyên tên gốc, tự thêm _v2 nếu trùng tên mà khác hash)
        saved_filename = get_unique_filename(DOCS_STORAGE_DIR, file.filename, new_hash)
        new_file_path = DOCS_STORAGE_DIR / saved_filename
        with open(new_file_path, "wb") as f:
            f.write(contents)

        file_type = saved_filename.split(".")[-1].lower() if "." in saved_filename else ""

        depts = [d.strip() for d in allowed_departments.split(",") if d.strip()] if allowed_departments else (old_depts or ["ALL"])

        # 5. Cập nhật bản ghi knowledge_documents (allowed_jobs removed)
        cursor.execute(
            """
            UPDATE knowledge_documents
            SET file_name = %s,
                file_type = %s,
                file_hash = %s,
                file_path = %s,
                file_size = %s,
                uploaded_by = %s,
                allowed_departments = %s,
                status = 'PROCESSING',
                error_message = NULL,
                updated_at = NOW()
            WHERE id = %s;
            """,
            (saved_filename, file_type, new_hash, str(new_file_path), file_size, updated_by or "ADMIN", depts, document_id)
        )
        conn.commit()

        # 6. Kích hoạt Worker ngầm để dọn chunk cũ & nạp chunk mới
        background_tasks.add_task(
            process_document_background,
            document_id=document_id,
            file_path=new_file_path,
            filename=saved_filename,
            jobs=["ALL"],
            depts=depts,
            old_file_path=old_path if old_path != str(new_file_path) else None
        )

        return {
            "status": "PROCESSING",
            "message": f"Tài liệu '{saved_filename}' đang được thay thế và cập nhật lại toàn bộ vector ngầm.",
            "document_id": document_id,
            "old_file_name": old_file_name,
            "new_file_name": saved_filename,
            "new_file_size": file_size,
            "new_file_hash": new_hash,
            "new_file_url": f"/api/ai/documents/{document_id}/download"
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
    search: Optional[str] = Query(None, description="Search by document name"),
    department: Optional[str] = Query(None, description="Filter by specific department"),
    user_dept: Optional[str] = Query(None, description="Current employee department for access control")
):
    """List all ingested documents with chunk counts, allowed departments, and download URLs."""
    def clean_param(val: Optional[str]) -> Optional[str]:
        if not val:
            return None
        v = str(val).strip()
        if not v:
            return None
        prev = None
        while prev != v and "%" in v:
            prev = v
            v = urllib.parse.unquote(v)
        return v.strip()

    status = clean_param(status)
    search = clean_param(search)
    department = clean_param(department)
    user_dept = clean_param(user_dept)

    print(f"[DEBUG FASTAPI list_documents] status={status}, search={search}, department={department}, user_dept={user_dept}")
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        query = """
            SELECT 
                d.id, d.file_name, d.file_type, d.file_size, d.file_hash, 
                d.uploaded_by, d.status, d.file_path, d.error_message, 
                d.created_at, d.updated_at,
                COUNT(c.id) as chunk_count,
                d.allowed_departments
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

        # Ràng buộc phân quyền PBAC: Nhân viên chỉ được xem tài liệu ALL hoặc phòng ban của mình
        if user_dept and user_dept.strip():
            clean_user_dept = user_dept.strip()
            query += " AND (d.allowed_departments && %s::varchar[] OR 'ALL' = ANY(d.allowed_departments))"
            params.append([clean_user_dept, "ALL"])

        # Bộ lọc tìm kiếm theo phòng ban do người dùng chọn trên UI (nếu là 'ALL' hoặc để trống -> xem tất cả tài liệu có quyền xem)
        if department and department.strip() and department.strip().upper() != "ALL":
            target_dept = department.strip()
            query += " AND (%s = ANY(d.allowed_departments))"
            params.append(target_dept)

        query += " GROUP BY d.id, d.allowed_departments ORDER BY d.created_at DESC;"

        cursor.execute(query, tuple(params))
        rows = cursor.fetchall()

        docs = []
        for r in rows:
            docs.append({
                "id": str(r[0]),
                "file_name": r[1],
                "file_type": r[2],
                "file_size": r[3],
                "file_hash": r[4],
                "uploaded_by": r[5],
                "status": r[6],
                "file_url": f"/api/ai/documents/{r[0]}/download",
                "error_message": r[8],
                "created_at": r[9].isoformat() if r[9] else None,
                "updated_at": r[10].isoformat() if r[10] else None,
                "chunk_count": r[11],
                "allowed_departments": r[12] if r[12] else ["ALL"]
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
                COUNT(c.id) as chunk_count,
                d.allowed_departments
            FROM knowledge_documents d
            LEFT JOIN document_chunks c ON d.id = c.document_id
            WHERE d.id = %s
            GROUP BY d.id, d.allowed_departments;
            """,
            (document_id,)
        )
        r = cursor.fetchone()
        if not r:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu!")

        return {
            "id": str(r[0]),
            "file_name": r[1],
            "file_type": r[2],
            "file_size": r[3],
            "file_hash": r[4],
            "uploaded_by": r[5],
            "status": r[6],
            "file_url": f"/api/ai/documents/{r[0]}/download",
            "error_message": r[8],
            "created_at": r[9].isoformat() if r[9] else None,
            "updated_at": r[10].isoformat() if r[10] else None,
            "chunk_count": r[11],
            "allowed_departments": r[12] if r[12] else ["ALL"]
        }
    finally:
        cursor.close()
        conn.close()


@app.get("/api/v1/documents/{document_id}/download")
async def download_document(
    document_id: str,
    user_dept: Optional[str] = Query(None, description="Employee department for PBAC authorization"),
    x_internal_secret: Optional[str] = Header(None)
):
    """
    Internal secure download API called ONLY by Spring Boot Gateway.
    Verifies internal secret and enforces PBAC before returning physical file.
    """
    await verify_internal_secret(x_internal_secret)
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT file_path, file_name, file_type, allowed_departments FROM knowledge_documents WHERE id = %s;",
            (document_id,)
        )
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy tài liệu!")

        file_path, file_name, file_type, allowed_departments = row[0], row[1], row[2], row[3] or ["ALL"]

        # Kiểm tra PBAC nếu có user_dept truyền vào
        if user_dept and user_dept.strip():
            clean_dept = urllib.parse.unquote(user_dept).strip()
            while "%" in clean_dept:
                clean_dept = urllib.parse.unquote(clean_dept).strip()

            is_allowed = "ALL" in allowed_departments or clean_dept in allowed_departments
            if not is_allowed:
                raise HTTPException(
                    status_code=403,
                    detail=f"Nhân viên phòng ban '{clean_dept}' không có quyền tải tài liệu này!"
                )

        if not file_path or not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="File vật lý không tồn tại trên hệ thống!")

        return FileResponse(
            path=file_path,
            filename=file_name,
            media_type="application/octet-stream"
        )
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
                summary, keywords, hypothetical_questions, allowed_jobs, allowed_departments
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
                "allowed_jobs": r[9],
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
# 3. CHATBOT REASONING & CONVERSATIONAL MEMORY API
# ==========================================
class ChatQueryRequest(BaseModel):
    question: str = Field(..., description="Câu hỏi của nhân viên")
    conversation_id: Optional[str] = Field(None, description="ID cuộc trò chuyện (nếu có để tiếp tục ngữ cảnh)")
    user_id: Optional[str] = Field("ANONYMOUS", description="ID của nhân viên")
    user_jobs: Optional[List[str]] = Field(default_factory=lambda: ["ALL"], description="Danh sách chức danh của nhân viên (Job Titles)")
    user_roles: Optional[List[str]] = Field(None, description="Tương thích ngược với user_jobs")
    department: Optional[str] = Field(default="ALL")
    top_k: int = Field(default=3, ge=1, le=10)


@app.post("/api/v1/chat/query", dependencies=[Security(verify_internal_secret)])
async def chat_query(request: ChatQueryRequest, background_tasks: BackgroundTasks):
    """
    API Hỏi - Đáp Chatbot AI RAG (Chế độ Phản hồi một lần - Non-streaming):
    
    Quy trình xử lý:
    1. Xác thực bảo mật: Kiểm tra header X-Internal-Secret từ Spring Boot Gateway.
    2. Phòng thủ Prompt Injection: Quét Regex phát hiện và chặn đứng câu lệnh can thiệp trái phép.
    3. Nạp bộ nhớ hội thoại: Lấy ngữ cảnh dài hạn (context_summary) và 6 tin nhắn gần nhất từ PostgreSQL.
    4. Tái tạo câu hỏi (Kỹ thuật 1 - Query Condensation): LLM viết lại câu hỏi phụ thuộc thành câu hỏi độc lập.
    5. Hybrid Search: Tìm kiếm kết hợp Vector (Gemini 768d) và Full-Text Search (tsvector tiếng Việt).
    6. Sinh câu trả lời (Kỹ thuật 2): Đóng gói câu hỏi trong thẻ XML <user_question> và yêu cầu LLM suy luận.
    7. Lưu vết: Lưu cả câu hỏi của người dùng và câu trả lời của AI vào bảng chat_messages.
    8. Tác vụ ngầm (BackgroundTasks): Tự động sinh tiêu đề thông minh ở câu hỏi đầu tiên và nén tóm tắt ngữ cảnh khi vượt mốc 12 tin nhắn.
    """
    try:
        # Chuẩn hóa chức danh và phòng ban của nhân viên phục vụ phân quyền dữ liệu (PBAC)
        jobs = request.user_jobs if (request.user_jobs and request.user_jobs != ["ALL"]) else (request.user_roles or request.user_jobs or ["ALL"])
        depts = [request.department] if request.department else ["ALL"]

        result = chat_service.answer_query(
            question=request.question,
            conversation_id=request.conversation_id,
            user_id=request.user_id or "ANONYMOUS",
            jobs=jobs,
            departments=depts,
            top_k=request.top_k,
            background_tasks=background_tasks
        )
        return result
    except Exception as e:
        print(f"[chat_query] Error: {e}")
        raise HTTPException(status_code=500, detail=f"Lỗi khi xử lý câu hỏi: {str(e)}")


@app.post("/api/v1/chat/stream", dependencies=[Security(verify_internal_secret)])
async def chat_stream(request: ChatQueryRequest, background_tasks: BackgroundTasks):
    """
    API Hỏi - Đáp Chatbot AI RAG (Chế độ Truyền luồng thời gian thực - Server-Sent Events / SSE):
    
    Định dạng các gói tin sự kiện (SSE Events) bắn về phía client:
      1. Event 'start':
         data: {"type": "start", "conversation_id": "<uuid>", "title": "<tiêu đề tạm>"}
         -> Giúp giao diện khởi tạo khung chat ngay lập tức (First-Token Latency < 0.5s).
         
      2. Event 'token':
         data: {"type": "token", "content": "..."}
         -> Chứa từng từ/âm tiết do LLM Ollama 120B sinh ra theo thời gian thực.
         
      3. Event 'citations':
         data: {"type": "citations", "citations": [...], "confidence": "HIGH|MEDIUM|LOW", "rewritten_query": "..."}
         -> Chứa danh sách các điều khoản, trang và tài liệu tham khảo kèm độ tin cậy.
         
      4. Event 'done':
         data: {"type": "done"}
         -> Thông báo kết thúc luồng truyền dữ liệu thành công.
         
    * Ghi chú: Sau khi stream kết thúc, toàn bộ nội dung câu trả lời và trích dẫn được tự động lưu vào PostgreSQL.
    """
    try:
        # Chuẩn hóa chức danh và phòng ban của nhân viên phục vụ phân quyền dữ liệu (PBAC)
        jobs = request.user_jobs if (request.user_jobs and request.user_jobs != ["ALL"]) else (request.user_roles or request.user_jobs or ["ALL"])
        depts = [request.department] if request.department else ["ALL"]

        generator = chat_service.answer_query_stream(
            question=request.question,
            conversation_id=request.conversation_id,
            user_id=request.user_id or "ANONYMOUS",
            jobs=jobs,
            departments=depts,
            top_k=request.top_k,
            background_tasks=background_tasks
        )
        return StreamingResponse(generator, media_type="text/event-stream")
    except Exception as e:
        print(f"[chat_stream] Error: {e}")
        raise HTTPException(status_code=500, detail=f"Lỗi khi xử lý streaming: {str(e)}")


@app.get("/api/v1/chat/conversations", dependencies=[Security(verify_internal_secret)])
async def list_conversations(user_id: str = Query(..., description="ID nhân viên")):
    """Lấy danh sách các cuộc trò chuyện của 1 nhân viên."""
    try:
        conversations = chat_service.list_conversations(user_id=user_id)
        return {"user_id": user_id, "conversations": conversations}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi lấy danh sách hội thoại: {str(e)}")


@app.get("/api/v1/chat/conversations/{conversation_id}", dependencies=[Security(verify_internal_secret)])
async def get_conversation_detail(conversation_id: str, user_id: Optional[str] = Query(None)):
    """Lấy chi tiết toàn bộ tin nhắn trong 1 cuộc trò chuyện."""
    try:
        conv = chat_service.get_conversation_detail(conversation_id=conversation_id, user_id=user_id)
        if not conv:
            raise HTTPException(status_code=404, detail="Không tìm thấy cuộc trò chuyện!")
        return conv
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi lấy chi tiết hội thoại: {str(e)}")


@app.delete("/api/v1/chat/conversations/{conversation_id}", dependencies=[Security(verify_internal_secret)])
async def delete_conversation(conversation_id: str, user_id: Optional[str] = Query(None)):
    """Xóa 1 cuộc trò chuyện."""
    try:
        deleted = chat_service.delete_conversation(conversation_id=conversation_id, user_id=user_id)
        if not deleted:
            raise HTTPException(status_code=404, detail="Không tìm thấy cuộc trò chuyện để xóa!")
        return {"status": "success", "message": "Đã xóa cuộc trò chuyện thành công!"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi xóa hội thoại: {str(e)}")


class UpdateConversationTitleRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=150, description="Tiêu đề mới cho cuộc trò chuyện")
    user_id: Optional[str] = Field(None, description="ID nhân viên (để bảo mật)")


@app.put("/api/v1/chat/conversations/{conversation_id}", dependencies=[Security(verify_internal_secret)])
async def update_conversation_title(conversation_id: str, request: UpdateConversationTitleRequest):
    """Đổi tên cuộc hội thoại thủ công."""
    try:
        updated = chat_service.update_conversation_title(
            conversation_id=conversation_id,
            new_title=request.title,
            user_id=request.user_id
        )
        if not updated:
            raise HTTPException(status_code=404, detail="Không tìm thấy cuộc trò chuyện để đổi tên!")
        return {
            "status": "success",
            "conversation_id": conversation_id,
            "title": request.title,
            "message": "Đổi tên cuộc hội thoại thành công!"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi đổi tên hội thoại: {str(e)}")


@app.post("/api/v1/chat/conversations/{conversation_id}/generate-title", dependencies=[Security(verify_internal_secret)])
async def regenerate_conversation_title(conversation_id: str, user_id: Optional[str] = Query(None)):
    """Kích hoạt AI tự động sinh lại tiêu đề 3-5 từ cho cuộc trò chuyện dựa vào câu hỏi đầu tiên."""
    try:
        new_title = chat_service.regenerate_conversation_title(conversation_id=conversation_id, user_id=user_id)
        if not new_title:
            raise HTTPException(status_code=404, detail="Không tìm thấy cuộc hội thoại hoặc chưa có tin nhắn nào từ nhân viên!")
        return {
            "status": "success",
            "conversation_id": conversation_id,
            "title": new_title,
            "message": "AI đã tạo tiêu đề thông minh thành công!"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi sinh lại tiêu đề: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

