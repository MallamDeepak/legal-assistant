# Legal Assistant Backend (FastAPI) — Complete Skeleton

This folder contains a complete FastAPI skeleton ready for extension with OCR, NER, semantic matching and PDF generation.

## Quick Start (recommended: minimal demo install)

These steps will install only the packages needed to run the demo endpoints (no heavy ML packages):

```powershell
cd D:\project\legal-assistant-complete\backend
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install fastapi uvicorn pydantic python-multipart Pillow pytesseract reportlab pytest spacy
python -m spacy download en_core_web_sm
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

If you want the full ML stack (embeddings, FAISS/Chroma, transformers, spaCy, torch), re-run:

```powershell
pip --default-timeout=100 install -r requirements.txt
```

Note: the full install downloads many large wheels and may take a long time or fail on an unstable network. For development the minimal install is sufficient because the code contains lightweight stubs for matcher/NER/OCR.

## Environment variables (.env)

Create a `.env` file in the `backend/` folder (you can copy the example):

```powershell
cd D:\project\legal-assistant-complete\backend
Copy-Item .env.example .env
notepad .env
```

Edit `.env` and set appropriate values. Example contents:

```dotenv
APP_NAME=legal-assistant
VECTOR_DB_PATH=./vector_db
TESSERACT_PATH=C:\Program Files\Tesseract-OCR\tesseract.exe
```

How to apply `.env` values to your shell session (one of):

- Manually set for session (PowerShell):

```powershell
$env:APP_NAME='legal-assistant'
$env:VECTOR_DB_PATH='D:\project\legal-assistant-complete\backend\vector_db'
$env:TESSERACT_PATH='C:\Program Files\Tesseract-OCR\tesseract.exe'
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Persist via `setx` (requires new terminal):

```powershell
setx APP_NAME "legal-assistant"
setx VECTOR_DB_PATH "D:\project\legal-assistant-complete\backend\vector_db"
setx TESSERACT_PATH "C:\Program Files\Tesseract-OCR\tesseract.exe"
```

Optional: add `python-dotenv` and auto-load `.env` at startup (I can add this for you if you prefer automatic loading).

## Tesseract OCR (Windows)

1. Download and install Tesseract for Windows (UB Mannheim builds are common):
   - https://github.com/UB-Mannheim/tesseract/wiki
2. Default install path is usually `C:\Program Files\Tesseract-OCR\tesseract.exe`.
3. Either add the Tesseract folder to your PATH or set `TESSERACT_PATH` in `.env` to the full `tesseract.exe` path.
4. Verify in PowerShell:

```powershell
& 'C:\Program Files\Tesseract-OCR\tesseract.exe' --version
# or if on PATH:
tesseract --version
```

The backend `ocr_service` will use `TESSERACT_PATH` (if set) to configure `pytesseract`.

## Health check & example requests

Health endpoint (after server start):

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8000/'
```

Example incident generation request (PowerShell):

```powershell
Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/incident/generate' -ContentType 'application/json' -Body '{"language":"en","text":"Someone stole my bike from the road"}'
```

Use Postman, curl or the frontend to POST multipart files to `/fir/analyze` and `/contract/review` with the form field name `file`.

## API endpoints (summary)

- `GET /` — health/status
- `POST /incident/generate` — body: `{language, text}` -> returns `{suggested_sections, fir_text}`
- `POST /fir/analyze` — form file field `file` (image/pdf) -> returns `{extracted_text, detected_sections, entities}`
- `POST /contract/review` — form file field `file` (image/pdf/text) -> returns `{text, clauses}` where each clause is `{clause, status}`

CORS is enabled for development (all origins allowed). Remove or restrict in production.

## Training roadmap (short)

If you want to train ML models over legal data, follow these phases:

1. Scope & safety: define jurisdictions, languages, and PII handling.
2. Collect & preprocess: statutes, case law, contracts, FIR examples; convert to text; chunk into passages with metadata.
3. Embeddings & index: compute embeddings (sentence-transformers) and build a vector store (FAISS/Chroma/Milvus).
4. NER & classifiers: label entities and clause classes; train SpaCy or Transformer models for NER and clause classification.
5. RAG + LLM: build retriever + LLM pipelines to generate FIR drafts and answers using retrieved context.
6. (Optional) Fine-tune models (LoRA/PEFT) for domain-specific generation.
7. Evaluate, monitor, and deploy with human-in-the-loop review.

If you want, I can add example scripts for embedding+indexing, NER training starters, or a simple RAG endpoint.

---
Notes: this README focuses on development and demonstration. For production, add secure API keys, HTTPS, CORS restrictions, authentication, logging, and legal disclaimers.
