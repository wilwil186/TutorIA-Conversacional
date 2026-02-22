# 🧗 Desafíos Técnicos y Consideraciones

Este documento detalla los principales desafíos técnicos encontrados durante la adaptación de Conversationally para ejecución local y las soluciones implementadas.

## 1. 🧠 Modelos Pesados en Local

### Desafío
Los modelos de IA originales estaban diseñados para ejecutarse en la nube con hardware potente:

- **Mistral 7B**: Requiere ~8 GB RAM en versión cuantizada
- **BETO fine-tuned**: No disponible públicamente, requiere entrenamiento propio
- **Sentence Transformers**: Relativamente ligero pero requiere descarga inicial

### Soluciones Implementadas

#### Mistral 7B
```python
# Usamos llama-cpp-python para modelos GGUF cuantizados
from llama_cpp import Llama

self.model = Llama(
    model_path=model_path,
    n_ctx=2048,
    n_threads=4,
    n_gpu_layers=0  # CPU-only por defecto
)
```

**Ventajas:**
- Reducción del uso de memoria con cuantización Q4_K_M (~4.7 GB)
- Soporte para CPU sin requerir GPU
- Inferencia razonablemente rápida

#### Modelo GEC
```python
# Usamos BETO base como fallback
from transformers import AutoModelForTokenClassification

self.model = AutoModelForTokenClassification.from_pretrained(
    "dccuchile/bert-base-spanish-wwm-cased"
)
```

**Limitaciones:**
- No está fine-tuned para corrección gramatical específica
- Requiere entrenamiento adicional con dataset COWS-L2H

## 2. ⚡ Orquestación de Modelos en Tiempo Real

### Desafío
Coordinar tres modelos diferentes sin afectar la experiencia del usuario:

- Latencia acumulada puede superar los 10 segundos
- Manejo concurrente de múltiples usuarios
- Uso eficiente de memoria

### Soluciones

#### Carga Lazy y Singleton
```python
# Modelos cargados una sola vez al iniciar
class ModelManager:
    _instances = {}
    
    @classmethod
    def get_model(cls, model_type):
        if model_type not in cls._instances:
            cls._instances[model_type] = cls._load_model(model_type)
        return cls._instances[model_type]
```

#### Async/Await para I/O
```python
@app.post("/chat")
async def chat(request: ChatRequest):
    # Procesamiento paralelo donde sea posible
    similarity_task = asyncio.create_task(check_similarity(user_message))
    errors_task = asyncio.create_task(detect_errors(user_message))
    
    is_on_topic = await similarity_task
    grammar_errors = await errors_task
```

#### Caché de Respuestas
```python
# Cache LRU para respuestas comunes
from functools import lru_cache

@lru_cache(maxsize=100)
def generate_scenario_response(scenario: str, user_input_hash: str):
    # Generar respuesta solo si no está en caché
    pass
```

## 3. 💾 Mantenimiento de Estado Conversacional

### Desafío
El sistema necesita mantener contexto de la conversación:

- Historial de mensajes para contexto
- Estado del escenario seleccionado
- Progreso del usuario

### Implementación

#### Estructura de Mensajes
```python
class ConversationState:
    def __init__(self):
        self.messages = []
        self.scenario = None
        self.expected_topic = None
        self.error_count = 0
    
    def add_message(self, role: str, content: str):
        self.messages.append({"role": role, "content": content})
        # Mantener solo últimos 20 mensajes para limitar contexto
        if len(self.messages) > 20:
            self.messages = self.messages[-20:]
```

#### Manejo de Sesiones
```python
# Para futura implementación multi-usuario
session_store = {}

@app.post("/chat")
async def chat(request: ChatRequest, session_id: str = None):
    if session_id and session_id in session_store:
        state = session_store[session_id]
    else:
        state = ConversationState()
        session_id = str(uuid.uuid4())
        session_store[session_id] = state
```

## 4. 🌐 Adaptación Multilingüe

### Desafío
El proyecto original se enfoca en español, pero los modelos soportan múltiples idiomas.

### Solución Arquitectónica
```python
class LanguageConfig:
    LANGUAGES = {
        "es": {
            "content_model": "paraphrase-multilingual-MiniLM-L12-v2",
            "gec_model": "dccuchile/bert-base-spanish-wwm-cased",
            "generator_prompt": "Eres un tutor de español..."
        },
        "en": {
            "content_model": "paraphrase-multilingual-MiniLM-L12-v2",
            "gec_model": "bert-base-uncased",
            "generator_prompt": "You are an English tutor..."
        }
    }
```

## 5. 🔧 Optimización de Recursos

### Memoria
- **Modelos cargados una sola vez**: Patrones Singleton
- **Liberación de memoria no utilizada**: `torch.cuda.empty_cache()`
- **Cuantización**: Modelos GGUF para reducir uso de RAM

### CPU
- **Procesamiento paralelo**: `asyncio` para I/O
- **Batch processing**: Procesar múltiples tokens simultáneamente
- **Thread pools**: Para operaciones CPU-intensivas

### Disco
- **Modelos comprimidos**: GGUF vs formatos originales
- **Lazy loading**: Descargar modelos solo cuando se necesitan
- **Cache local**: Evitar descargas repetidas

## 6. 🐛 Debugging y Monitoreo

### Logging Estructurado
```python
from loguru import logger

logger.info("Processing chat request", extra={
    "user_id": session_id,
    "scenario": scenario,
    "message_length": len(user_message)
})
```

### Métricas de Rendimiento
```python
import time

def measure_time(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        duration = time.time() - start
        logger.info(f"{func.__name__} completed in {duration:.2f}s")
        return result
    return wrapper
```

### Health Checks
```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "models": {
            "content": content_model is not None,
            "gec": gec_model is not None,
            "generator": generator_model is not None
        },
        "memory": psutil.virtual_memory()._asdict()
    }
```

## 7. 🔮 Mejoras Futuras

### Corto Plazo
- [ ] Implementar modelo GEC fine-tuned real
- [ ] Añadir soporte para más escenarios
- [ ] Mejorar la UI para mostrar errores gramaticales
- [ ] Optimizar tiempo de respuesta

### Mediano Plazo
- [ ] Soporte para múltiples idiomas
- [ ] Sistema de persistencia de sesiones
- [ ] Métricas de progreso del usuario
- [ ] Integración con modelos locales más pequeños

### Largo Plazo
- [ ] Interfaz de escritorio nativa (Electron/Tauri)
- [ ] Modo offline completo
- [ ] Personalización adaptativa del tutor
- [ ] Exportación de progreso y estadísticas

## 📚 Referencias Técnicas

- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python) - Bindings Python para llama.cpp
- [Sentence Transformers](https://www.sbert.net/) - Embeddings multilingües
- [FastAPI](https://fastapi.tiangolo.com/) - Backend async Python
- [Docker](https://www.docker.com/) - Contenerización
- [COWS-L2H Dataset](https://github.com/chrisjbryant/errant) - Dataset para GEC en español

---

**Nota**: Este documento evolucionará con el proyecto. Contribuciones y sugerencias son bienvenidas.
