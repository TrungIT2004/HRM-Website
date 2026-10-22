"""
Data schemas for the Ingestion Pipeline.
Defines models for raw parsed blocks, documents, and enriched chunks.
"""
from typing import List, Any, Optional
from pydantic import BaseModel, Field
import uuid


class DocumentBlock(BaseModel):
    """Represents a structural block in a parsed document (Heading, Paragraph, Table)."""
    block_type: str = Field(description="'HEADING', 'PARAGRAPH', or 'TABLE'")
    content: str = Field(description="Text content or Markdown formatted table")
    page_number: Optional[int] = Field(default=None, description="1-based page number; None when the format has no real pagination (docx, xlsx)")
    heading_level: Optional[int] = Field(default=None, description="1 for Chương/Title, 2 for Điều, 3 for Khoản")


class ParsedDocument(BaseModel):
    """Complete document extracted into structured blocks."""
    document_name: str
    file_type: str
    blocks: List[DocumentBlock] = Field(default_factory=list)


class ProcessedChunk(BaseModel):
    """
    A structure-aware chunk ready for vector storage and retrieval.
    Includes enriched metadata: summary, keywords, and hypothetical questions.
    """
    chunk_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    document_name: str
    document_id: Optional[str] = None
    breadcrumb: str = Field(description="Hierarchical path, e.g. 'Nội quy 2024 > Chương II > Điều 5'")
    chunk_type: str = Field(default="TEXT", description="'TEXT' or 'TABLE'")
    page_number: Optional[int] = None
    content: str = Field(description="The primary chunk content (text or markdown table)")
    
    # Enriched Metadata (from ByteMonk Architecture)
    summary: str = Field(default="", description="1-2 sentences context summary")
    keywords: List[str] = Field(default_factory=list, description="Extracted keywords and entities for BM25/keyword search")
    hypothetical_questions: List[str] = Field(
        default_factory=list, 
        description="3-5 hypothetical questions that this chunk answers (Reverse HyDE)"
    )
    
    # Access Control (PBAC: Job & Department)
    allowed_jobs: List[str] = Field(default_factory=lambda: ["ALL"], description="Danh sách chức danh được phép truy cập (Job titles), hoặc ['ALL']")
    allowed_departments: List[str] = Field(default_factory=lambda: ["ALL"], description="Danh sách phòng ban được phép truy cập, hoặc ['ALL']")
    allowed_roles: Optional[List[str]] = Field(default=None, description="Tương thích ngược với allowed_jobs")

    def model_post_init(self, __context: Any) -> None:
        if self.allowed_roles is not None and (not self.allowed_jobs or self.allowed_jobs == ["ALL"]):
            self.allowed_jobs = self.allowed_roles
        elif self.allowed_roles is None:
            self.allowed_roles = self.allowed_jobs
    
    # Vector Embeddings
    content_vector: Optional[List[float]] = Field(default=None, description="Embedding of the content (768d)")
    questions_vector: Optional[List[float]] = Field(default=None, description="Embedding of the hypothetical questions (768d)")
