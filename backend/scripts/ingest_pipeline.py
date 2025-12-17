import re, unicodedata, uuid
from pathlib import Path
from typing import List, Dict
from langdetect import detect
import pdfplumber
from bs4 import BeautifulSoup

def load_text(path: Path) -> str:
    ext = path.suffix.lower()
    if ext == ".pdf":
        with pdfplumber.open(path) as pdf:
            return "\n".join((p.extract_text() or "") for p in pdf.pages)
    if ext in {".html", ".htm"}:
        html = path.read_text(encoding="utf-8", errors="replace")
        soup = BeautifulSoup(html, "html.parser")
        return soup.get_text("\n")
    return path.read_text(encoding="utf-8", errors="replace")

def normalize(text: str) -> str:
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()

def chunk(text: str, min_tokens=200, max_tokens=500) -> List[str]:
    tokens = text.split()
    out, i = [], 0
    while i < len(tokens):
        block = tokens[i : i + max_tokens]
        if len(block) >= min_tokens:
            out.append(" ".join(block))
        i += max_tokens
    return out or ([text] if text else [])

def process_file(path: Path, source: str, title: str = "") -> List[Dict]:
    raw = load_text(path)
    norm = normalize(raw)
    language = detect(norm or "en")
    doc_id = str(uuid.uuid4())
    chunks = chunk(norm)
    records = []
    for idx, c in enumerate(chunks):
        records.append({
            "doc_id": doc_id,
            "source": source,
            "section_id": f"{path.stem}",
            "title": title or path.stem,
            "language": language,
            "chunk_index": idx,
            "text": c,
        })
    return records

if __name__ == "__main__":
    import json, sys
    files = [Path(p) for p in sys.argv[1:]]
    all_recs = []
    for f in files:
        all_recs.extend(process_file(f, source="ingest"))
    print(json.dumps(all_recs, ensure_ascii=False, indent=2))