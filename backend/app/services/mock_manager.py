# backend/app/services/mock_manager.py

from typing import Optional
from app.schemas.domain import EnvironmentState
import logging

logger = logging.getLogger(__name__)

class MockEnvironmentManager:
    """
    Service to handle runtime environment mocking.
    Allows testing/QA to inject specific weather/traffic states 
    without modifying the actual business logic code.
    """
    _instance = None
    _mock_state: Optional[EnvironmentState] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(MockEnvironmentManager, cls).__new__(cls)
        return cls._instance

    def set_override(self, state: EnvironmentState):
        """Enable simulation mode with specific state"""
        logger.info(f"🧪 TEST MODE ENABLED: Overriding environment to {state.weather_condition}")
        self._mock_state = state

    def get_override(self) -> Optional[EnvironmentState]:
        """Retrieve the mock state if it exists"""
        return self._mock_state

    def clear_override(self):
        """Disable simulation mode, return to real data"""
        logger.info("🧪 TEST MODE DISABLED: Returning to real data.")
        self._mock_state = None

# Singleton Instance
mock_manager = MockEnvironmentManager()