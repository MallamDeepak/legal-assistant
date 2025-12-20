from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List
from app.services import ocr_service, compliance_service
from app.services.language_detector_service import LanguageDetectorService

router = APIRouter(prefix="/contract")


class ClauseAnalysis(BaseModel):
    clause: str
    status: str


class ContractAnalysisResponse(BaseModel):
    text: str
    clauses: List[ClauseAnalysis]
    summary: str = ""


@router.post('/review', response_model=ContractAnalysisResponse)
async def review_contract(language: str = "en", file: UploadFile = File(...)):
    """OCR -> clause detection -> compliance analysis (stub).
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail='Empty file uploaded')

    text = ocr_service.extract_text_from_image(content)

    clauses_out = compliance_service.analyze_clauses(text)
    clauses = [ClauseAnalysis(**c) for c in clauses_out]

    # Add LLM Summary in target language
    from app.services.gemini_service import GeminiService
    from app.services.groq_service import GroqService
    
    # Auto-detect language from extracted text
    detected = LanguageDetectorService.detect_language(text)
    final_lang = detected if detected != 'en' else language
    
    lang_map = {'en': 'English', 'hi': 'Hindi', 'bn': 'Bengali', 'te': 'Telugu', 'mr': 'Marathi'}
    target_lang = lang_map.get(final_lang, 'English')
    
    summary = ""
    prompt = f"""Summarize the legal risks and findings for this contract in {target_lang}. 
    Highlight high-risk clauses and provide a general assessment of the agreement.
    KEEP IT SHORT (3-4 sentences).
    
    EXTRACTED TEXT: {text[:2000]}
    CLAUSES FOUND: {[c['clause'][:100] for c in clauses_out[:5]]}
    """
    
    if GroqService.is_available():
        summary = GroqService.generate_text(prompt, system_prompt=f"You are a helpful legal assistant named Legal Assistant. Respond in {target_lang}.")
    elif GeminiService.is_available():
        summary = GeminiService.generate_text(prompt, system_prompt=f"You are a helpful legal assistant named Legal Assistant. Respond in {target_lang}.")

    return ContractAnalysisResponse(
        text=text, 
        clauses=clauses,
        summary=summary or "Analysis summary not available."
    )
