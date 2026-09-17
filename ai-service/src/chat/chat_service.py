import os
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()

from src.retrievers.hybrid_retriever import HybridRetriever


SYSTEM_PROMPT = """Bạn là Trợ lý AI Quản trị Nhân sự (HR Assistant) chuyên nghiệp của công ty.
Nhiệm vụ của bạn là trả lời các câu hỏi của cán bộ nhân viên dựa trên các quy chế, nội quy và chính sách nội bộ được cung cấp.

--- NGUYÊN TẮC QUAN TRỌNG (BẮT BUỘC TUÂN THỦ) ---
1. BẢO CHỨNG THÔNG TIN (GROUNDEDNESS): Bạn CHỈ ĐƯỢC PHÉP sử dụng các thông tin có trong phần [TÀI LIỆU QUY CHẾ NỘI BỘ] bên dưới.
2. CHỐNG ẢO GIÁC (ZERO HALLUCINATION): Tuyệt đối không tự suy đoán, bịa đặt các quyền lợi hoặc chế tài xử phạt không có trong văn bản.
3. PHẠM VI NGOÀI TÀI LIỆU: Nếu câu hỏi không có câu trả lời trong tài liệu, bạn PHẢI trả lời: "Rất tiếc, quy chế hiện tại của công ty không có thông tin về vấn đề này. Bạn vui lòng liên hệ trực tiếp với Phòng Nhân sự (HR) để được giải đáp cụ thể."
4. TRÌNH BÀY RÕ RÀNG: Nếu quy định có các mức độ vi phạm, số tiền thưởng, hoặc ngày nghỉ, hãy gạch đầu dòng rõ ràng, mạch lạc, dễ đọc.
5. TRÍCH DẪN: Ở cuối câu trả lời, hãy tóm tắt các điều khoản/chương đã dùng để trả lời.
"""


class ChatService:
    def __init__(self):
        self.retriever = HybridRetriever()
        self.provider = os.getenv("LLM_PROVIDER", "ollama").lower()

        self.ollama_client = None
        self.gemini_client = None

        # Init Ollama Client
        ollama_url = os.getenv("OLLAMA_BASE_URL", "https://ollama.com/v1")
        ollama_key = os.getenv("OLLAMA_API_KEY", "ollama")
        try:
            from openai import OpenAI
            self.ollama_client = OpenAI(base_url=ollama_url, api_key=ollama_key)
            self.ollama_model = os.getenv("OLLAMA_MODEL", "gpt-oss-safeguard:120b")
        except Exception as e:
            print(f"[ChatService] Warning: Could not init Ollama client: {e}")

        # Init Gemini Client as Fallback
        gemini_key = os.getenv("GEMINI_API_KEY")
        if gemini_key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=gemini_key)
                self.gemini_client = genai.GenerativeModel(
                    os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
                )
            except Exception as e:
                print(f"[ChatService] Warning: Could not init Gemini client: {e}")

    def _generate_llm_answer(self, prompt: str) -> str:
        """Call primary LLM (Ollama 120b) with fallback to Gemini."""
        # 1. Try Ollama Cloud
        if self.ollama_client:
            try:
                res = self.ollama_client.chat.completions.create(
                    model=self.ollama_model,
                    messages=[
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.2  # Low temperature for factual precision
                )
                return res.choices[0].message.content.strip()
            except Exception as e:
                print(f"[ChatService] Ollama answer generation failed: {e}")

        # 2. Try Gemini Fallback
        if self.gemini_client:
            try:
                full_prompt = f"{SYSTEM_PROMPT}\n\n{prompt}"
                res = self.gemini_client.generate_content(full_prompt)
                return res.text.strip()
            except Exception as e:
                print(f"[ChatService] Gemini answer generation failed: {e}")

        return "Hệ thống AI hiện đang bận hoặc gặp sự cố kết nối. Bạn vui lòng thử lại sau giây lát."

    def answer_query(
        self,
        question: str,
        roles: Optional[List[str]] = None,
        departments: Optional[List[str]] = None,
        top_k: int = 3
    ) -> Dict[str, Any]:
        """
        Full RAG Reasoning Pipeline:
        1. Retrieve top relevant chunks via Hybrid Search
        2. Check confidence threshold
        3. Compose grounded prompt with citations
        4. Synthesize final answer with LLM
        """
        # Step 1: Hybrid Retrieval
        chunks = self.retriever.retrieve(
            query=question,
            roles=roles,
            departments=departments,
            top_k=top_k
        )

        # Check if any chunk passed minimum relevance threshold
        if not chunks or chunks[0]["relevance_score"] < 0.40:
            return {
                "question": question,
                "answer": "Rất tiếc, quy chế nội bộ hiện tại của công ty không có thông tin quy định về câu hỏi này. Bạn vui lòng liên hệ trực tiếp với Phòng Nhân sự (HR) để được hướng dẫn chi tiết.",
                "citations": [],
                "retrieved_chunks_count": 0,
                "confidence": "LOW"
            }

        # Step 2: Build Grounded Context
        context_parts = []
        citations = []

        for idx, c in enumerate(chunks):
            context_parts.append(
                f"[TÀI LIỆU {idx+1}]: {c['document_name']} (Trang {c['page_number']})\n"
                f"[ĐƯỜNG DẪN]: {c['breadcrumb']}\n"
                f"[NỘI DUNG]:\n{c['content']}\n"
            )

            citations.append({
                "document_name": c["document_name"],
                "breadcrumb": c["breadcrumb"],
                "page_number": c["page_number"],
                "file_url": c["file_url"],
                "chunk_type": c["chunk_type"],
                "relevance_score": c["relevance_score"]
            })

        context_text = "\n---\n".join(context_parts)

        prompt = f"""[TÀI LIỆU QUY CHẾ NỘI BỘ]:
{context_text}

---
[CÂU HỎI CỦA NHÂN VIÊN]:
{question}

Hãy đọc kỹ các tài liệu trên và trả lời câu hỏi của nhân viên một cách đầy đủ, chính xác."""

        # Step 3: Call LLM
        answer = self._generate_llm_answer(prompt)

        return {
            "question": question,
            "answer": answer,
            "citations": citations,
            "retrieved_chunks_count": len(chunks),
            "confidence": "HIGH" if chunks[0]["relevance_score"] > 0.65 else "MEDIUM"
        }
