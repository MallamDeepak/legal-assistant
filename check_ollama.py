import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.services.ollama_service import OllamaService

def test_ollama():
    print("Checking Ollama availability...")
    if not OllamaService.is_available():
        print("❌ Ollama service not reachable at http://localhost:11434")
        return

    print("✓ Ollama is online.")
    print("Attempting to generate text with llama3.2...")
    
    prompt = "Explain the concept of 'Habeas Corpus' in one sentence."
    response = OllamaService.generate_text(prompt)
    
    if response:
        print(f"\n✓ Generation Successful!")
        print(f"Prompt: {prompt}")
        print(f"Response: {response}")
    else:
        print("❌ Generation failed. Check server logs or model availability.")

if __name__ == "__main__":
    test_ollama()
