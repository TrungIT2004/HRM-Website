"""
Metadata Creation Module: Summary Generator, Keyword Extractor, and Question Generator.
Enriches raw document chunks to prepare for Multi-Vector and Hybrid Search.
"""
import os
import json
import re
import time
import threading
from typing import List, Optional
from pydantic import BaseModel, Field
from concurrent.futures import ThreadPoolExecutor

from dotenv import load_dotenv
load_dotenv()

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


class TokenBucket:
    """Token bucket rate limiter for API key quota management."""

    def __init__(self, rpm: int, cost_per_call: int = 1):
        self.rpm = rpm
        self.capacity = rpm
        self.cost_per_call = cost_per_call
        self._tokens = float(rpm)
        self._last_refill = time.time()
        self._lock = threading.Lock()

    def _refill(self) -> None:
        now = time.time()
        elapsed = now - self._last_refill
        refill_amount = elapsed * (self.rpm / 60.0)
        self._tokens = min(self.capacity, self._tokens + refill_amount)
        self._last_refill = now

    def available(self) -> float:
        with self._lock:
            self._refill()
            return self._tokens

    def try_take(self, cost: Optional[int] = None) -> bool:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                self._tokens -= cost
                return True
            return False

    def take(self, cost: Optional[int] = None) -> float:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                self._tokens -= cost
                return 0.0
            deficit = cost - self._tokens
            wait_time = deficit / (self.rpm / 60.0)
        if wait_time > 0:
            time.sleep(wait_time)
        with self._lock:
            self._refill()
            self._tokens = max(0.0, self._tokens - cost)
        return wait_time

    def time_until_ready(self, cost: Optional[int] = None) -> float:
        cost = cost or self.cost_per_call
        with self._lock:
            self._refill()
            if self._tokens >= cost:
                return 0.0
            deficit = cost - self._tokens
            return deficit / (self.rpm / 60.0)


