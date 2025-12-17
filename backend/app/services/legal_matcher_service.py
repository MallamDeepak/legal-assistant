import os
import csv
import re
from typing import List, Optional, Tuple

BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
# The corpus CSV is located at the repository `data/` directory (backend/data/legal_corpus.csv)
CORPUS = os.path.abspath(os.path.join(BASE, '..', 'data', 'legal_corpus.csv'))
CORPUS_PDFS = os.path.abspath(os.path.join(BASE, '..', 'data', 'legal_corpus_pdfs.csv'))


_CORPUS_CACHE: Optional[Tuple[float, list]] = None


def _pick_corpus_path() -> str:
    # Prefer the richer PDF-derived corpus if present.
    if os.path.exists(CORPUS_PDFS):
        return CORPUS_PDFS
    return CORPUS


def _load_corpus(path: str):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, newline='', encoding='utf-8') as f:
        r = csv.DictReader(f)
        for row in r:
            rows.append({'section_id': row.get('section_id', ''), 'title': row.get('title', ''), 'text': row.get('text', '')})
    return rows


def _get_corpus_cached() -> list:
    global _CORPUS_CACHE
    path = _pick_corpus_path()
    try:
        mtime = os.path.getmtime(path)
    except Exception:
        mtime = 0.0

    if _CORPUS_CACHE is not None:
        cached_mtime, cached_rows = _CORPUS_CACHE
        if cached_mtime == mtime:
            return cached_rows

    rows = _load_corpus(path)
    _CORPUS_CACHE = (mtime, rows)
    return rows


def _tokenize(s: str) -> List[str]:
    return re.findall(r"\w+", s.lower())


def find_relevant_sections(text: str, top_k: int = 5) -> list:
    """Lightweight fallback matcher using token overlap against `data/legal_corpus.csv`.

    This is a simple heuristic ranking suitable for development and demos.
    For production replace with embeddings + FAISS/Chroma.
    """
    if not text:
        return []

    corpus = _get_corpus_cached()
    if not corpus:
        return ['IPC 379']

    tokens = set(_tokenize(text))
    scores = []
    for row in corpus:
        doc_tokens = set(_tokenize(row.get('text', '') + ' ' + row.get('title', '')))
        overlap = len(tokens & doc_tokens)
        scores.append((overlap, row.get('section_id', ''), row.get('title', '')))

    scores.sort(reverse=True, key=lambda x: x[0])
    out = []
    for score, section_id, title in scores[:top_k]:
        if score > 0:
            out.append(f"{section_id} - {title}")
    # Fallback if nothing matched
    if not out:
        # Don't return random top-k rows as they are irrelevant (e.g. Preamble)
        return []
    return out


"""Keyword matcher as fallback when vector search is unavailable."""
class LegalMatcherService:
    def __init__(self):
        # Minimal keyword map as fallback only
        self.keyword_map = {
            'theft': ['IPC 379'],
            'murder': ['IPC 302'],
            'assault': ['IPC 323'],
            'cheating': ['IPC 420'],
        }
    
    def match_sections(self, text: str, top_k: int = 5) -> List[dict]:
        """Fallback keyword matcher. Vector search should be used first."""
        if not text:
            return []
        
        text_lower = text.lower()
        matched = []
        
        # Check specific keywords
        for keyword, sections in self.keyword_map.items():
            if keyword in text_lower:
               for sec in sections:
                   matched.append({'section_id': sec, 'title': f"Offence of {keyword.capitalize()}"})

        # If no strict keyword match, try token overlap with a small subset of corpus or return nothing
        # (Returning random top-k is confusing for users)
        if not matched:
             from app.services.legal_matcher_service import find_relevant_sections
             # usages of the standalone function which does token overlap
             raw_matches = find_relevant_sections(text, top_k)
             for m in raw_matches:
                 # m is "ID - Title" or just ID
                 if " - " in m:
                     sid, title = m.split(" - ", 1)
                     matched.append({'section_id': sid, 'title': title})
                 else:
                     matched.append({'section_id': m, 'title': 'Relevant Section'})
        
        # Deduplicate
        seen = set()
        unique_matched = []
        for m in matched:
            if m['section_id'] not in seen:
                seen.add(m['section_id'])
                unique_matched.append(m)
                
        return unique_matched[:top_k]
