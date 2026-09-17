"""
Metadata Creation Module: Summary Generator, Keyword Extractor, and Question Generator.
Enriches raw document chunks to prepare for Multi-Vector and Hybrid Search.
"""
import os
from dotenv import load_dotenv
load_dotenv()

import json
import re
from typing import List, Optional
from pydantic import BaseModel, Field

from src.models.schema import ProcessedChunk


class ChunkEnrichmentResult(BaseModel):
    summary: str = Field(description="1-2 sentences summarizing the chunk's core rule/information")
    keywords: List[str] = Field(description="5-7 entities, policy terms, department names, or regulation codes")
    hypothetical_questions: List[str] = Field(
        description="3-5 natural questions employees would ask that this chunk answers (Reverse HyDE)"
    )


ENRICHMENT_PROMPT = """Bạn là Chuyên gia Phân tích Văn bản Quản trị Nhân sự (HR Policy Analyst).
Hãy đọc kỹ đoạn văn bản quy định nội bộ của doanh nghiệp dưới đây:

---
[ĐƯỜNG DẪN NGỮ CẢNH]: {breadcrumb}
[LOẠI NỘI DUNG]: {chunk_type}
[NỘI DUNG VĂN BẢN]:
{content}
---

Hãy thực hiện 3 nhiệm vụ và trả về kết quả định dạng JSON:
1. "summary": Tóm tắt súc tích trong 1-2 câu về quy định/thông tin cốt lõi của đoạn này.
2. "keywords": Danh sách 5-7 từ khóa quan trọng (tên chính sách, mã quyết định, phòng ban áp dụng, chế độ, đối tượng).
3. "hypothetical_questions": Danh sách 3-5 câu hỏi tự nhiên mà người lao động/nhân viên công ty thường sẽ đặt ra nếu họ muốn tìm kiếm thông tin trong đoạn này.

Định dạng JSON BẮT BUỘC:
{{
  "summary": "...",
  "keywords": ["từ khóa 1", "từ khóa 2", "..."],
  "hypothetical_questions": ["câu hỏi 1?", "câu hỏi 2?", "..."]
}}
Chỉ trả về chuỗi JSON hợp lệ, không thêm chữ giải thích bên ngoài.
"""


