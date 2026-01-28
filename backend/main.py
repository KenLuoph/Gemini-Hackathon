# backend/main.py

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
    docs_url="/docs",
    redoc_url="/redoc"
)

# ============================================================================
# CORS Configuration (CRITICAL for Flutter Web/Mobile)
# ============================================================================
# This MUST be added BEFORE including routes

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",           # Flutter web dev server
        "http://127.0.0.1:*",           # Alternative localhost
        "http://localhost:3000",        # Common dev ports
        "http://localhost:8080",
        "http://localhost:8081",
        "*",                            # Allow all (development only)
    ],
    allow_credentials=True,
    allow_methods=["*"],                # Allow all HTTP methods including OPTIONS
    allow_headers=["*"],                # Allow all headers
    expose_headers=["*"],               # Expose all response headers
    max_age=3600,                       # Cache preflight for 1 hour
)

# Include API routes
app.include_router(router, prefix="/api")

# ============================================================================
# Root Endpoints
# ============================================================================

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
        "timestamp": "2026-01-28T03:00:00Z",
        "components": {
            "api": "operational",
            "gemini": "configured",
            "agents": "ready"
        }
    }

# ============================================================================
# Startup/Shutdown Events
# ============================================================================

@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Gemini Life Planner API starting...")
    logger.info("📡 API Documentation: http://localhost:8000/docs")
    logger.info("🔌 WebSocket Endpoint: ws://localhost:8000/api/ws/alerts/{plan_id}")
    logger.info("🌐 CORS enabled for all origins (development mode)")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("🛑 Gemini Life Planner API shutting down...")