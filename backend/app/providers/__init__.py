"""Pluggable LLM providers.

`run_structured` is the single entry point: given an LLM config, a system prompt,
a message list, and a Pydantic output model, it returns a validated instance from
the chosen provider (ollama by default, or the user's Claude/OpenAI). Chat and
grammar both build on it.
"""

import os

from fastapi import HTTPException
from pydantic import BaseModel

from app.providers import anthropic_provider, ollama_provider, openai_provider
from app.providers.base import build_system, message_dicts
from app.schemas import ChatRequest, LLMConfig, TutorTurn

DEFAULT_PROVIDER = os.getenv("DEFAULT_PROVIDER", "ollama")

_PROVIDERS = {
    "ollama": ollama_provider.structured,
    "anthropic": anthropic_provider.structured,
    "openai": openai_provider.structured,
}

_OPENING = (
    "\n\nThe conversation is just starting and the student hasn't written anything yet. "
    "Greet them warmly in English at their level, briefly set the scene for the scenario, "
    "and ask ONE simple opening question. Return an empty corrections list and a null "
    "grammar_tip. Still provide `suggestions`."
)


def resolve_config(request: ChatRequest) -> LLMConfig:
    if request.llm is not None:
        return request.llm
    return LLMConfig(provider=DEFAULT_PROVIDER)  # type: ignore[arg-type]


def run_structured(
    cfg: LLMConfig, system: str, messages: list[dict], output_model: type[BaseModel]
) -> BaseModel:
    provider = _PROVIDERS.get(cfg.provider)
    if provider is None:
        raise HTTPException(status_code=400, detail=f"Proveedor desconocido: {cfg.provider}")
    return provider(cfg, system, messages, output_model)


def generate_turn(request: ChatRequest) -> TutorTurn:
    cfg = resolve_config(request)
    has_user = any(m.role == "user" for m in request.messages)

    if not has_user:
        # Opening turn: the tutor speaks first.
        system = build_system(request) + _OPENING
        messages = [{"role": "user", "content": "(start)"}]
    else:
        if request.messages[-1].role != "user":
            raise HTTPException(status_code=400, detail="Last message must be from the user.")
        system = build_system(request)
        messages = message_dicts(request)

    return run_structured(cfg, system, messages, TutorTurn)  # type: ignore[return-value]
