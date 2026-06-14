"""Ollama provider — local, free, open-source models (the default).

Runs wherever the backend runs (a machine with Ollama installed).
"""

import os

from fastapi import HTTPException
from loguru import logger
from pydantic import BaseModel, ValidationError

from app.schemas import LLMConfig

DEFAULT_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1")
DEFAULT_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")


def _content(response) -> str:
    # The ollama client returns an object in recent versions, a dict in older ones.
    msg = getattr(response, "message", None)
    if msg is not None:
        return msg.content if hasattr(msg, "content") else msg["content"]
    return response["message"]["content"]


def structured(
    cfg: LLMConfig, system: str, messages: list[dict], output_model: type[BaseModel]
) -> BaseModel:
    import ollama

    host = cfg.base_url or DEFAULT_HOST
    model = cfg.model or DEFAULT_MODEL
    full = [{"role": "system", "content": system}, *messages]

    try:
        client = ollama.Client(host=host)
        response = client.chat(
            model=model,
            messages=full,
            format=output_model.model_json_schema(),  # structured output (Ollama >= 0.5)
            options={"temperature": 0.5},
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
    except Exception as e:  # connection refused surfaces as httpx/ConnectionError, etc.
        logger.error(f"Ollama connection error: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"No se pudo conectar a Ollama en {host}. ¿Está corriendo 'ollama serve'?",
        )

    try:
        return output_model.model_validate_json(_content(response))
    except ValidationError:
        logger.error("Ollama returned non-conforming JSON")
        raise HTTPException(
            status_code=502,
            detail="El modelo open source devolvió una respuesta inválida. Prueba otro modelo.",
        )
