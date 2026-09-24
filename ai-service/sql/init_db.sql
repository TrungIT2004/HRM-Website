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
    allowed_jobs VARCHAR[] DEFAULT ARRAY['ALL'],                            -- Phân quyền chức danh (Job Title)
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
    
    -- Nhóm Siêu dữ liệu & Phân quyền (Metadata & PBAC)
    summary TEXT,
    keywords TEXT[],                        -- Mảng từ khóa để tìm kiếm Full-text
    hypothetical_questions TEXT[],          -- Câu hỏi giả định lưu dạng text để tham khảo
    allowed_jobs VARCHAR[] NOT NULL DEFAULT ARRAY['ALL'],         -- Phân quyền chức vụ [Department Head, Software Engineer, ALL]
    allowed_departments VARCHAR[] NOT NULL DEFAULT ARRAY['ALL'],  -- Phân quyền phòng ban [IT, HR, ALL]
    
    -- Nhóm Vector 768 chiều (Google Gemini text-embedding-004)
    content_vector VECTOR(768),            
    questions_vector VECTOR(768),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Đánh Index (Chỉ mục) để tối ưu tốc độ truy vấn HÀNG TRIỆU DÒNG

-- 4.1. GIN Index cho mảng Quyền (PBAC: Job & Department) để chặn/lọc bảo mật siêu tốc
CREATE INDEX IF NOT EXISTS idx_chunks_jobs ON document_chunks USING GIN (allowed_jobs);
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

-- 5. Bảng Quản lý Cuộc trò chuyện & Bộ nhớ ngữ cảnh (Conversational Memory)
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    context_summary TEXT,                    -- Nén tóm tắt ngữ cảnh khi hội thoại dài (>12 tin nhắn)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_conv_user ON chat_conversations (user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conv_updated ON chat_conversations (updated_at DESC);

-- 6. Bảng Quản lý Lịch sử Tin nhắn (Chat Messages)
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_role VARCHAR(20) NOT NULL,        -- USER hoặc ASSISTANT
    content TEXT NOT NULL,
    rewritten_query TEXT,                    -- Câu hỏi độc lập được viết lại (Query Condensation)
    citations JSONB DEFAULT '[]'::jsonb,     -- Danh sách trích dẫn điều khoản/trang/tài liệu
    confidence VARCHAR(20),                  -- HIGH, MEDIUM, LOW
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conv ON chat_messages (conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON chat_messages (created_at ASC);

-- 7. Bảng Semantic Caching (Bộ nhớ đệm ngữ nghĩa siêu tốc <30ms)
CREATE TABLE IF NOT EXISTS semantic_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text TEXT NOT NULL,
    query_vector VECTOR(768) NOT NULL,
    response_text TEXT NOT NULL,
    citations JSONB DEFAULT '[]'::jsonb,
    allowed_jobs VARCHAR[] DEFAULT ARRAY['ALL'],
    allowed_departments VARCHAR[] DEFAULT ARRAY['ALL'],
    hit_count INT DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_semantic_cache_vector ON semantic_cache 
USING hnsw (query_vector vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS idx_semantic_cache_jobs ON semantic_cache USING GIN (allowed_jobs);
CREATE INDEX IF NOT EXISTS idx_semantic_cache_depts ON semantic_cache USING GIN (allowed_departments);
