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
    _load_failed: bool = False

    def __init__(self, model_name: Optional[str] = None):
        self.model_name = (
            model_name 
            or os.getenv("RERANKER_MODEL") 
            or "AITeamVN/Vietnamese_Reranker"
        )
        self.device = "cuda" if torch.cuda.is_available() else "cpu"

        if CrossEncoderReranker._model is None and not CrossEncoderReranker._load_failed:
            print(f"[CrossEncoderReranker] Loading reranker model '{self.model_name}' on {self.device.upper()}...")
            try:
                # ponytail: 512 du cho chunk luat VN (~1200 ky tu); 1024 gap doi latency moi cap (~1.4s->~0.7s).
                CrossEncoderReranker._model = CrossEncoder(self.model_name, device=self.device, max_length=512)
                # fp16 tren GPU: do duoc 40 cap chunk that dai 2003ms -> 587ms (3.4x).
                # Cross-encoder chi dung de RANK (khong sinh van ban) -> mat precision khong quan trong.
                if self.device == "cuda":
                    CrossEncoderReranker._model.model.half()
                print(f"[CrossEncoderReranker] Model ready on {self.device.upper()} (fp16={self.device == 'cuda'})!")
            except Exception as e:
                # Model tren HF thieu file tokenizer/processor hoac khong tai duoc:
                # tat rerank, giu retrieval hybrid (vector + BM25) thay vi crash ca service.
                CrossEncoderReranker._load_failed = True
                print(f"[CrossEncoderReranker] WARNING: could not load '{self.model_name}' ({e}). Reranking disabled.")

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
        if self.model is None:
            # Reranker khong load duoc luc startup: giu nguyen thu tu hybrid scores.
            return chunks[:top_k]

        # Prepare pairs: [query, chunk_content_with_breadcrumb]
        pairs = []
        for c in chunks:
            text = f"{c.get('breadcrumb', '')}\n{c.get('content', '')}".strip()
            pairs.append([query, text])

        try:
            # Batch inference on CUDA in milliseconds
            scores = self.model.predict(pairs, show_progress_bar=False)

            # Assign rerank scores; KEEP original relevance_score (hybrid) for gating.
            # Rerank score only used for ordering. ponytail: hybrid calibrated for threshold.
            for i, chunk in enumerate(chunks):
                score = round(float(scores[i]), 4)
                chunk["rerank_score"] = score
                # relevance_score unchanged = hybrid score

            # Sort by rerank_score for ordering; original relevance_score preserved
            reranked_chunks = sorted(chunks, key=lambda x: x["rerank_score"], reverse=True)
            return reranked_chunks[:top_k]

        except Exception as e:
            print(f"[CrossEncoderReranker] Warning: Reranking failed ({e}), falling back to initial scores.")
            return chunks[:top_k]
