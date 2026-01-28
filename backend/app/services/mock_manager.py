# backend/app/services/mock_manager.py
# Version: 2.0
# Last Updated: 2026-01-27
# Changes: Fix field name compatibility with domain.py v2.0

from typing import Optional, Dict
from datetime import datetime
from app.schemas.domain import EnvironmentState, WeatherCode
import logging

logger = logging.getLogger(__name__)

class MockEnvironmentManager:
    """
    Service for runtime environment mocking.
    
    Purpose:
    - Enable deterministic testing without external API calls
    - Allow QA to simulate weather changes for Watchdog testing
    - Support automated test scenarios
    
    Design:
    - Singleton pattern for global state management
    - Thread-safe (single Python process assumption)
    - Provides clear logging for test mode awareness
    
    Usage Examples:
    
    # Test Scenario 1: Force sunny weather
    mock_manager.set_override(
        EnvironmentState(
            location_id="test_sf",
            timestamp=datetime.utcnow(),
            weather_code=WeatherCode.CLEAR,
            temperature=25.0,
            traffic_index=2.0
        )
    )
    
    # Test Scenario 2: Simulate weather change timeline
    mock_manager.set_timeline([
        (datetime(2026,1,27,14,0), WeatherCode.CLEAR),
        (datetime(2026,1,27,15,0), WeatherCode.RAIN_HEAVY)
    ])
    
    # Test Scenario 3: Location-specific overrides
    mock_manager.set_override_for_location("SF", state1)
    mock_manager.set_override_for_location("Seattle", state2)
    """
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(MockEnvironmentManager, cls).__new__(cls)
            # Initialize instance variables
            cls._instance._mock_state = None
            cls._instance._location_overrides = {}
            cls._instance._timeline = []
            cls._instance._timeline_index = 0
        return cls._instance
    
    # ========================================================================
    # BASIC OVERRIDE (Original Functionality)
    # ========================================================================
    
    def set_override(self, state: EnvironmentState):
        """
        Enable global simulation mode with specific state.
        All Scout calls will return this state regardless of location.
        
        Args:
            state: EnvironmentState to return for all queries
        """
        logger.info(
            f"🧪 TEST MODE ENABLED: Global override set to "
            f"Weather={state.weather_code.value}, Traffic={state.traffic_index}"
        )
        self._mock_state = state
    
    def get_override(self) -> Optional[EnvironmentState]:
        """
        Retrieve the mock state if it exists.
        
        Priority order:
        1. Timeline-based state (if active)
        2. Location-specific override (if matches)
        3. Global override (fallback)
        
        Returns:
            EnvironmentState if mocking is active, None for real data
        """
        # Check timeline first
        if self._timeline:
            state = self._get_timeline_state()
            if state:
                return state
        
        # Return global override
        return self._mock_state
    
    def clear_override(self):
        """
        Disable simulation mode, return to real data.
        Clears all overrides: global, location-specific, and timeline.
        """
        logger.info("🧪 TEST MODE DISABLED: Returning to real API data")
        self._mock_state = None
        self._location_overrides.clear()
        self._timeline.clear()
        self._timeline_index = 0
    
    # ========================================================================
    # ADVANCED FEATURES (For Complex Testing)
    # ========================================================================
    
    def set_override_for_location(self, location_id: str, state: EnvironmentState):
        """
        Set location-specific override.
        Useful for testing multi-location plans.
        
        Example:
        mock_manager.set_override_for_location("SF", sunny_state)
        mock_manager.set_override_for_location("Seattle", rainy_state)
        
        # Scout calls:
        scout.get_realtime_state("SF") → sunny_state
        scout.get_realtime_state("Seattle") → rainy_state
        
        Args:
            location_id: Location identifier
            state: EnvironmentState for this location
        """
        logger.info(
            f"🧪 Location override set: {location_id} → "
            f"Weather={state.weather_code.value}"
        )
        self._location_overrides[location_id] = state
    
    def get_override_for_location(self, location_id: str) -> Optional[EnvironmentState]:
        """
        Get location-specific override if exists.
        
        Args:
            location_id: Location identifier
        
        Returns:
            EnvironmentState for this location, or None
        """
        return self._location_overrides.get(location_id)
    
    def set_timeline(self, events: list[tuple[datetime, WeatherCode, float]]):
        """
        Set a timeline of weather changes for simulating dynamic conditions.
        Scout will return different states based on current time.
        
        Use case: Test Watchdog alert triggering
        
        Example:
        mock_manager.set_timeline([
            (datetime(2026,1,27,14,0), WeatherCode.CLEAR, 3.5),
            (datetime(2026,1,27,15,0), WeatherCode.RAIN_LIGHT, 5.0),
            (datetime(2026,1,27,16,0), WeatherCode.RAIN_HEAVY, 8.5)
        ])
        
        # At 14:30, Scout returns CLEAR
        # At 15:30, Scout returns RAIN_LIGHT (triggers WARNING alert)
        # At 16:30, Scout returns RAIN_HEAVY (triggers CRITICAL alert)
        
        Args:
            events: List of (timestamp, weather_code, traffic_index) tuples
        """
        self._timeline = sorted(events, key=lambda x: x[0])  # Sort by time
        self._timeline_index = 0
        logger.info(f"🧪 Timeline set with {len(events)} weather changes")
    
    def _get_timeline_state(self) -> Optional[EnvironmentState]:
        """
        Internal: Get state from timeline based on current time.
        Automatically advances through timeline as time progresses.
        """
        if not self._timeline:
            return None
        
        now = datetime.utcnow()
        
        # Find the latest event that has occurred
        current_event = None
        for timestamp, weather_code, traffic_index in self._timeline:
            if timestamp <= now:
                current_event = (timestamp, weather_code, traffic_index)
            else:
                break
        
        if not current_event:
            return None
        
        timestamp, weather_code, traffic_index = current_event
        
        return EnvironmentState(
            location_id="timeline_simulation",
            timestamp=now,
            weather_code=weather_code,
            temperature=20.0,  # Placeholder
            precipitation_probability=0.5 if "RAIN" in weather_code.value else 0.1,
            traffic_index=traffic_index,
            is_poi_open=True
        )
    
    # ========================================================================
    # UTILITY METHODS
    # ========================================================================
    
    def is_active(self) -> bool:
        """Check if any mocking is currently active."""
        return (
            self._mock_state is not None or
            bool(self._location_overrides) or
            bool(self._timeline)
        )
    
    def get_status(self) -> Dict[str, any]:
        """
        Get current mock manager status for debugging.
        
        Returns:
            {
                "active": bool,
                "global_override": bool,
                "location_overrides": int,
                "timeline_events": int
            }
        """
        return {
            "active": self.is_active(),
            "global_override": self._mock_state is not None,
            "location_overrides": len(self._location_overrides),
            "timeline_events": len(self._timeline)
        }

# ============================================================================
# Singleton Instance Export
# ============================================================================
mock_manager = MockEnvironmentManager()