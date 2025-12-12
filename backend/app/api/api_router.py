from fastapi import APIRouter
from app.api.endpoints import incident_reporter, fir_analyzer, contract_reviewer, signals, rag_fir

api_router = APIRouter()

api_router.include_router(incident_reporter.router, prefix='/incident', tags=['incident'])
api_router.include_router(fir_analyzer.router, prefix='/fir', tags=['fir'])
api_router.include_router(contract_reviewer.router, prefix='/contract', tags=['contract'])
api_router.include_router(signals.router, prefix='/signals', tags=['signals'])
api_router.include_router(rag_fir.router, prefix='/rag', tags=['rag'])
