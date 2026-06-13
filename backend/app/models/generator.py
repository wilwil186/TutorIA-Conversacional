from loguru import logger
import random
from typing import List, Dict

class GeneratorModel:
    def __init__(self, model_path: str, n_ctx: int = 2048):
        self.model_path = model_path
        self.n_ctx = n_ctx
        self.model = None
        self._load_model()
    
    def _load_model(self):
        try:
            logger.info(f"Generator model path: {self.model_path}")
            # For now, we'll use a simple fallback since llama-cpp-python might be heavy
            logger.info("Using fallback generator (simple rule-based responses)")
            self.model = "fallback"
        except Exception as e:
            logger.error(f"Failed to load generator model: {e}")
            self.model = "fallback"
    
    def generate_response(
        self, 
        messages: List[Dict[str, str]], 
        max_tokens: int = 150,
        temperature: float = 0.7
    ) -> str:
        if not self.model:
            return "Lo siento, no puedo generar una respuesta en este momento."
        
        # Simple fallback responses based on the last user message
        user_message = ""
        for msg in reversed(messages):
            if msg.get("role") == "user":
                user_message = msg.get("content", "").lower()
                break
        
        # Simple pattern matching for basic responses
        if "hola" in user_message or "buenos" in user_message:
            return "¡Hola! ¿Cómo estás hoy? Estoy aquí para ayudarte a practicar español."
        elif "gracias" in user_message:
            return "De nada. ¿Hay algo más en lo que pueda ayudarte?"
        elif "adiós" in user_message or "chau" in user_message:
            return "¡Hasta luego! Fue un placer practicar contigo."
        elif "comida" in user_message or "restaurante" in user_message:
            return "¡Excelente! En el restaurante, podrías pedir: 'Quisiera ordenar el menú del día, por favor.' ¿Qué te gustaría pedir?"
        elif "nombre" in user_message or "llamo" in user_message:
            return "¡Mucho gusto! Es un placer conocerte. ¿De dónde eres?"
        elif "dirección" in user_message or "dónde" in user_message:
            return "Para pedir direcciones, puedes decir: 'Disculpe, ¿podría indicarme cómo llegar a...?' ¿A dónde quieres ir?"
        else:
            responses = [
                "¡Interesante! Cuéntame más sobre eso.",
                "Entiendo. ¿Podrías explicar eso de otra manera?",
                "¡Muy bien! Sigue practicando así.",
                "Tu español está mejorando. ¿Qué más te gustaría decir?",
                "¡Excelente! Estás progresando muy bien."
            ]
            return random.choice(responses)
    
    def generate_hint(
        self, 
        error_type: str, 
        incorrect_text: str,
        context: str = ""
    ) -> str:
        hints = {
            "gender_error": "Recuerda que los sustantivos en español tienen género (masculino/femenino). Revisa si debe ser 'el' o 'la'.",
            "number_error": "Fíjate en la concordancia de número. ¿Debería ser singular o plural?",
            "other_error": "Revisa la estructura de la oración. ¿Hay alguna palabra que podría cambiar de posición?",
            "unknown": "Piensa en la regla gramatical que aplicamos recientemente. ¿Cómo podrías mejorar esta frase?"
        }
        return hints.get(error_type, "Revisa tu respuesta y piensa en las reglas gramaticales que hemos practicado.")
