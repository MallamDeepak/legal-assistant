import os

class Settings:
    APP_NAME: str = os.getenv('APP_NAME', 'legal-assistant')
    VECTOR_DB_PATH: str = os.getenv('VECTOR_DB_PATH', './vector_db')
    # Optional: full path to the Tesseract executable (Windows). If empty, rely on PATH.
    TESSERACT_PATH: str = os.getenv('TESSERACT_PATH', '')
    DATABASE_URL: str = os.getenv('DATABASE_URL', 'postgresql+psycopg://postgres:deepak@localhost:5432/legal_assistant')
    DATABASE_ECHO: bool = os.getenv('DATABASE_ECHO', 'false').lower() == 'true'
    PGVECTOR_DIM: int = int(os.getenv('PGVECTOR_DIM', '768'))

settings = Settings()
