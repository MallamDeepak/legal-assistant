from pydantic import BaseModel
from typing import List

class FIRRequest(BaseModel):
    language: str
    facts: str

class FIRResponse(BaseModel):
    fir_text: str
    sections: List[str]
