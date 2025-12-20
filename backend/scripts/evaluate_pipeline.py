import json
import sys
import os
from pathlib import Path
import asyncio

# Setup path to import backend app
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from app.services.vector_search_service import VectorSearchService
from app.services.reranker_service import RerankerService
from app.services.legal_matcher_service import LegalMatcherService
from app.services.ollama_service import OllamaService

DATA_FILE = BASE_DIR / "data" / "evaluation" / "golden_dataset.json"

async def run_pipeline(text):
    """Simulate the logic in incident_reporter.py without needing the server running."""
    
    # 1. Expand
    expanded = []
    if OllamaService.is_available():
        expanded = OllamaService.expand_legal_query(text)
        
    # 2. Vector Search (with Reranking implicitly if enabled in Service)
    # We call the service directly which might already have reranking if implemented
    retrieved = VectorSearchService.search(text, top_k=5) or []
    
    # 3. Matcher
    matcher = LegalMatcherService()
    keyword_matches = matcher.match_sections(text) or []
    for kw in expanded:
        keyword_matches.extend(matcher.match_sections(kw, top_k=2))
        
    # Combine IDs
    found_ids = set()
    for item in retrieved:
        found_ids.add(item['section_id'])
    for item in keyword_matches:
        found_ids.add(item['section_id'])
        
    return list(found_ids)

def evaluate():
    if not DATA_FILE.exists():
        print(f"Golden dataset not found at {DATA_FILE}")
        return

    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        dataset = json.load(f)

    total = len(dataset)
    hits = 0
    
    print(f"Starting Evaluation on {total} test cases...")
    print("-" * 50)

    # We need an async loop for the pipeline simulation if we used async/await, 
    # but the services are synchronous normally. The endpoint is async.
    # We will just run synchronous logic here as the services are sync.
    
    import warnings
    warnings.filterwarnings("ignore")

    for case in dataset:
        query = case['query']
        truth = case['ground_truth_section_id']
        
        # Run Pipeline
        # Note: In a real script we might hit the API endpoint http://localhost:8000/incident/analyze
        # but importing logic is faster for dev loop.
        
        # SYNC WRAPPER
        # 1. Expand
        expanded = []
        if OllamaService.is_available():
             # MOCKING: call raw generate_text to avoid circular deps if any
             # But we can use the class method
             expanded = OllamaService.expand_legal_query(query)

        # 2. Vector
        retrieved = VectorSearchService.search(query, top_k=5)
        
        # 3. Keyword
        matcher = LegalMatcherService()
        kw_matches = matcher.match_sections(query)
        for e in expanded:
            kw_matches.extend(matcher.match_sections(e, top_k=2))
            
        # Collect Results
        results_ids = [r['section_id'] for r in retrieved] + [k['section_id'] for k in kw_matches]
        
        # Check Hit
        is_hit = truth in results_ids
        if is_hit:
            hits += 1
            print(f"[PASS] {query[:50]}... -> Found {truth}")
        else:
            print(f"[FAIL] {query[:50]}... -> Expected {truth}, Got {results_ids[:3]}...")

    print("-" * 50)
    accuracy = (hits / total) * 100
    print(f"Evaluation Complete.")
    print(f"Accuracy (Recall): {accuracy:.1f}%")

if __name__ == "__main__":
    evaluate()
