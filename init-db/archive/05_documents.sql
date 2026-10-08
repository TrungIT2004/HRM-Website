-- Bảng mẫu đơn / biểu mẫu dùng chung toàn công ty (module documents).
-- Tách khỏi knowledge_documents của AI service (RAG + PBAC) — bảng này public, không phân quyền phòng ban.
-- Volume DB mới tự chạy theo thứ tự tên file; volume cũ chạy tay: psql -d hrm -f init-db/05_documents.sql

CREATE TABLE IF NOT EXISTS documents (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(20) NOT NULL CHECK (category IN ('HANDOVER', 'MEETING', 'RECRUITMENT', 'LEAVE', 'RESIGN', 'HDLD')),
    document_name VARCHAR(255) NOT NULL,
    document_title VARCHAR(255) NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(10) NOT NULL CHECK (file_type IN ('DOCX', 'DOC', 'PDF', 'XLSX', 'XLS', 'PPT', 'PPTX')),
    file_size BIGINT NOT NULL CHECK (file_size > 0),
    summary TEXT,
    uploader_id UUID,
    uploader_name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_active_category ON documents (is_active, category);
