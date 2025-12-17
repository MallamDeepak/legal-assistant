"""
Phase 3: Build embeddings and FAISS index from legal corpus.

Usage (from backend/):
    pip install sentence-transformers faiss-cpu
    python -m scripts.embed_and_index --input data/legal_corpus.csv --output data/legal_index

This script:
1. Reads data/legal_corpus.csv
2. Converts to canonical JSONL with chunking
3. Computes multilingual embeddings (LaBSE)
4. Writes FAISS index + metadata JSON for retrieval
"""

import json
import csv
import sys
import argparse
import os
from pathlib import Path
from typing import List, Dict
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np

# Increase CSV limit for large PDF text fields
csv.field_size_limit(sys.maxsize)

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = BASE_DIR / "data" / "legal_corpus.csv"
DEFAULT_OUTPUT = BASE_DIR / "data" / "legal_index"


def load_csv(path: Path) -> List[Dict]:
    """Load CSV corpus into list of dicts."""
    rows = []
    if not path.exists():
        print(f"Error: {path} not found")
        return rows
    
    try:
        with open(path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if not row.get('text', '').strip():
                    continue
                rows.append({
                    'section_id': row.get('section_id', '').strip(),
                    'title': row.get('title', '').strip(),
                    'text': row.get('text', '').strip(),
                    'language': row.get('language', 'en').strip() or 'en'
                })
    except Exception as e:
        print(f"Error reading CSV: {e}")
    
    return rows


def chunk_text(text: str, target_tokens: int = 350, min_tokens: int = 150) -> List[str]:
    """Split text into passages of ~350 tokens."""
    if not text or len(text.strip()) < 50:
        return [text] if text.strip() else []
    tokens = text.split()
    chunks = []
    i = 0
    while i < len(tokens):
        chunk_tokens = tokens[i : i + target_tokens]
        if len(chunk_tokens) >= min_tokens or i + target_tokens >= len(tokens):
            chunks.append(' '.join(chunk_tokens))
        i += target_tokens
    return chunks if chunks else [text]


def build_passages(rows: List[Dict]) -> List[Dict]:
    """Convert CSV rows to chunked passages with metadata."""
    passages = []
    passage_id = 0
    for row in rows:
        section_id = row.get('section_id', 'unknown')
        title = row.get('title', section_id)
        text = row.get('text', '')
        language = row.get('language', 'en')
        
        if not text.strip():
            continue
        
        chunks = chunk_text(text)
        for chunk_idx, chunk_text_str in enumerate(chunks):
            passages.append({
                'id': f"{section_id}_{passage_id:04d}",
                'passage_id': passage_id,
                'section_id': section_id,
                'title': title,
                'text': chunk_text_str,
                'language': language,
                'chunk_index': chunk_idx,
                'chunk_count': len(chunks),
            })
            passage_id += 1
    
    return passages


def embed_passages(passages: List[Dict], model_name: str = 'LaBSE') -> tuple:
    """Compute embeddings for all passages using a multilingual model.
    
    LaBSE: supports 109 languages, ~768 dim.
    all-mpnet-base-v2: English-focused but fast, ~768 dim.
    """
    print(f"Loading embedding model: {model_name}...")
    model = SentenceTransformer(model_name)
    
    texts = [p['text'] for p in passages]
    print(f"Computing embeddings for {len(texts)} passages...")
    embeddings = model.encode(texts, show_progress_bar=True, batch_size=32, normalize_embeddings=True)
    
    return embeddings, model.get_sentence_embedding_dimension()


def build_faiss_index(embeddings: np.ndarray, passages: List[Dict], output_dir: Path):
    """Build and save FAISS index."""
    output_dir.mkdir(parents=True, exist_ok=True)
    
    dim = embeddings.shape[1]
    print(f"Building FAISS index (dim={dim}, passages={len(passages)})...")
    
    # Use IndexFlatIP for Inner Product (Cosine Similarity since normalized)
    index = faiss.IndexFlatIP(dim)
    index.add(embeddings.astype('float32'))
    
    index_path = output_dir / 'index.faiss'
    faiss.write_index(index, str(index_path))
    print(f"Saved FAISS index to {index_path}")
    
    # Save metadata as JSONL
    metadata_path = output_dir / 'metadata.jsonl'
    with open(metadata_path, 'w', encoding='utf-8') as f:
        for p in passages:
            f.write(json.dumps(p, ensure_ascii=False) + '\n')
    print(f"Saved metadata to {metadata_path}")
    
    # Save config
    config = {
        'model': 'LaBSE',
        'dimension': dim,
        'total_passages': len(passages),
        'index_type': 'IndexFlatIP'
    }
    config_path = output_dir / 'config.json'
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2)
    print(f"Saved config to {config_path}")


def main():
    parser = argparse.ArgumentParser(description='Build embeddings and FAISS index from legal corpus')
    parser.add_argument('--input', type=Path, default=DEFAULT_INPUT, help='Input CSV file')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT, help='Output directory for index')
    parser.add_argument('--model', default='LaBSE', help='Embedding model (LaBSE, all-mpnet-base-v2, etc.)')
    args = parser.parse_args()
    
    print(f"Reading corpus from {args.input}...")
    rows = load_csv(args.input)
    print(f"Loaded {len(rows)} rows")
    
    print("Building passages (chunking)...")
    passages = build_passages(rows)
    print(f"Created {len(passages)} passages")
    
    if not passages:
        print("No passages to embed. Exiting.")
        return
    
    embeddings, dim = embed_passages(passages, args.model)
    build_faiss_index(embeddings, passages, args.output)
    
    print(f"\n✓ Index built successfully at {args.output}")
    print(f"  To use: from scripts.retrieve import Retriever; r = Retriever('{args.output}')")


if __name__ == '__main__':
    main()