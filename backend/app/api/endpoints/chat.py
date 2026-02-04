from fastapi import APIRouter
from pydantic import BaseModel
from app.services.rag_service import generate_answer
from app.services.language_detector_service import LanguageDetectorService

router = APIRouter(prefix="/chat")

class ChatRequest(BaseModel):
    message: str
    language: str = "en"

class ChatResponse(BaseModel):
    reply: str

@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):
    # Detect language of user message
    detected = LanguageDetectorService.detect_language(request.message)
    
    # Use detected language if it's not English, otherwise fallback to request language
    final_lang = detected if detected != 'en' else request.language
    
    return ChatResponse(reply=generate_answer(request.message, language=final_lang))