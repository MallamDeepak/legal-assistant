import csv
import json
import sys
import os
import requests
import time
from pathlib import Path

# Add parent dir to path to import OllamaService if needed, 
# but for standalone script easier to use requests directly or mock.
# We will assume Ollama is running at localhost:11434

# Groq Configuration for Speed
GROQ_API_KEY = "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"
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
# MODEL_NAME = "llama3-8b-8192" # Decommissioned
MODEL_NAME = "llama-3.1-8b-instant" 
# OLLAMA_URL = "http://localhost:11434/api/generate" # Backup 

# Increase CSV field size limit (Explicit 100MB)
csv.field_size_limit(100 * 1024 * 1024) 

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "data" / "legal_corpus_pdfs.csv"
OUTPUT_FILE = BASE_DIR / "data" / "training" / "synthetic_dataset.jsonl"

def generate_queries(text_content):
    """Ask Groq LLM to generate user queries for this legal text."""
    system_prompt = "You are generating training data for a legal chatbot."
    user_prompt = f"""
    LEGAL TEXT:
    "{text_content[:6000]}"
    
    TASK:
    Generate 15 distinct "User Queries" that a layman might ask to trigger this legal section.
    - 5 Direct questions (e.g. "What is punishment for...", "Is it illegal to...")
    - 5 Short incident descriptions (e.g. "My neighbor hit me...", "I found a bag...")
    - 5 Keyword based queries (e.g. "Laws about theft", "IPC 302 meaning")
    
    Return ONLY the 15 queries, one per line. No numbering.
    """
    
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.7
    }
    
    # Infinite Retry Loop for robustness
    while True:
        try:
            # Groq is fast, 30s is enough
            resp = requests.post(GROQ_URL, headers=headers, json=payload, timeout=30)
            
            if resp.status_code == 413:
                print(f"Payload Too Large (413). Skipping section...")
                return [] # Skip this row, don't retry forever

            if resp.status_code == 429:
                print("Rate limit hit, sleeping 5s...")
                time.sleep(5)
                continue # Retry
                
            if resp.status_code == 503 or resp.status_code == 500:
                print(f"Groq Server Error {resp.status_code}, sleeping 10s...")
                time.sleep(10)
                continue
                
            resp.raise_for_status()
            output = resp.json()['choices'][0]['message']['content'].strip()
            lines = [l.strip().lstrip('-').strip() for l in output.split('\n') if l.strip()]
            return lines[:15]
            
        except requests.exceptions.Timeout:
            print("Timeout, retrying...")
            time.sleep(2)
            continue
        except Exception as e:
            print(f"Error generating: {e} - Retrying in 5s...")
            time.sleep(5)
            continue

def main():
    print(f"Reading from {DATA_FILE}")
    if not DATA_FILE.exists():
        print("Error: legal_corpus.csv not found.")
        return

    # Ensure output dir exists
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    from concurrent.futures import ThreadPoolExecutor, as_completed

    # Helper for thread
    def process_row(row):
        sid = row.get('section_id')
        text = row.get('text')
        title = row.get('title')
        
        # Filter: Process only IPC, CrPC, BNSS, BNS (Core Criminal Laws)
        # check_str = (str(title) + str(sid)).upper()
        # if "IPC" not in check_str and "CRPC" not in check_str and "BNS" not in check_str:
        #    return None
        
        # Just check for valid content
        if not text or len(text) < 50:
             return None
            
        print(f"Processing {sid}...")
        try:
            queries = generate_queries(text)
        except Exception as e:
            print(f"Query gen failed for {sid}: {e}")
            return None
        
        results = []
        for q in queries:
            results.append({
                "messages": [
                    {"role": "user", "content": q},
                    {"role": "assistant", "content": f"The relevant section is {sid}: {title}. {text[:200]}..."}
                ]
            })
        return results

    # Main Processing
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        all_rows = list(reader) # Read all into memory to safe-thread
        
    print(f"Loaded {len(all_rows)} rows. Limiting to first 1000 valid items for speed...")
    # Slicing doesn't work perfectly for 'valid items' logic but we can stop early.
    # We'll just submit all and let user stop, OR slice here.
    # User wanted 2-3 hours. 1000 items with 3 threads = ~333 batches. 1 min per batch?
    # 333 mins = 5 hours. 
    # User wanted 2-3 hours. With Groq we can do much more.
    # all_rows = all_rows[:500] 

    with open(OUTPUT_FILE, 'a', encoding='utf-8') as out_f:
        with ThreadPoolExecutor(max_workers=3) as executor:
            future_to_sid = {executor.submit(process_row, row): row.get('section_id') for row in all_rows}
            
            for future in as_completed(future_to_sid):
                try:
                    res = future.result()
                    if res:
                        for record in res:
                            out_f.write(json.dumps(record) + "\n")
                        out_f.flush()
                except Exception as exc:
                    print(f"Task generated an exception: {exc}")

    print(f"Done. Appended new data to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
