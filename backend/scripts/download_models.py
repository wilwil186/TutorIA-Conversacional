#!/usr/bin/env python3
"""
Script to download required AI models for Conversationally Desktop
"""

import os
import sys
from pathlib import Path
import requests
from tqdm import tqdm
import zipfile
import tarfile
from loguru import logger

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

class ModelDownloader:
    def __init__(self):
        self.models_dir = Path(__file__).parent.parent.parent / "models"
        self.models_dir.mkdir(exist_ok=True)
        
    def download_file(self, url: str, destination: Path, description: str = "Downloading"):
        """Download a file with progress bar"""
        try:
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            
            with open(destination, 'wb') as f:
                with tqdm(
                    total=total_size,
                    unit='B',
                    unit_scale=True,
                    desc=description
                ) as pbar:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
            
            logger.info(f"Successfully downloaded {destination}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to download {url}: {e}")
            return False
    
    def download_mistral_model(self):
        """Download Mistral 7B Instruct GGUF model"""
        logger.info("Downloading Mistral 7B Instruct model...")
        
        model_url = "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        model_path = self.models_dir / "mistral-7b-instruct-v0.2.Q4_K_M.gguf"
        
        if model_path.exists():
            logger.info(f"Mistral model already exists at {model_path}")
            return True
        
        return self.download_file(
            model_url, 
            model_path, 
            "Mistral 7B Instruct (4.7GB)"
        )
    
    def setup_sentence_transformers(self):
        """Setup Sentence Transformers model (will be downloaded automatically)"""
        logger.info("Sentence Transformers will be downloaded automatically on first use")
        st_dir = self.models_dir / "sentence-transformer"
        st_dir.mkdir(exist_ok=True)
        
        # Create a README with model info
        readme_content = """# Sentence Transformers Model

This directory will contain the Sentence Transformers model:
- Model: paraphrase-multilingual-MiniLM-L12-v2
- Purpose: Calculate similarity between user messages and expected topics
- Size: ~500MB
- Download: Automatic on first backend startup

The model will be downloaded automatically when you start the backend for the first time.
"""
        (st_dir / "README.md").write_text(readme_content)
        return True
    
    def setup_beto_model(self):
        """Setup BETO model for Spanish GEC"""
        logger.info("Setting up BETO model directory...")
        
        beto_dir = self.models_dir / "beto-gec"
        beto_dir.mkdir(exist_ok=True)
        
        # Create a README with model info
        readme_content = """# BETO Model for Spanish GEC

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
"""
        (beto_dir / "README.md").write_text(readme_content)
        return True
    
    def create_model_config(self):
        """Create model configuration file"""
        config = {
            "models": {
                "content": {
                    "name": "paraphrase-multilingual-MiniLM-L12-v2",
                    "type": "sentence_transformers",
                    "auto_download": True
                },
                "gec": {
                    "name": "dccuchile/bert-base-spanish-wwm-cased", 
                    "type": "transformers",
                    "auto_download": True
                },
                "generator": {
                    "name": "mistral-7b-instruct-v0.2.Q4_K_M.gguf",
                    "type": "gguf",
                    "path": str(self.models_dir / "mistral-7b-instruct-v0.2.Q4_K_M.gguf")
                }
            }
        }
        
        import json
        config_path = self.models_dir / "config.json"
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        logger.info(f"Created model config at {config_path}")
        return True
    
    def run(self):
        """Run the complete setup"""
        logger.info("Starting model download and setup...")
        
        success = True
        
        # Setup directories and configs
        success &= self.setup_sentence_transformers()
        success &= self.setup_beto_model()
        success &= self.create_model_config()
        
        # Download large models
        logger.info("\n" + "="*50)
        logger.info("IMPORTANT: Mistral 7B model download (4.7GB)")
        logger.info("This may take a while depending on your connection")
        logger.info("="*50 + "\n")
        
        response = input("Do you want to download Mistral 7B now? (y/n): ")
        if response.lower() in ['y', 'yes']:
            success &= self.download_mistral_model()
        else:
            logger.info("Skipping Mistral download. You can download it later with:")
            logger.info("wget -O models/mistral-7b-instruct-v0.2.Q4_K_M.gguf https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf")
        
        if success:
            logger.info("\n✅ Model setup completed successfully!")
            logger.info("You can now start the application with: make run")
        else:
            logger.error("\n❌ Some downloads failed. Check the logs above.")
        
        return success

if __name__ == "__main__":
    downloader = ModelDownloader()
    success = downloader.run()
    sys.exit(0 if success else 1)
