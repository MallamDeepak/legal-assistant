from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from app.services import ocr_service, legal_matcher_service, ner_service

router = APIRouter()


class FIRAnalysisResponse(BaseModel):
    extracted_text: str
    detected_sections: List[str]
    entities: Dict[str, Any] = {}


@router.post('/analyze', response_model=FIRAnalysisResponse)
async def analyze_fir(file: UploadFile = File(...)):
    """Perform OCR -> NER -> section matching and return structured JSON.

    Uses the OCR stub if pytesseract is not available on the system.
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail='Empty file uploaded')

    # Extract text (image/pdf) using the OCR service (stubbed if dependencies missing)
    text = ocr_service.extract_text_from_image(content)

    # Find relevant legal sections (stubbed matcher)
    sections = legal_matcher_service.find_relevant_sections(text, top_k=5)

    # Extract simple entities (names, dates, locations) using NER stub
    entities = ner_service.extract_entities(text)

    return FIRAnalysisResponse(extracted_text=text, detected_sections=sections, entities=entities)
