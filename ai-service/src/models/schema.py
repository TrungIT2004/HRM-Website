"""
Data schemas for the Ingestion Pipeline.
Defines models for raw parsed blocks, documents, and enriched chunks.
"""
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import uuid


class DocumentBlock(BaseModel):
    """Represents a structural block in a parsed document (Heading, Paragraph, Table)."""
    block_type: str = Field(description="'HEADING', 'PARAGRAPH', or 'TABLE'")
    content: str = Field(description="Text content or Markdown formatted table")
    page_number: int = Field(default=1, description="1-based page number")
    heading_level: Optional[int] = Field(default=None, description="1 for Chương/Title, 2 for Điều, 3 for Khoản")
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ParsedDocument(BaseModel):
    """Complete document extracted into structured blocks."""
    document_name: str
    file_type: str
    total_pages: int = 1
    blocks: List[DocumentBlock] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)


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
    page_number: int = 1
    content: str = Field(description="The primary chunk content (text or markdown table)")
    
    # Enriched Metadata (from ByteMonk Architecture)
    summary: str = Field(default="", description="1-2 sentences context summary")
    keywords: List[str] = Field(default_factory=list, description="Extracted keywords and entities for BM25/keyword search")
    hypothetical_questions: List[str] = Field(
        default_factory=list, 
        description="3-5 hypothetical questions that this chunk answers (Reverse HyDE)"
    )
    
    # Access Control (RBAC)
    allowed_roles: List[str] = Field(default_factory=lambda: ["ROLE_EMPLOYEE", "ROLE_MANAGER", "ROLE_ADMIN"])
    allowed_departments: List[str] = Field(default_factory=lambda: ["ALL"])
    
    # Vector Embeddings
    content_vector: Optional[List[float]] = Field(default=None, description="Embedding of the content (768d)")
    questions_vector: Optional[List[float]] = Field(default=None, description="Embedding of the hypothetical questions (768d)")
    
    extra_metadata: Dict[str, Any] = Field(default_factory=dict)

    def to_formatted_markdown(self) -> str:
        """Returns chunk with breadcrumb header for downstream LLM context."""
        header = f"[{self.breadcrumb}]"
        if self.summary:
            header += f"\n[Ngữ cảnh tóm tắt: {self.summary}]"
        return f"{header}\n\n{self.content}"
