from llama_cpp import Llama
from typing import List, Dict, Optional
from loguru import logger

class GeneratorModel:
    def __init__(self, model_path: str, n_ctx: int = 2048):
        self.model_path = model_path
        self.n_ctx = n_ctx
        self.model = None
        self._load_model()
    
    def _load_model(self):
        try:
            logger.info(f"Loading generator model: {self.model_path}")
            self.model = Llama(
                model_path=self.model_path,
                n_ctx=self.n_ctx,
                n_threads=4,
                n_gpu_layers=0  # Set to >0 if you have GPU
            )
            logger.info("Generator model loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load generator model: {e}")
            raise
    
    def generate_response(
        self, 
        messages: List[Dict[str, str]], 
        max_tokens: int = 150,
        temperature: float = 0.7
    ) -> str:
        if not self.model:
            raise RuntimeError("Model not loaded")
        
        try:
            # Format messages for the model
            prompt = self._format_messages(messages)
            
            response = self.model(
                prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                stop=["\n\n", "User:", "Human:"],
                echo=False
            )
            
            return response["choices"][0]["text"].strip()
        except Exception as e:
            logger.error(f"Error during generation: {e}")
            return "Lo siento, no puedo generar una respuesta en este momento."
    
    def generate_hint(
        self, 
        error_type: str, 
        incorrect_text: str,
        context: str = ""
    ) -> str:
        hint_prompt = f"""
        Como tutor de español, ayuda al estudiante a corregir su error de "{error_type}".
        Texto incorrecto: "{incorrect_text}"
        Contexto: {context}
        
        Da una pista sutil sin dar la respuesta directa:
        """
        
        try:
            response = self.model(
                hint_prompt,
                max_tokens=80,
                temperature=0.5,
                echo=False
            )
            return response["choices"][0]["text"].strip()
        except Exception as e:
            logger.error(f"Error generating hint: {e}")
            return "Revisa la concordancia de género y número en tu respuesta."
    
    def _format_messages(self, messages: List[Dict[str, str]]) -> str:
        formatted = ""
        for msg in messages:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role == "system":
                formatted += f"System: {content}\n"
            elif role == "user":
                formatted += f"User: {content}\n"
            elif role == "assistant":
                formatted += f"Assistant: {content}\n"
        
        formatted += "Assistant: "
        return formatted
