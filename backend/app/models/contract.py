from pydantic import BaseModel
from typing import List

class Clause(BaseModel):
    clause: str
    status: str

class ContractResponse(BaseModel):
    text: str
    clauses: List[Clause]
