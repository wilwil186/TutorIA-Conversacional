"""Anthropic (Claude) provider — uses the user's own API key."""

import os

from fastapi import HTTPException
from loguru import logger

from app.providers.base import build_system, message_dicts
from app.schemas import ChatRequest, LLMConfig, TutorTurn

DEFAULT_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-opus-4-8")


def generate(request: ChatRequest, cfg: LLMConfig) -> TutorTurn:
    import anthropic

    api_key = cfg.api_key or os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="Falta la API key de Claude. Añádela en Ajustes o usa la IA open source.",
        )

    client = anthropic.Anthropic(api_key=api_key, base_url=cfg.base_url or None)
    model = cfg.model or DEFAULT_MODEL

    try:
        response = client.messages.parse(
            model=model,
            max_tokens=1024,
            system=build_system(request),
            messages=message_dicts(request),
            output_format=TutorTurn,
        )
    except anthropic.AuthenticationError:
        raise HTTPException(status_code=401, detail="API key de Claude inválida.")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Límite de Claude alcanzado, intenta luego.")
    except anthropic.APIConnectionError:
        raise HTTPException(status_code=502, detail="No se pudo conectar con Claude.")
    except anthropic.APIStatusError as e:
        logger.error(f"Claude API error {e.status_code}: {e.message}")
        raise HTTPException(status_code=502, detail="Error al contactar con Claude.")

    if response.parsed_output is None:
        raise HTTPException(status_code=502, detail="Claude devolvió una respuesta inválida.")
    return response.parsed_output
