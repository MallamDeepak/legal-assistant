"""
Train a clause classifier with labels: ok, flagged, high-risk.

Prereqs:
    pip install transformers datasets accelerate scikit-learn

Expected CSV/JSONL with fields: "text", "label"
Labels file maps string -> id.

Example run:
    python -m scripts.train_clause_classifier --train data/clauses/train.jsonl --valid data/clauses/valid.jsonl --labels data/clauses/labels.txt --model distilbert-base-multilingual-cased --out models/clauses-distil
"""
import argparse, json
from pathlib import Path
import datasets
from datasets import Dataset
from transformers import (AutoTokenizer, AutoModelForSequenceClassification,
                          Trainer, TrainingArguments)
from sklearn.metrics import precision_recall_fscore_support, accuracy_score


def load_jsonl(path: Path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            rows.append(json.loads(line))
    return Dataset.from_list(rows)


def load_labels(path: Path):
    with open(path, "r", encoding="utf-8") as f:
        labels = [ln.strip() for ln in f if ln.strip()]
    return labels, {l: i for i, l in enumerate(labels)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--train", required=True, type=Path)
    ap.add_argument("--valid", required=True, type=Path)
    ap.add_argument("--labels", required=True, type=Path)
    ap.add_argument("--model", default="distilbert-base-multilingual-cased")
    ap.add_argument("--out", default="models/clauses-distil")
    ap.add_argument("--epochs", type=int, default=4)
    ap.add_argument("--batch", type=int, default=16)
    args = ap.parse_args()

    label_list, label2id = load_labels(args.labels)
    id2label = {i: l for l, i in label2id.items()}

    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForSequenceClassification.from_pretrained(
        args.model, num_labels=len(label_list), id2label=id2label, label2id=label2id
    )

    def preprocess(batch):
        enc = tok(batch["text"], truncation=True, padding="max_length", max_length=256)
        enc["labels"] = [label2id[l] for l in batch["label"]]
        return enc

    train_ds = load_jsonl(args.train).map(preprocess, batched=True)
    valid_ds = load_jsonl(args.valid).map(preprocess, batched=True)

    def compute_metrics(p):
        preds = p.predictions.argmax(-1)
        labels = p.label_ids
        prec, rec, f1, _ = precision_recall_fscore_support(labels, preds, average="macro", zero_division=0)
        acc = accuracy_score(labels, preds)
        return {"accuracy": acc, "precision": prec, "recall": rec, "f1": f1}

    targs = TrainingArguments(
        output_dir=args.out,
        learning_rate=3e-5,
        per_device_train_batch_size=args.batch,
        per_device_eval_batch_size=args.batch,
        num_train_epochs=args.epochs,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="f1",
        greater_is_better=True,
        logging_steps=50,
    )

    trainer = Trainer(
        model=model,
        args=targs,
        train_dataset=train_ds,
        eval_dataset=valid_ds,
        tokenizer=tok,
        compute_metrics=compute_metrics,
    )
    trainer.train()
    trainer.save_model(args.out)
    tok.save_pretrained(args.out)


if __name__ == "__main__":
    main()