import os
import torch
from typing import List, Optional
from pathlib import Path
from dotenv import load_dotenv

# Load .env
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)
load_dotenv()

from sentence_transformers import SentenceTransformer
from src.models.schema import ProcessedChunk


class LocalEmbedder:
    """
    Offline Vietnamese/Multilingual Vector Embedder using Sentence-Transformers.
    - Runs 100% locally on CUDA GPU (or CPU if no GPU available).
    - 100% Free forever: No API Key, No Network Latency, No Rate Limits (0% 429).
    - Produces exact 768-dimensional vectors matching PostgreSQL pgvector schema.
    """
    _instance: Optional["LocalEmbedder"] = None
    _model: Optional[SentenceTransformer] = None

    def __init__(self, model_name: Optional[str] = None):
        self.model_name = (
            model_name 
            or os.getenv("LOCAL_EMBEDDING_MODEL") 
            or "bkai-foundation-models/vietnamese-bi-encoder"
        )
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        # Load model once (singleton pattern)
        if LocalEmbedder._model is None:
            print(f"[LocalEmbedder] Loading embedding model '{self.model_name}' on {self.device.upper()}...")
            LocalEmbedder._model = SentenceTransformer(self.model_name, device=self.device)
            print(f"[LocalEmbedder] Model ready! Vectors will be 768 dimensions.")

        self.model = LocalEmbedder._model

    def generate_embedding(self, text: str, task_type: str = "retrieval_document") -> List[float]:
        """Generates a 768-dimensional vector embedding for a single text."""
        if not text or not text.strip():
            return [0.0] * 768
        
        vector = self.model.encode(
            text.strip(), 
            show_progress_bar=False, 
            normalize_embeddings=True
        )
        return vector.tolist()

    def generate_embeddings_batch(
        self, 
        texts: List[str], 
        task_type: str = "retrieval_document", 
        batch_size: int = 32
    ) -> List[List[float]]:
        """Generates 768-dimensional vector embeddings in batch on CUDA/CPU in milliseconds."""
        if not texts:
            return []

        clean_texts = [t.strip() if (t and t.strip()) else "trống" for t in texts]
        vectors = self.model.encode(
            clean_texts, 
            batch_size=batch_size, 
            show_progress_bar=False, 
            normalize_embeddings=True
        )
        return vectors.tolist()

    def _embed_questions(self, chunk: ProcessedChunk) -> Optional[List[float]]:
        """
        Vector đại diện cho hypothetical_questions: trung bình các vector câu hỏi
        rồi chuẩn hoá lại (để cosine distance vẫn đúng).

        KHÔNG được gán = content_vector: làm vậy thì GREATEST(content_sim, question_sim)
        trong SQL thành vô nghĩa và câu hỏi diễn đạt khác văn bản luật không bao giờ
        khớp được (ví dụ "sếp có được phạt tiền ko?" vs Điều 127).
        """
        if not chunk.hypothetical_questions:
            return None
        vecs = self.generate_embeddings_batch(list(chunk.hypothetical_questions))
        if not vecs:
            return None
        mean = [sum(col) / len(vecs) for col in zip(*vecs)]
        norm = sum(x * x for x in mean) ** 0.5
        return [x / norm for x in mean] if norm else None

    def embed_chunks(self, chunks: List[ProcessedChunk], batch_size: int = 32) -> List[ProcessedChunk]:
        """
        Batch embeds all chunks locally.
        Runs hundreds of chunks in < 1 second on GPU!
        """
        if not chunks:
            return chunks

        print(f"[LocalEmbedder] Generating local 768d vectors for {len(chunks)} chunks on {self.device.upper()}...")
        contents = [f"{c.breadcrumb}\n{c.content}" for c in chunks]
        content_vectors = self.generate_embeddings_batch(contents, batch_size=batch_size)

        flat_questions, owners = [], []
        for i, c in enumerate(chunks):
            for q in (c.hypothetical_questions or []):
                flat_questions.append(q)
                owners.append(i)
        question_vectors = self.generate_embeddings_batch(flat_questions, batch_size=batch_size) if flat_questions else []

        grouped: dict[int, list] = {}
        for owner, vec in zip(owners, question_vectors):
            grouped.setdefault(owner, []).append(vec)

        for i, chunk in enumerate(chunks):
            chunk.content_vector = content_vectors[i]
            vecs = grouped.get(i)
            if vecs:
                mean = [sum(col) / len(vecs) for col in zip(*vecs)]
                norm = sum(x * x for x in mean) ** 0.5
                chunk.questions_vector = [x / norm for x in mean] if norm else content_vectors[i]
            else:
                chunk.questions_vector = content_vectors[i]

        print(f"[LocalEmbedder] Successfully generated 768d vectors for all {len(chunks)} chunks in milliseconds.")
        return chunks
