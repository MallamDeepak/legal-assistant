from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from app.services import ocr_service, legal_matcher_service, ner_service
from app.services.language_detector_service import LanguageDetectorService

router = APIRouter(prefix="/fir")


class FIRAnalysisResponse(BaseModel):
    extracted_text: str
    detected_sections: List[str]
    entities: Dict[str, Any] = {}
    summary: str = ""


@router.post('/analyze', response_model=FIRAnalysisResponse)
async def analyze_fir(language: str = "en", file: UploadFile = File(...)):
    """Perform OCR -> NER -> section matching and return structured JSON.
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail='Empty file uploaded')

    text = ocr_service.extract_text_from_image(content)
    sections = legal_matcher_service.find_relevant_sections(text, top_k=5)
    entities = ner_service.extract_entities(text)

    # Add LLM Summary in target language
    from app.services.gemini_service import GeminiService
    from app.services.groq_service import GroqService
    
    # Auto-detect language from extracted text if explicit language is English
    detected = LanguageDetectorService.detect_language(text)
    final_lang = detected if detected != 'en' else language
    
    lang_map = {'en': 'English', 'hi': 'Hindi', 'bn': 'Bengali', 'te': 'Telugu', 'mr': 'Marathi'}
    target_lang = lang_map.get(final_lang, 'English')
    
    summary = ""
    prompt = f"""Summarize these FIR details in {target_lang}. 
    Focus on the main crime, victims, suspects, and relevant legal sections found.
    KEEP IT SHORT (3-4 sentences).
    
    EXTRACTED TEXT: {text[:2000]}
    SECTIONS: {", ".join(sections)}
    ENTITIES: {entities}
    """
    
    if GroqService.is_available():
        summary = GroqService.generate_text(prompt, system_prompt=f"You are a helpful legal assistant named Legal Assistant. Respond in {target_lang}.")
    elif GeminiService.is_available():
        summary = GeminiService.generate_text(prompt, system_prompt=f"You are a helpful legal assistant named Legal Assistant. Respond in {target_lang}.")

    return FIRAnalysisResponse(
        extracted_text=text, 
        detected_sections=sections, 
        entities=entities,
        summary=summary or "Summary not available."
    )
