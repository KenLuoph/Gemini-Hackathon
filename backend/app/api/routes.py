# backend/app/api/routes.py
# Version: 2.0
# Last Updated: 2026-01-27
# Changes: Complete 3-phase flow, WebSocket support, proper response model

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from typing import Dict
import logging
import json

from app.schemas.domain import (
    PlanGenerationRequest,
    PlanGenerationResponse,
    TripPlan,
    AlertSignal
)
from app.services.orchestrator import orchestrator

router = APIRouter()
logger = logging.getLogger(__name__)

# ============================================================================
# REST API ENDPOINTS
# ============================================================================

@router.post("/plan/generate", response_model=PlanGenerationResponse)
async def generate_trip_plan(request: PlanGenerationRequest):
    """
    Main entry point for trip planning.
    
    Flow (PDF Page 3 Sequence Diagram):
    1. Extract user context (user_id, preferences)
    2. Call Orchestrator to execute 3-phase workflow:
       - Phase 1: Scout gathers environment data
       - Phase 2: Simulator generates candidate plans
       - Phase 3: Validator checks constraints and scores
    3. Return plan + validation result
    
    Request Example:
    {
        "intent": "Plan a romantic date in SF this Friday, budget $200",
        "user_id": "user_123",  // Optional
        "preferences": {        // Optional override
            "budget_limit": 200,
            "sensitive_to_rain": true
        }
    }
    
    Response Example:
    {
        "success": true,
        "data": { <TripPlan JSON> },
        "validation": {
            "is_valid": true,
            "score": 0.85,
            "warnings": ["Tight schedule between activities"]
        }
    }
    """
    logger.info(f"📥 Received planning request | Intent: {request.intent[:50]}...")
    
    try:
        # Delegate to Orchestrator (business logic separation)
        result = await orchestrator.initiate_planning(
            user_input=request.intent,
            user_id=request.user_id,
            preferences_override=request.preferences
        )
        
        logger.info(f"✅ Plan generated successfully | ID: {result['data'].plan_id}")
        
        return PlanGenerationResponse(
            success=True,
            data=result["data"],
            validation=result["validation"]
        )
    
    except ValueError as e:
        # Business logic errors (e.g., invalid input)
        logger.warning(f"⚠️ Validation error: {e}")
        return PlanGenerationResponse(
            success=False,
            error=str(e),
            data=None
        )
    
    except Exception as e:
        # Unexpected system errors
        logger.error(f"❌ Plan generation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/plan/{plan_id}/confirm")
async def confirm_plan(plan_id: str):
    """
    User confirms a VERIFIED plan, transitioning it to ACTIVE.
    This triggers the Watchdog monitoring to start.
    
    Flow:
    1. Load plan from storage
    2. Verify status is VERIFIED
    3. Update status to ACTIVE
    4. Start Scout.monitor_routine() background task
    
    Args:
        plan_id: UUID of the plan to confirm
    
    Returns:
        {"status": "active", "monitoring_started": true}
    """
    logger.info(f"📝 Plan confirmation request | ID: {plan_id}")
    
    try:
        result = await orchestrator.confirm_and_activate_plan(plan_id)
        return result
    
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    
    except Exception as e:
        logger.error(f"Plan confirmation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/plan/{plan_id}")
