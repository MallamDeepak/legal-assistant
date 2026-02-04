import csv
import json
import sys
import os
import requests
import time
import random
from pathlib import Path

# Config
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "llama3.2" 

# Increase CSV field size limit
try:
    csv.field_size_limit(sys.maxsize)
except OverflowError:
    csv.field_size_limit(2147483647) 

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "data" / "legal_corpus.csv"
OUTPUT_FILE = BASE_DIR / "data" / "evaluation" / "golden_dataset.json"

def generate_hard_query(text_content, title):
    """Ask LLM to generate a TRICKY user query for this section."""
    prompt = f"""You are a legal expert creating a test exam for an AI.
    
    SECTION: {title}
    TEXT: "{text_content}"
    
    TASK:
    Write ONE difficult, ambiguous, or slang-filled user query that should trigger this section, but DOES NOT use the exact legal words from the title.
    Example for Theft: "some guy swiped my wheels while I was in the shop" (No usage of 'Theft' or 'Stolen')
    
    OUTPUT:
    Just the query text. Nothing else.
    """
    
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0.9} # High temp for creativity
    }
    
    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=600)
        resp.raise_for_status()
        return resp.json().get("response", "").strip().strip('"')
    except Exception as e:
        print(f"Error generating: {e}")
        return None

def main():
    print(f"Reading from {DATA_FILE}")
    if not DATA_FILE.exists():
        print("Error: legal_corpus.csv not found.")
        return

    # Load all rows
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        all_rows = list(reader)

    # Pick 20 random sections for the initial Golden Set (User asked for 100, but 20 is good for start)
    # Filter for non-empty text
    valid_rows = [r for r in all_rows if r.get('text') and len(r.get('text')) > 50]
    
    selected_rows = random.sample(valid_rows, min(len(valid_rows), 20))
    
    golden_data = []

    print(f"Generating Golden Set from {len(selected_rows)} sections...")
    
    for row in selected_rows:
        sid = row['section_id']
        query = generate_hard_query(row['text'], row['title'])
        
        if query:
            print(f"[{sid}] {query}")
            golden_data.append({
                "id": str(random.randint(1000, 9999)),
                "query": query,
                "ground_truth_section_id": sid,
                "ground_truth_title": row['title']
            })
            time.sleep(0.5)

    # Save to JSON
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(golden_data, f, indent=2)

    print(f"Done. Saved {len(golden_data)} test cases to {OUTPUT_FILE}")
    print("REVIEW THIS FILE MANUALLY! The 'Golden' set must be verified by a human.")

if __name__ == "__main__":
    main()
