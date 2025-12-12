import os


# Best-effort .env loading (safe if python-dotenv not installed)
try:
    from dotenv import load_dotenv  # type: ignore

    _BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    load_dotenv(os.path.join(_BASE_DIR, '.env'))
except Exception:
    pass

class Settings:
    APP_NAME: str = os.getenv('APP_NAME', 'legal-assistant')
    VECTOR_DB_PATH: str = os.getenv('VECTOR_DB_PATH', './vector_db')
    # Optional: full path to the Tesseract executable (Windows). If empty, rely on PATH.
    TESSERACT_PATH: str = os.getenv('TESSERACT_PATH', '')

    # RAG / LLM (OpenAI-compatible)
    OPENAI_API_KEY: str = os.getenv('OPENAI_API_KEY', '')
    OPENAI_MODEL: str = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
    OPENAI_BASE_URL: str = os.getenv('OPENAI_BASE_URL', 'https://api.openai.com/v1')

    # Embeddings / FAISS paths
    EMBEDDING_MODEL: str = os.getenv('EMBEDDING_MODEL', 'sentence-transformers/all-mpnet-base-v2')
    FAISS_INDEX_PATH: str = os.getenv('FAISS_INDEX_PATH', '')
    FAISS_META_PATH: str = os.getenv('FAISS_META_PATH', '')

settings = Settings()
