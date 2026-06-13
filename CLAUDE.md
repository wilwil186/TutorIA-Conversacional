# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**TutorIA Conversacional** is a Duolingo-style **English** tutor for Spanish-speaking students. A **Flutter desktop** app (Linux + web from one codebase; mobile/Android intentionally dropped) talks to a **FastAPI** backend that calls a **pluggable LLM provider**: local open-source via **Ollama** (default, free) or the user's own **Claude**/**OpenAI** account. The student picks a CEFR level (A1–C2) and a practice scenario, chats in English, and gets per-message corrections plus a grammar tip.

> History: the repo began as a local-model **Spanish** tutor (Sentence-Transformers + BETO + Mistral), briefly used Ollama, and was fully rewritten (v2) to the Flutter + Claude architecture described here. If you find references to Ollama, BETO, Mistral, `models/`, or a static `index.html`, they are stale — that stack was removed.

## Architecture

The app is a thin client; the LLM runs behind the backend. Each chat turn is **one LLM call** that returns a structured `TutorTurn` (reply + corrections + grammar tip), so the Flutter client consumes it directly.

```
Flutter app (app/) ──HTTP──> FastAPI (backend/) ──> provider: ollama | anthropic | openai
  level + scenario + history       /api/chat              structured output (TutorTurn)
  + optional llm config (provider, model, api_key)
```

**Provider selection:** the app's Settings screen lets the user pick the provider; it's sent per request as `llm` in the chat body. If absent, the backend falls back to `DEFAULT_PROVIDER` (default `ollama`). Open-source (Ollama) runs on the same machine as the backend.

**Deployment model:** desktop — the user runs the backend, the app, and (for the free path) Ollama all on the same machine; the app talks to `localhost:8000`. API keys live in the backend env **or** are supplied by the user per request (their own key, stored only on their device); no key is baked into the app.

### Backend (`backend/app/`)
- `main.py` — FastAPI app. `load_dotenv()` runs **first**, before importing routers. CORS is open in dev.
- `routers/chat.py` — `POST /api/chat` (body: `messages`, `level`, `scenario`, optional `llm`) → `TutorTurn`; `GET /api/scenarios`; `GET /health`.
- `providers/` — the LLM layer. `__init__.py` holds `generate_turn(request)`: validates the last message is the user's, resolves the `LLMConfig` (from `request.llm` or `DEFAULT_PROVIDER`), and dispatches to one of:
  - `ollama_provider.py` — local open-source (default). Structured output via Ollama's `format=<json schema>` (needs Ollama ≥ 0.5); parses with `TutorTurn.model_validate_json`. Clean 503s when the daemon is down or the model isn't pulled.
  - `anthropic_provider.py` — Claude via `messages.parse(output_format=TutorTurn)`. Key from `cfg.api_key` or `ANTHROPIC_API_KEY`.
  - `openai_provider.py` — OpenAI (or any OpenAI-compatible `base_url`) via `beta.chat.completions.parse(response_format=TutorTurn)`.
  - `base.py` — shared `SYSTEM_BASE` prompt + `build_system`/`message_dicts` helpers used by all three.
  - Each provider imports its SDK **lazily** inside `generate()`, so an unused provider's SDK never has to be importable. Errors are mapped to `HTTPException` with Spanish messages.
- `schemas/chat.py` — Pydantic models. **`TutorTurn` is both the API response and the structured-output schema for every provider**, so each field needs a JSON-schema-expressible type and a clear `description` (the model reads them). Correction explanations and the grammar tip are intentionally in **Spanish**; the `reply` is in English. `LLMConfig` carries `provider`/`model`/`api_key`/`base_url`.
- `scenarios.py` — static scenario catalog.

SDK requirements: `anthropic` (with `messages.parse`), `openai` (with `beta.chat.completions.parse`), `ollama` (with schema `format`). The pre-existing `backend/venv` predates these; `pip install -r requirements.txt` upgrades it.

### App (`app/`, Flutter)
- `lib/config.dart` — `Config.baseUrl`, persisted via `shared_preferences`; defaults to `http://localhost:8000`, editable in Settings.
- `lib/models.dart` — mirrors the backend JSON (`TutorTurn`, `Correction`, `Scenario`, `ChatMessage`).
- `lib/api.dart` — HTTP client for `/api/chat` and `/api/scenarios`.
- `lib/screens/` — `level_screen` (onboarding) → `scenarios_screen` → `chat_screen`; plus `settings_screen` (provider + per-provider model/key, backend URL, level). `lib/widgets/feedback_card.dart` renders corrections (strikethrough → fix) and the tip.
- `lib/storage.dart` — persists level + provider config (model/key stored per-provider); `getLlmConfig()` builds the `llm` sent with each chat request.
- State is plain `setState`/`FutureBuilder` (no state-management package). Deps: `http`, `shared_preferences` only.
- Platforms: only `app/linux/` and `app/web/` exist (Android removed). They're committed so a fresh clone builds without regeneration; `make app-init` (runs `flutter create . --platforms=linux,web`) recreates them if needed. The hand-written source is `lib/` + `pubspec.yaml`.

## Commands

```bash
# Backend
make install        # venv + pip install (also upgrades anthropic)
make setup          # backend/.env.example -> backend/.env  (then add ANTHROPIC_API_KEY)
make dev-backend    # uvicorn --reload on :8000

# App (needs Flutter SDK; not installed by default in this repo)
make app-init       # (re)generate linux/web scaffolding + flutter pub get
make dev-app        # flutter run -d linux
make app-linux      # -> app/build/linux/x64/release/bundle/tutoria  (needs clang cmake ninja-build libgtk-3-dev)
make app-web        # -> app/build/web/
```

There is **no automated test suite or linter config for the backend** yet, and no CI. The app uses `flutter_lints` via `app/analysis_options.yaml`.

### Manual end-to-end check
```bash
cd backend && . venv/bin/activate && uvicorn app.main:app --port 8000
# Open source (needs `ollama serve` + a pulled model):
curl -X POST localhost:8000/api/chat -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"I goed to the park yesterday"}],"level":"A2","scenario":"Small talk","llm":{"provider":"ollama","model":"qwen2.5:7b"}}'
# Or Claude/OpenAI by swapping llm: {"provider":"anthropic","api_key":"sk-..."}.
# Expect JSON with reply, a correction (goed -> went), and a grammar_tip.
```

## Conventions
- Logging is `loguru` in the backend.
- Config via `os.getenv` + `backend/.env` (see `.env.example`); `python-dotenv` loads it.
- When changing the chat contract, keep these in sync: `backend/app/schemas/chat.py`, `app/lib/models.dart`, and the shared prompt in `backend/app/providers/base.py`. Adding a provider = one file in `backend/app/providers/` + a `Provider` enum entry in both `schemas/chat.py` and `app/lib/models.dart`.
- All learner-facing English (the `reply`) stays at the requested CEFR level; feedback (explanations, tips) stays in Spanish.

## Not yet built (roadmap)
Voice/pronunciation, a placement test (`/api/placement`), progress persistence/DB, public backend deployment, and streaming replies. See `/home/wilson/.claude/plans/okey-explciame-que-es-twinkly-gadget.md`.
