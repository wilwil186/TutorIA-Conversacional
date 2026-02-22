.PHONY: help install build run stop clean download-models test dev-backend dev-frontend

# Default target
help:
	@echo "Conversationally Desktop - Tutor de Idiomas con IA"
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  install      - Instala dependencias del backend"
	@echo "  build        - Construye las imágenes Docker"
	@echo "  run          - Ejecuta la aplicación con Docker Compose"
	@echo "  stop         - Detiene los contenedores Docker"
	@echo "  clean        - Limpia contenedores e imágenes Docker"
	@echo "  download-models - Descarga los modelos de IA necesarios"
	@echo "  test         - Ejecuta tests del backend"
	@echo "  dev-backend  - Ejecuta el backend en modo desarrollo"
	@echo "  dev-frontend - Sirve el frontend en modo desarrollo"
	@echo ""

# Install dependencies
install:
	@echo "Instalando dependencias del backend..."
	cd backend && python -m venv venv && \
		source venv/bin/activate && \
		pip install --upgrade pip && \
		pip install -r requirements.txt

# Build Docker images
build:
	@echo "Construyendo imágenes Docker..."
	docker-compose build

# Run the application
run:
	@echo "Iniciando Conversationally Desktop..."
	docker-compose up --build

# Stop the application
stop:
	@echo "Deteniendo contenedores..."
	docker-compose down

# Clean Docker resources
clean:
	@echo "Limpiando recursos Docker..."
	docker-compose down -v --rmi all

# Download AI models
download-models:
	@echo "Creando directorio de modelos..."
	mkdir -p models/sentence-transformer models/beto-gec
	@echo "Descargando modelo de Sentence Transformers..."
	@echo "Este modelo se descargará automáticamente al iniciar el backend"
	@echo ""
	@echo "Para descargar Mistral 7B manualmente:"
	@echo "wget -O models/mistral-7b-instruct-v0.2.Q4_K_M.gguf https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"

# Run tests
test:
	@echo "Ejecutando tests..."
	cd backend && python -m pytest tests/ -v

# Development backend
dev-backend:
	@echo "Iniciando backend en modo desarrollo..."
	cd backend && source venv/bin/activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Development frontend (simple HTTP server)
dev-frontend:
	@echo "Iniciando frontend en modo desarrollo..."
	cd frontend && python3 -m http.server 3000

# Setup environment
setup:
	@echo "Configurando entorno..."
	cp backend/.env.example backend/.env
	@echo "Por favor, edita backend/.env con tu configuración"

# Check system requirements
check:
	@echo "Verificando requisitos del sistema..."
	@python3 --version
	@docker --version
	@docker-compose --version
	@echo ""
	@echo "Memoria disponible:"
	@free -h
	@echo ""
	@echo "Espacio en disco:"
	@df -h .
