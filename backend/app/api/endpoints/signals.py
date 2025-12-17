import json
import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter
from pydantic import BaseModel, Field


router = APIRouter()


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _signals_path() -> str:
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    return os.path.abspath(os.path.join(base, '..', 'data', 'user_section_signals.jsonl'))


class SectionSelectionSignal(BaseModel):
    query_text: str = Field(..., description="User query / case description shown to the matcher")
    suggested_sections: List[str] = Field(default_factory=list)
    selected_section_ids: List[str] = Field(default_factory=list)
    language: str = "en"
    source_endpoint: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SignalAck(BaseModel):
    ok: bool = True


@router.post('/section-selection', response_model=SignalAck)
def log_section_selection(sig: SectionSelectionSignal):
    """Log which sections users pick.

    This is intentionally simple (JSONL append) so it can be used during early UI rollout.
    """
    record = sig.model_dump()
    record["recorded_at_utc"] = _utc_now_iso()

    out_path = _signals_path()
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'a', encoding='utf-8') as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")

    return SignalAck(ok=True)
