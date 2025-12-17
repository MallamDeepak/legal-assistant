from sqlalchemy import Column, Integer, String, Text, LargeBinary
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Document(Base):
    __tablename__ = "documents"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    source = Column(String(50))
    section = Column(String(100))
    content = Column(Text, nullable=False)
    pdf_data = Column(LargeBinary)