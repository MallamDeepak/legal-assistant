from __future__ import annotations

import json
import os
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


_lock = threading.Lock()
_state: Optional[Tuple[object, List[Dict[str, Any]], object]] = None
# _state = (faiss_index, meta_list, sentence_transformer_model)


@dataclass(frozen=True)
class RetrievalHit:
    row_id: int
    score: float
    section_id: str
    title: str
    source: str
    language: str
    text: str


def _default_index_paths() -> Tuple[Path, Path]:
    base = Path(__file__).resolve().parents[2]  # backend/app
    index_path = base / ".." / "data" / "faiss_index" / "legal.faiss"
    meta_path = base / ".." / "data" / "faiss_index" / "legal_meta.jsonl"
    return index_path.resolve(), meta_path.resolve()


def _load_meta(meta_path: Path) -> List[Dict[str, Any]]:
    meta: List[Dict[str, Any]] = []
    with open(meta_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            meta.append(json.loads(line))
    return meta


def _get_configured_paths() -> Tuple[Path, Path]:
    # Allow overriding via env vars for deployments.
    idx = os.getenv("FAISS_INDEX_PATH", "").strip()
    meta = os.getenv("FAISS_META_PATH", "").strip()
    if idx and meta:
        return Path(idx), Path(meta)
    return _default_index_paths()


def _get_embedding_model_name() -> str:
    return os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-mpnet-base-v2")


def _ensure_loaded() -> Tuple[object, List[Dict[str, Any]], object]:
    global _state
    with _lock:
        if _state is not None:
            return _state

        index_path, meta_path = _get_configured_paths()
        if not index_path.exists() or not meta_path.exists():
            raise FileNotFoundError(
                "FAISS index not found. Build it first with scripts/build_faiss_index.py "
                f"(missing {index_path} or {meta_path})."
            )

        try:
            import faiss  # type: ignore
        except Exception as e:
            raise RuntimeError(f"faiss-cpu not available: {e}")

        try:
            from sentence_transformers import SentenceTransformer
        except Exception as e:
            raise RuntimeError(f"sentence-transformers not available: {e}")

        index = faiss.read_index(str(index_path))
        meta = _load_meta(meta_path)
        model = SentenceTransformer(_get_embedding_model_name())

        _state = (index, meta, model)
        return _state


def retrieve(query: str, top_k: int = 5) -> List[RetrievalHit]:
    if not query or not query.strip():
        return []

    index, meta, model = _ensure_loaded()

    import numpy as np

    q = model.encode([query], normalize_embeddings=True, show_progress_bar=False)
    q = np.asarray(q, dtype="float32")

    scores, ids = index.search(q, top_k)
    hits: List[RetrievalHit] = []

    for row_id, score in zip(ids[0].tolist(), scores[0].tolist()):
        if row_id < 0 or row_id >= len(meta):
            continue
        m = meta[row_id]
        hits.append(
            RetrievalHit(
                row_id=int(row_id),
                score=float(score),
                section_id=str(m.get("id") or m.get("section_id") or ""),
                title=str(m.get("title") or ""),
                source=str(m.get("source") or ""),
                language=str(m.get("language") or "unknown"),
                text=str(m.get("text") or ""),
            )
        )

    return hits
