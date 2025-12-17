r"""Query a FAISS index built by build_faiss_index.py.

Example:
  python .\scripts\query_faiss_index.py \
    --index .\data\faiss_index\legal.faiss \
    --meta  .\data\faiss_index\legal_meta.jsonl \
    --model sentence-transformers/all-mpnet-base-v2 \
    --query "someone stole my bike" \
    --top-k 5
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_meta(meta_path: Path) -> List[Dict[str, Any]]:
    meta: List[Dict[str, Any]] = []
    with open(meta_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            meta.append(json.loads(line))
    return meta


def main() -> int:
    parser = argparse.ArgumentParser(description="Query FAISS index")
    parser.add_argument(
        "--index",
        default=str(Path(__file__).resolve().parents[1] / "data" / "faiss_index" / "legal.faiss"),
        help="FAISS index file",
    )
    parser.add_argument(
        "--meta",
        default=str(Path(__file__).resolve().parents[1] / "data" / "faiss_index" / "legal_meta.jsonl"),
        help="Metadata JSONL file aligned with row ids",
    )
    parser.add_argument(
        "--model",
        default="sentence-transformers/all-mpnet-base-v2",
        help="SentenceTransformers model name (must match build step)",
    )
    parser.add_argument("--query", required=True, help="Query text")
    parser.add_argument("--top-k", type=int, default=5, help="Number of results")

    args = parser.parse_args()

    index_path = Path(args.index)
    meta_path = Path(args.meta)
    if not index_path.exists():
        raise SystemExit(f"Index not found: {index_path}")
    if not meta_path.exists():
        raise SystemExit(f"Meta not found: {meta_path}")

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

    meta = load_meta(meta_path)
    index = faiss.read_index(str(index_path))
    model = SentenceTransformer(args.model)

    q = model.encode([args.query], normalize_embeddings=True, show_progress_bar=False)
    q = np.asarray(q, dtype="float32")

    scores, ids = index.search(q, args.top_k)
    hits = ids[0].tolist()
    sims = scores[0].tolist()

    for rank, (row_id, score) in enumerate(zip(hits, sims), start=1):
        if row_id < 0 or row_id >= len(meta):
            print(f"#{rank} score={score:.4f} row_id={row_id} (out of range)")
            continue
        m = meta[row_id]
        print(
            f"#{rank} score={score:.4f} id={m.get('id')} title={m.get('title')} source={m.get('source')}"
        )
        # print a short preview to help during debugging
        t = (m.get("text") or "").strip().replace("\n", " ")
        if t:
            print("  ", (t[:240] + "…") if len(t) > 240 else t)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
