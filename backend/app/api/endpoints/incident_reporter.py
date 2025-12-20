from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from app.services.legal_matcher_service import LegalMatcherService
from app.services.report_generator_service import ReportGeneratorService
from app.services.vector_search_service import VectorSearchService
from app.services.language_detector_service import LanguageDetectorService

router = APIRouter(prefix="/incident", tags=["incident"])


class IncidentRequest(BaseModel):
    language: str = "en"
    text: str


matcher = LegalMatcherService()
reporter = ReportGeneratorService()


@router.post("/analyze")
async def analyze_incident(req: IncidentRequest):
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Text required")
    
    # 1. Query Expansion (Synonyms/Keywords)
    # 1. Query Expansion (Synonyms/Keywords)
    from app.services.ollama_service import OllamaService
    from app.services.groq_service import GroqService
    from app.services.gemini_service import GeminiService
    
    expanded_keywords = []
    
    # Try Groq (Fastest)
    if GroqService.is_available():
        prompt = f"""Identify 5 key legal terms, IPC sections, or Information Technology (IT) Act sections relevant to this incident. 
        If it involves online fraud, OTP, or computers, YOU MUST INCLUDE 'IT Act Section 66C', 'Identity Theft', 'Personation'.
        Return ONLY a comma-separated list.
        Incident: "{req.text}"
        Keywords:"""
        resp = GroqService.generate_text(prompt, system_prompt="You are a legal expert.")
        if resp:
            expanded_keywords = [w.strip() for w in resp.split(',') if w.strip()]

    # Try Gemini (Backup)
    if not expanded_keywords and GeminiService.is_available():
        prompt = f"""Identify 3-5 key legal terms or IPC offenses relevant to this incident. Return ONLY a comma-separated list.
        Incident: "{req.text}"
        Keywords:"""
        resp = GeminiService.generate_text(prompt, system_prompt="You are a legal expert.")
        if resp:
            expanded_keywords = [w.strip() for w in resp.split(',') if w.strip()]
            
    # Fallback to Ollama if all Cloud AI failed
    if not expanded_keywords and OllamaService.is_available():
         expanded_keywords = OllamaService.expand_legal_query(req.text)
    
    # 2. Vector Search (Original Text)
    retrieved = VectorSearchService.search(req.text, top_k=3) or []
    
    # 3. Keyword/Heuristic Matcher (Original + Expanded)
    # Search for original text
    keyword_matches = matcher.match_sections(req.text) or []
    
    # Search for expanded keywords
    for kw in expanded_keywords:
        keyword_matches.extend(matcher.match_sections(kw, top_k=2))
    
    # Helper to add unique sections or update if text is missing
    section_map = {}

    def add_section(sid, title, text=''):
        if not sid: return
        
        if sid in section_map:
            # Update text if current is empty and new is not
            if not section_map[sid]['text'] and text:
                section_map[sid]['text'] = text
                if title != 'Relevant Section': # simple heuristic to keep better titles
                     section_map[sid]['title'] = title
        else:
            section_map[sid] = {
                'section_id': sid, 
                'title': title,
                'text': text 
            }

    # Add Keyword matches first (high confidence)
    for m in keyword_matches:
        add_section(m.get('section_id'), m.get('title'), m.get('text', ''))

    # Add Vector matches
    for p in retrieved:
        add_section(p.get('section_id'), p.get('title', 'Relevant Section'), p.get('text', ''))

    sections = sorted(section_map.values(), key=lambda x: x['section_id'])

    # Auto-detect language
    detected = LanguageDetectorService.detect_language(req.text)
    final_lang = detected if detected != 'en' else req.language
    
    fir_text = reporter.generate_fir(req.text, sections, language=final_lang)
    
    # Return list of section IDs for frontend compatibility, but purely for display list
    suggested_ids = [s['section_id'] for s in sections]
    return {"suggested_sections": suggested_ids, "fir_text": fir_text}
