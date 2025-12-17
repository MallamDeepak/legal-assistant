# Phase 1 — Collect & Prepare Corpus

Goal: build a structured, multilingual legal corpus (statutes, case law, contracts, FIR examples, police forms) ready for embeddings, training, and RAG pipelines. This document captures sources, formats, normalization, and splitting strategy plus next steps for automation.

---

## 1) Primary Sources (initial backlog)

| Category | Source | Format | Notes |
| --- | --- | --- | --- |
| Statutes | India Code (https://www.indiacode.nic.in/) | HTML/PDF | IPC, CrPC, other penal laws; check terms for permissible reuse; include version/date |
| Case law | Supreme Court / High Court websites; SCC or AI-based scrapers; IndianKanoon exports | HTML/PDF/TXT | Use publicly available judgments or summaries; attribute source |
| Official Gazettes | egazette (https://egazette.nic.in/) | PDF | Use for amendments and notifications |
| Contracts | Public company filings, sample templates (e.g., MCA filings, SEC, template repos) | PDF/DOC/TXT | Focus on standard clauses (employment, service, rental) |
| FIR Samples | Synthetic FIRs from this repo; anonymized forms; training data from law enforcement if permitted | TXT/PDF/IMG | Apply strict redaction; document licensing/permissions |
| Police forms | Official forms from state police portals | PDF/IMG | Use OCR for scanned images |
| Multilingual resources | Government translations, AI4Bharat datasets, local-language law materials | PDF/TXT | Record language metadata |

Secondary / future:
- NGO/legal-aid published guides (with permission)
- Law textbooks and treatises (if copyright allows)
- News articles (to create incident -> sections mapping) — use caution re: licensing.

---

## 2) File Acquisition & Conversion Pipeline

1. **Download / scrape** (respect robots.txt & terms): use `requests`, `beautifulsoup4`, or headless browsers for paginated statutes.
2. **Store raw files** under `data/raw/<source>/<document_id>.<ext>` — maintain metadata (source URL, download date, license).
3. **Convert to text**:
   - PDF: `pdfplumber`, `pypdf`, `pdfminer.six`.
   - Scanned/IMG: `pytesseract` with deskew/resizing.
   - HTML: `BeautifulSoup` to strip tags & keep headings.
   - DOC/DOCX: `python-docx` / `textract`.
4. **Normalize text**:
   - Unicode NFC normalization (Python `unicodedata.normalize`).
   - Remove boilerplate (headers, footers, repeated disclaimers) via regex heuristics per source.
   - Convert multiple newlines to single blank line, ensure consistent `\n` endings.
   - Add `language` using `langdetect` or fastText langid (store code like `en`, `hi`).

---

## 3) Passage Splitting & Metadata

Split each normalized document into 200–500 token chunks (or ~800–1500 characters) to fit embedding context windows.

Pseudo steps:
```python
from nltk.tokenize import sent_tokenize

def chunk_text(text, target_tokens=350, min_tokens=150):
    sentences = sent_tokenize(text)
    current, chunks = [], []
    token_count = 0
    for sent in sentences:
        tokens = sent.split()
        if token_count + len(tokens) > target_tokens and token_count >= min_tokens:
            chunks.append(' '.join(current))
            current, token_count = [], 0
        current.append(sent)
        token_count += len(tokens)
    if current:
        chunks.append(' '.join(current))
    return chunks
```

Metadata to capture per chunk:
- `id` — unique string (`<source>_<section>_<chunk>`)
- `doc_id` — original document identifier
- `title` — section heading / case title / clause name
- `source` — e.g., `india_code`, `indiankanoon`, `synthetic_fir`
- `language` — ISO code
- `section_id` — for statutes (e.g., `IPC 379`), optional for other docs
- `chunk_index`, `chunk_count`
- `created_at`, `version` (if doc updates tracked)

Store normalized chunks in `data/processed/legal_corpus.jsonl` (UTF-8) — one JSON per line.

### Canonical JSONL record example

```json
{
  "id": "ipc_379_001",
  "doc_id": "ipc_379",
  "section_id": "IPC 379",
  "title": "IPC 379 - Theft",
  "text": "Whoever commits theft shall be punished with imprisonment...",
  "source": "india_code",
  "language": "en",
  "chunk_index": 0,
  "chunk_count": 2,
  "tokens_est": 120,
  "download_url": "https://www.indiacode.nic.in/show-data?actid=...",
  "license": "Government of India (public domain)",
  "created_at": "2025-12-12T12:00:00Z"
}
```

---

## 4) Normalization Checklist

- [ ] Deduplicate identical sections (same section from multiple sources) — keep canonical text.
- [ ] Remove hyphenation artifacts from PDFs.
- [ ] Standardize bullet lists and numbering (replace `•` etc. with `-`).
- [ ] Add paragraph markers if important (for referencing in responses).
- [ ] Map known section numbers to canonical forms (e.g., `Sec. 379 IPC` -> `IPC 379`).
- [ ] Run `langdetect` and, if non-English, store translation plan (use translator service later).

---

## 5) Tooling & Scripts (to implement next)

1. `scripts/download_india_code.py` — fetch IPC/CrPC sections via IndiaCode API or scraped HTML, save raw HTML/PDF.
2. `scripts/convert_to_text.py` — iterate raw files, convert to plain text, store in `data/normalized` with metadata JSON.
3. `scripts/split_corpus.py` — load normalized text, chunk, emit JSONL as described above.
4. `scripts/qa_validate.py` — run heuristics to ensure each chunk has required metadata and acceptable length.
5. `scripts/langid_report.py` — produce stats of languages detected to plan translation coverage.

I can implement any of these scripts next; recommended to start with `convert_to_text.py` + `split_corpus.py` since we already have `data/legal_corpus.csv`.

---

## 6) Data Governance

- Keep `data/raw/` under access control; do not commit to git.
- Commit only processed, non-sensitive data (e.g., open statutes) when licensing allows.
- Maintain `data/sources_manifest.json` listing each source, license, download date, status, and QA completion flag.

---

## 7) Next Immediate Tasks

1. Populate `data/sources_manifest.json` with entries for IPC, CrPC, synthetic FIRs.
2. Write `scripts/split_corpus.py` to read `data/legal_corpus.csv` and emit `data/legal_corpus.jsonl` using the canonical schema.
3. Add unit test (`tests/test_corpus_pipeline.py`) to validate JSONL schema (fields present, non-empty text, valid language codes).
4. Set up `Makefile`/`tasks.py` target to run: download -> normalize -> split -> embed.

Let me know which script or automation you'd like me to implement first.
