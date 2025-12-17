from __future__ import annotations

from dataclasses import dataclass
from typing import List

from app.services import llm_service
from app.services.vector_retriever_service import RetrievalHit


@dataclass(frozen=True)
class SuggestedSection:
    section_id: str
    title: str
    confidence: float


def _clamp01(x: float) -> float:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def build_prompt(user_facts_en: str, hits: List[RetrievalHit]) -> tuple[str, str]:
    system = (
        "You are a legal assistant drafting a First Information Report (FIR) draft. "
        "Use ONLY the provided context passages and the user facts. "
        "If the context is insufficient for a claim, say you are not sure. "
        "Always cite section ids in square brackets like [it_act_2000_updated:p16:c2]. "
        "Output must be in English. Keep it concise and structured. "
        "This is a draft for review, not legal advice."
    )

    ctx_parts: List[str] = []
    for i, h in enumerate(hits, start=1):
        # Delimit context clearly.
        ctx_parts.append(
            "\n".join(
                [
                    f"<<<PASSAGE {i} id={h.section_id} title={h.title} source={h.source} score={h.score:.4f}>>>",
                    h.text.strip(),
                    "<<<END PASSAGE>>>",
                ]
            )
        )
    context_block = "\n\n".join(ctx_parts) if ctx_parts else "(no retrieved context)"

    user = (
        "User facts (English):\n"
        f"{user_facts_en.strip()}\n\n"
        "Retrieved context passages:\n"
        f"{context_block}\n\n"
        "Task:\n"
        "1) Produce an FIR draft narrative.\n"
        "2) List suggested legal sections with confidence scores (0.0 to 1.0) based on retrieval relevance.\n"
        "3) Ensure every legal claim or section mention has citations using the provided section ids.\n"
        "Return in this format:\n"
        "FIR_DRAFT:\n...\n\n"
        "SUGGESTED_SECTIONS:\n- <section_id> | <confidence> | <short reason with citations>\n"
    )
    return system, user


def generate_fir_draft(user_facts_en: str, hits: List[RetrievalHit]) -> str:
    system, user = build_prompt(user_facts_en, hits)
    out = llm_service.chat_completion(system, user)
    return sanitize_output(out)


def sanitize_output(text: str, max_chars: int = 7000) -> str:
    text = (text or "").strip()
    if len(text) > max_chars:
        text = text[:max_chars].rstrip() + "\n\n[truncated]"
    return text


def suggested_sections_from_hits(hits: List[RetrievalHit], max_sections: int = 5) -> List[SuggestedSection]:
    # Use retrieval hits directly as section suggestions for now.
    out: List[SuggestedSection] = []
    for h in hits[:max_sections]:
        out.append(
            SuggestedSection(
                section_id=h.section_id,
                title=h.title,
                confidence=_clamp01(float(h.score)),
            )
        )
    return out
