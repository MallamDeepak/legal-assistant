# Legal Assistant AI Pipeline Orchestrator

function Show-Menu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "   LEGAL ASSISTANT AI - PIPELINE CONTROLLER   " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "1. [Data] Generate Synthetic Training Data" -ForegroundColor Yellow
    Write-Host "2. [Data] Enrich CSV Metadata (Detailed)" -ForegroundColor Yellow
    Write-Host "3. [Test] Verify Reranking Accuracy (Quick)" -ForegroundColor Green
    Write-Host "4. [Exam] Generate Golden Evaluation Set" -ForegroundColor Magenta
    Write-Host "5. [Exam] Run Full Accuracy Evaluation" -ForegroundColor Magenta
    Write-Host "6. [Train] Fine-Tune Embedding Model (CPU/GPU)" -ForegroundColor Red
    Write-Host "7. [Train] Fine-Tune LLM (Requires GPU)" -ForegroundColor Red
    Write-Host "q. Quit"
    Write-Host "==============================================" -ForegroundColor Cyan
}

while ($true) {
    Show-Menu
    $selection = Read-Host "Select an option"

    switch ($selection) {
        "1" { 
            Write-Host "Running Data Generator..." -ForegroundColor Yellow
            python backend/scripts/generate_train_data.py
            Pause
        }
        "2" {
            Write-Host "Running Metadata Enricher..." -ForegroundColor Yellow
            python backend/scripts/enrich_metadata.py
            Pause
        }
        "3" {
            Write-Host "Verifying Reranker..." -ForegroundColor Green
            python backend/scripts/verify_rerank.py
            Pause
        }
        "4" {
            Write-Host "Generating Golden Exam Set..." -ForegroundColor Magenta
            python backend/scripts/generate_golden_set.py
            Pause
        }
        "5" {
            Write-Host "Running Evaluator..." -ForegroundColor Magenta
            python backend/scripts/evaluate_pipeline.py
            Pause
        }
        "6" {
            Write-Host "Training Embedding Model..." -ForegroundColor Red
            python backend/scripts/train_embedding.py
            Pause
        }
        "7" {
            Write-Host "Proprietary LLM Training..." -ForegroundColor Red
            python backend/scripts/train_llm.py
            Pause
        }
        "q" { exit }
        Default { Write-Host "Invalid selection" }
    }
}
