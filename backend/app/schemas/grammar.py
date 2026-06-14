"""Schemas for the grammar practice section (capsules + exercises).

`GrammarLesson` is also the structured-output schema sent to the LLM, so its
fields carry descriptions the model reads.
"""

from pydantic import BaseModel, Field

from app.schemas.chat import CEFRLevel, LLMConfig


class GrammarTopic(BaseModel):
    id: str
    title_es: str  # shown to the student (Spanish)
    name_en: str   # the English grammar concept
    cefr: CEFRLevel


class GrammarExample(BaseModel):
    english: str = Field(..., description="Example sentence in English.")
    spanish: str = Field(..., description="Its Spanish translation.")


class GrammarExercise(BaseModel):
    prompt: str = Field(
        ...,
        description="A fill-in-the-blank or transform task in English, using '___' for the blank.",
    )
    answer: str = Field(..., description="The expected answer (just the missing word/phrase).")
    hint: str = Field(..., description="A short hint IN SPANISH.")


class GrammarLesson(BaseModel):
    title: str = Field(..., description="Short lesson title in Spanish.")
    explanation: str = Field(
        ...,
        description="Clear, short explanation of the grammar point IN SPANISH, suited to the level.",
    )
    examples: list[GrammarExample] = Field(..., description="2-4 example sentences.")
    exercises: list[GrammarExercise] = Field(
        ..., description="3-5 short practice exercises with answers."
    )


class GrammarLessonRequest(BaseModel):
    topic_id: str
    level: CEFRLevel = "A2"
    llm: LLMConfig | None = None
