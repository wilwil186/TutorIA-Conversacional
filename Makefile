.PHONY: help install setup build run stop clean dev-backend \
        app-init dev-app app-linux app-web

# Default target
help:
	@echo "TutorIA Conversacional - Tutor de inglés con IA (Claude)"
	@echo ""
	@echo "Backend:"
	@echo "  install      - Crea venv e instala dependencias del backend"
	@echo "  setup        - Copia backend/.env.example -> backend/.env"
	@echo "  dev-backend  - Levanta el backend FastAPI (uvicorn --reload, :8000)"
	@echo "  build/run/stop/clean - Docker Compose (solo backend)"
	@echo ""
	@echo "App Flutter de escritorio (app/):"
	@echo "  app-init     - Genera el scaffolding (linux, web) y baja dependencias"
	@echo "  dev-app      - flutter run -d linux"
	@echo "  app-linux    - Compila la app de escritorio Linux"
	@echo "  app-web      - Compila la versión web"
	@echo ""

# ---- Backend ----------------------------------------------------------------

install:
	@echo "Instalando dependencias del backend..."
	cd backend && python3 -m venv venv && \
		. venv/bin/activate && \
		pip install --upgrade pip && \
		pip install -r requirements.txt

setup:
	cp backend/.env.example backend/.env
	@echo "Edita backend/.env y pon tu ANTHROPIC_API_KEY"

dev-backend:
	cd backend && . venv/bin/activate && \
		uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

build:
	docker-compose build

run:
	docker-compose up --build

stop:
	docker-compose down

clean:
	docker-compose down -v --rmi all

# ---- App Flutter ------------------------------------------------------------

# Generate the platform runner folders (linux/, web/) into app/
# without touching lib/ or pubspec.yaml, then fetch packages.
app-init:
	cd app && flutter create . --project-name tutoria \
		--platforms=linux,web && flutter pub get

dev-app:
	cd app && flutter run -d linux

app-linux:
	cd app && flutter build linux --release
	@echo "Binario: app/build/linux/x64/release/bundle/tutoria"

app-web:
	cd app && flutter build web --release
	@echo "Web: app/build/web/"
