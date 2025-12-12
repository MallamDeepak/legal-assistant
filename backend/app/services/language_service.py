from __future__ import annotations


def detect_language(text: str) -> str:
    """Best-effort language detection.

    Returns a short language code (e.g., 'en') or 'unknown'.
    """
    if not text or not text.strip():
        return "unknown"

    try:
        from langdetect import detect  # type: ignore
    except Exception:
        return "unknown"

    try:
        return detect(text)
    except Exception:
        return "unknown"
