import sys
from pathlib import Path
import os

# Setup path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from app.services.vector_search_service import VectorSearchService
from app.services.reranker_service import RerankerService

def verify():
    query = "my neighbor slapped me during an argument"
    print(f"QUERY: '{query}'")
    print("-" * 50)
    
    svc = VectorSearchService.get_instance()
    if not svc:
        print("Vector DB not available. Skipping.")
        return

    # 1. Simulate Raw Vector Search (Old Way)
    # We ask for a few to see where the good one lands
    raw_results = svc.search(query, top_k=10)
    print("RAW VECTOR SEARCH RESULTS (Top 3):")
    for i, res in enumerate(raw_results[:3]):
        print(f"  #{i+1}: {res.get('section_id')} ({res.get('score', 0):.4f}) - {res.get('title')}")
        
    print("-" * 50)

    # 2. Simulate Reranked Search (New Way)
    # This calls the *modified* VectorSearchService.search which internally does reranking
    # But wait, looking at my code, VectorSearchService.search NOW does reranking by default!
    # So 'raw_results' above MIGHT already be reranked if I didn't bypass it.
    
    # Let's bypass the static wrapper to test raw vs rerank manualy for demonstration.
    # Access the raw retriever directly
    raw_retriever = svc 
    candidates = raw_retriever.search(query, top_k=50) # Get many
    
    print("RE-RANKING 50 CANDIDATES...")
    reranked = RerankerService.rerank(query, candidates, top_k=3)
    
    print("RERANKED RESULTS (Top 3):")
    for i, res in enumerate(reranked):
        score = res.get('_rerank_score', 'N/A')
        if isinstance(score, float):
            score = f"{score:.4f}"
        print(f"  #{i+1}: {res.get('section_id')} (Score: {score}) - {res.get('title')}")

if __name__ == "__main__":
    verify()
