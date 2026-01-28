# backend/app/agents/scout.py
# Version: 2.0
# Last Updated: 2026-01-27
# Changes: Complete alignment with domain.py v2.0, full method implementation

import logging
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any, Callable
from app.schemas.domain import (
    EnvironmentState,
    AlertSignal,
    AlertSeverity,
    WeatherCode,
    TripPlan
)
from app.services.mock_manager import mock_manager

logger = logging.getLogger(__name__)

class ScoutAgent:
    """
    The Eyes: Real-time environment monitoring and change detection.
    
    Responsibilities (PDF Page 3):
    1. fetch_static_context(): Provide initial planning data
    2. get_realtime_state(): Fetch current environment snapshot
    3. compare_states(): Detect significant changes
    4. monitor_routine(): Background watchdog loop
    
    Design Principles:
    - Mock-First: Test interface has priority for deterministic testing
    - Fail-Safe: Graceful degradation when external APIs fail
    - Change Detection: Smart thresholds to avoid alert spam
    """
    
    def __init__(self):
        # Cache for last known state per location
        self._state_cache: Dict[str, EnvironmentState] = {}
        
        # TODO: Initialize external API clients in Week 2 end
        # self.weather_client = OpenWeatherClient()
        # self.traffic_client = GoogleMapsClient()
        # self.poi_client = YelpClient()
    
    async def fetch_static_context(
        self,
        location: str,
        date: datetime
    ) -> Dict[str, Any]:
        """
        Fetch comprehensive context for initial planning.
        
        This is called ONCE at the beginning of plan generation.
        Provides static/semi-static data like:
        - Historical weather patterns
        - Popular venues (POIs)
        - Average traffic by time of day
        
        Args:
            location: City or region identifier
            date: Target date for the trip
        
        Returns:
            Dict with keys: weather_forecast, popular_pois, traffic_patterns
        """
        logger.info(f"Fetching static context for {location} on {date.strftime('%Y-%m-%d')}")
        
        # Check mock first
        mock_state = mock_manager.get_override()
        if mock_state:
            logger.info("Using mocked static context")
            return {
                "weather_forecast": {
                    "code": mock_state.weather_code.value,
                    "temp": mock_state.temperature
                },
                "popular_pois": ["Mock Museum", "Mock Restaurant"],
                "traffic_patterns": {"peak_hours": [17, 18, 19]}
            }
        
        # TODO: Real API calls (Week 2)
        # weather_forecast = await self.weather_client.get_forecast(location, date)
        # pois = await self.poi_client.search_popular(location)
        # traffic = await self.traffic_client.get_patterns(location)
        
        # Placeholder production logic
        return {
            "weather_forecast": {
                "code": WeatherCode.CLEAR.value,
                "temp": 20.0,
                "description": "Placeholder - will integrate real API"
            },
            "popular_pois": [
                {"name": "SFMOMA", "category": "art", "rating": 4.5},
                {"name": "Ferry Building", "category": "food", "rating": 4.3}
            ],
            "traffic_patterns": {
                "peak_hours": [8, 9, 17, 18],
                "avg_index": 5.2
            }
        }
    
    async def get_realtime_state(self, location: str) -> EnvironmentState:
        """
        Get current environment snapshot (Watchdog core).
        
        This is called repeatedly (every 5 minutes) during monitoring.
        Must be fast and reliable.
        
        Args:
            location: Location identifier (e.g., "SF_Downtown")
        
        Returns:
            EnvironmentState with current conditions
        """
        logger.info(f"Scout checking real-time state for: {location}")
        
        # ===== STEP 1: Check Mock Override =====
        mock_state = mock_manager.get_override()
        if mock_state:
            logger.info(f"⚡️ Using MOCKED state: Weather={mock_state.weather_code.value}")
            # Ensure location matches context
            mock_state.location_id = location
            return mock_state
        
        # ===== STEP 2: Production Logic =====
        try:
            # TODO: Real API calls (Week 2 end)
            # weather_data = await self.weather_client.get_current(location)
            # traffic_data = await self.traffic_client.get_current(location)
            
            # Placeholder: Safe defaults
            current_state = EnvironmentState(
                location_id=location,
                timestamp=datetime.utcnow(),
                weather_code=WeatherCode.CLEAR,
                temperature=20.0,
                precipitation_probability=0.1,
                traffic_index=3.5,
                is_poi_open=True
            )
            
            # Cache for comparison
            self._state_cache[location] = current_state
            return current_state
            
        except Exception as e:
            logger.error(f"Failed to fetch real-time state: {e}")
            
            # Fail-safe: Return cached state if available
            if location in self._state_cache:
                logger.warning("Using cached state due to API failure")
                return self._state_cache[location]
            
            # Last resort: Return safe defaults
            logger.warning("Returning default safe state")
            return EnvironmentState(
                location_id=location,
                timestamp=datetime.utcnow(),
                weather_code=WeatherCode.CLEAR,
                temperature=20.0,
                precipitation_probability=0.0,
                traffic_index=5.0,
                is_poi_open=None  # Unknown
            )
    
    def compare_states(
        self,
        last: EnvironmentState,
        current: EnvironmentState
    ) -> Optional[AlertSignal]:
        """
        Detect significant environmental changes.
        
        Decision Logic (threshold-based):
        - Weather change: Any transition between weather codes
        - Traffic spike: Index change > 3.0
        - Temperature: Change > 10°C
        
        Returns:
            AlertSignal if change is significant, None otherwise
        """
        # ===== Weather Change Detection =====
        if last.weather_code != current.weather_code:
            severity = self._assess_weather_severity(
                last.weather_code,
                current.weather_code
            )
            
            return AlertSignal(
                source="SCOUT_AGENT",
                change_type="weather",
                message=f"Weather changed from {last.weather_code.value} to {current.weather_code.value}",
                trigger_value=current.weather_code.value,
                severity=severity,
                affected_plan_id="",  # Will be set by Orchestrator
                payload=current,
                timestamp=datetime.utcnow()
            )
        
        # ===== Traffic Change Detection =====
        traffic_delta = abs(current.traffic_index - last.traffic_index)
        if traffic_delta > 3.0:
            severity = AlertSeverity.WARNING if traffic_delta < 5.0 else AlertSeverity.CRITICAL
            
            return AlertSignal(
                source="SCOUT_AGENT",
                change_type="traffic",
                message=f"Traffic spiked from {last.traffic_index} to {current.traffic_index}",
                trigger_value=str(current.traffic_index),
                severity=severity,
                affected_plan_id="",
                payload=current,
                timestamp=datetime.utcnow()
            )
        
        # ===== Temperature Change Detection =====
        temp_delta = abs(current.temperature - last.temperature)
        if temp_delta > 10.0:
            return AlertSignal(
                source="SCOUT_AGENT",
                change_type="temperature",
                message=f"Temperature changed by {temp_delta}°C",
                trigger_value=str(current.temperature),
                severity=AlertSeverity.WARNING,
                affected_plan_id="",
                payload=current,
                timestamp=datetime.utcnow()
            )
        
        # No significant changes detected
        return None
    
    async def monitor_routine(
        self,
        plan: TripPlan,
        interval: int = 300,  # 5 minutes
        callback: Optional[Callable] = None
    ):
        """
        Background task: Continuously monitor environment and trigger alerts.
        
        Flow (PDF Page 3 Watchdog Sequence):
        1. Fetch current state
        2. Compare with last known state
        3. If change detected → Call callback (Orchestrator.handle_alert_event)
        4. Sleep for interval
        5. Repeat until plan is completed/cancelled
        
        Args:
            plan: The TripPlan to monitor
            interval: Polling interval in seconds (default: 5 minutes)
            callback: Function to call when alert triggered
        
        Note:
            This should be started as a background task in FastAPI:
```
            asyncio.create_task(scout.monitor_routine(plan, callback=orchestrator.handle_alert))
```
        """
        logger.info(f"Starting watchdog for plan {plan.plan_id} (interval: {interval}s)")
        
        # Get initial baseline
        location = self._extract_primary_location(plan)
        last_state = await self.get_realtime_state(location)
        
        iteration = 0
        while True:
            try:
                iteration += 1
                logger.debug(f"Watchdog iteration {iteration} for plan {plan.plan_id}")
                
                # Fetch current state
                current_state = await self.get_realtime_state(location)
                
                # Compare and detect changes
                alert = self.compare_states(last_state, current_state)
                
                if alert:
                    logger.warning(
                        f"⚠️ Alert detected: {alert.change_type} | "
                        f"Severity: {alert.severity.value}"
                    )
                    
                    # Set the plan_id
                    alert.affected_plan_id = plan.plan_id
                    
                    # Trigger callback (Orchestrator will handle re-planning)
                    if callback:
                        await callback(alert)
                    else:
                        logger.warning("No callback registered for alert")
                
                # Update baseline
                last_state = current_state
                
                # Sleep until next poll
                await asyncio.sleep(interval)
                
            except asyncio.CancelledError:
                logger.info(f"Watchdog for plan {plan.plan_id} cancelled")
                break
            
            except Exception as e:
                logger.error(f"Watchdog error: {e}")
                # Continue monitoring despite errors
                await asyncio.sleep(interval)
    
    # ========================================================================
    # PRIVATE HELPER METHODS
    # ========================================================================
    
    def _assess_weather_severity(
        self,
        old_weather: WeatherCode,
        new_weather: WeatherCode
    ) -> AlertSeverity:
        """
        Determine alert severity based on weather transition.
        
        Logic:
        - Clear → Storm: CRITICAL
        - Clear → Rain Heavy: CRITICAL
        - Rain Light → Rain Heavy: WARNING
        - Rain Heavy → Clear: INFO (improvement)
        """
        # Define critical weather conditions
        critical_conditions = {WeatherCode.RAIN_HEAVY, WeatherCode.STORM, WeatherCode.SNOW}
        
        # Degradation scenarios
        if old_weather not in critical_conditions and new_weather in critical_conditions:
            return AlertSeverity.CRITICAL
        
        # Moderate degradation
        if new_weather == WeatherCode.RAIN_LIGHT:
            return AlertSeverity.WARNING
        
        # Improvement scenario (e.g., rain stops)
        if old_weather in critical_conditions and new_weather == WeatherCode.CLEAR:
            return AlertSeverity.INFO
        
        # Default for other transitions
        return AlertSeverity.WARNING
    
    def _extract_primary_location(self, plan: TripPlan) -> str:
        """
        Extract the primary location identifier from a plan.
        Uses the first activity's location as reference.
        """
        if not plan.main_itinerary:
            return "unknown_location"
        
        first_activity = plan.main_itinerary[0]
        # Use a simplified location ID (could be enhanced with geocoding)
        return f"loc_{first_activity.location.lat:.2f}_{first_activity.location.lng:.2f}"

# ============================================================================
# Singleton Instance Export
# ============================================================================
scout = ScoutAgent()