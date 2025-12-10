from pydantic import BaseModel
from typing import List

class IncidentIn(BaseModel):
    language: str
    text: str

class IncidentOut(BaseModel):
    suggested_sections: List[str]
    fir_text: str
