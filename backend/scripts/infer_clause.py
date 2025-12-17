import sys
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

model_dir = sys.argv[1] if len(sys.argv) > 1 else "models/clauses-distil"
text = sys.argv[2] if len(sys.argv) > 2 else "Landlord may terminate without notice."

tok = AutoTokenizer.from_pretrained(model_dir)
mdl = AutoModelForSequenceClassification.from_pretrained(model_dir)

inputs = tok(text, return_tensors="pt", truncation=True)
with torch.no_grad():
    out = mdl(**inputs).logits.softmax(-1).squeeze()
probs = out.tolist()
labels = mdl.config.id2label
print(sorted([(labels[i], p) for i, p in enumerate(probs)], key=lambda x: x[1], reverse=True))