import csv
import sys
from pathlib import Path

csv.field_size_limit(sys.maxsize)

path = Path("backend/data/legal_corpus_pdfs.csv")

with open(path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)
    print(f"Total Parsed Rows: {len(rows)}")
    
    # Check for giant rows
    giant_rows = [r for r in rows if len(r['text']) > 5000]
    print(f"Rows with >5000 chars: {len(giant_rows)}")
    
    if giant_rows:
        print("\nExample Giant Row (First 500 chars):")
        print(giant_rows[0]['text'][:500])
        print("...")
