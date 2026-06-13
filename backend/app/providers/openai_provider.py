"""OpenAI provider — uses the user's own API key.

`base_url` also makes this work with any OpenAI-compatible endpoint
(Groq, OpenRouter, Together, a local server, ...), which is a handy way to
reach hosted open-source models.
"""

import os

from fastapi import HTTPException
from loguru import logger

from app.providers.base import build_system, message_dicts
from app.schemas import ChatRequest, LLMConfig, TutorTurn

DEFAULT_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")


def generate(request: ChatRequest, cfg: LLMConfig) -> TutorTurn:
    import openai

    api_key = cfg.api_key or os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="Falta la API key de OpenAI. Añádela en Ajustes o usa la IA open source.",
        )

    client = openai.OpenAI(
        api_key=api_key,
        base_url=cfg.base_url or os.getenv("OPENAI_BASE_URL") or None,
    )
    model = cfg.model or DEFAULT_MODEL
    messages = [{"role": "system", "content": build_system(request)}, *message_dicts(request)]

    try:
        completion = client.beta.chat.completions.parse(
            model=model,
            messages=messages,
            response_format=TutorTurn,
            max_tokens=1024,
        )
    except openai.AuthenticationError:
        raise HTTPException(status_code=401, detail="API key de OpenAI inválida.")
    except openai.RateLimitError:
        raise HTTPException(status_code=429, detail="Límite de OpenAI alcanzado, intenta luego.")
    except openai.APIConnectionError:
        raise HTTPException(status_code=502, detail="No se pudo conectar con OpenAI.")
    except openai.APIStatusError as e:
        logger.error(f"OpenAI API error {e.status_code}: {e.message}")
        raise HTTPException(status_code=502, detail="Error al contactar con OpenAI.")

    parsed = completion.choices[0].message.parsed
    if parsed is None:
        raise HTTPException(status_code=502, detail="OpenAI devolvió una respuesta inválida.")
    return parsed
