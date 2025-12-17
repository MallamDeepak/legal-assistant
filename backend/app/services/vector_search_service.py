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
        """Search for relevant legal passages."""
        svc = VectorSearchService.get_instance()
        if svc:
            return svc.search(query, top_k)
        return []