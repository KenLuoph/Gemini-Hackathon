# backend/app/agents/simulator.py

import json
import logging
import uuid
from datetime import datetime
from app.services.llm_client import llm_client
from app.schemas.domain import TripPlan, UserProfile, PlanStatus, EnvironmentState

logger = logging.getLogger(__name__)

class SimulatorAgent:
    """
    Agent Layer: Simulator (Updated with Context Awareness)
    Responsibilities:
    1. Accept User Intent + Environmental Context.
    2. Generate a valid TripPlan JSON via Gemini.
    """

    # [UPDATE] Added 'environment' parameter to the run method
    async def run(self, intent: str, preferences: UserProfile, environment: EnvironmentState) -> TripPlan:
        logger.info(f"Simulator started. Weather Context: {environment.weather_condition}")

        # 1. Construct Context-Aware System Prompt
        # We inject the weather condition and enforce logic based on it.
        system_prompt = f"""
        You are an expert Travel Planner.
        Current Time: {datetime.now().strftime("%Y-%m-%d %H:%M")}
        
        --- REAL-TIME CONTEXT ---
        Location: {environment.location_id}
        Weather: {environment.weather_condition} (CRITICAL: If Rainy, avoid Outdoor activities!)
        Traffic: {environment.traffic_level}
        -------------------------
        
        USER INTENT: "{intent}"
        
        USER PREFERENCES:
        - Budget Limit: {preferences.budget_limit}
        - Likes: {preferences.preferences}
        
        TASK:
        Generate a TripPlan JSON.
        1. If Weather is 'Rainy', verify that all 'main_itinerary' items are type 'Indoor'.
        2. Strict JSON format matching 'TripPlan' schema.
        """

        # 2. Call Infrastructure Layer (Gemini)
        raw_json = await llm_client.generate_json(system_prompt)

        # 3. Parse & Validate
        try:
            data = json.loads(raw_json)
            
            # Enforcement: Overwrite ID to ensure system consistency
            data["plan_id"] = str(uuid.uuid4())
            # Enforcement: Initial status must be DRAFT
            data["status"] = PlanStatus.DRAFT
            
            plan = TripPlan(**data)
            return plan

        except Exception as e:
            logger.error(f"Simulator failed parsing or validation: {e}")
            raise e

# Singleton Instance
simulator = SimulatorAgent()