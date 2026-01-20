# backend/app/api/routes.py

from fastapi import APIRouter, HTTPException
from app.schemas.domain import PlanGenerationRequest, TripPlan
from app.agents.simulator import simulator
from app.agents.scout import scout # [NEW] Import Scout
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/plan/generate", response_model=TripPlan)
async def generate_trip_plan(request: PlanGenerationRequest):
    """
    Orchestrator Flow (PDF Page 3 Sequence):
    1. Orchestrator -> Scout (Get Real-time Context)
    2. Orchestrator -> Simulator (Generate Plan using Context)
    """
    logger.info(f"Received Intent: {request.intent}")

    try:
        # Step 1: Context Gathering (Phase 1)
        # Extract basic location from intent or default to Palo Alto.
        # In a real App, this would come from GPS coordinates.
        location_query = "Palo Alto" 
        if "Seattle" in request.intent or "rain" in request.intent.lower(): 
            location_query = "Seattle"
        
        # Call Scout Agent to get weather/traffic
        env_state = await scout.collect_state(location_query)
        
        # Step 2: Simulation (Phase 2)
        # Pass the gathered environment state to the Simulator
        plan = await simulator.run(
            intent=request.intent,
            preferences=request.preferences,
            environment=env_state # [NEW] Injecting context
        )
        return plan

    except Exception as e:
        logger.error(f"Plan Generation Failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))