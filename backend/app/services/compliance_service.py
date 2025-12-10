from typing import List, Dict
import re


def analyze_clauses(text: str) -> List[Dict[str, str]]:
    """Simple clause scanner that flags suspicious clauses by keyword heuristics.

    Returns a list of dicts: {'clause': <text>, 'status': 'ok'|'flagged'}
    """
    if not text:
        return []

    # Split into candidate clauses by newline or semicolon or numbered clause markers
    candidates = re.split(r"\n+|;|(?<=\))\s*|\d+\.\s+", text)
    keywords_flag = [
        'penalty', 'forfeit', 'without liability', 'no refund', 'unilateral', 'indemnify', 'waive', 'arbitration'
    ]
    out = []
    for c in candidates:
        s = c.strip()
        if not s:
            continue
        lowered = s.lower()
        status = 'ok'
        for kw in keywords_flag:
            if kw in lowered:
                status = 'flagged'
                break
        out.append({'clause': s, 'status': status})
    # If no clear clauses found, return a sample
    if not out:
        return [{'clause': text[:200], 'status': 'ok'}]
    return out
