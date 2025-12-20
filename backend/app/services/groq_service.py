import os
import requests
import json
from typing import Optional

class GroqService:
    # Use the key provided in generate_contract_data.py
    API_KEY = "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"
    BASE_URL = "https://api.groq.com/openai/v1/chat/completions"
    DEFAULT_MODEL = "llama-3.1-8b-instant" # Fast and good for chat

    @classmethod
    def generate_text(cls, prompt: str, system_prompt: str = "You are a helpful assistant.", model: str = None) -> Optional[str]:
        """
        Generate text using Groq API.
        Returns the generated text string, or None if the service is unavailable/fails.
        """
        model = model or cls.DEFAULT_MODEL
        
        headers = {
            "Authorization": f"Bearer {cls.API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.0,
            "max_tokens": 1024
        }
        
        try:
            response = requests.post(cls.BASE_URL, headers=headers, json=payload, timeout=10)
            if response.status_code != 200:
                print(f"Groq API Error: {response.status_code} {response.text}")
                return None
                
            data = response.json()
            return data['choices'][0]['message']['content'].strip()
        except Exception as e:
            print(f"Groq generation failed: {e}")
            return None

    @classmethod
    def is_available(cls) -> bool:
        """Check if we have an API key configured (simple check)."""
        return bool(cls.API_KEY)
