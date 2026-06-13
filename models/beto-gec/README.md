# BETO Model for Spanish GEC

This directory is for the BETO (Spanish BERT) model fine-tuned for Grammatical Error Correction.

## Current Status
- Using base BETO model: dccuchile/bert-base-spanish-wwm-cased
- This will be downloaded automatically by Hugging Face transformers
- For better GEC performance, fine-tune with COWS-L2H dataset

## Model Info
- Base Model: dccuchile/bert-base-spanish-wwm-cased
- Purpose: Spanish grammatical error detection
- Size: ~1.4GB
- Download: Automatic via Hugging Face

## Fine-tuning (Optional)
To improve GEC performance:
1. Get COWS-L2H dataset
2. Run: python scripts/train_gec.py
3. Replace model files in this directory
