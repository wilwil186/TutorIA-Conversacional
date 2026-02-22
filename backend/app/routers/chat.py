from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
from app.models.content import ContentModel
from app.models.gec import GECModel
from app.models.generator import GeneratorModel
from loguru import logger
import os

router = APIRouter()

# Global model instances
content_model = None
gec_model = None
generator_model = None

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
    global content_model, gec_model, generator_model
    
    try:
        # Initialize content model
        content_model = ContentModel()
        
        # Initialize GEC model
        gec_model = GECModel()
        
        # Initialize generator model
        model_path = os.getenv("MISTRAL_MODEL_PATH", "models/mistral-7b-instruct-v0.2.Q4_K_M.gguf")
        if os.path.exists(model_path):
            generator_model = GeneratorModel(model_path)
        else:
            logger.warning(f"Generator model not found at {model_path}")
            generator_model = None
            
        logger.info("All models initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize models: {e}")

# Initialize models on module import
initialize_models()

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        if not content_model or not gec_model:
            raise HTTPException(status_code=503, detail="Models not initialized")
        
        # Get the last user message
        user_message = None
        for msg in reversed(request.messages):
            if msg.role == "user":
                user_message = msg.content
                break
        
        if not user_message:
            raise HTTPException(status_code=400, detail="No user message found")
        
        # Check if message is on topic
        is_on_topic = True
        if request.expected_topic:
            is_on_topic = content_model.is_on_topic(user_message, request.expected_topic)
        
        # Check for grammar errors
        grammar_errors = gec_model.predict_errors(user_message)
        
        # Generate response
        response_text = "Lo siento, el modelo generador no está disponible."
        if generator_model:
            messages_dict = [{"role": msg.role, "content": msg.content} for msg in request.messages]
            response_text = generator_model.generate_response(messages_dict)
        
        # Generate hint if there are errors
        hint = None
        if grammar_errors:
            error_types = [error["label"] for error in grammar_errors if error["label"] != "correct"]
            if error_types and generator_model:
                hint = generator_model.generate_hint(
                    error_types[0], 
                    user_message, 
                    request.scenario or ""
                )
        
        return ChatResponse(
            response=response_text,
            is_on_topic=is_on_topic,
            grammar_errors=grammar_errors,
            hint=hint
        )
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/models/status")
async def get_models_status():
    return {
        "content_model": content_model is not None,
        "gec_model": gec_model is not None,
        "generator_model": generator_model is not None
    }
