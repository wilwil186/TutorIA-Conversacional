from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List
from loguru import logger

class ContentModel:
    def __init__(self, model_name: str = "paraphrase-multilingual-MiniLM-L12-v2"):
        self.model_name = model_name
        self.model = None
        self._load_model()
    
    def _load_model(self):
        try:
            logger.info(f"Loading content model: {self.model_name}")
            self.model = SentenceTransformer(self.model_name)
            logger.info("Content model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load content model: {e}")
            raise
    
    def calculate_similarity(self, text1: str, text2: str) -> float:
        if not self.model:
            raise RuntimeError("Model not loaded")
        
        embeddings = self.model.encode([text1, text2])
        similarity = np.dot(embeddings[0], embeddings[1]) / (
            np.linalg.norm(embeddings[0]) * np.linalg.norm(embeddings[1])
        )
        return float(similarity)
    
    def is_on_topic(self, user_message: str, expected_topic: str, threshold: float = 0.3) -> bool:
        similarity = self.calculate_similarity(user_message, expected_topic)
        return similarity >= threshold