class MetadataEnricher:
    def __init__(self, provider: Optional[str] = None):
        self.provider = provider or os.getenv("LLM_PROVIDER", "gemini").lower()
        self.gemini_key = os.getenv("GEMINI_API_KEY")
        self.openai_key = os.getenv("OPENAI_API_KEY")
        self.ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434/v1")
        self.ollama_api_key = os.getenv("OLLAMA_API_KEY", "ollama") # Cloud Ollama might require key

        # Initialize clients lazily or if keys exist
        self.gemini_client = None
        self.openai_client = None
        self.ollama_client = None

        if self.provider == "gemini" and self.gemini_key and self.gemini_key != "your_gemini_api_key_here":
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.gemini_key)
                self.gemini_client = genai.GenerativeModel(
                    os.getenv("GEMINI_MODEL", "gemini-1.5-flash"),
                    generation_config={"response_mime_type": "application/json"}
                )
            except Exception as e:
                print(f"[MetadataEnricher] Warning: Failed to init Gemini client: {e}")

        elif self.provider == "openai" and self.openai_key and self.openai_key != "your_openai_api_key_here":
            try:
                from openai import OpenAI
                self.openai_client = OpenAI(api_key=self.openai_key)
            except Exception as e:
                print(f"[MetadataEnricher] Warning: Failed to init OpenAI client: {e}")
                
        elif self.provider == "ollama":
            try:
                from openai import OpenAI
                # Ollama is compatible with the OpenAI API SDK
                self.ollama_client = OpenAI(
                    base_url=self.ollama_base_url,
                    api_key=self.ollama_api_key
                )
            except Exception as e:
                print(f"[MetadataEnricher] Warning: Failed to init Ollama client: {e}")

    def _fallback_enrichment(self, chunk: ProcessedChunk) -> ChunkEnrichmentResult:
        """Heuristic offline generator used if no API key is available or API calls fail."""
        text = chunk.content.strip()
        lines = [line.strip() for line in text.split("\n") if line.strip()]

        # Generate summary
        first_line = lines[0] if lines else chunk.breadcrumb
        summary = f"Quy định liên quan đến {chunk.breadcrumb.split('>')[-1].strip()}: {first_line[:120]}..."

        # Extract keywords using simple regex
        words = re.findall(r'\b[A-Za-zÀ-ỹ0-9_/%-]{3,}\b', text)
        keywords = list(dict.fromkeys(words[:7]))  # Deduplicate

        # Heuristic hypothetical questions
        sub_title = chunk.breadcrumb.split('>')[-1].strip()
        questions = [
            f"Quy định về {sub_title} như thế nào?",
            f"Nhân viên cần lưu ý gì về {sub_title}?",
            f"Chính sách {sub_title} áp dụng cho đối tượng nào?"
        ]

        return ChunkEnrichmentResult(
            summary=summary,
            keywords=keywords,
            hypothetical_questions=questions
        )

    def enrich_chunk(self, chunk: ProcessedChunk) -> ProcessedChunk:
        """Enriches a single chunk with summary, keywords, and hypothetical questions."""
        prompt = ENRICHMENT_PROMPT.format(
            breadcrumb=chunk.breadcrumb,
            chunk_type=chunk.chunk_type,
            content=chunk.content[:2500]  # Cap context to prevent token overflows
        )

        result: Optional[ChunkEnrichmentResult] = None

        # 1. Try Gemini
        if self.gemini_client:
            try:
                response = self.gemini_client.generate_content(prompt)
                parsed = json.loads(response.text)
                result = ChunkEnrichmentResult(**parsed)
            except Exception as e:
                print(f"[MetadataEnricher] Gemini call failed for chunk {chunk.chunk_id}: {e}")

        # 2. Try OpenAI
        elif self.openai_client:
            try:
                model_name = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
                response = self.openai_client.chat.completions.create(
                    model=model_name,
                    messages=[{"role": "user", "content": prompt}],
                    response_format={"type": "json_object"}
                )
                parsed = json.loads(response.choices[0].message.content)
                result = ChunkEnrichmentResult(**parsed)
            except Exception as e:
                print(f"[MetadataEnricher] OpenAI call failed for chunk {chunk.chunk_id}: {e}")
                
        # 3. Try Ollama (API compatible with OpenAI)
        elif self.ollama_client:
            try:
                model_name = os.getenv("OLLAMA_MODEL", "gpt-oss:120B")
                response = self.ollama_client.chat.completions.create(
                    model=model_name,
                    messages=[{"role": "user", "content": prompt}],
                    # Not all Ollama models natively support json_object strictly, 
                    # but specifying format helps. You might need to parse robustly.
                    response_format={"type": "json_object"}
                )
                
                # Sometime Ollama adds markdown ```json blocks
                content = response.choices[0].message.content.strip()
                if content.startswith("```json"):
                    content = content[7:]
                if content.endswith("```"):
                    content = content[:-3]
                    
                parsed = json.loads(content.strip())
                result = ChunkEnrichmentResult(**parsed)
            except Exception as e:
                print(f"[MetadataEnricher] Ollama call failed for chunk {chunk.chunk_id}: {e}")

        # 4. Fallback
        if not result:
            result = self._fallback_enrichment(chunk)

        chunk.summary = result.summary
        chunk.keywords = result.keywords
        chunk.hypothetical_questions = result.hypothetical_questions

        return chunk

    def enrich_all(self, chunks: List[ProcessedChunk], show_progress: bool = True) -> List[ProcessedChunk]:
        """Batch enriches a list of chunks."""
        enriched: List[ProcessedChunk] = []
        for c in chunks:
            enriched.append(self.enrich_chunk(c))
        return enriched
