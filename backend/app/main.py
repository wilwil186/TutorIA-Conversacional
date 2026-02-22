from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import chat
import uvicorn

app = FastAPI(
    title="Conversationally Desktop API",
    description="Backend API for AI language tutor",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(chat.router, prefix="/api", tags=["chat"])

@app.get("/")
async def root():
    return {"message": "Conversationally Desktop API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
