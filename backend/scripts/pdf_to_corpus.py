"""Convert one or more PDFs into a simple ML-friendly corpus.

Outputs:
- CSV with at least: section_id,title,text (compatible with preload_vector_db.py)
- Optional JSONL with metadata for training / RAG ingestion

This script focuses on extracting embedded text from PDFs.
If a PDF is scanned (no extractable text), you will likely need OCR.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import unicodedata
from collections import Counter
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List, Optional, Sequence, Tuple


try:
    from pypdf import PdfReader
except Exception as e:  # pragma: no cover
    PdfReader = None  # type: ignore
    _PYPDF_IMPORT_ERROR = e


try:
    from langdetect import detect as _detect_lang
except Exception:  # pragma: no cover
    _detect_lang = None


_WS_RE = re.compile(r"[ \t]+")
_NL_RE = re.compile(r"\n{3,}")
_MULTI_SPACE_RE = re.compile(r" {2,}")
_ONLY_PUNCT_RE = re.compile(r"^[\W_]+$")
_PAGE_NUM_RE = re.compile(r"^\s*\d+\s*$")


@dataclass(frozen=True)
class CorpusRow:
    section_id: str
    title: str
    text: str
    source_file: str
    page_start: int
    page_end: int
    chunk_index: int
    extracted_at_utc: str


@dataclass(frozen=True)
class CanonicalRecord:
    id: str
    text: str
    title: str
    source: str
    language: str
    doc_id: str
    section_id: str


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def normalize_text(text: str) -> str:
    if not text:
        return ""
    text = unicodedata.normalize("NFKC", text)
    text = text.replace("\x00", " ")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = _WS_RE.sub(" ", text)
    text = _NL_RE.sub("\n\n", text)
    text = _MULTI_SPACE_RE.sub(" ", text)
    return text.strip()


def _clean_lines(text: str) -> List[str]:
    lines = [ln.strip() for ln in text.split("\n")]
    cleaned: List[str] = []
    for ln in lines:
        if not ln:
            continue
        if _PAGE_NUM_RE.match(ln):
            continue
        if _ONLY_PUNCT_RE.match(ln):
            continue
        if ln.lower() in {"contents", "table of contents"}:
            cleaned.append(ln)
            continue
        cleaned.append(ln)
    return cleaned


def remove_repeated_headers_footers(page_texts: List[str]) -> List[str]:
    """Heuristic boilerplate removal for PDFs with repeated page headers/footers."""
    if not page_texts:
        return page_texts

    per_page_lines: List[List[str]] = [_clean_lines(normalize_text(t)) for t in page_texts]
    # collect likely headers/footers: first 2 and last 2 lines
    header_candidates: List[str] = []
    footer_candidates: List[str] = []
    for lines in per_page_lines:
        if not lines:
            continue
        header_candidates.extend(lines[:2])
        footer_candidates.extend(lines[-2:])

    page_count = max(1, len(per_page_lines))
    header_freq = Counter(header_candidates)
    footer_freq = Counter(footer_candidates)
    # remove lines that appear on >=30% of pages
    min_hits = max(2, int(page_count * 0.30))
    common_headers = {k for k, v in header_freq.items() if v >= min_hits}
    common_footers = {k for k, v in footer_freq.items() if v >= min_hits}

    cleaned_pages: List[str] = []
    for lines in per_page_lines:
        if not lines:
            cleaned_pages.append("")
            continue
        kept: List[str] = []
        for i, ln in enumerate(lines):
            if i < 2 and ln in common_headers:
                continue
            if i >= max(0, len(lines) - 2) and ln in common_footers:
                continue
            kept.append(ln)
        cleaned_pages.append("\n".join(kept).strip())
    return cleaned_pages


def detect_language_for_document(sample_text: str) -> str:
    sample_text = normalize_text(sample_text)
    if not sample_text:
        return "unknown"
    if _detect_lang is None:
        return "unknown"
    try:
        return _detect_lang(sample_text)
    except Exception:
        return "unknown"


def chunk_text_tokens(text: str, chunk_tokens: int, overlap_tokens: int) -> Iterable[str]:
    """Token chunking using a simple whitespace tokenization (portable, no extra deps)."""
    text = text.strip()
    if not text:
        return
    if chunk_tokens <= 0:
        yield text
        return

    tokens = text.split()
    if not tokens:
        return
    overlap_tokens = max(0, min(overlap_tokens, max(0, chunk_tokens - 1)))

    start = 0
    n = len(tokens)
    while start < n:
        end = min(n, start + chunk_tokens)
        chunk = " ".join(tokens[start:end]).strip()
        if chunk:
            yield chunk
        if end >= n:
            break
        start = max(0, end - overlap_tokens)


def extract_pdf_pages(pdf_path: Path) -> List[str]:
    if PdfReader is None:  # pragma: no cover
        raise RuntimeError(
            "pypdf is not installed. Install it with: pip install pypdf\n"
            f"Original import error: {_PYPDF_IMPORT_ERROR}"
        )

    reader = PdfReader(str(pdf_path))
    pages: List[str] = []
    for page in reader.pages:
        try:
            pages.append(page.extract_text() or "")
        except Exception:
            pages.append("")
    return pages


def iter_pdf_paths(pdf_args: Sequence[str], input_dir: Optional[str]) -> List[Path]:
    paths: List[Path] = []
    for p in pdf_args:
        paths.append(Path(p))

    if input_dir:
        d = Path(input_dir)
        if d.exists() and d.is_dir():
            for p in sorted(d.glob("*.pdf")):
                paths.append(p)

    # de-dupe while preserving order
    seen = set()
    out: List[Path] = []
    for p in paths:
        rp = str(p.resolve()) if p.exists() else str(p)
        if rp in seen:
            continue
        seen.add(rp)
        out.append(p)
    return out


def build_rows_for_pdf(
    pdf_path: Path,
    *,
    title: Optional[str],
    chunk_tokens: int,
    overlap_tokens: int,
    min_chars: int,
) -> List[CorpusRow]:
    pages_raw = extract_pdf_pages(pdf_path)
    pages = remove_repeated_headers_footers(pages_raw)
    extracted_at = _utc_now_iso()
    doc_title = title or pdf_path.stem
    # language detection per document (sample first ~20k chars from joined pages)
    sample = "\n".join([p for p in pages if p][:20])
    doc_language = detect_language_for_document(sample[:20000])

    rows: List[CorpusRow] = []
    for page_idx, page_text in enumerate(pages, start=1):
        page_text = normalize_text(page_text)
        if len(page_text) < min_chars:
            continue
        for chunk_idx, chunk in enumerate(chunk_text_tokens(page_text, chunk_tokens, overlap_tokens), start=1):
            if len(chunk) < min_chars:
                continue
            section_id = f"{pdf_path.stem}:p{page_idx}:c{chunk_idx}"
            rows.append(
                CorpusRow(
                    section_id=section_id,
                    title=doc_title,
                    text=chunk,
                    source_file=str(pdf_path),
                    page_start=page_idx,
                    page_end=page_idx,
                    chunk_index=chunk_idx,
                    extracted_at_utc=extracted_at,
                )
            )
    return rows


def to_canonical_records(rows: List[CorpusRow], *, source: str, language: str) -> List[CanonicalRecord]:
    records: List[CanonicalRecord] = []
    for r in rows:
        doc_id = Path(r.source_file).stem or r.title
        records.append(
            CanonicalRecord(
                id=r.section_id,
                text=r.text,
                title=r.title,
                source=source,
                language=language,
                doc_id=doc_id,
                section_id=r.section_id,
            )
        )
    return records


def write_csv(rows: List[CorpusRow], out_csv: Path, append: bool) -> None:
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(asdict(rows[0]).keys()) if rows else [
        "section_id",
        "title",
        "text",
        "source_file",
        "page_start",
        "page_end",
        "chunk_index",
        "extracted_at_utc",
    ]

    write_header = True
    mode = "w"
    if append and out_csv.exists():
        mode = "a"
        write_header = False

    with open(out_csv, mode, newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        if write_header:
            w.writeheader()
        for r in rows:
            w.writerow(asdict(r))


def write_jsonl(rows: List[CorpusRow], out_jsonl: Path, append: bool) -> None:
    out_jsonl.parent.mkdir(parents=True, exist_ok=True)
    mode = "a" if (append and out_jsonl.exists()) else "w"
    with open(out_jsonl, mode, encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(asdict(r), ensure_ascii=False) + "\n")


def write_canonical_jsonl(records: List[CanonicalRecord], out_jsonl: Path, append: bool) -> None:
    out_jsonl.parent.mkdir(parents=True, exist_ok=True)
    mode = "a" if (append and out_jsonl.exists()) else "w"
    with open(out_jsonl, mode, encoding="utf-8") as f:
        for rec in records:
            f.write(json.dumps(asdict(rec), ensure_ascii=False) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert PDFs into ML-friendly corpus CSV/JSONL")
    parser.add_argument("--pdf", action="append", default=[], help="Path to a PDF (can be repeated)")
    parser.add_argument("--input-dir", default=None, help="Directory containing PDFs (*.pdf)")
    parser.add_argument(
        "--out-csv",
        default=str(Path(__file__).resolve().parents[1] / "data" / "legal_corpus.csv"),
        help="Output CSV path (default: backend/data/legal_corpus.csv)",
    )
    parser.add_argument(
        "--out-jsonl",
        default=str(Path(__file__).resolve().parents[1] / "data" / "legal_corpus.jsonl"),
        help="Output JSONL path (default: backend/data/legal_corpus.jsonl)",
    )
    parser.add_argument(
        "--out-canonical-jsonl",
        default=str(Path(__file__).resolve().parents[1] / "data" / "legal_corpus_canonical.jsonl"),
        help="Output canonical JSONL path (default: backend/data/legal_corpus_canonical.jsonl)",
    )
    parser.add_argument("--no-jsonl", action="store_true", help="Do not write JSONL output")
    parser.add_argument("--no-canonical-jsonl", action="store_true", help="Do not write canonical JSONL output")
    parser.add_argument("--append", action="store_true", help="Append to outputs instead of overwriting")
    parser.add_argument("--title", default=None, help="Override title for all rows (default: PDF filename)")
    parser.add_argument("--chunk-tokens", type=int, default=300, help="Chunk size in tokens (200-500 recommended)")
    parser.add_argument("--overlap-tokens", type=int, default=50, help="Chunk overlap in tokens")
    parser.add_argument("--min-chars", type=int, default=50, help="Skip chunks/pages shorter than this")

    args = parser.parse_args()

    pdf_paths = iter_pdf_paths(args.pdf, args.input_dir)
    if not pdf_paths:
        parser.error("Provide at least one --pdf or an --input-dir")

    out_csv = Path(args.out_csv)
    out_jsonl = Path(args.out_jsonl)
    out_canonical_jsonl = Path(args.out_canonical_jsonl)

    total_rows = 0
    for pdf_path in pdf_paths:
        if not pdf_path.exists():
            print(f"[skip] not found: {pdf_path}")
            continue
        if pdf_path.suffix.lower() != ".pdf":
            print(f"[skip] not a PDF: {pdf_path}")
            continue

        print(f"[read] {pdf_path}")
        rows = build_rows_for_pdf(
            pdf_path,
            title=args.title,
            chunk_tokens=args.chunk_tokens,
            overlap_tokens=args.overlap_tokens,
            min_chars=args.min_chars,
        )
        if not rows:
            print(f"[warn] no extractable text rows (maybe scanned/OCR needed): {pdf_path}")
            continue

        # language detection (document-level)
        # re-sample from produced rows to avoid re-reading PDFs
        sample_text = "\n".join([r.text for r in rows[:10]])
        language = detect_language_for_document(sample_text)

        source_label = str(pdf_path)

        write_csv(rows, out_csv, append=args.append)
        if not args.no_jsonl:
            write_jsonl(rows, out_jsonl, append=args.append)

        if not args.no_canonical_jsonl:
            canonical = to_canonical_records(rows, source=source_label, language=language)
            write_canonical_jsonl(canonical, out_canonical_jsonl, append=args.append)
        total_rows += len(rows)
        # after first PDF, subsequent ones must append to avoid overwriting in a multi-PDF run
        args.append = True

    msg = f"Done. Wrote {total_rows} rows to {out_csv}"
    if not args.no_jsonl:
        msg += f" and {out_jsonl}"
    if not args.no_canonical_jsonl:
        msg += f" and {out_canonical_jsonl}"
    print(msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
