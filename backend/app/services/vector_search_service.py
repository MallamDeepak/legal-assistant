import os
from pathlib import Path

class VectorSearchService:
    _retriever = None
    
    @classmethod
    def get_instance(cls):
        if cls._retriever is None:
            try:
                from app.services.retriever import Retriever
                index_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'legal_index'))
                if Path(index_dir).exists():
                    cls._retriever = Retriever(index_dir)
            except Exception as e:
                print(f"Warning: Vector DB not loaded: {e}")
        return cls._retriever
    
    @staticmethod
    def search(query: str, top_k: int = 5):
        """Search for relevant legal passages with Reranking."""
        svc = VectorSearchService.get_instance()
        if not svc:
            return []
            
        # 1. Retrieval: Fetch fewer candidates (e.g. 20) for faster reranking
        candidate_k = top_k * 4 
        candidates = svc.search(query, top_k=candidate_k)
        
        if not candidates:
            return []

        # 2. Reranking: Use Cross-Encoder to find the best semantic matches
        try:
            from app.services.reranker_service import RerankerService
            # Rerank and slice to final top_k
            reranked = RerankerService.rerank(query, candidates, top_k=top_k)
            return reranked
        except Exception as e:
            print(f"Reranking failed, falling back to raw vector scores: {e}")
            return candidates[:top_k]