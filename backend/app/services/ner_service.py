import re
from typing import Dict, List
import spacy

# Global Spacy model (lazy load)
_nlp = None

def get_nlp():
    global _nlp
    if _nlp is None:
        try:
            _nlp = spacy.load("en_core_web_sm")
        except Exception as e:
            print(f"Warning: Could not load spacy model: {e}")
            _nlp = False  # Mark as failed to avoid retrying
    return _nlp if _nlp else None


def extract_entities(text: str) -> Dict[str, List[str]]:
    """Extract entities using Spacy with Regex fallback."""
    out = {'names': [], 'locations': [], 'dates': [], 'sections': []}
    if not text:
        return out

    # 1. Try Spacy for robust NER
    nlp = get_nlp()
    if nlp:
        doc = nlp(text)
        for ent in doc.ents:
            if ent.label_ == 'PERSON':
                out['names'].append(ent.text)
            elif ent.label_ in ('GPE', 'LOC'):
                out['locations'].append(ent.text)
            elif ent.label_ == 'DATE':
                out['dates'].append(ent.text)
    
    # 2. Regex fallback/supplement (especially for Sections which Spacy might miss)
    
    # Dates (simple backup)
    if not out['dates']:
        dates = re.findall(r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b", text)
        out['dates'].extend(dates)

    # Sections: extract 'IPC 379' like patterns (Spacy won't catch this specific legal format)
    sections = re.findall(r"\bIP[Cc]\s*\d{1,4}\b", text)
    out['sections'] = sections

    # Deduplicate and limit
    out['names'] = list(set(out['names']))[:10]
    out['locations'] = list(set(out['locations']))[:10]
    out['dates'] = list(set(out['dates']))[:10]
    out['sections'] = list(set(out['sections']))
    
    return out
