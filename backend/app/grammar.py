"""Grammar capsules: a static topic catalog + an AI-generated lesson per topic."""

from fastapi import HTTPException

from app.providers import resolve_config, run_structured
from app.schemas import GrammarLesson, GrammarLessonRequest, GrammarTopic

# Curated catalog. Each topic's lesson content is generated on demand by the LLM.
TOPICS: list[GrammarTopic] = [
    GrammarTopic(id="verb_to_be", title_es="El verbo «to be»", name_en="the verb 'to be' (am/is/are)", cefr="A1"),
    GrammarTopic(id="articles", title_es="Artículos a / an / the", name_en="articles a, an, the", cefr="A1"),
    GrammarTopic(id="plurals", title_es="Plurales", name_en="regular and irregular plural nouns", cefr="A1"),
    GrammarTopic(id="present_simple", title_es="Presente simple", name_en="present simple tense", cefr="A1"),
    GrammarTopic(id="past_simple", title_es="Pasado simple", name_en="past simple (regular and irregular verbs)", cefr="A2"),
    GrammarTopic(id="present_continuous", title_es="Presente continuo", name_en="present continuous tense", cefr="A2"),
    GrammarTopic(id="comparatives", title_es="Comparativos y superlativos", name_en="comparatives and superlatives", cefr="A2"),
    GrammarTopic(id="prepositions_place", title_es="Preposiciones de lugar", name_en="prepositions of place (in, on, at, under...)", cefr="A2"),
    GrammarTopic(id="present_perfect", title_es="Presente perfecto", name_en="present perfect tense", cefr="B1"),
    GrammarTopic(id="first_conditional", title_es="Primer condicional", name_en="the first conditional", cefr="B1"),
    GrammarTopic(id="future", title_es="Futuro: will / going to", name_en="future with 'will' and 'going to'", cefr="B1"),
    GrammarTopic(id="passive", title_es="La voz pasiva", name_en="the passive voice", cefr="B2"),
    GrammarTopic(id="reported_speech", title_es="Estilo indirecto", name_en="reported (indirect) speech", cefr="B2"),
    GrammarTopic(id="conditionals_23", title_es="Segundo y tercer condicional", name_en="the second and third conditionals", cefr="B2"),
    GrammarTopic(id="relative_clauses", title_es="Oraciones de relativo", name_en="relative clauses", cefr="C1"),
    GrammarTopic(id="modals_deduction", title_es="Modales de deducción", name_en="modal verbs of deduction (must, might, can't)", cefr="C1"),
    GrammarTopic(id="inversion", title_es="Inversión enfática", name_en="inversion for emphasis", cefr="C2"),
]

_ORDER = {lvl: i for i, lvl in enumerate(["A1", "A2", "B1", "B2", "C1", "C2"])}
_BY_ID = {t.id: t for t in TOPICS}


def topics_for_level(level: str) -> list[GrammarTopic]:
    """Topics at or below the student's level (cumulative)."""
    ceiling = _ORDER.get(level, 1)
    return [t for t in TOPICS if _ORDER[t.cefr] <= ceiling]


def generate_lesson(request: GrammarLessonRequest) -> GrammarLesson:
    topic = _BY_ID.get(request.topic_id)
    if topic is None:
        raise HTTPException(status_code=404, detail="Tema de gramática desconocido.")

    system = (
        "You are an English grammar teacher for Spanish-speaking students. "
        f"Produce a short, clear grammar capsule about {topic.name_en}, "
        f"calibrated to CEFR level {request.level}.\n"
        "STRICT language rules:\n"
        "- IN SPANISH: `title`, `explanation`, every `hint`, and the `spanish` field of examples.\n"
        "- IN ENGLISH: the `english` field of examples, and BOTH the `prompt` and the `answer` "
        "of every exercise. The answer is an ENGLISH word/phrase — never Spanish.\n"
        "Content rules:\n"
        "- `examples`: 2-4 short English sentences, each with its Spanish translation.\n"
        "- `exercises`: 3-5 fill-in-the-blank items. Each `prompt` is an ENGLISH sentence with "
        "'___' where the missing English word goes; `answer` is ONLY that missing English "
        "word/phrase (e.g. prompt 'She ___ dinner last night.' -> answer 'ate').\n"
        "Make each exercise unambiguous so a single English answer is clearly correct."
    )
    messages = [{"role": "user", "content": f"Create the grammar capsule about {topic.name_en}."}]
    cfg = resolve_config(request)  # type: ignore[arg-type]
    return run_structured(cfg, system, messages, GrammarLesson)  # type: ignore[return-value]
