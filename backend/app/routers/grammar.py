from fastapi import APIRouter

from app.grammar import generate_lesson, topics_for_level
from app.schemas import CEFRLevel, GrammarLesson, GrammarLessonRequest, GrammarTopic

router = APIRouter()


@router.get("/grammar/topics", response_model=list[GrammarTopic])
async def grammar_topics(level: CEFRLevel = "A2") -> list[GrammarTopic]:
    return topics_for_level(level)


@router.post("/grammar/lesson", response_model=GrammarLesson)
async def grammar_lesson(request: GrammarLessonRequest) -> GrammarLesson:
    return generate_lesson(request)
