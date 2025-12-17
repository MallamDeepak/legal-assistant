"""Train NER model with comprehensive evaluation."""
import argparse
import json
from pathlib import Path
from datasets import Dataset, load_metric
from transformers import (
    AutoTokenizer, AutoModelForTokenClassification,
    TrainingArguments, Trainer, DataCollatorForTokenClassification
)
import numpy as np
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

def load_dataset(path: Path, labels_path: Path):
    """Load JSONL dataset."""
    with open(labels_path, 'r') as f:
        label_list = [line.strip() for line in f]
    label2id = {label: i for i, label in enumerate(label_list)}
    
    data = []
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            item = json.loads(line)
            item['ner_tags'] = [label2id[tag] for tag in item['ner_tags']]
            data.append(item)
    
    return Dataset.from_list(data), label_list, label2id

def tokenize_and_align(examples, tokenizer, label2id):
    """Tokenize and align labels with subwords."""
    tokenized = tokenizer(examples['tokens'], truncation=True, is_split_into_words=True)
    
    labels = []
    for i, label in enumerate(examples['ner_tags']):
        word_ids = tokenized.word_ids(batch_index=i)
        label_ids = []
        previous_word_idx = None
        
        for word_idx in word_ids:
            if word_idx is None:
                label_ids.append(-100)
            elif word_idx != previous_word_idx:
                label_ids.append(label[word_idx])
            else:
                label_ids.append(-100)
            previous_word_idx = word_idx
        
        labels.append(label_ids)
    
    tokenized['labels'] = labels
    return tokenized

def compute_metrics(p, label_list):
    """Compute evaluation metrics."""
    predictions, labels = p
    predictions = np.argmax(predictions, axis=2)
    
    # Remove ignored index (-100)
    true_predictions = [
        [label_list[p] for p, l in zip(pred, label) if l != -100]
        for pred, label in zip(predictions, labels)
    ]
    true_labels = [
        [label_list[l] for p, l in zip(pred, label) if l != -100]
        for pred, label in zip(predictions, labels)
    ]
    
    # Flatten for sklearn metrics
    flat_preds = [p for sublist in true_predictions for p in sublist]
    flat_labels = [l for sublist in true_labels for l in sublist]
    
    # Classification report
    print("\n" + "="*60)
    print("CLASSIFICATION REPORT")
    print("="*60)
    print(classification_report(flat_labels, flat_preds))
    
    # Confusion matrix
    cm = confusion_matrix(flat_labels, flat_preds, labels=label_list)
    plt.figure(figsize=(12, 10))
    sns.heatmap(cm, annot=True, fmt='d', xticklabels=label_list, yticklabels=label_list)
    plt.title('Confusion Matrix')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig('data/ner/confusion_matrix.png')
    print("\n✓ Saved confusion matrix to: data/ner/confusion_matrix.png")
    
    # Compute seqeval metrics
    from seqeval.metrics import f1_score, precision_score, recall_score
    return {
        'precision': precision_score(true_labels, true_predictions),
        'recall': recall_score(true_labels, true_predictions),
        'f1': f1_score(true_labels, true_predictions)
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--train', required=True, help='Training JSONL')
    parser.add_argument('--valid', required=True, help='Validation JSONL')
    parser.add_argument('--labels', required=True, help='Labels file')
    parser.add_argument('--model', default='xlm-roberta-base', help='Base model')
    parser.add_argument('--out', default='models/ner', help='Output directory')
    parser.add_argument('--epochs', type=int, default=3)
    parser.add_argument('--batch-size', type=int, default=16)
    args = parser.parse_args()
    
    print("Loading dataset...")
    train_dataset, label_list, label2id = load_dataset(Path(args.train), Path(args.labels))
    valid_dataset, _, _ = load_dataset(Path(args.valid), Path(args.labels))
    
    print(f"Train examples: {len(train_dataset)}")
    print(f"Valid examples: {len(valid_dataset)}")
    print(f"Labels: {label_list}")
    
    print(f"\nLoading model: {args.model}")
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForTokenClassification.from_pretrained(
        args.model, 
        num_labels=len(label_list),
        id2label={i: label for i, label in enumerate(label_list)},
        label2id=label2id
    )
    
    print("Tokenizing...")
    train_tokenized = train_dataset.map(
        lambda x: tokenize_and_align(x, tokenizer, label2id),
        batched=True
    )
    valid_tokenized = valid_dataset.map(
        lambda x: tokenize_and_align(x, tokenizer, label2id),
        batched=True
    )
    
    training_args = TrainingArguments(
        output_dir=args.out,
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        warmup_steps=500,
        weight_decay=0.01,
        logging_dir=f'{args.out}/logs',
        logging_steps=10,
        eval_strategy='epoch',
        save_strategy='epoch',
        load_best_model_at_end=True,
        metric_for_best_model='f1',
    )
    
    data_collator = DataCollatorForTokenClassification(tokenizer)
    
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_tokenized,
        eval_dataset=valid_tokenized,
        tokenizer=tokenizer,
        data_collator=data_collator,
        compute_metrics=lambda p: compute_metrics(p, label_list),
    )
    
    print("\n🚀 Starting training...")
    trainer.train()
    
    print("\n✓ Training complete!")
    print(f"Model saved to: {args.out}")
    
    # Final evaluation
    print("\n📊 Final evaluation on validation set:")
    results = trainer.evaluate()
    print(f"  Precision: {results['eval_precision']:.4f}")
    print(f"  Recall: {results['eval_recall']:.4f}")
    print(f"  F1: {results['eval_f1']:.4f}")

if __name__ == '__main__':
    main()