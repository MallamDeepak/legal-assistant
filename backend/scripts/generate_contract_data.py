import json
import csv
import time
import requests
import random
from pathlib import Path

# CONFIG
GROQ_API_KEY = "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"
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = "llama-3.1-8b-instant"
OUTPUT_FILE = "data/training/contract_fraud_dataset.csv"
NUM_SAMPLES = 1700 # 1700 * 3 = 5100 total samples 

PROMPTS = {
    "Safe": "Generate a short, standard, fair, and legally sound contract clause for a generic Service Agreement. It should be completely safe and standard.",
    "Risky": "Generate a short contract clause that contains a 'Risky' term, such as a hidden fee, automatic renewal without notice, or broad indemnity. It should be technically legal but unfavorable to one party.",
    "Fraudulent": "Generate a short 'Fraudulent' or highly illegal contract clause. Examples: completely waiving all liability for gross negligence, requiring arbitration in a fake jurisdiction, or demanding payment for services not rendered. It should be clearly deceptive or unenforceable."
}

def generate_clause(label):
    system_prompt = "You are a legal expert generating data for a fraud detection system."
    user_prompt = f"""
    TASK: {PROMPTS[label]}
    
    OUTPUT: Return ONLY the raw text of the clause. Do not add quotes, prefixes, or explanations.
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
        "temperature": 0.8
    }
    
    try:
        resp = requests.post(GROQ_URL, headers=headers, json=payload, timeout=30)
        
        if resp.status_code == 429:
             time.sleep(2)
             return generate_clause(label) # Simple retry
             
        resp.raise_for_status()
        return resp.json()['choices'][0]['message']['content'].strip()
    except Exception as e:
        print(f"Error generating {label}: {e}")
        return None

def main():
    base_dir = Path(__file__).resolve().parent.parent
    output_path = base_dir / OUTPUT_FILE
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating {NUM_SAMPLES} samples per category using Groq (Parallel)...")
    
    data = []
    
    from concurrent.futures import ThreadPoolExecutor, as_completed

    def task(i, label):
        clause = generate_clause(label)
        return {"text": clause, "label": label} if clause else None

    # Generate balanced dataset
    # Total tasks = NUM_SAMPLES * 3 labels
    # We use a ThreadPool to run them in parallel
    total_tasks = NUM_SAMPLES * 3
    
        
    # Open file in append mode immediately to save incrementally
    mode = 'a' if output_path.exists() else 'w'
    with open(output_path, mode, newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=["text", "label"])
        if mode == 'w': writer.writeheader()
        
        completed = 0
        MAX_RETRIES = 5
        with ThreadPoolExecutor(max_workers=5) as executor:
            future_map = {}
            for i in range(NUM_SAMPLES):
                for label in ["Safe", "Risky", "Fraudulent"]:
                    future = executor.submit(task, i, label)
                    future_map[future] = (i, label)
            
            for future in as_completed(future_map):
                res = future.result()
                if res:
                    writer.writerow(res)
                    f.flush() # Ensure written to disk
                completed += 1
                if completed % 50 == 0:
                    print(f"Progress: {completed}/{total_tasks}")
                
    print(f"Done! Saved to {output_path}")
        
    print("Done! You can now run train_fraud_detector.py")

if __name__ == "__main__":
    main()
