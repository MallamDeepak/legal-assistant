"""Retrieve passages from FAISS index."""

import json
import faiss
from pathlib import Path
from sentence_transformers import SentenceTransformer
from typing import List, Dict


class Retriever:
    def __init__(self, index_dir: str, model_name: str = 'LaBSE'):
        self.index_dir = Path(index_dir)
        self.model = SentenceTransformer(model_name)
        
        # Load FAISS index
        self.index = faiss.read_index(str(self.index_dir / 'index.faiss'))
        
        # Load metadata
        self.metadata = []
        metadata_file = self.index_dir / 'metadata.jsonl'
        if metadata_file.exists():
            with open(metadata_file, 'r', encoding='utf-8') as f:
                self.metadata = [json.loads(line) for line in f]
    
    def search(self, query: str, top_k: int = 5) -> List[Dict]:
        """Retrieve top_k most relevant passages."""
        # Normalize query for Cosine Similarity
        query_embedding = self.model.encode([query], normalize_embeddings=True)[0].reshape(1, -1).astype('float32')
        distances, indices = self.index.search(query_embedding, top_k * 3)  # overfetch then dedupe

        best = {}
        for idx, dist in zip(indices[0], distances[0]):
            if idx >= len(self.metadata):
                continue
            sec_id = self.metadata[idx].get("section_id")
            
            # Distance is Cosine Similarity (Inner Product) here, range [-1, 1]
            # We map to [0, 1] roughly, or just use raw score
            score = float(dist)
            
            if sec_id not in best or score > best[sec_id]["score"]:
                item = self.metadata[idx].copy()
                item["score"] = score
                best[sec_id] = item

        # sort by score desc and trim
        return sorted(best.values(), key=lambda x: x["score"], reverse=True)[:top_k]
