-- =====================================================================
-- BẢNG SEMANTIC CACHING CHO CHATBOT AI RAG (HRM SYSTEM)
-- Lưu trữ câu hỏi, vector 768d, câu trả lời và trích dẫn để phản hồi ngay (<50ms)
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS semantic_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text TEXT NOT NULL,                                              -- Câu hỏi nguyên bản của nhân viên
    query_vector VECTOR(768) NOT NULL,                                     -- Vector 768 chiều của câu hỏi
    response_text TEXT NOT NULL,                                           -- Câu trả lời do AI sinh ra
    citations JSONB DEFAULT '[]'::jsonb,                                   -- Danh sách tài liệu/điều khoản trích dẫn
    allowed_jobs VARCHAR[] DEFAULT ARRAY['ALL'],                            -- Phân quyền chức danh (Job Title) xem câu trả lời
    allowed_departments VARCHAR[] DEFAULT ARRAY['ALL'],                    -- Phân quyền phòng ban
    hit_count INT DEFAULT 1,                                               -- Số lượt nhân viên hỏi trúng câu này
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Chỉ mục HNSW cho vector câu hỏi để tìm kiếm độ tương đồng Cosine siêu tốc
CREATE INDEX IF NOT EXISTS idx_semantic_cache_vector ON semantic_cache 
USING hnsw (query_vector vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Chỉ mục GIN lọc quyền hạn người dùng (PBAC: Job & Department)
CREATE INDEX IF NOT EXISTS idx_semantic_cache_jobs ON semantic_cache USING GIN (allowed_jobs);
CREATE INDEX IF NOT EXISTS idx_semantic_cache_depts ON semantic_cache USING GIN (allowed_departments);
