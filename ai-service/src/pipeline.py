"""
Document Ingestion Pipeline Orchestrator.
Connects Document Parser -> Structure-Aware Chunker -> Metadata Enricher.
"""
from pathlib import Path
from typing import List, Optional
import json

from src.models.schema import ProcessedChunk, ParsedDocument
from src.parsers.pdf_parser import PDFParser
from src.parsers.docx_parser import DOCXParser
from src.parsers.excel_parser import ExcelParser
from src.chunkers.legal_chunker import LegalChunker
from src.metadata.metadata_enricher import MetadataEnricher


class IngestionPipeline:
    def __init__(
        self,
        max_chunk_chars: int = 1500,
        min_chunk_chars: int = 80,
        enrich_with_llm: bool = True,
        llm_provider: Optional[str] = None
    ):
        self.chunker = LegalChunker(max_chunk_chars=max_chunk_chars, min_chunk_chars=min_chunk_chars)
        self.enrich_with_llm = enrich_with_llm
        self.enricher = MetadataEnricher(provider=llm_provider) if enrich_with_llm else None

    def process_file(
        self, 
        file_path: Path | str, 
        allowed_jobs: Optional[List[str]] = None,
        allowed_departments: Optional[List[str]] = None,
        allowed_roles: Optional[List[str]] = None
    ) -> List[ProcessedChunk]:
        """
        Full end-to-end ingestion:
        1. Parse file based on extension
        2. Structure-aware chunking (preserving tables & hierarchy)
        3. Metadata enrichment (Summary, Keywords, Hypothetical Questions)
        """
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {path}")

        ext = path.suffix.lower()

        # Step 1: Parsing
        if ext == ".pdf":
            parser = PDFParser()
        elif ext == ".docx":
            parser = DOCXParser()
        elif ext in [".xlsx", ".xls"]:
            parser = ExcelParser()
        elif ext == ".doc":
            raise ValueError("Định dạng Word cũ (.doc) không được hỗ trợ trực tiếp. Vui lòng lưu/chuyển đổi file sang định dạng .docx trước khi tải lên.")
        else:
            raise ValueError(f"Unsupported file format: {ext}. Supported: .pdf, .docx, .xlsx")

        parsed_doc: ParsedDocument = parser.parse(path)

        # Step 2: Structure-aware chunking
        chunks = self.chunker.chunk(parsed_doc)

        # Apply PBAC (Job & Department) overrides if provided
        effective_jobs = allowed_jobs or allowed_roles or ["ALL"]
        effective_depts = allowed_departments or ["ALL"]
        for c in chunks:
            c.allowed_jobs = effective_jobs
            c.allowed_departments = effective_depts

        # Step 3: Metadata creation & enrichment
        if self.enrich_with_llm and self.enricher:
            chunks = self.enricher.enrich_all(chunks)

        return chunks

    @staticmethod
    def export_to_json(chunks: List[ProcessedChunk], output_file: Path | str):
        """Export processed chunks to JSON for debugging or database batch insert."""
        data = [chunk.model_dump() for chunk in chunks]
        out_path = Path(output_file)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"[IngestionPipeline] Exported {len(chunks)} chunks to {out_path}")
