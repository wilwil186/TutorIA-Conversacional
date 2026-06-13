"""Pluggable LLM providers.

Each provider turns a ChatRequest into a structured `TutorTurn`. Selection is
driven by the request's `llm` config, falling back to server env defaults, so
the end user can run free local open-source models (Ollama) by default and
optionally plug in their own Claude / OpenAI account.
"""

import os

from fastapi import HTTPException

from app.providers import anthropic_provider, ollama_provider, openai_provider
from app.schemas import ChatRequest, LLMConfig, TutorTurn

# Default provider when the request carries no `llm` config.
DEFAULT_PROVIDER = os.getenv("DEFAULT_PROVIDER", "ollama")

_GENERATORS = {
    "ollama": ollama_provider.generate,
    "anthropic": anthropic_provider.generate,
    "openai": openai_provider.generate,
}


def _resolve_config(request: ChatRequest) -> LLMConfig:
    if request.llm is not None:
        return request.llm
    return LLMConfig(provider=DEFAULT_PROVIDER)  # type: ignore[arg-type]


def generate_turn(request: ChatRequest) -> TutorTurn:
    if not request.messages or request.messages[-1].role != "user":
        raise HTTPException(status_code=400, detail="Last message must be from the user.")

    cfg = _resolve_config(request)
    generator = _GENERATORS.get(cfg.provider)
    if generator is None:
        raise HTTPException(status_code=400, detail=f"Proveedor desconocido: {cfg.provider}")
    return generator(request, cfg)
