# TutorIA Conversacional - Guía de Uso

## Requisitos

- Ollama instalado y funcionando
- Python 3.10+
- ~8GB de RAM libre (para el modelo mistral)

## Ejecución

### 1. Iniciar Ollama

```bash
ollama serve
```

### 2. Iniciar el Backend

```bash
cd TutorIA-Conversacional/backend
source venv/bin/activate
OLLAMA_MODEL=mistral:latest uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 3. Iniciar el Frontend

```bash
cd TutorIA-Conversacional
python3 -m http.server 3000
```

### 4. Acceder a la App

Abre en tu navegador: **http://localhost:3000**

## Notas

- El modelo por defecto es `mistral:latest` (~4GB)
- Si tienes más RAM disponible, puedes usar `ollama list` para ver otros modelos disponibles
- El backend debe estar corriendo antes de abrir el frontend
