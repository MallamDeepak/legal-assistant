from fastapi import HTTPException

def verify_api_key(key: str):
    # Placeholder: implement API key checks against env or DB
    if not key:
        raise HTTPException(status_code=401, detail='API key required')
