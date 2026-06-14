import os

from dotenv import load_dotenv

load_dotenv()  # must run before importing modules that read env at import time

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import chat, grammar

app = FastAPI(
    title="TutorIA Conversacional API",
    description="Backend para el tutor de inglés con IA (Claude)",
    version="2.0.0",
)

# Dev: open CORS so the Flutter app (desktop/web/device) can reach the API.
# In production, restrict allow_origins to known origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, prefix="/api", tags=["chat"])
app.include_router(grammar.router, prefix="/api", tags=["grammar"])


@app.get("/")
async def root():
    return {"message": "TutorIA Conversacional API is running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(
        app,
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8000")),
    )
