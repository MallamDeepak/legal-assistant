import re
from typing import Dict, List


def extract_entities(text: str) -> Dict[str, List[str]]:
    """Simple heuristic NER: dates, capitalized words as name candidates, and basic location tokens.

    This is a development stub. Replace with SpaCy or transformer-based NER for production.
    """
    out = {'names': [], 'locations': [], 'dates': [], 'sections': []}
    if not text:
        return out

    # Dates (very simple)
    dates = re.findall(r"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b", text)
    out['dates'] = dates

    # Names: sequences of capitalized words (naive)
    name_matches = re.findall(r"\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b", text)
    # Filter very short tokens
    out['names'] = [n for n in name_matches if len(n) > 2][:10]

    # Locations: common place words (naive)
    loc_keywords = ['city', 'village', 'district', 'state', 'road', 'colony', 'mandal', 'pincode']
    locs = []
    for kw in loc_keywords:
        for m in re.finditer(rf"([A-Za-z0-9\s\,\-]+{kw})", text, flags=re.IGNORECASE):
            locs.append(m.group(1).strip())
    out['locations'] = locs[:10]

    # Sections: extract 'IPC 379' like patterns
    sections = re.findall(r"\bIP[Cc]\s*\d{1,4}\b", text)
    out['sections'] = sections

    return out
