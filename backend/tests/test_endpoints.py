import io
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


def test_root():
    r = client.get('/')
    assert r.status_code == 200
    assert 'service' in r.json()


def test_incident_generate():
    r = client.post('/incident/generate', json={'language': 'en', 'text': 'someone stole my bike from the road'})
    assert r.status_code == 200
    j = r.json()
    assert 'suggested_sections' in j
    assert 'fir_text' in j


def test_fir_analyze_empty():
    # send a small fake file
    files = {'file': ('test.txt', b'Theft reported on 12/12/2020 at New Market. IPC 379.')}
    r = client.post('/fir/analyze', files=files)
    assert r.status_code == 200
    j = r.json()
    assert 'extracted_text' in j
    assert 'detected_sections' in j


def test_contract_review():
    files = {'file': ('contract.txt', b'This contract says no refund and unilateral termination.')}
    r = client.post('/contract/review', files=files)
    assert r.status_code == 200
    j = r.json()
    assert 'text' in j
    assert 'clauses' in j
