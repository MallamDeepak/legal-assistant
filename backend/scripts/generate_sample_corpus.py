"""Generate synthetic legal corpus for testing when PDFs are unavailable."""
import csv
from pathlib import Path

SAMPLE_SECTIONS = [
    {
        'section_id': 'IPC_379',
        'title': 'IPC Section 379 - Theft',
        'text': 'Whoever intending to take dishonestly any moveable property out of the possession of any person without that person\'s consent, moves that property in order to such taking, is said to commit theft. Punishment: Imprisonment up to three years, or fine, or both.',
        'language': 'en'
    },
    {
        'section_id': 'IPC_302',
        'title': 'IPC Section 302 - Murder',
        'text': 'Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine. Murder is the act of intentionally causing death with premeditation.',
        'language': 'en'
    },
    {
        'section_id': 'IPC_420',
        'title': 'IPC Section 420 - Cheating',
        'text': 'Whoever cheats and thereby dishonestly induces the person deceived to deliver any property to any person, or to make, alter or destroy the whole or any part of a valuable security, shall be punished with imprisonment of either description for a term which may extend to seven years, and shall also be liable to fine.',
        'language': 'en'
    },
    {
        'section_id': 'IPC_323',
        'title': 'IPC Section 323 - Voluntarily Causing Hurt',
        'text': 'Whoever, except in the case provided for by section 334, voluntarily causes hurt, shall be punished with imprisonment of either description for a term which may extend to one year, or with fine which may extend to one thousand rupees, or with both.',
        'language': 'en'
    },
    {
        'section_id': 'IPC_406',
        'title': 'IPC Section 406 - Criminal Breach of Trust',
        'text': 'Whoever commits criminal breach of trust shall be punished with imprisonment of either description for a term which may extend to three years, or with fine, or with both.',
        'language': 'en'
    },
]

def main():
    output = Path('data/legal_corpus.csv')
    output.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['section_id', 'title', 'text', 'source', 'language'])
        writer.writeheader()
        for sec in SAMPLE_SECTIONS:
            writer.writerow({**sec, 'source': 'synthetic'})
    
    print(f"✓ Generated {len(SAMPLE_SECTIONS)} sections at {output}")

if __name__ == '__main__':
    main()