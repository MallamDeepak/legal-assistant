import torch
from datasets import load_dataset
from peft import LoraConfig, get_peft_model, TaskType
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling
)
import os
from pathlib import Path

# CONFIG
MODEL_ID = "microsoft/Phi-3-mini-4k-instruct" 
OUTPUT_DIR = "data/models/legal-phi3-v1"
DATA_FILE = "data/training/synthetic_dataset.jsonl"

def train():
    base_dir = Path(__file__).resolve().parent.parent
    data_path = str(base_dir / DATA_FILE)
    output_path = str(base_dir / OUTPUT_DIR)
    
    print(f"Loading dataset from {data_path}...")
    if not os.path.exists(data_path):
        print("Dataset not found.")
        return

    # Load JSONL dataset
    dataset = load_dataset('json', data_files=data_path, split='train')
    
    print("Loading Tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
    tokenizer.pad_token = tokenizer.eos_token 

    def format_chat(sample):
        # Phi-3 Chat Template
        prompt = ""
        for m in sample['messages']:
            role = m['role']
            content = m['content']
            if role == "user":
                prompt += f"<|user|>\n{content}<|end|>\n"
            elif role == "assistant":
                prompt += f"<|assistant|>\n{content}<|end|>\n"
        return {"text": prompt}

    print("Formatting dataset...")
    dataset = dataset.map(format_chat)

    def tokenize_function(examples):
        return tokenizer(examples["text"], padding="max_length", truncation=True, max_length=512)
    
    tokenized_datasets = dataset.map(tokenize_function, batched=True)
    
    print("Loading Model (FP16 mode)...")
    # Low memory loading without quantization
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_ID, 
        device_map="auto",
        torch_dtype=torch.float16,
        low_cpu_mem_usage=True
    )
    
    # Apply LoRA
    peft_config = LoraConfig(
        task_type=TaskType.CAUSAL_LM, 
        inference_mode=False, 
        r=8, 
        lora_alpha=32, 
        lora_dropout=0.1,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj"]
    )
    model = get_peft_model(model, peft_config)
    
    training_args = TrainingArguments(
        output_dir=output_path,
        per_device_train_batch_size=1, # Lowest possible to safe memory
        gradient_accumulation_steps=8, # Compensate for batch size
        learning_rate=2e-4,
        num_train_epochs=3,
        logging_steps=10,
        fp16=True,
        save_strategy="epoch",
        optim="adamw_torch" # Standard Pytorch optimizer, no bitsandbytes needed
    )
    
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets,
        data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False),
    )
    
    print("Starting Training...")
    trainer.train()
    
    print(f"Saving model to {output_path}...")
    model.save_pretrained(output_path)

if __name__ == "__main__":
    train()
