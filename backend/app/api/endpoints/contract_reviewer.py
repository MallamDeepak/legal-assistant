from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List
from app.services import ocr_service, compliance_service

router = APIRouter(prefix="/contract")


class ClauseAnalysis(BaseModel):
    clause: str
    status: str


class ContractAnalysisResponse(BaseModel):
    text: str
    clauses: List[ClauseAnalysis]


@router.post('/review', response_model=ContractAnalysisResponse)
async def review_contract(file: UploadFile = File(...)):
    """OCR -> clause detection -> compliance analysis (stub).

    Returns extracted text and a list of clause analyses.
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail='Empty file uploaded')

    text = ocr_service.extract_text_from_image(content)

    clauses_out = compliance_service.analyze_clauses(text)
    clauses = [ClauseAnalysis(**c) for c in clauses_out]

    return ContractAnalysisResponse(text=text, clauses=clauses)
