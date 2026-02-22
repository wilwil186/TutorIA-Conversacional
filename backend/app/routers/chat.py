from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
from app.models.ollama_client import OllamaModel
from loguru import logger
import os

router = APIRouter()

ollama_model = None


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    scenario: Optional[str] = None
    expected_topic: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    is_on_topic: bool
    grammar_errors: List[Dict]
    hint: Optional[str] = None


def initialize_models():
    global ollama_model
    try:
        model_name = os.getenv("OLLAMA_MODEL", "mistral:latest")
        ollama_model = OllamaModel(model_name)
        logger.info("Ollama model initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Ollama model: {e}")
        raise


initialize_models()


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        if not ollama_model:
            raise HTTPException(status_code=503, detail="Model not initialized")

        user_message = None
        for msg in reversed(request.messages):
            if msg.role == "user":
                user_message = msg.content
                break

        if not user_message:
            raise HTTPException(status_code=400, detail="No user message found")

        is_on_topic = True
        if request.expected_topic:
            is_on_topic = ollama_model.check_topic(user_message, request.expected_topic)

        grammar_errors = ollama_model.analyze_grammar(user_message)

        messages_dict = [
            {"role": msg.role, "content": msg.content} for msg in request.messages
        ]
        response_text = ollama_model.chat(messages_dict)

        hint = None
        if grammar_errors:
            error_types = [error.get("label", "error") for error in grammar_errors]
            if error_types:
                hint = ollama_model.generate_hint(
                    error_types[0], user_message, request.scenario or ""
                )

        return ChatResponse(
            response=response_text,
            is_on_topic=is_on_topic,
            grammar_errors=grammar_errors,
            hint=hint,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/models/status")
async def get_models_status():
    return {"ollama_model": ollama_model is not None}
