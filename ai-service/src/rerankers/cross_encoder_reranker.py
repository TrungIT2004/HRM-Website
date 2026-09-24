import os
import torch
from typing import List, Dict, Any, Optional
from sentence_transformers import CrossEncoder


class CrossEncoderReranker:
    """
    Two-Stage Retrieval Reranker using Cross-Encoder (BAAI/bge-reranker-base).
    - Runs on CUDA GPU (or CPU) in ~20-30ms.
    - Evaluates query-document pairs jointly with Cross-Attention.
    - Eliminates false positives from Bi-Encoder keyword overlap.
    """
    _instance: Optional["CrossEncoderReranker"] = None
    _model: Optional[CrossEncoder] = None

    def __init__(self, model_name: Optional[str] = None):
        self.model_name = (
            model_name 
            or os.getenv("RERANKER_MODEL") 
            or "BAAI/bge-reranker-base"
        )
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        if CrossEncoderReranker._model is None:
            print(f"[CrossEncoderReranker] Loading reranker model '{self.model_name}' on {self.device.upper()}...")
            CrossEncoderReranker._model = CrossEncoder(self.model_name, device=self.device)
            print(f"[CrossEncoderReranker] Model ready on {self.device.upper()}!")

        self.model = CrossEncoderReranker._model

    def rerank(
        self, 
        query: str, 
        chunks: List[Dict[str, Any]], 
        top_k: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Reranks a list of candidate chunks against the query.
        Returns top_k chunks sorted by Cross-Encoder relevance score.
        """
        if not chunks or not query:
            return chunks[:top_k]

        # Prepare pairs: [query, chunk_content_with_breadcrumb]
        pairs = []
        for c in chunks:
            text = f"{c.get('breadcrumb', '')}\n{c.get('content', '')}".strip()
            pairs.append([query, text])

        try:
            # Batch inference on CUDA in milliseconds
            scores = self.model.predict(pairs, show_progress_bar=False)

            # Assign rerank scores
            for i, chunk in enumerate(chunks):
                score = round(float(scores[i]), 4)
                chunk["rerank_score"] = score
                chunk["relevance_score"] = score

            # Sort descending by rerank score
            reranked_chunks = sorted(chunks, key=lambda x: x["relevance_score"], reverse=True)
            return reranked_chunks[:top_k]

        except Exception as e:
            print(f"[CrossEncoderReranker] Warning: Reranking failed ({e}), falling back to initial scores.")
            return chunks[:top_k]
