import sys
import os

# Ensure backend path is in python path
sys.path.append(os.path.abspath('backend'))

from app.services.vector_search_service import VectorSearchService

def debug_search():
    print("Initializing Vector Search...")
    service = VectorSearchService.get_instance()
    
    if not service:
        print("ERROR: Service failed to initialize.")
        return

    queries = [
        "Theft of a bike from my house.",
    ]
    
    for q in queries:
        print(f"\n--- Query: {q} ---")
        results = service.search(q, top_k=10)
        if not results:
            print("No results found.")
        else:
            for r in results:
                print(f"ID: {r.get('section_id')} | Score: {r.get('score')} | Title: {r.get('title')}")

if __name__ == "__main__":
    debug_search()
