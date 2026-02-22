import ollama
from typing import List, Dict, Optional
from loguru import logger
import os


class OllamaModel:
    def __init__(self, model_name: str = "llama3.1:70b"):
        self.model_name = model_name
        self._verify_model()

    def _verify_model(self):
        try:
            available = ollama.list()
            model_names = [m.model for m in available.models]
            if self.model_name not in model_names:
                logger.warning(
                    f"Model {self.model_name} not found. Available: {model_names}"
                )
                logger.info(f"Pulling model {self.model_name}...")
                ollama.pull(self.model_name)
            logger.info(f"Model '{self.model_name}' is ready")
        except Exception as e:
            logger.error(f"Failed to verify/pull model: {e}")
            raise

    def chat(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 150,
        temperature: float = 0.7,
    ) -> str:
        try:
            ollama_messages = self._convert_messages(messages)
            response = ollama.chat(
                model=self.model_name,
                messages=ollama_messages,
                options={
                    "num_predict": max_tokens,
                    "temperature": temperature,
                },
            )
            return response["message"]["content"].strip()
        except Exception as e:
            logger.error(f"Error during chat: {e}")
            return "Lo siento, no puedo generar una respuesta en este momento."

    def analyze_grammar(self, text: str) -> List[Dict]:
        prompt = f"""Analiza el siguiente texto en español y detecta errores gramaticales de concordancia de género y número.
Si hay errores, devuelve la lista de errores en formato JSON como este ejemplo:
[{{"token": "casa", "label": "gender_error", "message": "debería ser 'casa' si es femenino"}}]
Si no hay errores, devuelve: []

Texto: "{text}"

Respuesta (solo JSON):"""

        try:
            response = ollama.chat(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                options={"num_predict": 200, "temperature": 0.3},
            )
            content = response["message"]["content"].strip()

            import json
            import re

            json_match = re.search(r"\[.*\]", content, re.DOTALL)
            if json_match:
                errors = json.loads(json_match.group())
                return errors if isinstance(errors, list) else []
            return []
        except Exception as e:
            logger.error(f"Error analyzing grammar: {e}")
            return []

    def generate_hint(
        self, error_type: str, incorrect_text: str, context: str = ""
    ) -> str:
        prompt = f"""Como tutor de español, ayuda al estudiante a corregir su error de "{error_type}".
Texto incorrecto: "{incorrect_text}"
Contexto: {context}

Da una pista sutil sin dar la respuesta directa:"""

        try:
            response = ollama.chat(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                options={"num_predict": 80, "temperature": 0.5},
            )
            return response["message"]["content"].strip()
        except Exception as e:
            logger.error(f"Error generating hint: {e}")
            return "Revisa la concordancia de género y número en tu respuesta."

    def check_topic(self, user_message: str, expected_topic: str) -> bool:
        prompt = f"""Determina si el siguiente mensaje del estudiante está relacionado con el tema: "{expected_topic}"

Mensaje del estudiante: "{user_message}"

Responde solo con "sí" o "no":"""

        try:
            response = ollama.chat(
                model=self.model_name,
                messages=[{"role": "user", "content": prompt}],
                options={"num_predict": 10, "temperature": 0.1},
            )
            answer = response["message"]["content"].strip().lower()
            return "sí" in answer or "si" in answer
        except Exception as e:
            logger.error(f"Error checking topic: {e}")
            return True

    def _convert_messages(self, messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
        converted = []
        system_msg = """Eres un tutor de español amigable. Ayudas a estudiantes a practicar español
en escenarios de la vida real. Debes:
- Mantener la conversación en español
- Ser paciente y colaborador
- Dar pistas sutiles cuando cometan errores gramaticales
- Mantener el tema de conversación"""

        converted.append({"role": "system", "content": system_msg})

        for msg in messages:
            role = msg.get("role", "user")
            if role == "assistant":
                role = "assistant"
            elif role == "user":
                role = "user"
            else:
                role = "user"
            converted.append({"role": role, "content": msg.get("content", "")})

        return converted
