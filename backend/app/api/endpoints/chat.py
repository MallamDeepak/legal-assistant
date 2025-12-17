from fastapi import APIRouter
from pydantic import BaseModel
from app.services.rag_service import generate_answer

router = APIRouter(prefix="/chat")

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    reply: str

@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):
    return ChatResponse(reply=generate_answer(request.message))