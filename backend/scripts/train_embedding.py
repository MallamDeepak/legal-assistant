from sentence_transformers import SentenceTransformer, InputExample, losses, evaluation
from torch.utils.data import DataLoader
import json
import os
from pathlib import Path
import random

# CONFIG
MODEL_NAME = 'sentence-transformers/all-MiniLM-L6-v2' # Base model
OUTPUT_PATH = 'data/models/legal-embed-v1'
BATCH_SIZE = 16
EPOCHS = 3
DATA_FILE = 'data/training/synthetic_dataset.jsonl'

def load_training_data(filepath):
    """Load jsonl data and convert to InputExample"""
    examples = []
    if not os.path.exists(filepath):
        print(f"Error: {filepath} not found. Run generate_train_data.py first.")
        return []
        
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                # Structure: {"messages": [{"role": "user", "content": QUERY}, {"role": "assistant", "content": POSITIVE_DOC}]}
                query = data['messages'][0]['content']
                pos_doc = data['messages'][1]['content']
                
                # We treat this as a positive pair
                examples.append(InputExample(texts=[query, pos_doc], label=1.0))
            except Exception as e:
                pass
    return examples

def train():
    base_dir = Path(__file__).resolve().parent.parent
    data_path = base_dir / DATA_FILE
    output_path = base_dir / OUTPUT_PATH
    
    print(f"Loading data from {data_path}...")
    train_examples = load_training_data(str(data_path))
    
    if not train_examples:
        return

    # Split train/dev
    random.shuffle(train_examples)
    train_split = int(len(train_examples) * 0.9)
    train_data = train_examples[:train_split]
    dev_data = train_examples[train_split:]
    
    print(f"Training on {len(train_data)} pairs")
    
    # Define Dataloader
    train_dataloader = DataLoader(train_data, shuffle=True, batch_size=BATCH_SIZE)
    
    # Define Model
    print(f"Loading base model {MODEL_NAME}...")
    model = SentenceTransformer(MODEL_NAME)
    
    # Define Loss (MultipleNegativesRankingLoss is great for query-doc pairs)
    # Note: For strict pairs without negatives, CosineSimilarityLoss is also an option, 
    # but MNRL is standard for search. It requires the batch to act as negatives.
    train_loss = losses.MultipleNegativesRankingLoss(model)
    
    # Evaluator
    evaluator = evaluation.EmbeddingSimilarityEvaluator.from_input_examples(dev_data, name='dev')

    # Train
    print("Starting training...")
    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        evaluator=evaluator,
        epochs=EPOCHS,
        evaluation_steps=100,
        warmup_steps=100,
        output_path=str(output_path),
        save_best_model=True
    )
    
    print(f"Training complete. Model saved to {output_path}")

if __name__ == "__main__":
    train()
