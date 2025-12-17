from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from app.services.legal_matcher_service import LegalMatcherService
from app.services.report_generator_service import ReportGeneratorService
from app.services.vector_search_service import VectorSearchService

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
    
    # Try vector search first, fallback to keyword matcher
    # Try vector search first, fallback to keyword matcher
    # Try vector search first, fallback to keyword matcher
    retrieved = VectorSearchService.search(req.text, top_k=3) or []
    sections = []
    
    # retrieved items are dicts with section_id, title, etc.
    for p in retrieved:
        sec_id = p.get("section_id")
        if sec_id:
            # Check if already added
            if not any(s['section_id'] == sec_id for s in sections):
                sections.append({
                    'section_id': sec_id, 
                    'title': p.get('title', 'Relevant Section'),
                    'text': p.get('text', '')  # Pass full legal text
                })

    if not sections:
        # Fallback matcher now returns list of dicts {'section_id':..., 'title':...}
        sections = matcher.match_sections(req.text) or []
    
    fir_text = reporter.generate_fir(req.text, sections)
    
    # Return list of section IDs for frontend compatibility, but purely for display list
    suggested_ids = [s['section_id'] for s in sections]
    return {"suggested_sections": suggested_ids, "fir_text": fir_text}
