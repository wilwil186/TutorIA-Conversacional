from transformers import AutoTokenizer, AutoModelForTokenClassification
import torch
from typing import List, Dict
from loguru import logger

class GECModel:
    def __init__(self, model_name: str = "dccuchile/bert-base-spanish-wwm-cased"):
        self.model_name = model_name
        self.model = None
        self.tokenizer = None
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self._load_model()
    
    def _load_model(self):
        try:
            logger.info(f"Loading GEC model: {self.model_name}")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForTokenClassification.from_pretrained(self.model_name)
            self.model.to(self.device)
            self.model.eval()
            logger.info("GEC model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load GEC model: {e}")
            raise
    
    def predict_errors(self, text: str) -> List[Dict]:
        if not self.model or not self.tokenizer:
            raise RuntimeError("Model not loaded")
        
        try:
            inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            with torch.no_grad():
                outputs = self.model(**inputs)
            
            predictions = torch.argmax(outputs.logits, dim=2)
            tokens = self.tokenizer.convert_ids_to_tokens(inputs["input_ids"][0])
            
            results = []
            for i, token in enumerate(tokens):
                if token not in ["[CLS]", "[SEP]", "[PAD]"]:
                    pred_label = predictions[0][i].item()
                    results.append({
                        "token": token,
                        "label": self._get_error_type(pred_label),
                        "position": i
                    })
            
            return results
        except Exception as e:
            logger.error(f"Error during prediction: {e}")
            return []
    
    def _get_error_type(self, prediction: int) -> str:
        label_map = {
            0: "correct",
            1: "gender_error", 
            2: "number_error",
            3: "other_error"
        }
        return label_map.get(prediction, "unknown")
