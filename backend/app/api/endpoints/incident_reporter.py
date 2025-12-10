from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from app.services import legal_matcher_service, translator_service

router = APIRouter()


class IncidentRequest(BaseModel):
    language: str
    text: str


class IncidentResponse(BaseModel):
    suggested_sections: List[str]
    fir_text: str


@router.post('/generate', response_model=IncidentResponse)
def generate_fir(req: IncidentRequest):
    """Generate FIR text and suggested sections.

    Currently uses translator stub and legal matcher stub.
    """
    src_text = req.text
    if req.language and req.language.lower() != 'en':
        src_text = translator_service.translate(req.text, target_lang='en')

    suggested_sections = legal_matcher_service.find_relevant_sections(src_text, top_k=5)
    fir_text = f"Generated FIR (placeholder) for: {req.text}"

    return IncidentResponse(suggested_sections=suggested_sections, fir_text=fir_text)
