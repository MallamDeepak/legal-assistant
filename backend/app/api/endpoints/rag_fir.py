from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List

from app.services import translator_service
from app.services import language_service, vector_retriever_service, rag_fir_service
from app.services.llm_service import LLMNotConfiguredError


router = APIRouter()


class RAGFIRRequest(BaseModel):
    text: str = Field(..., description="User facts / incident description")
    language: str = Field("", description="Optional language hint (e.g., 'en')")
    top_k: int = Field(5, ge=1, le=20)


class SuggestedSection(BaseModel):
    section_id: str
    title: str
    confidence: float


class RAGFIRResponse(BaseModel):
    detected_language: str
    query_english: str
    suggested_sections: List[SuggestedSection]
    fir_text: str


@router.post('/fir-draft', response_model=RAGFIRResponse)
def rag_fir_draft(req: RAGFIRRequest):
    if not req.text or not req.text.strip():
        raise HTTPException(status_code=400, detail='Empty text')

    detected = (req.language or '').strip().lower() or language_service.detect_language(req.text)
    query_en = req.text
    if detected and detected != 'en' and detected != 'unknown':
        query_en = translator_service.translate(req.text, target_lang='en')

    try:
        hits = vector_retriever_service.retrieve(query_en, top_k=req.top_k)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retriever error: {e}")

    suggested = rag_fir_service.suggested_sections_from_hits(hits)
    suggested_models = [SuggestedSection(**s.__dict__) for s in suggested]

    try:
        fir = rag_fir_service.generate_fir_draft(query_en, hits)
    except LLMNotConfiguredError as e:
        raise HTTPException(
            status_code=503,
            detail=f"LLM not configured: {e}. Set OPENAI_API_KEY (and optionally OPENAI_BASE_URL, OPENAI_MODEL).",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM error: {e}")

    return RAGFIRResponse(
        detected_language=detected or 'unknown',
        query_english=query_en,
        suggested_sections=suggested_models,
        fir_text=fir,
    )
