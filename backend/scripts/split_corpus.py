"""Convert structured CSV/legal text files into the canonical JSONL corpus.

Reads `data/legal_corpus.csv` by default and emits `data/legal_corpus.jsonl`
with records matching the schema documented in `docs/PHASE1_CORPUS_PLAN.md`.

Usage (from backend/):

    python -m scripts.split_corpus \
        --input data/legal_corpus.csv \
        --output data/legal_corpus.jsonl

You can change chunk/token parameters with `--target-tokens` and
`--min-tokens`.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_INPUT = BASE_DIR / "data" / "legal_corpus.csv"
DEFAULT_OUTPUT = BASE_DIR / "data" / "legal_corpus.jsonl"


def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return value.strip("_") or "chunk"


def chunk_text(text: str, target_tokens: int = 350, min_tokens: int = 150) -> List[str]:
    sentences = re.split(r"(?<=[.!?])\s+", text.strip())
    chunks: List[str] = []
    current: List[str] = []
    token_count = 0
    for sent in sentences:
        sent = sent.strip()
        if not sent:
            continue
        tokens = sent.split()
        if token_count + len(tokens) > target_tokens and token_count >= min_tokens:
            chunks.append(" ".join(current))
            current = []
            token_count = 0
        current.append(sent)
        token_count += len(tokens)
    if current:
        chunks.append(" ".join(current))
    # Guarantee at least one chunk if text exists.
    if not chunks and text.strip():
        chunks = [text.strip()]
    return chunks


def build_records(rows: Iterable[dict], source: str, target_tokens: int, min_tokens: int) -> List[dict]:
    records: List[dict] = []
    created_at = datetime.now(timezone.utc).isoformat()
    for row in rows:
        section_id = row.get("section_id", "").strip() or "unknown"
        title = row.get("title", section_id).strip()
        text = row.get("text", "").strip()
        doc_slug = slugify(section_id or title)
        chunks = chunk_text(text, target_tokens=target_tokens, min_tokens=min_tokens)
        chunk_count = len(chunks)
        for idx, chunk in enumerate(chunks):
            record_id = f"{doc_slug}_{idx:03d}"
            records.append(
                {
                    "id": record_id,
                    "doc_id": doc_slug,
                    "section_id": section_id,
                    "title": title,
                    "text": chunk,
                    "source": source,
                    "language": row.get("language", "en") or "en",
                    "chunk_index": idx,
                    "chunk_count": chunk_count,
                    "tokens_est": len(chunk.split()),
                    "download_url": row.get("download_url", ""),
                    "license": row.get("license", ""),
                    "created_at": created_at,
                }
            )
    return records


def load_csv(path: Path) -> List[dict]:
    with path.open(newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        return list(reader)


def write_jsonl(records: List[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        for record in records:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Split legal corpus into canonical JSONL chunks")
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT, help="Input CSV file path")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Output JSONL file path")
    parser.add_argument("--source", default="india_code", help="Source identifier stored in JSONL")
    parser.add_argument("--target-tokens", type=int, default=350, help="Target tokens per chunk")
    parser.add_argument("--min-tokens", type=int, default=150, help="Minimum tokens before starting new chunk")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    rows = load_csv(args.input)
    records = build_records(rows, source=args.source, target_tokens=args.target_tokens, min_tokens=args.min_tokens)
    write_jsonl(records, args.output)
    print(f"Wrote {len(records)} records to {args.output}")


if __name__ == "__main__":
    main()
