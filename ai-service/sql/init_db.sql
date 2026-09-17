-- 1. Kích hoạt extension pgvector (BẮT BUỘC)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- Hỗ trợ tìm kiếm full-text mờ (fuzzy search)

-- 2. Bảng quản lý Tài liệu gốc (File upload lên)
CREATE TABLE IF NOT EXISTS knowledge_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50),                   -- pdf, docx, xlsx
    file_hash VARCHAR(64) UNIQUE,            -- Mã băm SHA-256 chống trùng lặp
    file_path VARCHAR(500),                  -- Đường dẫn lưu file trên ổ cứng
    file_size BIGINT,                        -- Dung lượng file (bytes)
    uploaded_by VARCHAR(100),                -- Người upload (User ID)
    status VARCHAR(50) DEFAULT 'PROCESSING', -- PROCESSING, COMPLETED, FAILED
    allowed_roles VARCHAR[] DEFAULT ARRAY['ROLE_EMPLOYEE', 'ROLE_MANAGER'], -- Phân quyền vai trò
    allowed_departments VARCHAR[] DEFAULT ARRAY['ALL'],                     -- Phân quyền phòng ban
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bảng cốt lõi: Lưu trữ Chunks và Vectors
CREATE TABLE IF NOT EXISTS document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES knowledge_documents(id) ON DELETE CASCADE,
    
    -- Nhóm Dữ liệu gốc (Raw Data)
    chunk_index INT NOT NULL,               -- Thứ tự chunk trong tài liệu
    chunk_type VARCHAR(50) NOT NULL,        -- TEXT hoặc TABLE
    breadcrumb TEXT,                        -- Đường dẫn ngữ cảnh (VD: Chương I > Điều 1)
    content TEXT NOT NULL,                  -- Nội dung chữ gốc hoặc Markdown Table
    page_number INT,
    
    -- Nhóm Siêu dữ liệu & Phân quyền (Metadata & RBAC)
    summary TEXT,
    keywords TEXT[],                        -- Mảng từ khóa để tìm kiếm Full-text
    hypothetical_questions TEXT[],          -- Câu hỏi giả định lưu dạng text để tham khảo
    allowed_roles VARCHAR[] NOT NULL,       -- [ROLE_EMPLOYEE, ROLE_MANAGER]
    allowed_departments VARCHAR[] NOT NULL, -- [IT, HR, ALL]
    
    -- Nhóm Vector 768 chiều (Google Gemini text-embedding-004)
    content_vector VECTOR(768),            
    questions_vector VECTOR(768),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Đánh Index (Chỉ mục) để tối ưu tốc độ truy vấn HÀNG TRIỆU DÒNG

-- 4.1. GIN Index cho mảng Quyền (RBAC) để chặn/lọc bảo mật siêu tốc
CREATE INDEX IF NOT EXISTS idx_chunks_roles ON document_chunks USING GIN (allowed_roles);
CREATE INDEX IF NOT EXISTS idx_chunks_departments ON document_chunks USING GIN (allowed_departments);

-- 4.2. GIN Index cho Keywords để tìm kiếm từ khóa (BM25 style)
CREATE INDEX IF NOT EXISTS idx_chunks_keywords ON document_chunks USING GIN (keywords);

-- 4.3. HNSW Index cho Vector (Thuật toán xịn nhất của pgvector để tìm kiếm ngữ nghĩa siêu tốc)
CREATE INDEX IF NOT EXISTS idx_chunks_content_vec ON document_chunks 
USING hnsw (content_vector vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS idx_chunks_questions_vec ON document_chunks 
USING hnsw (questions_vector vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
