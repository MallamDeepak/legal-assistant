import os, sys, re, fitz
from pathlib import Path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# Update these paths to your actual PDF locations
PDF_FILES = {
    "IPC": r"C:\Users\malla\Downloads\ipc_act.pdf",
    "CrPC": r"C:\Users\malla\Downloads\the_code_of_criminal_procedure,_1973.pdf",
    "IEA": r"C:\Users\malla\Downloads\iea_1872.pdf",
    "IT_Act": r"C:\Users\malla\Downloads\it_act_2000_updated.pdf",
}

DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:deepak@localhost:5432/legal_assistant')
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)

def create_table():
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS documents CASCADE"))
        conn.execute(text("""
            CREATE TABLE documents (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                source VARCHAR(50),
                section VARCHAR(100),
                content TEXT NOT NULL,
                pdf_data BYTEA,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.commit()
    print("✓ Created documents table")

def extract_text(path):
    doc = fitz.open(path)
    return "".join(p.get_text() for p in doc)

def load_pdf(source, path):
    session = Session()
    try:
        print(f"\n📄 Processing {source} from {Path(path).name}...")
        txt = extract_text(path)
        
        # Split by section markers
        parts = re.split(r"(Section\s+\d+[A-Z]?\.?)", txt, flags=re.IGNORECASE)
        sec, content, sections = "Preamble", "", []
        
        for p in parts:
            if re.match(r"Section\s+\d+", p, flags=re.IGNORECASE): 
                if content.strip(): 
                    sections.append({"section": sec, "content": content.strip()})
                sec, content = p.strip(), ""
            else: 
                content += p
        
        if content.strip(): 
            sections.append({"section": sec, "content": content.strip()})
        
        # Insert into database
        for s in sections:
            # Truncate very long sections to 50k chars
            truncated_content = s["content"][:50000]
            session.execute(
                text("INSERT INTO documents (name, source, section, content) VALUES (:n, :src, :sec, :c)"),
                {
                    "n": f"{source}_{s['section']}", 
                    "src": source, 
                    "sec": s["section"], 
                    "c": truncated_content
                }
            )
        
        session.commit()
        print(f"✓ Loaded {len(sections)} sections from {source}")
        return len(sections)
        
    except Exception as e: 
        session.rollback()
        print(f"✗ Error loading {source}: {e}")
        return 0
    finally: 
        session.close()

def main():
    print("🔧 Setting up database...")
    create_table()
    
    total_sections = 0
    missing_files = []
    
    for src, path in PDF_FILES.items():
        if Path(path).exists():
            count = load_pdf(src, path)
            total_sections += count
        else:
            missing_files.append(f"  ❌ {src}: {path}")
    
    print(f"\n{'='*60}")
    print(f"✓ Database populated with {total_sections} sections")
    
    if missing_files:
        print(f"\n⚠ Missing PDF files:")
        for mf in missing_files:
            print(mf)
        print("\nUpdate PDF_FILES paths in scripts/load_pdfs.py with your actual file locations.")
    
    print(f"\n📊 Next steps:")
    print(f"  1. Export to corpus: python -m scripts.export_db_to_corpus")
    print(f"  2. Build embeddings: python -m scripts.embed_and_index")
    print(f"  3. Start backend: uvicorn app.main:app --reload")

if __name__ == "__main__":
    main()