# backend/main.py
# FastAPI Application Entry Point

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.api.routes import router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI application
app = FastAPI(
    title="Gemini Life Planner API",
    description="Dynamic trip planning with real-time monitoring",
    version="2.0.0",
    docs_url="/docs",      # Swagger UI
    redoc_url="/redoc"     # ReDoc UI
)

# CORS Configuration (允许前端跨域访问)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",      # React dev server
        "http://localhost:8080",      # Flutter web
        "http://localhost:*",         # 任何本地端口
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(router, prefix="/api")

# Health check endpoint
@app.get("/")
async def root():
    """Root endpoint - health check"""
    return {
        "status": "online",
        "service": "Gemini Life Planner API",
        "version": "2.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": "2026-01-27T20:00:00Z",
        "components": {
            "api": "operational",
            "gemini": "configured",
            "agents": "ready"
        }
    }

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Gemini Life Planner API starting...")
    logger.info("📡 API Documentation: http://localhost:8000/docs")
    logger.info("🔌 WebSocket Endpoint: ws://localhost:8000/api/ws/alerts/{plan_id}")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("🛑 Gemini Life Planner API shutting down...")