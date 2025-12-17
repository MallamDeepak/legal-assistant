"""Extract sample texts from database for annotation."""
import json
import random
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

def get_db_session():
    db_url = os.getenv('DATABASE_URL', 'postgresql://postgres:deepak@localhost:5432/legal_assistant')
    engine = create_engine(db_url)
    return sessionmaker(bind=engine)()

def extract_ner_samples(session, output_path: Path, count: int = 100):
    """Extract sentences for NER annotation."""
    result = session.execute(text("""
        SELECT content FROM documents 
        WHERE LENGTH(content) > 200 
        ORDER BY RANDOM() 
        LIMIT :count
    """), {"count": count})
    
    samples = []
    for row in result:
        # Split into sentences (simple split by period)
        sentences = [s.strip() for s in row.content.split('.') if len(s.strip()) > 50]
        for sent in sentences[:3]:  # Take first 3 sentences
            samples.append({"text": sent})
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        for sample in samples:
            f.write(json.dumps(sample) + '\n')
    
    print(f"✓ Prepared {len(samples)} samples for NER annotation at {output_path}")

def extract_clause_samples(session, output_path: Path, count: int = 200):
    """Extract clauses for classification annotation."""
    # Sample contract/agreement clauses
    common_patterns = [
        "party shall", "agrees to", "in the event", "notwithstanding",
        "subject to", "provided that", "terms and conditions", "liability"
    ]
    
    result = session.execute(text("""
        SELECT content FROM documents 
        WHERE source LIKE '%contract%' OR source LIKE '%agreement%'
        ORDER BY RANDOM() 
        LIMIT :count
    """), {"count": count})
    
    samples = []
    for row in result:
        # Split by sentence/clause
        clauses = [c.strip() for c in row.content.split('.') if len(c.strip()) > 40]
        for clause in clauses[:5]:
            # Check if contains legal language
            if any(p in clause.lower() for p in common_patterns):
                samples.append({"text": clause})
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        for sample in samples:
            f.write(json.dumps(sample) + '\n')
    
    print(f"✓ Prepared {len(samples)} samples for clause annotation at {output_path}")

def main():
    session = get_db_session()
    
    try:
        print("Extracting samples from database...")
        extract_ner_samples(session, Path('data/annotations/ner/samples.jsonl'), count=100)
        extract_clause_samples(session, Path('data/annotations/clauses/samples.jsonl'), count=200)
        
        print("\n📋 Next steps:")
        print("1. Start Label Studio: label-studio start")
        print("2. Create NER project with config from: data/annotations/ner_config.xml")
        print("3. Import: data/annotations/ner/samples.jsonl")
        print("4. Annotate entities (PER, LOC, ORG, DATE, SECTION)")
        print("5. Export as JSON and run: python -m scripts.convert_labelstudio_to_training")
        
    finally:
        session.close()

if __name__ == '__main__':
    main()