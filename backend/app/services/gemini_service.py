import requests
import json
from typing import Optional

class GeminiService:
    API_KEY = "AIzaSyA6G42MyK5ZDC4lEYI0jVL9KyrEwnLkz0c"
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    @classmethod
    def generate_text(cls, prompt: str, system_prompt: str = None) -> Optional[str]:
        """
        Generate text using Google Gemini API (`gemini-1.5-flash`).
        Returns the generated text string, or None if the service is unavailable/fails.
        """
        if not cls.API_KEY:
            return None

        url = f"{cls.BASE_URL}?key={cls.API_KEY}"
        
        # Combine system prompt if provided (Gemini REST API handles system instructions differently, 
        # but for simple usage, prepending is fine or we can use the 'systemInstruction' field if strictly needed.
        # For simplicity and robustness with the free tier, we'll combine them or strictly follow the API).
        # Official API fits text in 'contents'.
        
        final_prompt = prompt
        if system_prompt:
            final_prompt = f"System: {system_prompt}\n\nUser: {prompt}"

        payload = {
            "contents": [{
                "parts": [{"text": final_prompt}]
            }],
            "generationConfig": {
                "temperature": 0.0,
                "topP": 0.0,
                "topK": 1
            }
        }
        
        try:
            response = requests.post(url, json=payload, timeout=10)
            if response.status_code != 200:
                print(f"Gemini API Error: {response.status_code} {response.text}")
                return None
                
            data = response.json()
            # Extract text
            # Response format: { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
            return data['candidates'][0]['content']['parts'][0]['text'].strip()
        except Exception as e:
            print(f"Gemini generation failed: {e}")
            return None

    @classmethod
    def is_available(cls) -> bool:
        return bool(cls.API_KEY)
