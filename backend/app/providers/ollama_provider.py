"""Ollama provider — local, free, open-source models (the default).

Runs wherever the backend runs (a PC with Ollama installed). Phones can't run
the model locally, so a phone must reach a backend that has Ollama, or use the
Claude/OpenAI providers instead.
"""

import os

from fastapi import HTTPException
from loguru import logger
from pydantic import ValidationError

from app.providers.base import build_system, message_dicts
from app.schemas import ChatRequest, LLMConfig, TutorTurn

DEFAULT_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1")
DEFAULT_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")


def _content(response) -> str:
    # The ollama client returns an object in recent versions, a dict in older ones.
    msg = getattr(response, "message", None)
    if msg is not None:
        return msg.content if hasattr(msg, "content") else msg["content"]
    return response["message"]["content"]


def generate(request: ChatRequest, cfg: LLMConfig) -> TutorTurn:
    import ollama

    host = cfg.base_url or DEFAULT_HOST
    model = cfg.model or DEFAULT_MODEL
    messages = [{"role": "system", "content": build_system(request)}, *message_dicts(request)]

    try:
        client = ollama.Client(host=host)
        response = client.chat(
            model=model,
            messages=messages,
            format=TutorTurn.model_json_schema(),  # structured output (Ollama >= 0.5)
            options={"temperature": 0.5},
        )
    except ConnectionError:
        raise HTTPException(
            status_code=503,
            detail=f"No se pudo conectar a Ollama en {host}. ¿Está corriendo 'ollama serve'?",
        )
    except ollama.ResponseError as e:
        msg = str(e)
        if "not found" in msg.lower():
            raise HTTPException(
                status_code=503,
                detail=f"El modelo '{model}' no está en Ollama. Ejecuta: ollama pull {model}",
            )
        logger.error(f"Ollama error: {msg}")
        raise HTTPException(status_code=502, detail="Error del modelo open source (Ollama).")
    except Exception as e:  # connection refused surfaces as httpx errors, etc.
        logger.error(f"Ollama connection error: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"No se pudo conectar a Ollama en {host}. ¿Está corriendo 'ollama serve'?",
        )

    try:
        return TutorTurn.model_validate_json(_content(response))
    except ValidationError:
        logger.error("Ollama returned non-conforming JSON")
        raise HTTPException(
            status_code=502,
            detail="El modelo open source devolvió una respuesta inválida. Prueba otro modelo.",
        )
