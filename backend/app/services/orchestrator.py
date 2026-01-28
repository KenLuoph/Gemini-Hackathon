# backend/app/services/orchestrator.py
# Version: 1.0
# Last Updated: 2026-01-27
# Purpose: Central business logic coordinator (PDF Page 2 BFF layer)

import logging
import asyncio
from typing import Dict, Any, Optional
from datetime import datetime

from app.schemas.domain import (
    TripPlan,
    UserProfile,
    PlanStatus,
    AlertSignal,
    AlertSeverity,
    ValidationResult
)
from app.agents.scout import scout
from app.agents.simulator import simulator
from app.agents.validator import validator  

logger = logging.getLogger(__name__)

class Orchestrator:
    """
    The Conductor: Coordinates all agents and manages plan lifecycle.
    
    Responsibilities (PDF Page 2):
    1. initiate_planning(): Execute 3-phase generation flow
    2. confirm_and_activate_plan(): Start monitoring
    3. handle_alert_event(): React to Scout alerts
    4. manage plan storage and state transitions
    
    Design Principles:
    - Stateless: Each method is independent
    - Event-Driven: Reacts to alerts via callbacks
    - Fail-Safe: Graceful degradation on agent failures
    """
    
    def __init__(self):
        # In-memory storage (replace with Redis/DB in production)
        self._plan_storage: Dict[str, TripPlan] = {}
        self._active_monitors: Dict[str, asyncio.Task] = {}
    
    async def initiate_planning(
        self,
        user_input: str,
        user_id: Optional[str] = None,
        preferences_override: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Execute complete plan generation workflow.
        
        Flow (PDF Page 3 Sequence Diagram):
        ┌─────────────┐
        │ Phase 1:    │ Scout.fetch_static_context()
        │ Context     │ → Returns EnvironmentState
        └─────────────┘
        ┌─────────────┐
        │ Phase 2:    │ Simulator.run()
        │ Simulation  │ → Returns TripPlan (status=DRAFT)
        └─────────────┘
        ┌─────────────┐
        │ Phase 3:    │ Validator.validate_constraints()
        │ Validation  │ → Returns ValidationResult
        └─────────────┘
        
        Args:
            user_input: Natural language planning request
            user_id: Optional user identifier to load profile
            preferences_override: Optional preference overrides
        
        Returns:
            {
                "data": TripPlan,
                "validation": ValidationResult
            }
        """
        logger.info("🎬 Initiating planning workflow")
        
        # ===== Step 1: Build User Profile =====
        user_profile = self._build_user_profile(user_id, preferences_override)
        
        # ===== Step 2: Extract Location =====
        location = self._extract_location_from_intent(user_input)
        logger.info(f"📍 Detected location: {location}")
        
        # ===== Phase 1: Context Gathering =====
        logger.info("📡 Phase 1: Gathering environment context")
        env_state = await scout.get_realtime_state(location)
        
        # ===== Phase 2: Plan Generation =====
        logger.info("🎲 Phase 2: Generating trip scenarios")
        plan = await simulator.run(
            intent=user_input,
            preferences=user_profile,
            environment=env_state
        )
        
        # ===== Phase 3: Validation =====
        logger.info("⚖️ Phase 3: Validating constraints")
        validation_result = await validator.validate_constraints(
            plan=plan,
            profile=user_profile
        )
        
        # ===== Post-Processing =====
        if validation_result.is_valid:
            plan.status = PlanStatus.VERIFIED
        else:
            plan.status = PlanStatus.DRAFT
            logger.warning(f"Plan validation failed: {validation_result.violations}")
        
        # Store plan
        self._plan_storage[plan.plan_id] = plan
        
        return {
            "data": plan,
            "validation": validation_result
        }
    
    async def confirm_and_activate_plan(self, plan_id: str) -> Dict[str, Any]:
        """
        User confirms plan → Transition to ACTIVE → Start monitoring.
        
        Flow (PDF Page 4 State Machine):
        VERIFIED → (User Confirms) → ACTIVE → Watchdog Started
        
        Args:
            plan_id: UUID of verified plan
        
        Returns:
            {"status": "active", "monitoring_started": true}
        """
        # Load plan
        plan = self._plan_storage.get(plan_id)
        if not plan:
            raise ValueError(f"Plan {plan_id} not found")
        
        if plan.status != PlanStatus.VERIFIED:
            raise ValueError(f"Plan must be VERIFIED to activate (current: {plan.status})")
        
        # Update status
        plan.status = PlanStatus.ACTIVE
        plan.updated_at = datetime.utcnow()
        
        # Start monitoring background task
        monitor_task = asyncio.create_task(
            scout.monitor_routine(
                plan=plan,
                interval=300,  # 5 minutes
                callback=self.handle_alert_event
            )
        )
        
        self._active_monitors[plan_id] = monitor_task
        logger.info(f"👁️ Watchdog started for plan {plan_id}")
        
        return {
            "status": "active",
            "monitoring_started": True,
            "plan_id": plan_id
        }
    
    async def handle_alert_event(self, alert: AlertSignal):
        """
        Callback function for Scout alerts.
        
        Flow (PDF Page 3 Watchdog Sequence):
        1. Scout detects change → Calls this function
        2. Load affected plan
        3. If severity=CRITICAL → Call Simulator.emergency_replan()
        4. Update plan storage
        5. Broadcast to WebSocket clients
        
        Args:
            alert: AlertSignal from Scout
        """
        logger.warning(
            f"⚠️ Alert received | "
            f"Plan: {alert.affected_plan_id} | "
            f"Type: {alert.change_type} | "
            f"Severity: {alert.severity.value}"
        )
        
        # Load plan
        plan = self._plan_storage.get(alert.affected_plan_id)
        if not plan:
            logger.error(f"Plan {alert.affected_plan_id} not found in storage")
            return
        
        # Handle based on severity
        if alert.severity == AlertSeverity.CRITICAL:
            # Immediate re-planning required
            logger.info("🚨 CRITICAL alert - triggering emergency replan")
            
            updated_plan = await simulator.emergency_replan(plan, alert)
            
            # Update storage
            self._plan_storage[plan.plan_id] = updated_plan
            
            # Broadcast to frontend (import ws_manager from routes)
            from app.api.routes import ws_manager
            await ws_manager.broadcast(plan.plan_id, {
                "type": "plan_updated",
                "data": {
                    "alert": alert.model_dump(),
                    "updated_plan": updated_plan.model_dump()
                }
            })
        
        elif alert.severity == AlertSeverity.WARNING:
            # Just notify, no auto-change
            logger.info("⚠️ WARNING alert - notifying user")
            
            from app.api.routes import ws_manager
            await ws_manager.broadcast(plan.plan_id, {
                "type": "alert",
                "data": alert.model_dump()
            })
        
        else:  # INFO
            # Log only
            logger.info(f"ℹ️ INFO alert: {alert.message}")
    
    async def get_plan(self, plan_id: str) -> Optional[TripPlan]:
        """Retrieve plan from storage."""
        return self._plan_storage.get(plan_id)
    
    # ========================================================================
    # PRIVATE HELPER METHODS
    # ========================================================================
    
    def _build_user_profile(
        self,
        user_id: Optional[str],
        preferences_override: Optional[Dict[str, Any]]
    ) -> UserProfile:
        """
        Build UserProfile from user_id and overrides.
        
        Logic:
        1. If user_id provided → Load from DB (TODO)
        2. Merge with preferences_override
        3. If no user_id → Create from override only
        """
        # TODO: Load from database
        # profile = db.get_user_profile(user_id)
        
        # Placeholder: Create from overrides
        if preferences_override:
            return UserProfile(
                user_id=user_id or "anonymous",
                budget_limit=preferences_override.get("budget_limit", 100.0),
                preferences=preferences_override.get("preferences", []),
                sensitive_to_rain=preferences_override.get("sensitive_to_rain", False),
                dietary_restrictions=preferences_override.get("dietary_restrictions"),
                mobility_constraints=preferences_override.get("mobility_constraints")
            )
        
        # Default profile
        return UserProfile(
            user_id=user_id or "anonymous",
            budget_limit=200.0,
            preferences=["food", "art"],
            sensitive_to_rain=False
        )
    
    def _extract_location_from_intent(self, intent: str) -> str:
        """
        Extract location from user intent.
        
        Current: Simple keyword matching
        TODO: Use Gemini NER (Named Entity Recognition)
        """
        intent_lower = intent.lower()
        
        # City mapping
        cities = {
            "sf": "San Francisco",
            "san francisco": "San Francisco",
            "seattle": "Seattle",
            "palo alto": "Palo Alto",
            "new york": "New York",
            "nyc": "New York"
        }
        
        for keyword, city in cities.items():
            if keyword in intent_lower:
                return city
        
        # Default
        return "San Francisco"

# ============================================================================
# Singleton Instance Export
# ============================================================================
orchestrator = Orchestrator()