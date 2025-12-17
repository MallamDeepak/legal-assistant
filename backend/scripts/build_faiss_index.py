r"""Build a FAISS vector index from a canonical JSONL corpus.

Input (canonical JSONL): one JSON object per line, expected keys:
- id, text, title, source, language (required)
- doc_id, section_id (optional)

Outputs:
- .faiss index file
- metadata JSONL aligned by vector row-id (0..N-1)

Example:
  python .\scripts\build_faiss_index.py \
    --input .\data\legal_corpus_pdfs_canonical.jsonl \
    --out-index .\data\faiss_index\legal.faiss \
    --out-meta .\data\faiss_index\legal_meta.jsonl \
    --model sentence-transformers/all-mpnet-base-v2
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple


def _default_input_path() -> Path:
    base = Path(__file__).resolve().parents[1]
    pdfs = base / "data" / "legal_corpus_pdfs_canonical.jsonl"
    if pdfs.exists():
        return pdfs
    return base / "data" / "legal_corpus_canonical.jsonl"


def iter_jsonl(path: Path) -> Iterable[Dict[str, Any]]:
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            yield json.loads(line)


def batched(items: List[Any], batch_size: int) -> Iterable[List[Any]]:
    for i in range(0, len(items), batch_size):
        yield items[i : i + batch_size]


def require_keys(rec: Dict[str, Any], keys: Tuple[str, ...]) -> None:
    missing = [k for k in keys if not rec.get(k)]
    if missing:
        raise ValueError(f"Missing required keys {missing} in record: {rec}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Build FAISS index from canonical JSONL corpus")
    parser.add_argument(
        "--input",
        default=str(_default_input_path()),
        help="Canonical JSONL input path",
    )
    parser.add_argument(
        "--out-index",
        default=str(Path(__file__).resolve().parents[1] / "data" / "faiss_index" / "legal.faiss"),
        help="Output FAISS index path",
    )
    parser.add_argument(
        "--out-meta",
        default=str(Path(__file__).resolve().parents[1] / "data" / "faiss_index" / "legal_meta.jsonl"),
        help="Output metadata JSONL path (aligned with index row ids)",
    )
    parser.add_argument(
        "--model",
        default="sentence-transformers/all-mpnet-base-v2",
        help="SentenceTransformers model name (e.g. LaBSE or multilingual-e5-base)",
    )
    parser.add_argument("--batch-size", type=int, default=32, help="Embedding batch size")
    parser.add_argument(
        "--metric",
        choices=["cosine"],
        default="cosine",
        help="Similarity metric (currently cosine only)",
    )
    parser.add_argument(
        "--max-records",
        type=int,
        default=0,
        help="Optional cap for quick tests (0 = no cap)",
    )

    args = parser.parse_args()

    in_path = Path(args.input)
    if not in_path.exists():
        raise SystemExit(f"Input not found: {in_path}")

    try:
        from sentence_transformers import SentenceTransformer
    except Exception as e:
        raise SystemExit(
            "sentence-transformers is not installed. Install with: pip install sentence-transformers\n"
            f"Import error: {e}"
        )

    try:
        import numpy as np
    except Exception as e:
        raise SystemExit(
            "numpy is not installed. Install with: pip install numpy\n" f"Import error: {e}"
        )

    try:
        import faiss  # type: ignore
    except Exception as e:
        raise SystemExit(
            "faiss-cpu is not installed/available for this Python. Install with: pip install faiss-cpu\n"
            f"Import error: {e}"
        )

    print(f"[load] {in_path}")
    records: List[Dict[str, Any]] = []
    texts: List[str] = []

    for rec in iter_jsonl(in_path):
        require_keys(rec, ("id", "text", "title", "source", "language"))
        records.append(rec)
        texts.append(rec["text"])
        if args.max_records and len(records) >= args.max_records:
            break

    if not records:
        raise SystemExit("No records found in input JSONL")

    print(f"[model] {args.model}")
    model = SentenceTransformer(args.model)

    # cosine similarity in FAISS via inner product on L2-normalized vectors
    all_vecs: List[Any] = []
    for b in batched(texts, args.batch_size):
        vecs = model.encode(
            b,
            batch_size=len(b),
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        all_vecs.append(vecs)

    X = np.vstack(all_vecs).astype("float32")
    dim = X.shape[1]
    print(f"[embed] records={X.shape[0]} dim={dim}")

    index = faiss.IndexFlatIP(dim)
    index.add(X)

    out_index = Path(args.out_index)
    out_meta = Path(args.out_meta)
    out_index.parent.mkdir(parents=True, exist_ok=True)
    out_meta.parent.mkdir(parents=True, exist_ok=True)

    print(f"[write] index -> {out_index}")
    faiss.write_index(index, str(out_index))

    print(f"[write] meta  -> {out_meta}")
    with open(out_meta, "w", encoding="utf-8") as f:
        for row_id, rec in enumerate(records):
            meta = {
                "row_id": row_id,
                "id": rec.get("id"),
                "title": rec.get("title"),
                "source": rec.get("source"),
                "language": rec.get("language"),
                "doc_id": rec.get("doc_id"),
                "section_id": rec.get("section_id"),
                # keep text optional to reduce size; can be reloaded from corpus if needed
                "text": rec.get("text"),
            }
            f.write(json.dumps(meta, ensure_ascii=False) + "\n")

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
