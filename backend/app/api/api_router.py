from fastapi import APIRouter
from app.api.endpoints import incident_reporter, fir_analyzer, contract_reviewer, chat

api_router = APIRouter()
api_router.include_router(incident_reporter.router, tags=["incident"])
api_router.include_router(fir_analyzer.router, tags=["fir"])
api_router.include_router(contract_reviewer.router, tags=["contract"])
api_router.include_router(chat.router, tags=["chat"])
