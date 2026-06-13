# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

TutorIA Conversacional (a.k.a. "Conversationally Desktop") is a local-first Spanish-language conversational tutor. A FastAPI backend orchestrates NLP models and a static HTML frontend provides the chat UI. The app is a local Debian/Linux adaptation of UC Berkeley's `team-langbot/conversationally`. **All user-facing text, prompts, and most comments are in Spanish — keep new strings in Spanish.**

For each user message the backend produces three things:
1. **On-topic check** — is the message related to the lesson's `expected_topic`?
2. **Grammar error detection (GEC)** — gender/number concordance errors, per token.
3. **A tutor reply** plus an optional **hint (scaffolding)** that nudges the student to self-correct without giving the answer.

## Commands

Run from the repo root unless noted. The Makefile help text is Spanish; key targets:

```bash
make install        # create backend/venv and pip install requirements
make dev-backend    # uvicorn app.main:app --reload on :8000 (needs venv active)
make dev-frontend   # python3 -m http.server 3000 in frontend/
make run            # docker-compose up --build (backend :8000 + nginx frontend :3000)
make test           # pytest backend/tests/ -v  -- NOTE: no tests/ dir exists yet
make download-models
```

Backend directly (matches GUIA.md):
```bash
cd backend && source venv/bin/activate
OLLAMA_MODEL=mistral:latest uvicorn app.main:app --host 0.0.0.0 --port 8000
```

There is **no test suite, linter config, or CI** yet (a `.ruff_cache/` exists but no ruff config). `make test` will fail until `backend/tests/` is created. The single API endpoint is `POST /api/chat`; `GET /api/models/status` reports which models loaded; `GET /health` is the Docker healthcheck.

## Architecture

### Backend (`backend/app/`)
- `main.py` — FastAPI app, CORS locked to `http://localhost:3000`, mounts `routers/chat.py` under `/api`.
- `routers/chat.py` — the entire request pipeline. Models are **module-level globals initialized eagerly** via `initialize_models()` called at import time, so model loading happens (and can block/fail) the moment the router is imported, not per-request. The `/api/chat` handler extracts the last user message, runs the on-topic check, GEC, response generation, and hint generation in sequence.
- `models/` — one class per model, each loading its weights in `__init__` and logging via `loguru`.

### The two generation backends (important — repo is mid-migration)
There are **two competing implementations** of the model layer, and HEAD vs. the working tree disagree about which is active:

- **Ollama path** (`models/ollama_client.py`, `OllamaModel`): a single LLM (default `mistral:latest` / `llama3.1:70b` via env `OLLAMA_MODEL`) does everything — chat, `analyze_grammar` (JSON out), `generate_hint`, `check_topic`. This is what the **committed** `chat.py`, `docker-compose.yml`, and `GUIA.md` use. Requires a running Ollama daemon (`ollama serve`); Docker reaches it via `host.docker.internal:11434`.
- **Local three-model path** (`models/content.py`, `gec.py`, `generator.py`): the **current working-tree** `chat.py` imports these instead.
  - `ContentModel` — Sentence Transformers (`paraphrase-multilingual-MiniLM-L12-v2`), cosine similarity ≥ threshold (0.3) for on-topic.
  - `GECModel` — Spanish BERT/BETO (`dccuchile/bert-base-spanish-wwm-cased`) token classification → `correct` / `gender_error` / `number_error` / `other_error`. **It uses the base BETO model, which is not fine-tuned for GEC, so predictions are not meaningful yet.**
  - `GeneratorModel` — *named* for Mistral 7B GGUF (`MISTRAL_MODEL_PATH`) but currently a **rule-based keyword stub** that returns canned Spanish replies; it does not load `llama-cpp-python` despite the dependency being declared.

When editing the pipeline, first check which backend `routers/chat.py` currently imports and keep `requirements.txt`, `docker-compose.yml`, and the env vars consistent with that choice (e.g. the working tree dropped `ollama` from requirements while `ollama_client.py` still imports it).

### Frontend (`frontend/`)
A **single static `index.html`** (vanilla JS calling the API) served by nginx (`nginx.conf`) or `http.server` — despite the README's "React" / `langbot-ui` description, there is no React build, `package.json`, or node tooling. There's a second copy of `index.html` at the repo root.

### Models on disk (`models/`)
Populated by `backend/scripts/download_models.py` (interactive; prompts before the ~4.7GB Mistral GGUF download). Sentence-Transformers and BETO auto-download from Hugging Face on first backend start. `models/`, `backend/venv/`, and `backend/.env` are gitignored.

## Conventions
- Logging is `loguru` everywhere (`from loguru import logger`); follow that rather than the stdlib `logging`.
- Config comes from environment variables read with `os.getenv(...)` and defaults (see `backend/.env.example`); copy it to `.env` via `make setup`.
- API contracts are Pydantic models defined inline in `routers/chat.py` (`ChatMessage`, `ChatRequest`, `ChatResponse`).
