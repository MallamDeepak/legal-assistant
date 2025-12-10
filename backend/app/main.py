from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.api_router import api_router

app = FastAPI(title='Multilingual Legal Assistant API (complete skeleton)')

# Enable CORS for local development so the frontend (web/desktop/mobile) can call the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get('/')
def read_root():
    return {'status': 'ok', 'service': 'Multilingual Legal Assistant API (complete skeleton)'}
