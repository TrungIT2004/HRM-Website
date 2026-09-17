"""
Structure-Aware Legal & Policy Chunker.
Detects Vietnamese administrative/legal headings (Chương, Mục, Điều, Khoản),
maintains hierarchical breadcrumb trails, and ensures natural semantic boundaries.
"""
from typing import List, Optional
import re

from src.models.schema import DocumentBlock, ParsedDocument, ProcessedChunk


class LegalChunker:
    def __init__(self, max_chunk_chars: int = 1500, min_chunk_chars: int = 80):
        self.max_chunk_chars = max_chunk_chars
        self.min_chunk_chars = min_chunk_chars

    def _build_breadcrumb(self, doc_name: str, h1: Optional[str], h2: Optional[str], h3: Optional[str]) -> str:
        parts = [doc_name]
        if h1:
            parts.append(h1)
        if h2:
            parts.append(h2)
        if h3:
            parts.append(h3)
        return " > ".join(parts)

    def chunk(self, parsed_doc: ParsedDocument) -> List[ProcessedChunk]:
        chunks: List[ProcessedChunk] = []
        doc_name = parsed_doc.document_name

        current_h1: Optional[str] = None  # Chương / Phần
        current_h2: Optional[str] = None  # Điều / Mục
        current_h3: Optional[str] = None  # Khoản / Tiêu đề phụ

        current_buffer: List[str] = []
        current_page: int = 1

        def flush_buffer(force: bool = False):
            nonlocal current_buffer
            if not current_buffer:
                return

            text_content = "\n\n".join(current_buffer).strip()
            min_limit = 20 if force else self.min_chunk_chars
            if len(text_content) >= min_limit:
                breadcrumb = self._build_breadcrumb(doc_name, current_h1, current_h2, current_h3)
                chunks.append(ProcessedChunk(
                    document_name=doc_name,
                    breadcrumb=breadcrumb,
                    chunk_type="TEXT",
                    page_number=current_page,
                    content=text_content,
                    allowed_roles=["ROLE_EMPLOYEE", "ROLE_MANAGER", "ROLE_ADMIN"],
                    allowed_departments=["ALL"]
                ))
            current_buffer = []

        for block in parsed_doc.blocks:
            current_page = block.page_number

            if block.block_type == "TABLE":
                # Flush existing text buffer before recording the table
                flush_buffer()

                breadcrumb = self._build_breadcrumb(doc_name, current_h1, current_h2, current_h3)
                # Tables are always kept intact as standalone TABLE chunks
                chunks.append(ProcessedChunk(
                    document_name=doc_name,
                    breadcrumb=f"{breadcrumb} (Bảng biểu)",
                    chunk_type="TABLE",
                    page_number=current_page,
                    content=block.content,
                    allowed_roles=["ROLE_EMPLOYEE", "ROLE_MANAGER", "ROLE_ADMIN"],
                    allowed_departments=["ALL"]
                ))
                continue

            if block.block_type == "HEADING":
                level = block.heading_level or 1
                if level == 1:
                    flush_buffer()
                    current_h1 = block.content
                    current_h2 = None
                    current_h3 = None
                elif level == 2:
                    flush_buffer()
                    current_h2 = block.content
                    current_h3 = None
                elif level == 3:
                    flush_buffer()
                    current_h3 = block.content
                continue

            # PARAGRAPH
            text = block.content.strip()
            if not text:
                continue

            # Check if this paragraph starts a new "Điều" or "Khoản" that wasn't tagged as heading
            dieu_match = re.match(r'^(ĐIỀU|Điều)\s+(\d+)[:\.\s]*(.*)$', text, re.IGNORECASE)
            if dieu_match:
                flush_buffer()
                current_h2 = text.split('\n')[0]
                current_h3 = None
                current_buffer.append(text)
                continue

            # Check buffer size to avoid overly large chunks
            projected_len = sum(len(p) for p in current_buffer) + len(text)
            if projected_len > self.max_chunk_chars:
                flush_buffer()

            current_buffer.append(text)

        # Flush any remaining text at the end of document
        if not current_buffer and (current_h2 or current_h1):
            if current_h2 and current_h2 not in [c.content for c in chunks]:
                current_buffer.append(current_h2)
            elif current_h1 and current_h1 not in [c.content for c in chunks]:
                current_buffer.append(current_h1)

        flush_buffer(force=True)

        return chunks
