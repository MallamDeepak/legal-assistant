"""Convert Label Studio JSON exports to training format."""
import json
import argparse
from pathlib import Path
from typing import List, Dict

def labelstudio_to_ner(input_path: Path, output_dir: Path):
    """Convert Label Studio NER annotations to token classification format."""
    with open(input_path, 'r', encoding='utf-8') as f:
        annotations = json.load(f)
    
    train_data = []
    label_set = set()
    
    for item in annotations:
        text = item['data']['text']
        if 'annotations' not in item or not item['annotations']:
            continue
        
        # Get entity spans
        entities = []
        for ann in item['annotations'][0]['result']:
            if ann['type'] == 'labels':
                entities.append({
                    'start': ann['value']['start'],
                    'end': ann['value']['end'],
                    'label': ann['value']['labels'][0]
                })
        
        # Convert to token-level tags
        tokens = text.split()
        tags = ['O'] * len(tokens)
        
        char_to_token = {}
        char_idx = 0
        for i, token in enumerate(tokens):
            for _ in range(len(token)):
                char_to_token[char_idx] = i
                char_idx += 1
            char_idx += 1  # space
        
        for ent in entities:
            start_token = char_to_token.get(ent['start'])
            end_token = char_to_token.get(ent['end'] - 1)
            
            if start_token is not None and end_token is not None:
                tags[start_token] = f"B-{ent['label']}"
                label_set.add(f"B-{ent['label']}")
                for i in range(start_token + 1, end_token + 1):
                    if i < len(tags):
                        tags[i] = f"I-{ent['label']}"
                        label_set.add(f"I-{ent['label']}")
        
        train_data.append({
            'tokens': tokens,
            'ner_tags': tags
        })
    
    # Save training data
    output_dir.mkdir(parents=True, exist_ok=True)
    
    with open(output_dir / 'train.jsonl', 'w', encoding='utf-8') as f:
        for item in train_data[:int(len(train_data) * 0.8)]:
            f.write(json.dumps(item) + '\n')
    
    with open(output_dir / 'valid.jsonl', 'w', encoding='utf-8') as f:
        for item in train_data[int(len(train_data) * 0.8):]:
            f.write(json.dumps(item) + '\n')
    
    # Save label list
    labels = sorted(['O'] + list(label_set))
    with open(output_dir / 'labels.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(labels))
    
    print(f"✓ Converted {len(train_data)} examples to {output_dir}")
    print(f"  Labels: {len(labels)}")

def labelstudio_to_classifier(input_path: Path, output_dir: Path):
    """Convert Label Studio clause annotations to classification format."""
    with open(input_path, 'r', encoding='utf-8') as f:
        annotations = json.load(f)
    
    train_data = []
    labels = set()
    
    for item in annotations:
        text = item['data']['text']
        if 'annotations' not in item or not item['annotations']:
            continue
        
        # Get risk level
        for ann in item['annotations'][0]['result']:
            if ann['from_name'] == 'risk_level':
                label = ann['value']['choices'][0]
                labels.add(label)
                train_data.append({
                    'text': text,
                    'label': label
                })
                break
    
    # Save training data
    output_dir.mkdir(parents=True, exist_ok=True)
    
    with open(output_dir / 'train.jsonl', 'w', encoding='utf-8') as f:
        for item in train_data[:int(len(train_data) * 0.8)]:
            f.write(json.dumps(item) + '\n')
    
    with open(output_dir / 'valid.jsonl', 'w', encoding='utf-8') as f:
        for item in train_data[int(len(train_data) * 0.8):]:
            f.write(json.dumps(item) + '\n')
    
    # Save labels
    with open(output_dir / 'labels.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(labels)))
    
    print(f"✓ Converted {len(train_data)} examples to {output_dir}")
    print(f"  Labels: {sorted(labels)}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', required=True, help='Label Studio JSON export')
    parser.add_argument('--output', required=True, help='Output directory')
    parser.add_argument('--task', choices=['ner', 'classifier'], required=True)
    args = parser.parse_args()
    
    input_path = Path(args.input)
    output_dir = Path(args.output)
    
    if args.task == 'ner':
        labelstudio_to_ner(input_path, output_dir)
    else:
        labelstudio_to_classifier(input_path, output_dir)

if __name__ == '__main__':
    main()