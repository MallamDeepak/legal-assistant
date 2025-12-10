"""Preload vector DB helper (lightweight): read `data/legal_corpus.csv` and write a small JSON index.

This helper builds a simple keyword index for development/demo usage. For production,
replace with embedding computation (sentence-transformers) and store vectors in FAISS/Chroma.
"""
import os
import json
import csv
import sys

BASE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DATA = os.path.join(BASE, 'data', 'legal_corpus.csv')
OUT = os.path.join(BASE, 'data', 'legal_corpus_index.json')


def build_index():
    if not os.path.exists(DATA):
        print('data/legal_corpus.csv not found — please create it')
        sys.exit(1)

    index = []
    with open(DATA, newline='', encoding='utf-8') as f:
        r = csv.DictReader(f)
        for row in r:
            index.append({'section_id': row.get('section_id'), 'title': row.get('title'), 'text': row.get('text')})

    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(index, f, indent=2, ensure_ascii=False)

    print(f'Wrote simple index to {OUT} — this is a development helper, not a vector DB')


def main():
    build_index()


if __name__ == '__main__':
    main()
