import requests
import json

url = "http://localhost:8000/incident/analyze"
payload = {
    "text": "A man snatched my gold chain while I was walking in the park.",
    "language": "en"
}

results = []
for i in range(3):
    try:
        print(f"Starting Run {i+1}...")
        response = requests.post(url, json=payload, timeout=120)
        data = response.json()
        sections = data.get("suggested_sections", [])
        results.append(tuple(sections))
        print(f"Run {i+1} Success: {sections}")
    except Exception as e:
        print(f"Run {i+1} failed: {e}")

if not results:
    print("\nFAILURE: No successful runs.")
elif len(set(results)) == 1:
    print(f"\nSUCCESS: All {len(results)} successful runs returned identical legal sections.")
else:
    print(f"\nFAILURE: Results were inconsistent across {len(results)} successful runs.")
