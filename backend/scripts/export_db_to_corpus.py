"""Export legal sections from PostgreSQL database to corpus CSV for embeddings."""
import argparse
import csv
from pathlib import Path
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

def get_db_session():
    db_url = os.getenv('DATABASE_URL', 'postgresql://postgres:deepak@localhost:5432/legal_assistant')
    engine = create_engine(db_url)
    SessionLocal = sessionmaker(bind=engine)
    return SessionLocal()

def export_from_db(output_path: Path, min_length: int = 100):
    """Extract all documents from PostgreSQL and write to CSV."""
    session = get_db_session()
    
    try:
        # Query all documents from the database
        result = session.execute(text("""
            SELECT id, name, source, section, content
            FROM documents
            WHERE content IS NOT NULL 
            AND LENGTH(TRIM(content)) >= :min_len
            ORDER BY source, section
        """), {"min_len": min_length})
        
        rows = []
        for row in result:
            # Use section as section_id, or fallback to source_id
            section_id = row.section if row.section else f"{row.source}_{row.id}"
            title = f"{row.source} - {row.section}" if row.section else row.name
            
            rows.append({
                'section_id': section_id,
                'title': title,
                'text': row.content.strip(),
                'source': row.source or 'database',
                'language': 'en'
            })
        
        if not rows:
            print("⚠ No documents found in database.")
            print("Run: python -m scripts.load_pdfs to populate the database first.")
            return False
        
        # Write to CSV
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['section_id', 'title', 'text', 'source', 'language'])
            writer.writeheader()
            writer.writerows(rows)
        
        print(f"✓ Exported {len(rows)} sections from database to {output_path}")
        return True
        
    except Exception as e:
        print(f"✗ Database export failed: {e}")
        print("\nTroubleshooting:")
        print("1. Ensure PostgreSQL is running")
        print("2. Verify DATABASE_URL in .env")
        print("3. Run: python -m scripts.load_pdfs to populate data")
        return False
    finally:
        session.close()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--output', default='data/legal_corpus.csv', help='Output CSV path')
    ap.add_argument('--min-length', type=int, default=100, help='Minimum content length')
    args = ap.parse_args()
    
    output = Path(args.output)
    success = export_from_db(output, args.min_length)
    
    if success:
        print(f"\n📊 Next steps:")
        print(f"  1. Build embeddings: python -m scripts.embed_and_index --input {output} --output data/legal_index")
        print(f"  2. Test retrieval: python -m scripts.retrieve")
        print(f"  3. Start backend: uvicorn app.main:app --reload")
    else:
        print("\n❌ Export failed. Database is empty or unreachable.")

if __name__ == '__main__':
    main()