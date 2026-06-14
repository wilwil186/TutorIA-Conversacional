"""Pydantic schemas shared between the API layer and the tutor service.

`TutorTurn` doubles as the structured-output schema passed to the Claude API
(`messages.parse`), so keep every field describable by a JSON schema and give
each one a clear description — the model reads those descriptions.
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field

# CEFR levels the tutor adapts to.
CEFRLevel = Literal["A1", "A2", "B1", "B2", "C1", "C2"]


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str


# Which AI backend to use. "ollama" = local open-source (default, free);
# "anthropic"/"openai" = the user's own paid account.
Provider = Literal["ollama", "anthropic", "openai"]


class LLMConfig(BaseModel):
    provider: Provider
    model: Optional[str] = Field(None, description="Model name; provider default if omitted.")
    api_key: Optional[str] = Field(None, description="User's own key (anthropic/openai).")
    base_url: Optional[str] = Field(
        None,
        description="Override endpoint. For Ollama, the host URL; for OpenAI, an "
        "OpenAI-compatible base URL (Groq, OpenRouter, local server, ...).",
    )


class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(
        ..., description="Full conversation history; the API is stateless."
    )
    level: CEFRLevel = Field("A2", description="Student's target CEFR level.")
    scenario: Optional[str] = Field(
        None, description="Practice scenario title, e.g. 'At a restaurant'."
    )
    llm: Optional[LLMConfig] = Field(
        None, description="AI provider chosen by the user; falls back to server defaults."
    )


class Correction(BaseModel):
    original: str = Field(..., description="The exact erroneous fragment the student wrote.")
    corrected: str = Field(..., description="The corrected fragment in natural English.")
    explanation: str = Field(
        ...,
        description="Short explanation IN SPANISH of why it was wrong, suited to the student's level.",
    )
    category: Literal["grammar", "vocabulary", "spelling", "word_order", "punctuation"] = Field(
        ..., description="Type of mistake."
    )


class TutorTurn(BaseModel):
    """Structured result of one tutor turn (also the Claude output schema)."""

    reply: str = Field(
        ...,
        description="The tutor's conversational reply, IN ENGLISH, written at the student's CEFR level.",
    )
    is_on_topic: bool = Field(
        ...,
        description="Whether the student's last message stayed on the practice scenario.",
    )
    corrections: list[Correction] = Field(
        default_factory=list,
        description="Corrections for the student's last message. Empty if it was correct.",
    )
    grammar_tip: Optional[str] = Field(
        None,
        description="A short scaffolding hint IN SPANISH that nudges self-correction without giving the answer. Null if no mistakes.",
    )
    suggestions: list[str] = Field(
        default_factory=list,
        description="2-3 short, ready-to-use example replies IN ENGLISH (at the student's level) that the student could send next.",
    )
    estimated_level: Optional[CEFRLevel] = Field(
        None, description="CEFR level estimated from the student's last message."
    )


class Scenario(BaseModel):
    id: str
    title: str
    description: str
    expected_topic: str
