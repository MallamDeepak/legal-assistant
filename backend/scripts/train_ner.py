"""
Train a multilingual NER model (token classification) with Hugging Face Trainer.

Prereqs:
    pip install transformers datasets seqeval accelerate

Expected dataset (HF datasets.load_dataset compatible):
    A split with features: "tokens": List[str], "ner_tags": List[int]
    And a "label_list" metadata you pass in --labels.

Example run:
    python -m scripts.train_ner --train data/ner/train.jsonl --valid data/ner/valid.jsonl --labels data/ner/labels.txt --model xlm-roberta-base --out models/ner-xlmrb
"""
import argparse, json
from pathlib import Path
from typing import List
import datasets
from datasets import Dataset
from transformers import (AutoTokenizer, AutoModelForTokenClassification,
                          DataCollatorForTokenClassification, Trainer, TrainingArguments)
from seqeval.metrics import classification_report, f1_score


def load_jsonl_tokens(path: Path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            rows.append(json.loads(line))
    return Dataset.from_list(rows)


def load_labels(path: Path) -> List[str]:
    with open(path, "r", encoding="utf-8") as f:
        return [ln.strip() for ln in f if ln.strip()]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--train", required=True, type=Path)
    ap.add_argument("--valid", required=True, type=Path)
    ap.add_argument("--labels", required=True, type=Path)
    ap.add_argument("--model", default="xlm-roberta-base")
    ap.add_argument("--out", default="models/ner-xlmrb")
    ap.add_argument("--epochs", type=int, default=5)
    ap.add_argument("--batch", type=int, default=8)
    args = ap.parse_args()

    label_list = load_labels(args.labels)
    label2id = {l: i for i, l in enumerate(label_list)}
    id2label = {i: l for l, i in label2id.items()}

    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForTokenClassification.from_pretrained(
        args.model, num_labels=len(label_list), id2label=id2label, label2id=label2id
    )

    def tokenize_and_align(examples):
        tokenized = tok(examples["tokens"], truncation=True, is_split_into_words=True)
        labels = []
        for i, word_ids in enumerate(tokenized.word_ids(batch_index=k) for k in range(len(examples["tokens"]))):
            example_labels = examples["ner_tags"][i]
            aligned = []
            prev = None
            for wid in word_ids:
                if wid is None:
                    aligned.append(-100)
                elif wid != prev:
                    aligned.append(example_labels[wid])
                else:
                    aligned.append(example_labels[wid])  # or -100 if you prefer labeling only first subtoken
                prev = wid
            labels.append(aligned)
        tokenized["labels"] = labels
        return tokenized

    train_ds = load_jsonl_tokens(args.train)
    valid_ds = load_jsonl_tokens(args.valid)
    train_ds = train_ds.map(tokenize_and_align, batched=True)
    valid_ds = valid_ds.map(tokenize_and_align, batched=True)

    collator = DataCollatorForTokenClassification(tok)

    def compute_metrics(p):
        preds = p.predictions.argmax(-1)
        labels = p.label_ids
        true_preds = [
            [id2label[l] for (l, m) in zip(label_row, mask_row) if m != -100]
            for label_row, mask_row in zip(labels, labels)
        ]
        true_labels = [
            [id2label[p] for (p, m) in zip(pred_row, mask_row) if m != -100]
            for pred_row, mask_row in zip(preds, labels)
        ]
        return {"f1": f1_score(true_labels, true_preds)}

    args_train = TrainingArguments(
        output_dir=args.out,
        learning_rate=3e-5,
        per_device_train_batch_size=args.batch,
        per_device_eval_batch_size=args.batch,
        num_train_epochs=args.epochs,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        logging_steps=50,
        load_best_model_at_end=True,
        metric_for_best_model="f1",
        greater_is_better=True,
    )

    trainer = Trainer(
        model=model,
        args=args_train,
        train_dataset=train_ds,
        eval_dataset=valid_ds,
        tokenizer=tok,
        data_collator=collator,
        compute_metrics=compute_metrics,
    )

    trainer.train()
    trainer.save_model(args.out)
    tok.save_pretrained(args.out)


if __name__ == "__main__":
    main()