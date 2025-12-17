import requests
import json
from typing import Optional

class OllamaService:
    BASE_URL = "http://localhost:11434/api/generate"
    DEFAULT_MODEL = "llama3.2"

    @classmethod
    def generate_text(cls, prompt: str, model: str = None) -> Optional[str]:
        """
        Generate text using the local Ollama instance.
        Returns the generated text string, or None if the service is unavailable.
        """
        model = model or cls.DEFAULT_MODEL
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                # "num_ctx": 4096 # Uncomment if context window needs strictly defined
            }
        }
        
        try:
            response = requests.post(cls.BASE_URL, json=payload, timeout=120)
            response.raise_for_status()
            data = response.json()
            return data.get("response", "").strip()
        except requests.exceptions.RequestException as e:
            print(f"Ollama generation failed: {e}")
            return None
        except Exception as e:
            print(f"Unexpected error in Ollama service: {e}")
            return None

    @classmethod
    def is_available(cls) -> bool:
        """Check if Ollama is reachable."""
        try:
            requests.get("http://localhost:11434/api/tags", timeout=2)
            return True
        except:
            return False
