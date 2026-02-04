import csv
import json
import sys
import os
import requests
import time
from pathlib import Path

# Assumes Ollama is running at localhost:11434
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "llama3.2" 

# Increase CSV field size limit
try:
    csv.field_size_limit(sys.maxsize)
except OverflowError:
    csv.field_size_limit(2147483647) 

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "data" / "legal_corpus.csv"
OUTPUT_FILE = BASE_DIR / "data" / "legal_corpus_enriched.csv"

def generate_metadata(text_content, title):
    """Ask LLM to extract/generate metadata for this legal section."""
    prompt = f"""You are a legal data expert. Analyze this Indian Law section.
    
    SECTION: {title}
    TEXT: "{text_content}"
    
    TASK:
    Extract or infer the following metadata.
    1. common_name: A short popular name (e.g. "Theft", "Murder"). If none, use the legal title.
    2. severity: "Cognizable" or "Non-Cognizable", "Bailable" or "Non-Bailable". (Infer from general knowledge if not in text).
    3. keywords: 5 comma-separated keywords useful for search.
    
    OUTPUT FORMAT:
    Return ONLY a valid JSON object. Do not explain.
    {{
        "common_name": "...",
        "severity": "...",
        "keywords": "..."
    }}
    """
    
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "format": "json", # Force JSON mode if model supports it
        "options": {"temperature": 0.3}
    }
    
    try:
        resp = requests.post(OLLAMA_URL, json=payload, timeout=600)
        resp.raise_for_status()
        output = resp.json().get("response", "").strip()
        return json.loads(output)
    except Exception as e:
        print(f"Error generating/parsing: {e}")
        # Return fallback empty structure
        return {"common_name": "", "severity": "", "keywords": ""}

def main():
    print(f"Reading from {DATA_FILE}")
    if not DATA_FILE.exists():
        print("Error: legal_corpus.csv not found.")
        return

    # Load all rows
    rows = []
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    # Add new columns if not present
    new_fields = ['common_name', 'severity', 'keywords']
    for nf in new_fields:
        if nf not in fieldnames:
            fieldnames.append(nf)
            
    # Process rows
    processed_count = 0
    
    # OUTPUT FILE
    with open(OUTPUT_FILE, 'w', encoding='utf-8', newline='') as out_f:
        writer = csv.DictWriter(out_f, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in rows:
            sid = row.get('section_id')
            processed_count += 1
            
            # Removed demo limit of 5.
            # if processed_count > 5:
            #      break

            print(f"Enriching {sid}...")
            
            # Use LLM to get new data
            meta = generate_metadata(row.get('text', ''), row.get('title', ''))
            
            # Update row
            row['common_name'] = meta.get('common_name', '')
            row['severity'] = meta.get('severity', '')
            row['keywords'] = meta.get('keywords', '')
            
            writer.writerow(row)
            
            # Be nice to local LLM
            time.sleep(0.5)
            
    print(f"Done. Enriched data saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
