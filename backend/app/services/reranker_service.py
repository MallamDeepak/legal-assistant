import os
# Force PyTorch usage and suppress TF logs
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
os.environ["USE_TORCH"] = "1"

import torch
# Check if torch is available
if not torch.cuda.is_available() and not torch.backends.mps.is_available() and not hasattr(torch, 'cpu'):
    # Just a sanity check access
    pass

from sentence_transformers import CrossEncoder

class RerankerService:
    _model = None
    # A small, fast, high-quality reranker model
    MODEL_NAME = 'cross-encoder/ms-marco-MiniLM-L-6-v2'

    @classmethod
    def get_model(cls):
        if cls._model is None:
            try:
                # Use CPU for safety, or CUDA if available
                device = 'cuda' if torch.cuda.is_available() else 'cpu'
                print(f"Loading Reranker Model {cls.MODEL_NAME} on {device}...")
                cls._model = CrossEncoder(cls.MODEL_NAME, device=device)
            except Exception as e:
                print(f"Failed to load Reranker Mode: {e}")
        return cls._model

    @classmethod
    def rerank(cls, query: str, documents: list, top_k: int = 5) -> list:
        """
        Rerank a list of documents based on the query.
        
        Args:
            query: The search query.
            documents: List of dicts, each must have a 'text' or 'content' field.
            top_k: Number of results to return.
            
        Returns:
            Top k documents re-ordered by relevance.
        """
        model = cls.get_model()
        if not model or not documents:
            return documents[:top_k]

        # Prepare pairs for the model: (query, document_text)
        # We need to extract the text content from the document dicts
        # section['text'] is the main content in our data model
        pairs = []
        valid_docs = []
        
        for doc in documents:
            text = doc.get('text', '') or doc.get('content', '') or doc.get('title', '')
            if text:
                pairs.append([query, text])
                valid_docs.append(doc)

        if not pairs:
            return documents[:top_k]

        # Predict scores
        scores = model.predict(pairs)

        # Attach scores to documents for debugging/sorting
        results = []
        for doc, score in zip(valid_docs, scores):
            # Make a copy to avoid mutation side effects if needed, 
            # though here we just return references.
            doc['_rerank_score'] = float(score)
            results.append(doc)

        # Sort by score descending
        results.sort(key=lambda x: x['_rerank_score'], reverse=True)

        return results[:top_k]

    @classmethod
    def is_available(cls):
        return cls.get_model() is not None