class MetadataEnricher:
    def __init__(self, provider: Optional[str] = None):
        self.provider = provider or os.getenv("LLM_PROVIDER", "gemini").lower()
        self.nvidia_api_key = os.getenv("NVIDIA_API_KEY")
        self.nvidia_base_url = os.getenv("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1")

        # Clients
        self.nvidia_client = None
        self.gemini_clients = []
        self.gemini_key_buckets = []
        self.gemini_invalid_keys = set()
        self.gemini_affinity = {}
        self.gemini_affinity_lock = threading.Lock()

        # Load Gemini API keys for enrichment (7-key rotation)
        if self.provider == "gemini":
            self._init_gemini_clients()

        # Initialize NVIDIA provider
        if self.provider == "nvidia" and self.nvidia_api_key and self.nvidia_api_key != "your_nvidia_api_key_here":
            try:
                from openai import OpenAI
                self.nvidia_client = OpenAI(
                    api_key=self.nvidia_api_key,
                    base_url=self.nvidia_base_url
                )
            except Exception as e:
                print(f"[MetadataEnricher] Warning: Failed to init NVIDIA client: {e}")

    def _load_gemini_keys(self) -> List[str]:
        """Load Gemini API keys from environment (GEMINI_API_KEY_0 through GEMINI_API_KEY_6 = 7 keys)."""
        keys = []
        for i in range(7):
            key = os.getenv(f"GEMINI_API_KEY_{i}")
            if key and key != f"your_gemini_api_key_{i}_here":
                keys.append(key)

        if len(keys) == 7:
            print(f"[MetadataEnricher] Loaded 7 Gemini API keys for enrichment rotation")
            return keys
        elif len(keys) > 0:
            print(f"[MetadataEnricher] Loaded {len(keys)} Gemini API keys for enrichment rotation")
            return keys

        # Fallback: try single GEMINI_API_KEY
        single_key = os.getenv("GEMINI_API_KEY")
        if single_key and single_key != "your_gemini_api_key_here":
            print(f"[MetadataEnricher] Using single GEMINI_API_KEY for enrichment")
            return [single_key] * 7

        print("[MetadataEnricher] Warning: No Gemini API keys found, enrichment will use fallback")
        return []

    def _init_gemini_clients(self):
        """Initialize Gemini clients with token bucket rate limiting (30 RPM for enrichment)."""
        from google import genai
        from google.genai import types

        self.gemini_keys = self._load_gemini_keys()
        if not self.gemini_keys:
            return

        try:
            self.gemini_clients = [genai.Client(api_key=key) for key in self.gemini_keys]

            # Model for enrichment
            self.enrich_model = os.getenv("GEMINI_MODEL_ENRICH", "gemini-3.5-flash-lite")

            # Rate limit: 30 RPM for enrichment (safer than NVIDIA's 40 RPM)
            self.enrich_rpm = int(os.getenv("GEMINI_RPM_ENRICH", "30"))

            # Token buckets - cost_per_call=1 for enrichment
            max_rpm = self.enrich_rpm
            self.gemini_key_buckets = [
                TokenBucket(rpm=max_rpm, cost_per_call=1)
                for _ in self.gemini_clients
            ]

            # Generation config for enrichment
            self.enrich_config = types.GenerateContentConfig(
                temperature=0.0,
                max_output_tokens=2048,
                response_mime_type="application/json",
            )

            print(f"[MetadataEnricher] Gemini clients initialized ({len(self.gemini_clients)} keys, "
                  f"model={self.enrich_model}, rpm={self.enrich_rpm})")
        except Exception as e:
            print(f"[MetadataEnricher] Warning: Could not init Gemini clients: {e}")
            self.gemini_clients = []

    def _pick_gemini_key(self, chunk_id: Optional[str] = None) -> int:
        """Pick the best Gemini API key using token bucket + sticky affinity."""
        if not self.gemini_clients:
            return 0

        cost = 1  # Enrichment calls are light

        # Try sticky key first (skip if invalid)
        if chunk_id:
            with self.gemini_affinity_lock:
                sticky_idx = self.gemini_affinity.get(chunk_id)
            if (sticky_idx is not None
                and sticky_idx < len(self.gemini_key_buckets)
                and sticky_idx not in self.gemini_invalid_keys):
                if self.gemini_key_buckets[sticky_idx].try_take(cost):
                    return sticky_idx

        # Find key with most headroom (skip invalid)
        best_idx = -1
        best_available = -1.0
        for idx, bucket in enumerate(self.gemini_key_buckets):
            if idx in self.gemini_invalid_keys:
                continue
            available = bucket.available()
            if available > best_available:
                best_available = available
                best_idx = idx

        # Try best key
        if best_idx >= 0 and self.gemini_key_buckets[best_idx].try_take(cost):
            if chunk_id:
                with self.gemini_affinity_lock:
                    self.gemini_affinity[chunk_id] = best_idx
            return best_idx

        # All buckets low - wait for the one that will be ready soonest (skip invalid)
        valid_indices = [i for i in range(len(self.gemini_key_buckets)) if i not in self.gemini_invalid_keys]
        if not valid_indices:
            print(f"[MetadataEnricher] All {len(self.gemini_key_buckets)} Gemini keys invalid!")
            return 0
        wait_idx = min(
            valid_indices,
            key=lambda i: self.gemini_key_buckets[i].time_until_ready(cost)
        )
        wait_time = self.gemini_key_buckets[wait_idx].take(cost)
        if wait_time > 0:
            print(f"[MetadataEnricher] Rate limit: waited {wait_time:.1f}s for key {wait_idx} (enrich)")
        if chunk_id:
            with self.gemini_affinity_lock:
                self.gemini_affinity[chunk_id] = wait_idx
        return wait_idx

    def _llm_complete_gemini(self, prompt: str, chunk_id: Optional[str] = None) -> str:
        """1 LLM call using Gemini with token bucket + sticky key assignment.
        Retries up to 15 times on transient errors (503, 429) with fixed 5s delay."""
        if not self.gemini_clients:
            print(f"[MetadataEnricher] No Gemini clients available for enrichment")
            return ""

        max_retries = 15  # 15 attempts total
        fixed_delay = 5.0  # Fixed 5s delay between retries

        for attempt in range(max_retries):
            key_idx = self._pick_gemini_key(chunk_id)
            client = self.gemini_clients[key_idx]

            try:
                res = client.models.generate_content(
                    model=self.enrich_model,
                    contents=prompt,
                    config=self.enrich_config,
                )

                text = (res.text or "").strip()

                # Track usage
                usage = getattr(res, "usage_metadata", None)
                if usage:
                    prompt_tokens = getattr(usage, "prompt_token_count", 0) or 0
                    completion_tokens = getattr(usage, "candidates_token_count", 0) or 0
                    print(f"[MetadataEnricher] Gemini enrich key={key_idx} in={prompt_tokens} out={completion_tokens}")

                if text:
                    return text

            except Exception as e:
                err_str = str(e)
                print(f"[MetadataEnricher] Gemini enrich key={key_idx} attempt {attempt+1}/{max_retries} failed: {e}")

                is_rate_limit = "429" in err_str or "quota" in err_str.lower() or "rate limit" in err_str.lower()
                is_unavailable = "503" in err_str or "unavailable" in err_str.lower()
                is_transient = is_rate_limit or is_unavailable

                # Permanent failures - mark key invalid, don't retry
                if "401" in err_str or "unauthenticated" in err_str.lower():
                    self.gemini_invalid_keys.add(key_idx)
                    print(f"[MetadataEnricher] Key {key_idx} marked INVALID (401/unauth)")
                    break  # Don't retry on auth failures

                # Transient failures - retry with fixed 5s delay
                if is_transient and attempt < max_retries - 1:
                    with self.gemini_key_buckets[key_idx]._lock:
                        self.gemini_key_buckets[key_idx]._tokens = 0
                        self.gemini_key_buckets[key_idx]._last_refill = time.time()

                    print(f"[MetadataEnricher] Transient error ({'rate limit' if is_rate_limit else '503'}) - waiting {fixed_delay:.1f}s before retry...")
                    time.sleep(fixed_delay)
                    continue

                # Non-retryable or last attempt
                break

        return ""

    def _fallback_enrichment(self, chunk: ProcessedChunk) -> ChunkEnrichmentResult:
        """Heuristic offline generator used for fast enrichment or fallback without calling external LLM."""
        text = chunk.content.strip()
        lines = [line.strip() for line in text.split("\n") if line.strip()]

        # 1. Trích xuất tên Điều khoản / Mục quy định chính
        dieu_match = re.search(r'(Điều\s+\d+[\.:\s]+[^\n\r>]+)', chunk.breadcrumb)
        if not dieu_match:
            dieu_match = re.search(r'(Điều\s+\d+[\.:\s]+[^\n\r]+)', text)

        main_topic = ""
        article_title = ""
        if dieu_match:
            article_title = dieu_match.group(1).strip()
            m_name = re.search(r'Điều\s+\d+[\.:\s]+(.+)', article_title)
            if m_name:
                main_topic = m_name.group(1).strip()

        if not main_topic:
            crumbs = [c.strip() for c in chunk.breadcrumb.split('>') if c.strip()]
            main_topic = crumbs[-1] if crumbs else "quy định"

        # 2. Sinh Tóm tắt (Summary)
        first_content = lines[0] if lines else main_topic
        summary = f"Quy định về {main_topic}: {first_content[:140]}"

        # 3. Trích xuất Từ khóa sạch (bỏ stopwords & tên file)
        stopwords = {
            "bo", "luat", "docx", "pdf", "xlsx", "chuong", "chương", "dieu", "điều", "khoan", "khoản",
            "muc", "mục", "cua", "của", "va", "và", "cac", "các", "nhung", "những", "trong", "cho",
            "theo", "duoc", "được", "khong", "không", "phai", "phải", "nay", "này", "khi", "hoac", "hoặc",
            "tren", "trên", "duoi", "dưới", "sau", "đây", "day", "nguoi", "người", "co", "có"
        }
        # Lấy văn bản bỏ qua phần tên file ban đầu trong breadcrumb
        text_without_filename = re.sub(r'^[^\>]+>', '', chunk.breadcrumb) + " " + text
        raw_words = re.findall(r'\b[A-Za-zÀ-ỹ0-9_/%-]{3,}\b', text_without_filename)
        clean_keywords = []
        for w in raw_words:
            w_lower = w.lower()
            if w_lower not in stopwords and not w.endswith(('.docx', '.pdf', '.xlsx')):
                if w not in clean_keywords:
                    clean_keywords.append(w)
            if len(clean_keywords) >= 8:
                break

        # 4. Sinh Câu hỏi giả định tự nhiên (Reverse HyDE)
        questions = [
            f"{main_topic} là gì?",
            f"Quy định về {main_topic} như thế nào?",
            f"Nội dung chi tiết của {main_topic} gồm những gì?"
        ]
        if article_title:
            questions.append(f"Nội dung theo {article_title} được áp dụng ra sao?")

        return ChunkEnrichmentResult(
            summary=summary,
            keywords=clean_keywords,
            hypothetical_questions=questions[:5]
        )

    def enrich_chunk(self, chunk: ProcessedChunk) -> ProcessedChunk:
        """Enriches a single chunk with summary, keywords, and hypothetical questions."""
        prompt = ENRICHMENT_PROMPT.format(
            breadcrumb=chunk.breadcrumb,
            chunk_type=chunk.chunk_type,
            content=chunk.content[:2500]  # Cap context to prevent token overflows
        )

        result: Optional[ChunkEnrichmentResult] = None

        # 1. Try Gemini (using 7-key rotation with token bucket, 30 RPM)
        if self.gemini_clients:
            try:
                response_text = self._llm_complete_gemini(prompt, chunk.chunk_id)
                if response_text:
                    parsed = json.loads(response_text)
                    result = ChunkEnrichmentResult(**parsed)
            except Exception as e:
                print(f"[MetadataEnricher] Gemini call failed for chunk {chunk.chunk_id}: {e}")

        # 2. Try NVIDIA (fallback if provider=nvidia)
        elif self.nvidia_client:
            try:
                from openai import OpenAI
                model_name = os.getenv("NVIDIA_MODEL_ENRICH", "nvidia/nemotron-3-ultra")
                response = self.nvidia_client.chat.completions.create(
                    model=model_name,
                    messages=[{"role": "user", "content": prompt}],
                    response_format={"type": "json_object"},
                    temperature=0.0,
                    max_tokens=2048,
                )
                parsed = json.loads(response.choices[0].message.content)
                result = ChunkEnrichmentResult(**parsed)
            except Exception as e:
                print(f"[MetadataEnricher] NVIDIA call failed for chunk {chunk.chunk_id}: {e}")

        # 3. Fallback (heuristic)
        if not result:
            result = self._fallback_enrichment(chunk)

        chunk.summary = result.summary
        chunk.keywords = result.keywords
        chunk.hypothetical_questions = result.hypothetical_questions

        return chunk

    def enrich_all(self, chunks: List[ProcessedChunk], show_progress: bool = True) -> List[ProcessedChunk]:
        """
        Batch enriches a list of chunks.
        Always tries LLM enrichment first for every chunk; falls back to rule-based enrichment
        only when the LLM call fails.
        """
        print(f"[MetadataEnricher] Bắt đầu làm giàu {len(chunks)} chunks bằng LLM đa luồng...")
        # Use ThreadPoolExecutor but limit workers to avoid overwhelming rate limits
        max_workers = min(3, len(chunks))  # Limit to 3 concurrent to respect 30 RPM
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            enriched = list(executor.map(self.enrich_chunk, chunks))
        print(f"[MetadataEnricher] Hoàn tất làm giàu {len(enriched)} chunks.")
        return enriched