import pandas as pd
import torch
from sklearn.model_selection import train_test_split
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification, Trainer, TrainingArguments
from datasets import Dataset
import os
from pathlib import Path

# CONFIG
MODEL_NAME = "distilbert-base-uncased"
DATA_FILE = "data/training/contract_fraud_dataset.csv"
OUTPUT_DIR = "data/models/fraud-detector-v1"
LABELS = {"Safe": 0, "Risky": 1, "Fraudulent": 2}

def train():
    base_dir = Path(__file__).resolve().parent.parent
    data_path = base_dir / DATA_FILE
    output_path = base_dir / OUTPUT_DIR
    
    if not data_path.exists():
        print(f"Error: {data_path} not found. Run generate_contract_data.py first.")
        return

    print("Loading data...")
    df = pd.read_csv(data_path)
    df = df.dropna()
    df['label_id'] = df['label'].map(LABELS)
    
    # Convert to HuggingFace Dataset
    dataset = Dataset.from_pandas(df[['text', 'label_id']])
    dataset = dataset.rename_column("label_id", "label")
    dataset = dataset.train_test_split(test_size=0.2)
    
    print("Tokenizing...")
    tokenizer = DistilBertTokenizer.from_pretrained(MODEL_NAME)
    
    def tokenize_function(examples):
        return tokenizer(examples["text"], padding="max_length", truncation=True)
        
    tokenized_datasets = dataset.map(tokenize_function, batched=True)
    
    print("Loading Model...")
    model = DistilBertForSequenceClassification.from_pretrained(
        MODEL_NAME, 
        num_labels=len(LABELS),
        id2label={v: k for k, v in LABELS.items()},
        label2id=LABELS
    )
    
    training_args = TrainingArguments(
        output_dir=str(output_path),
        eval_strategy="epoch", # Updated from evaluation_strategy
        learning_rate=2e-5,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        num_train_epochs=3,
        weight_decay=0.01,
        logging_dir=str(output_path / "logs"),
        save_strategy="epoch"
    )
    
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets["train"],
        eval_dataset=tokenized_datasets["test"],
        tokenizer=tokenizer,
    )
    
    print("Starting Training...")
    trainer.train()
    
    print(f"Saving model to {output_path}...")
    trainer.save_model(str(output_path))
    
    # Save label mapping manually to be safe
    import json
    with open(output_path / "labels.json", 'w') as f:
        json.dump(LABELS, f)

if __name__ == "__main__":
    train()
