import requests
import json

API_KEY = "AIzaSyA6G42MyK5ZDC4lEYI0jVL9KyrEwnLkz0c"
URL = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"

def list_models():
    try:
        response = requests.get(URL)
        data = response.json()
        print(json.dumps(data, indent=2))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    list_models()
