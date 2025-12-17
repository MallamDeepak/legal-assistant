import argparse, json, os, csv
from pathlib import Path
from typing import List
import pdfplumber

def pdf_to_text(path: Path) -> str:
    try:
        with pdfplumber.open(path) as pdf:
            pages = [p.extract_text() or "" for p in pdf.pages]
        return "\n".join(pages).strip()
    except Exception as e:
        print(f"Error reading {path}: {e}")
        return ""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input_dir", default="data/raw/india_code", help="Folder with PDFs")
    ap.add_argument("--output", default="data/legal_corpus.csv", help="CSV output")
    args = ap.parse_args()

    input_dir = Path(args.input_dir)
    if not input_dir.exists():
        print(f"Error: {input_dir} does not exist")
        return

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    pdf_count = 0

    for root, _, files in os.walk(input_dir):
        for fname in files:
            if not fname.lower().endswith(".pdf"):
                continue
            pdf_count += 1
            fpath = Path(root) / fname
            print(f"Processing {pdf_count}: {fpath.name}...")
            text = pdf_to_text(fpath)
            if not text or len(text.strip()) < 50:
                print(f"  Skipped (no text or too short)")
                continue
            
            section_id = fpath.stem
            title = fpath.stem.replace("_", " ").title()
            rows.append({
                'section_id': section_id,
                'title': title,
                'text': text.replace('\n', ' ').replace('"', "'"),
                'source': str(fpath),
                'language': 'en'
            })
            print(f"  Added ({len(text)} chars)")

    if not rows:
        print(f"\nNo PDFs found or extracted in {input_dir}")
        return

    with open(out, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['section_id', 'title', 'text', 'source', 'language'])
        writer.writeheader()
        writer.writerows(rows)

    print(f"\n✓ Written {len(rows)} sections to {out}")

if __name__ == "__main__":
    main()