async def get_plan(plan_id: str):
    """
    Retrieve a plan by ID.
    
    Returns:
        TripPlan JSON with current status
    """
    try:
        plan = await orchestrator.get_plan(plan_id)
        if not plan:
            raise HTTPException(status_code=404, detail="Plan not found")
        return plan
    
    except Exception as e:
        logger.error(f"Failed to retrieve plan: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# WEBSOCKET ENDPOINT (PDF Page 5 Requirement)
# ============================================================================

# WebSocket connection manager
class ConnectionManager:
    """
    Manages WebSocket connections for real-time alert broadcasting.
    
    Usage:
    - Frontend connects: ws://localhost:8000/api/ws/alerts/{plan_id}
    - Scout detects change → Orchestrator calls manager.broadcast()
    - Frontend receives alert and updates UI
    """
    def __init__(self):
        # Store active connections per plan_id
        self.active_connections: Dict[str, list[WebSocket]] = {}
    
    async def connect(self, plan_id: str, websocket: WebSocket):
        await websocket.accept()
        if plan_id not in self.active_connections:
            self.active_connections[plan_id] = []
        self.active_connections[plan_id].append(websocket)
        logger.info(f"🔌 WebSocket connected | Plan: {plan_id}")
    
    def disconnect(self, plan_id: str, websocket: WebSocket):
        if plan_id in self.active_connections:
            self.active_connections[plan_id].remove(websocket)
            logger.info(f"🔌 WebSocket disconnected | Plan: {plan_id}")
    
    async def broadcast(self, plan_id: str, message: dict):
        """
        Send message to all clients monitoring this plan.
        
        Message format:
        {
            "type": "alert" | "plan_updated" | "status_change",
            "data": { <AlertSignal or TripPlan JSON> }
        }
        """
        if plan_id not in self.active_connections:
            logger.warning(f"No active connections for plan {plan_id}")
            return
        
        # Send to all connected clients
        for connection in self.active_connections[plan_id]:
            try:
                await connection.send_json(message)
                logger.debug(f"📤 Broadcast sent | Plan: {plan_id}")
            except Exception as e:
                logger.error(f"Failed to send message: {e}")

# Global connection manager instance
ws_manager = ConnectionManager()

@router.websocket("/ws/alerts/{plan_id}")
async def websocket_alerts(websocket: WebSocket, plan_id: str):
    """
    WebSocket endpoint for real-time alert streaming.
    
    Flow (PDF Page 3 Watchdog Sequence):
    1. Frontend connects when user confirms plan
    2. Scout.monitor_routine() detects change
    3. Orchestrator.handle_alert_event() calls ws_manager.broadcast()
    4. Frontend receives alert and shows notification
    
    Message Types:
    - "alert": Scout detected environment change
    - "plan_updated": Plan was automatically adjusted
    - "status_change": Plan lifecycle state changed
    
    Example Message:
    {
        "type": "alert",
        "data": {
            "severity": "CRITICAL",
            "message": "Heavy rain detected",
            "updated_plan": { <TripPlan JSON> }
        }
    }
    """
    await ws_manager.connect(plan_id, websocket)
    
    try:
        # Keep connection alive and listen for client messages
        while True:
            # Wait for any message from client (e.g., ping/pong)
            data = await websocket.receive_text()
            
            # Handle client commands
            if data == "ping":
                await websocket.send_text("pong")
            
            elif data == "get_status":
                # Send current plan status
                plan = await orchestrator.get_plan(plan_id)
                if plan:
                    await websocket.send_json({
                        "type": "status",
                        "data": {"status": plan.status.value}
                    })
    
    except WebSocketDisconnect:
        ws_manager.disconnect(plan_id, websocket)
        logger.info(f"Client disconnected from plan {plan_id}")
    
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        ws_manager.disconnect(plan_id, websocket)

# ============================================================================
# TESTING/DEBUG ENDPOINTS (Optional - for development)
# ============================================================================

@router.post("/test/mock-alert/{plan_id}")
async def trigger_test_alert(plan_id: str, alert_data: dict):
    """
    Development endpoint to simulate Scout alerts.
    Useful for testing frontend alert handling without waiting for real weather changes.
    
    Example Request:
    POST /api/test/mock-alert/plan_123
    {
        "severity": "CRITICAL",
        "message": "Test rain alert",
        "change_type": "weather"
    }
    """
    await ws_manager.broadcast(plan_id, {
        "type": "alert",
        "data": alert_data
    })
    return {"status": "alert_sent"}