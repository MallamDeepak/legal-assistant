"""Train clause risk classifier with evaluation."""
import argparse
import json
from pathlib import Path
from datasets import Dataset
from transformers import (
    AutoTokenizer, AutoModelForSequenceClassification,
    TrainingArguments, Trainer
)
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

def load_dataset(path: Path, labels_path: Path):
    """Load classification dataset."""
    with open(labels_path, 'r') as f:
        label_list = [line.strip() for line in f]
    label2id = {label: i for i, label in enumerate(label_list)}
    
    data = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            item = json.loads(line)
            item['label'] = label2id[item['label']]
            data.append(item)
    
    return Dataset.from_list(data), label_list, label2id

def compute_metrics(p, label_list):
    """Compute classification metrics."""
    predictions, labels = p
    predictions = np.argmax(predictions, axis=1)
    
    print("\n" + "="*60)
    print("CLASSIFICATION REPORT")
    print("="*60)
    print(classification_report(
        labels, predictions, 
        target_names=label_list, 
        digits=4
    ))
    
    # Confusion matrix
    cm = confusion_matrix(labels, predictions)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=label_list, yticklabels=label_list, cmap='Blues')
    plt.title('Confusion Matrix - Clause Risk Classification')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig('data/clauses/confusion_matrix.png')
    print("\n✓ Saved confusion matrix to: data/clauses/confusion_matrix.png")
    
    from sklearn.metrics import precision_recall_fscore_support
    precision, recall, f1, _ = precision_recall_fscore_support(labels, predictions, average='weighted')
    
    return {
        'precision': precision,
        'recall': recall,
        'f1': f1
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--train', required=True)
    parser.add_argument('--valid', required=True)
    parser.add_argument('--labels', required=True)
    parser.add_argument('--model', default='distilbert-base-multilingual-cased')
    parser.add_argument('--out', default='models/clause-classifier')
    parser.add_argument('--epochs', type=int, default=5)
    parser.add_argument('--batch-size', type=int, default=16)
    args = parser.parse_args()
    
    print("Loading dataset...")
    train_dataset, label_list, label2id = load_dataset(Path(args.train), Path(args.labels))
    valid_dataset, _, _ = load_dataset(Path(args.valid), Path(args.labels))
    
    print(f"Train: {len(train_dataset)} | Valid: {len(valid_dataset)}")
    print(f"Labels: {label_list}")
    
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForSequenceClassification.from_pretrained(
        args.model,
        num_labels=len(label_list),
        id2label={i: l for i, l in enumerate(label_list)},
        label2id=label2id
    )
    
    def tokenize(examples):
        return tokenizer(examples['text'], truncation=True, padding='max_length', max_length=512)
    
    train_tokenized = train_dataset.map(tokenize, batched=True)
    valid_tokenized = valid_dataset.map(tokenize, batched=True)
    
    training_args = TrainingArguments(
        output_dir=args.out,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        warmup_steps=200,
        weight_decay=0.01,
        logging_steps=10,
        eval_strategy='epoch',
        save_strategy='epoch',
        load_best_model_at_end=True,
        metric_for_best_model='f1',
    )
    
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_tokenized,
        eval_dataset=valid_tokenized,
        tokenizer=tokenizer,
        compute_metrics=lambda p: compute_metrics(p, label_list),
    )
    
    print("\n🚀 Training...")
    trainer.train()
    
    print(f"\n✓ Model saved to: {args.out}")
    results = trainer.evaluate()
    print(f"\n📊 Final Results:")
    print(f"  Precision: {results['eval_precision']:.4f}")
    print(f"  Recall: {results['eval_recall']:.4f}")
    print(f"  F1: {results['eval_f1']:.4f}")

if __name__ == '__main__':
    main()