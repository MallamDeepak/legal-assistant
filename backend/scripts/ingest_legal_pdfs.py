import pdfplumber
import re
import csv
import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data"
CORPUS_PATH = BASE_DIR / "data" / "legal_corpus_pdfs.csv"

def extract_text_from_pdf(pdf_path):
    print(f"Processing {pdf_path.name}...")
    full_text = ""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            total_pages = len(pdf.pages)
            print(f"  Found {total_pages} pages.")
            for i, page in enumerate(pdf.pages, 1):
                text = page.extract_text()
                if text:
                    full_text += text + "\n"
                if i % 20 == 0:
                    print(f"  ...read {i}/{total_pages} pages")
    except Exception as e:
        print(f"Error reading PDF: {e}")
    return full_text

def parse_sections(text, source_name="Unknown"):
    """
    Heuristic parser to split text into legal sections.
    Matches "Section 123.", "Article 45.", etc.
    """
    # Regex to find section headers: e.g. "Section 379." or "379. Punishment for theft."
    # Adjust regex based on the specific PDF format.
    # Pattern: Newline followed by digits, dot, and text OR "Section" followed by digits
    
    # Common India Code format: "1. Short title..." or "Section 302. Punishment..."
    # We will try a generic splitter.
    
    # Improved split: "Section 302" OR "302." at start of line
    # Matches: \n + (Section + space + digits + dot) OR \n + (digits + dot + space)
    parts = re.split(r'(\n\s*Section\s+\d+\.|\n\s*\d+\.\s+)', text)
    
    sections = []
    current_title = "Preamble"
    current_text = ""
    
    if len(parts) > 0:
        current_text = parts[0]
        
    for i in range(1, len(parts), 2):
        header = parts[i].strip() # e.g. "Section 302."
        content = parts[i+1] if i+1 < len(parts) else ""
        
        # Save previous
        if current_text.strip():
            # Try to extract a title from the first line of content
            lines = current_text.strip().split('\n')
            
            # Clean up the ID
            clean_id = current_title.replace('.', '').strip()
            if source_name not in clean_id:
                clean_id = f"{source_name} {clean_id}"
                
            sections.append({
                'section_id': clean_id,
                'title': lines[0][:100] if lines else 'Content',
                'text': current_text.strip(),
                'source': source_name,
                'language': 'en'
            })
            
        current_title = header
        current_text = content
        
    # Append last
    if current_text.strip():
        clean_id = current_title.replace('.', '').strip()
        if source_name not in clean_id:
            clean_id = f"{source_name} {clean_id}"
        sections.append({
            'section_id': clean_id,
            'title': 'End Section',
            'text': current_text.strip(),
            'source': source_name,
            'language': 'en'
        })
            
    print(f"  -> Extracted {len(sections)} sections")
    return sections

def main():
    if not RAW_DIR.exists():
        RAW_DIR.mkdir(parents=True)
        print(f"Created directory: {RAW_DIR}")
        print("Please place your 'ipc_act.pdf' and other files here and run this script again.")
        return

    pdf_files = list(RAW_DIR.glob("*.pdf"))
    if not pdf_files:
        print(f"No PDF files found in {RAW_DIR}")
        print("Please place 'ipc_act.pdf' etc. in this folder.")
        return

    all_rows = []
    for pdf_file in pdf_files:
        # Determine source name from filename (e.g. ipc_act.pdf -> IPC)
        name = pdf_file.stem.lower()
        source = "LAW"
        if "ipc" in name: source = "IPC"
        elif "crpc" in name or "criminal" in name: source = "CrPC"
        elif "contract" in name: source = "ContractAct"
        
        text = extract_text_from_pdf(pdf_file)
        if not text.strip():
            print(f"  Warning: No text extracted from {pdf_file.name}. It might be scanned images.")
            print("  Try using OCR tools if this is a scanned PDF.")
            continue
            
        rows = parse_sections(text, source)
        all_rows.extend(rows)

    if not all_rows:
        print("No sections extracted.")
        return

    # Overwrite (Replace Init)
    with open(CORPUS_PATH, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['section_id', 'title', 'text', 'source', 'language'])
        writer.writeheader()
        writer.writerows(all_rows)
        
    print(f"✓ Successfully appended {len(all_rows)} sections to {CORPUS_PATH}")
    print("Now run the re-indexing script to update the search index.")

if __name__ == "__main__":
    main()
