# backend/main.py

import uvicorn
from fastapi import FastAPI
from app.api.routes import router as api_router

# Initialize App (BFF Layer)
app = FastAPI(
    title="Gemini Life Planner Orchestrator",
    version="1.0.0",
    description="Implementation of ISDD v2.0"
)

# Register Routes
app.include_router(api_router, prefix="/api")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)