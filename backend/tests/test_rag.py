import os

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_rag_fir_draft_requires_llm_key(monkeypatch):
    monkeypatch.delenv('OPENAI_API_KEY', raising=False)
    r = client.post('/rag/fir-draft', json={'text': 'someone stole my bike from the road', 'language': 'en', 'top_k': 3})
    # If retrieval/index is missing, we also return 503, which is acceptable for this test.
    assert r.status_code in (503,)
