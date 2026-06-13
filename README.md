# 🗣️ TutorIA Conversacional

Tutor de **inglés** estilo Duolingo para hispanohablantes. Conversas en inglés según tu
nivel del **Marco Común Europeo (A1–C2)** y la app te corrige y te da consejos de gramática
en español.

Es una **app de escritorio para Linux/Debian**. La IA puede ser:

- 🟢 **Open source (gratis)** con **Ollama**, corriendo en tu propia máquina, o
- 🔵 **Claude** u **OpenAI**, usando **tu propia cuenta y tu propia API key** (tú pagas el consumo).

La app nunca trae claves incrustadas: o usas Ollama (gratis) o pones tu key en la pantalla de Ajustes.

---

## 🧩 Cómo funciona

```
App de escritorio (Flutter)  ──HTTP──►  Backend (FastAPI)  ──►  Ollama | Claude | OpenAI
   localhost:8000                          /api/chat
```

Todo corre en tu máquina: el backend, la app y (para el modo gratis) Ollama.

---

## ✅ Requisitos

- Linux Debian/Ubuntu (probado en Debian 13).
- **Python 3.10+**
- **Flutter SDK** (para compilar la app de escritorio) — https://docs.flutter.dev/get-started/install/linux
- Paquetes de escritorio para compilar en Linux:
  ```bash
  sudo apt install -y clang cmake ninja-build libgtk-3-dev pkg-config
  ```
- Para el modo **gratis**: **Ollama** instalado (https://ollama.com).
- Para el modo **Claude/OpenAI**: una API key tuya (opcional).

---

## 🚀 Instalación paso a paso

### 1. Clonar el proyecto
```bash
git clone https://github.com/wilwil186/TutorIA-Conversacional.git
cd TutorIA-Conversacional
```

### 2. Elegir el motor de IA

**Opción gratis (Ollama):** instala Ollama y descarga un modelo (recomendado un modelo de
instrucciones de buen tamaño):
```bash
ollama pull qwen2.5:7b      # ~4.7 GB
ollama serve                # deja Ollama corriendo
```

**Opción Claude/OpenAI:** no necesitas instalar nada aquí; pondrás tu API key dentro de la
app (pantalla de **Ajustes**). El consumo se cobra a tu cuenta.

### 3. Levantar el backend
```bash
make install        # crea el entorno e instala dependencias del backend
make setup          # crea backend/.env (puedes dejarlo como está para usar Ollama)
make dev-backend    # backend en http://localhost:8000
```
Déjalo corriendo en esa terminal.

> Por defecto el backend usa Ollama con el modelo `llama3.1`. Si descargaste otro modelo,
> edita `OLLAMA_MODEL` en `backend/.env` (p. ej. `OLLAMA_MODEL=qwen2.5:7b`) o elige el modelo
> en la pantalla de Ajustes de la app.

### 4. Compilar y abrir la app de escritorio (en otra terminal)
```bash
make app-init       # prepara el proyecto Flutter (linux, web) la primera vez
make app-linux      # compila el ejecutable
./app/build/linux/x64/release/bundle/tutoria
```
O, para desarrollo, simplemente:
```bash
make dev-app        # flutter run -d linux
```

---

## 📱 Uso

1. Abre la app y elige tu **nivel** (A1–C2).
2. Elige un **escenario** (restaurante, viajes, entrevista de trabajo…).
3. Escribe en inglés. El tutor te responde en inglés a tu nivel y, debajo de tu mensaje,
   te muestra las **correcciones** (lo que escribiste → lo correcto) y un **consejo** de gramática.
4. En **Ajustes** puedes cambiar el motor de IA:
   - **Open source (gratis)** → usa tu Ollama local.
   - **Claude / OpenAI** → pega tu API key (se guarda solo en este equipo).

---

## 🧠 Modelos

| Motor | Coste | Dónde corre | Calidad de correcciones |
|-------|-------|-------------|--------------------------|
| Ollama (open source) | Gratis | Tu máquina | Buena con modelos 7B+; mejora con modelos más grandes |
| Claude (tu cuenta) | Por uso | Nube de Anthropic | La más alta |
| OpenAI (tu cuenta) | Por uso | Nube de OpenAI | Alta |

---

## 🗂️ Estructura

```
TutorIA-Conversacional/
├── backend/            # FastAPI + capa de proveedores (Ollama/Claude/OpenAI)
│   └── app/
│       ├── providers/  # ollama_provider, anthropic_provider, openai_provider, base
│       ├── routers/     # /api/chat, /api/scenarios, /health
│       └── schemas/     # modelos Pydantic (TutorTurn, Correction, LLMConfig)
├── app/                # app de escritorio Flutter (lib/ = código; linux/, web/)
├── Makefile            # comandos (ver `make help`)
└── docker-compose.yml  # backend en contenedor (opcional)
```

## 🛠️ Comandos útiles
```bash
make help          # lista todos los comandos
make dev-backend   # backend en :8000
make app-linux     # compila la app de escritorio
make app-web       # compila la versión web (opcional)
```

---

## ✨ Roadmap
- Voz / pronunciación.
- Test de nivel automático.
- Guardar progreso y errores frecuentes.

> El proyecto partió de una adaptación del tutor **Conversationally** (UC Berkeley) y fue
> reescrito como tutor de inglés multi-proveedor.
