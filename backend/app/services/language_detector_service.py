from langdetect import detect, detect_langs, DetectorFactory
from typing import Optional

# Ensure consistent results
DetectorFactory.seed = 0

class LanguageDetectorService:
    SUPPORTED_LANGUAGES = {
        'en': 'en',
        'hi': 'hi',
        'bn': 'bn',
        'te': 'te',
        'mr': 'mr'
    }

    @staticmethod
    def detect_language(text: str) -> str:
        """
        Detects the language of the input text and returns our supported code.
        Defaults to 'en' if detection fails or language is not supported.
        """
        if not text or len(text.strip()) < 3:
            return 'en'
            
        try:
            detected = detect(text)
            # Map common variants or unsupported codes
            if detected in LanguageDetectorService.SUPPORTED_LANGUAGES:
                return detected
            
            # Check for high confidence alternatives if the top one isn't supported
            # (e.g., langdetect might return 'hi-IN' or 'hi' but sometimes 'ne' for short Hindi snippets)
            possible = detect_langs(text)
            for p in possible:
                if p.lang in LanguageDetectorService.SUPPORTED_LANGUAGES and p.prob > 0.5:
                    return p.lang
            
        except Exception as e:
            print(f"Language detection failed: {e}")
            
        return 'en'
