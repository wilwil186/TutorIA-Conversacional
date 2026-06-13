from fastapi import APIRouter

from app.providers import generate_turn
from app.scenarios import SCENARIOS
from app.schemas import ChatRequest, Scenario, TutorTurn

router = APIRouter()


@router.get("/scenarios", response_model=list[Scenario])
async def list_scenarios() -> list[Scenario]:
    return SCENARIOS


@router.post("/chat", response_model=TutorTurn)
async def chat(request: ChatRequest) -> TutorTurn:
    return generate_turn(request)
