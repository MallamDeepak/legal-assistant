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

# RAG (required only if you call /rag/fir-draft)
OPENAI_API_KEY=sk-...
# OPENAI_MODEL=gpt-4o-mini
# OPENAI_BASE_URL=https://api.openai.com/v1

# Optional overrides for FAISS index paths
# FAISS_INDEX_PATH=./data/faiss_index/legal.faiss
# FAISS_META_PATH=./data/faiss_index/legal_meta.jsonl
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

This project auto-loads `backend/.env` at startup using `python-dotenv`.

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

## Convert PDFs into ML-ready data

To turn one or more legal PDFs into a simple corpus you can use for embeddings/RAG or training, use:

```powershell
cd D:\v4.0\legal-assistant\backend
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt

# convert specific files
python .\scripts\pdf_to_corpus.py --pdf "C:\Users\malla\Downloads\it_act_2000_updated.pdf" --pdf "C:\Users\malla\Downloads\iea_1872.pdf" --chunk-tokens 300 --overlap-tokens 50

# or convert all PDFs in a folder
# python .\scripts\pdf_to_corpus.py --input-dir "C:\Users\malla\Downloads"
```

This writes:
- `backend/data/legal_corpus.csv` (includes `section_id,title,text` so it works with `scripts/preload_vector_db.py`)
- `backend/data/legal_corpus.jsonl` (same data with metadata per chunk)
- `backend/data/legal_corpus_canonical.jsonl` (canonical ML record format: `id,text,title,source,language` + a few extra metadata fields)

Note: If a PDF is scanned (image-only), `pypdf` may extract little/no text; you'll need an OCR-based pipeline.

## Phase 3 — Embeddings & Vector DB (FAISS)

Install minimal packages (if not already installed via `requirements.txt`):

```powershell
cd D:\v4.0\legal-assistant\backend
. .venv\Scripts\Activate.ps1
pip install sentence-transformers faiss-cpu chromadb
```

Build a FAISS index (embedding + metadata JSONL):

```powershell
python .\scripts\build_faiss_index.py --input .\data\legal_corpus_pdfs_canonical.jsonl --out-index .\data\faiss_index\legal.faiss --out-meta .\data\faiss_index\legal_meta.jsonl --model sentence-transformers/all-mpnet-base-v2
```

Retrieval usage (load index, embed query, search top_k, print metadata):

```powershell
python .\scripts\query_faiss_index.py --index .\data\faiss_index\legal.faiss --meta .\data\faiss_index\legal_meta.jsonl --model sentence-transformers/all-mpnet-base-v2 --query "someone stole my bike" --top-k 5
```

## Phase 5 — RAG (Retriever + LLM)

1) Build your FAISS index first (Phase 3).

2) Configure an LLM (OpenAI-compatible):

- `OPENAI_API_KEY` (required)
- `OPENAI_MODEL` (optional, default: `gpt-4o-mini`)
- `OPENAI_BASE_URL` (optional, default: `https://api.openai.com/v1`)\
   Use this if you run a local OpenAI-compatible server.

3) Start the API and call the RAG endpoint:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

```powershell
Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/rag/fir-draft' -ContentType 'application/json' -Body '{"language":"en","text":"someone stole my bike from the road","top_k":5}'
```

The prompt template explicitly delimits retrieved context and asks the model to cite section ids.

---
Notes: this README focuses on development and demonstration. For production, add secure API keys, HTTPS, CORS restrictions, authentication, logging, and legal disclaimers.
