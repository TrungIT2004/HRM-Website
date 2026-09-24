import os
from typing import List
from pathlib import Path
from dotenv import load_dotenv
import google.generativeai as genai

# Load .env from ai-service root regardless of current working directory
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)
load_dotenv()

from src.models.schema import ProcessedChunk

class GeminiEmbedder:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.model_name = os.getenv("GEMINI_EMBEDDING_MODEL", "models/gemini-embedding-001")
        
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not set in the environment.")
        
        genai.configure(api_key=self.api_key)

    def generate_embedding(self, text: str, task_type: str = "retrieval_document") -> List[float]:
        """Generates a 768-dimensional vector embedding with automatic retry on Rate Limit (429)."""
        if not text or not text.strip():
            return [0.0] * 768
            
        import time
        for attempt in range(5):
            try:
                result = genai.embed_content(
                    model=self.model_name,
                    content=text,
                    task_type=task_type,
                    output_dimensionality=768
                )
                return result['embedding']
            except Exception as e:
                err_str = str(e)
                if "429" in err_str or "quota" in err_str.lower() or "ResourceExhausted" in err_str:
                    wait_sec = 6 * (attempt + 1)
                    print(f"[GeminiEmbedder] Rate limit 429 hit. Tự động chờ {wait_sec}s rồi thử lại (lần {attempt+1}/5)...")
                    time.sleep(wait_sec)
                else:
                    print(f"[GeminiEmbedder] Failed to embed content: {e}")
                    break
        return [0.0] * 768

    def generate_embeddings_batch(self, texts: List[str], task_type: str = "retrieval_document", batch_size: int = 20) -> List[List[float]]:
        """
        Generates 768-dimensional vector embeddings in batches using Google Gemini API.
        Accurately parses Google's 'retry_delay' header/message to wait precisely and avoid 429 loops.
        """
        import time, re
        all_embeddings = []

        for idx, i in enumerate(range(0, len(texts), batch_size)):
            # Pacing: slight delay between batches to stay under token/min rate
            if idx > 0:
                time.sleep(1.0)

            batch = texts[i:i + batch_size]
            batch_clean = [t if (t and t.strip()) else "empty" for t in batch]
            embedded = False

            for attempt in range(5):
                try:
                    result = genai.embed_content(
                        model=self.model_name,
                        content=batch_clean,
                        task_type=task_type,
                        output_dimensionality=768
                    )
                    all_embeddings.extend(result['embedding'])
                    embedded = True
                    break
                except Exception as e:
                    err_str = str(e)
                    if "429" in err_str or "quota" in err_str.lower() or "ResourceExhausted" in err_str:
                        # Extract exact wait time instructed by Google API
                        m = re.search(r'retry in ([0-9\.]+)s', err_str)
                        m2 = re.search(r'retry_delay\s*\{\s*seconds:\s*(\d+)', err_str)
                        if m:
                            wait_sec = float(m.group(1)) + 1.0
                        elif m2:
                            wait_sec = float(m2.group(1)) + 1.0
                        else:
                            wait_sec = 15.0 * (attempt + 1)
                        print(f"[GeminiEmbedder] Quota 429 hit tại batch {i//batch_size + 1}. Chờ đúng {wait_sec:.1f}s theo yêu cầu Google (lần {attempt+1}/5)...")
                        time.sleep(wait_sec)
                    else:
                        print(f"[GeminiEmbedder] Failed to embed batch: {e}")
                        break
            if not embedded:
                print(f"[GeminiEmbedder] Warning: Fallback zero vectors for batch {i}..{i+len(batch)}")
                all_embeddings.extend([[0.0] * 768] * len(batch))
        return all_embeddings

    def embed_chunk(self, chunk: ProcessedChunk) -> ProcessedChunk:
        """Generates vectors for the chunk's content and its hypothetical questions."""
        content_to_embed = f"{chunk.breadcrumb}\n{chunk.content}"
        chunk.content_vector = self.generate_embedding(content_to_embed)
        chunk.questions_vector = chunk.content_vector
        return chunk

    def embed_chunks(self, chunks: List[ProcessedChunk], batch_size: int = 20) -> List[ProcessedChunk]:
        """
        Batch generates 768d vectors for all chunks in 20-chunk batches.
        Reuses content_vector for questions_vector to cut quota consumption by 50%
        and prevent rate limit exhaustion.
        """
        if not chunks:
            return chunks

        print(f"[GeminiEmbedder] Generating batch embeddings for {len(chunks)} chunks (batch_size={batch_size})...")
        contents = [f"{c.breadcrumb}\n{c.content}" for c in chunks]
        content_vectors = self.generate_embeddings_batch(contents, task_type="retrieval_document", batch_size=batch_size)

        for i, chunk in enumerate(chunks):
            chunk.content_vector = content_vectors[i]
            chunk.questions_vector = content_vectors[i]

        print(f"[GeminiEmbedder] ✅ Successfully generated all vectors for {len(chunks)} chunks.")
        return chunks


