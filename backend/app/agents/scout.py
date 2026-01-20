# backend/app/agents/scout.py

import logging
from datetime import datetime
from app.schemas.domain import EnvironmentState
# [NEW] Import the mock manager
from app.services.mock_manager import mock_manager

logger = logging.getLogger(__name__)

class ScoutAgent:
    """
    Agent Layer: Data Scout
    Responsibilities:
    1. Check for Test/Mock Overrides first.
    2. If no override, Fetch Real-time Context (Real Logic).
    """

    async def collect_state(self, location_str: str) -> EnvironmentState:
        logger.info(f"Scout is checking environment for: {location_str}")

        # [STEP 1] Check for Test Interface Injection
        # If the QA/Dev has set a mock state via API, use it immediately.
        mock_data = mock_manager.get_override()
        if mock_data:
            logger.info(f"⚡️ Using MOCKED Environment: {mock_data.weather_condition}")
            # Ensure the location matches the current query context visually
            mock_data.location_id = location_str 
            return mock_data

        # [STEP 2] Production Logic (Real Data)
        # No more hardcoded "Seattle" checks here. This is pure business logic.
        
        # Placeholder for Real OpenWeather API call
        # In the future, this will be: weather = await openweather_client.get(...)
        weather = "Sunny" 
        traffic = "Low"
        
        return EnvironmentState(
            location_id=location_str,
            timestamp=datetime.now(),
            weather_condition=weather,
            traffic_level=traffic
        )

scout = ScoutAgent()