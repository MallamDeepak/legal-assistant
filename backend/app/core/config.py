import os

class Settings:
    APP_NAME: str = os.getenv('APP_NAME', 'legal-assistant')
    VECTOR_DB_PATH: str = os.getenv('VECTOR_DB_PATH', './vector_db')
    # Optional: full path to the Tesseract executable (Windows). If empty, rely on PATH.
    TESSERACT_PATH: str = os.getenv('TESSERACT_PATH', '')

settings = Settings()
