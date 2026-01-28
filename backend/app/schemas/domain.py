# backend/app/schemas/domain.py
# Version: 2.0
# Last Updated: 2026-01-27
# Strictly aligned with PDF Page 2 Domain Model + Week 1 Weekend Todo Requirements

from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any
from enum import Enum
from datetime import datetime
import uuid

# ============================================================================
# SECTION 1: ENUMERATIONS (Standardized Vocabularies)
# ============================================================================
# Purpose: Define all allowed values for categorical fields
# Benefits: Type safety + Auto-validation + Clear API contracts

class PlanStatus(str, Enum):
    """
    Lifecycle states from PDF Page 4 State Machine [cite: 131-139]
    Flow: DRAFT -> GENERATING -> VALIDATING -> VERIFIED -> ACTIVE -> (COMPLETED | CANCELLED)
    """
    DRAFT = "draft"              # Initial state when user submits intent
    GENERATING = "generating"    # Simulator is working
    VALIDATING = "validating"    # Validator is checking constraints
    VERIFIED = "verified"        # Passed validation, waiting for user confirmation
    ACTIVE = "active"            # User confirmed, Watchdog monitoring started
    MONITORING = "monitoring"    # Actively being monitored by Scout
    COMPLETED = "completed"      # Trip ended successfully
    CANCELLED = "cancelled"      # User aborted or system failed

class ActivityType(str, Enum):
    """
    From PDF Page 2 ActivityItem [cite: 51]
    Used by Simulator to determine weather sensitivity
    """
    INDOOR = "indoor"
    OUTDOOR = "outdoor"

class AlertSeverity(str, Enum):
    """
    From PDF Page 2 AlertSignal [cite: 72]
    Determines urgency of re-planning:
    - INFO: Just FYI, no action needed
    - WARNING: May affect plan, user should review
    - CRITICAL: Immediate re-plan required (e.g. venue closed, storm warning)
    """
    INFO = "INFO"
    WARNING = "WARNING"
    CRITICAL = "CRITICAL"

class WeatherCode(str, Enum):
    """
    Standardized weather codes for EnvironmentState
    Enables Scout to detect significant changes numerically
    """
    CLEAR = "clear"
    PARTLY_CLOUDY = "partly_cloudy"
    CLOUDY = "cloudy"
    RAIN_LIGHT = "rain_light"
    RAIN_HEAVY = "rain_heavy"
    SNOW = "snow"
    STORM = "storm"
    FOG = "fog"

# ============================================================================
# SECTION 2: SHARED COMPONENTS (Reusable Building Blocks)
# ============================================================================
# Purpose: Avoid duplication, ensure consistency across all domain objects

class GeoLocation(BaseModel):
    """
    Standard geographic coordinate representation [cite: 48]
    Used by: ActivityItem, Scout's API calls to Maps/Weather
    """
    lat: float = Field(..., ge=-90, le=90, description="Latitude")
    lng: float = Field(..., ge=-180, le=180, description="Longitude")
    address: str = Field(..., description="Human-readable address")

    @field_validator('lat', 'lng')
    def validate_coordinates(cls, v, info):
        """Ensure coordinates are within valid Earth bounds"""
        field_name = info.field_name
        if field_name == 'lat' and not (-90 <= v <= 90):
            raise ValueError('Latitude must be between -90 and 90')
        if field_name == 'lng' and not (-180 <= v <= 180):
            raise ValueError('Longitude must be between -180 and 180')
        return v

class BudgetInfo(BaseModel):
    """
    Standard budget representation [cite: 50]
    Used by: ActivityItem, Validator constraint checking
    """
    amount: float = Field(..., ge=0, description="Budget amount")
    currency: str = Field(default="USD", description="ISO currency code")
    category: str = Field(
        default="general",
        description="Budget category: 'food', 'transport', 'entertainment', 'general'"
    )

# ============================================================================
# SECTION 3: CORE DOMAIN MODELS (The "Nouns" of Our System)
# ============================================================================
# Purpose: Define the primary data structures that flow between Agents

class ActivityItem(BaseModel):
    """
    Atomic unit of a trip plan.
    Strictly follows PDF Page 2 definition [cite: 46-51] + Week 1 enhancements.
    
    Lifecycle:
    1. Created by Simulator.generate_scenarios()
    2. Validated by Validator.validate_constraints()
    3. Monitored by Scout during execution
    4. Can be swapped with alternatives during emergency_replan()
    """
    activity_id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        description="Unique identifier"
    )
    name: str = Field(..., description="Activity name [cite: 49]")
    time_slot: str = Field(
        ...,
        description="Time duration e.g. '10:00-11:00' [cite: 47]"
    )
    location: GeoLocation = Field(..., description="[cite: 48]")
    budget: BudgetInfo = Field(..., description="[cite: 50]")
    type: ActivityType = Field(..., description="Indoor/Outdoor [cite: 51]")
    description: Optional[str] = Field(
        default=None,
        description="Detailed description generated by Gemini"
    )
    
    # ===== Week 1 Weekend Todo Enhancements =====
    constraints: Optional[Dict[str, Any]] = Field(
        default=None,
        description=(
            "User-specific constraints for Validator checking. "
            "Examples: {'must_be_halal': true, 'walking_limit_km': 2.0, 'wheelchair_accessible': true}"
        )
    )
    risk_score: float = Field(
        default=0.0,
        ge=0.0,
        le=1.0,
        description=(
            "Weather/traffic sensitivity score (0.0-1.0). "
            "Used by Simulator.emergency_replan() to prioritize which activities to replace. "
            "High score = high dependency on good weather/traffic. "
            "Examples: Outdoor concert = 0.9, Indoor museum = 0.1"
        )
    )
    
    # Used for tracking during execution
    status: str = Field(
        default="pending",
        description="Execution status: 'pending', 'in_progress', 'completed', 'cancelled'"
    )

class TripPlan(BaseModel):
    """
    The root aggregate passed between all Agents.
    Strictly follows PDF Page 2 definition [cite: 34-39] + Week 1 enhancements.
    
    Data Flow:
    1. User Input -> Orchestrator
    2. Orchestrator -> Scout.fetch_static_context() -> Returns EnvironmentState
    3. Orchestrator -> Simulator.generate_scenarios(context) -> Returns TripPlan (status=DRAFT)
    4. Orchestrator -> Validator.validate_constraints(plan) -> Returns ValidationResult
    5. If valid -> status=VERIFIED -> User confirms -> status=ACTIVE
    6. Scout.monitor_routine() watches this plan and triggers re-planning if needed
    """
    plan_id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        description="UUID [cite: 35]"
    )
    name: str = Field(..., description="Plan title [cite: 36]")
    status: PlanStatus = Field(
        default=PlanStatus.DRAFT,
        description="Current lifecycle state [cite: 39]"
    )
    
    main_itinerary: List[ActivityItem] = Field(
        ...,
        description="Primary execution path [cite: 37]"
    )
    alternatives: List[ActivityItem] = Field(
        default=[],
        description=(
            "Backup activities for dynamic switching [cite: 38]. "
            "Emergency_replan() swaps items from this list into main_itinerary "
            "when weather/traffic alerts are triggered."
        )
    )
    
    # ===== Week 1 Weekend Todo Enhancement =====
    reasoning_path: Optional[str] = Field(
        default=None,
        description=(
            "Gemini's internal chain-of-thought explanation. "
            "Generated during Simulator.generate_scenarios(). "
            "Used for demo presentation to show AI decision-making transparency."
        )
    )
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class UserProfile(BaseModel):
    """
    User preference/constraint model for Validator.
    Strictly follows PDF Page 2 definition [cite: 42-45].
    
    Usage:
    - Loaded from DB by user_id
    - Passed to Validator.validate_constraints()
    - Used to calculate preference matching score
    """
    user_id: str
    budget_limit: float = Field(..., description="Total budget hard constraint")
    preferences: List[str] = Field(
        default=[],
        description=(
            "User interests for scoring. "
            "Examples: ['art', 'hiking', 'food', 'history', 'nightlife']"
        )
    )
    sensitive_to_rain: bool = Field(
        default=False,
        description="If true, Simulator must prioritize indoor alternatives during rain"
    )
    
    # Additional constraints (optional)
    dietary_restrictions: Optional[List[str]] = Field(
        default=None,
        description="Examples: ['halal', 'vegan', 'gluten_free']"
    )
    mobility_constraints: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Examples: {'wheelchair_accessible': true, 'max_walking_distance_km': 2.0}"
    )

class EnvironmentState(BaseModel):
    """
    Real-time environmental snapshot from Data Scout.
    Strictly follows PDF Page 2 definition [cite: 57-61] with enhancements.
    
    Lifecycle:
    1. Scout.get_realtime_state() fetches this from external APIs
    2. Scout.compare_states(last, current) detects significant changes
    3. If change detected -> Emit AlertSignal -> Trigger Simulator.emergency_replan()
    """
    location_id: str = Field(..., description="Reference to the monitored location")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="When this snapshot was captured"
    )
    
    # Weather data
    weather_code: WeatherCode = Field(..., description="Standardized weather condition")
    temperature: float = Field(..., description="Temperature in Celsius")
    precipitation_probability: Optional[float] = Field(
        default=None,
        ge=0.0,
        le=1.0,
        description="Probability of rain (0.0-1.0)"
    )
    
    # Traffic data
    traffic_index: float = Field(
        ...,
        ge=0.0,
        le=10.0,
        description="Traffic congestion level (0=free flow, 10=gridlock)"
    )
    
    # Additional context (optional)
    is_poi_open: Optional[bool] = Field(
        default=None,
        description="Whether the target venue is currently open"
    )

class AlertSignal(BaseModel):
    """
    Event emitted by Scout when significant environment change detected.
    Strictly follows PDF Page 2 definition [cite: 68-72].
    
    Flow (PDF Page 3 Sequence Diagram):
    1. Scout detects change (e.g. weather: clear -> rain_heavy)
    2. Scout.compare_states() -> Creates AlertSignal
    3. Orchestrator.handle_alert_event(alert)
    4. Orchestrator -> Simulator.emergency_replan(current_plan, alert)
    5. Updated plan pushed to frontend via WebSocket
    """
    source: str = Field(
        default="SCOUT_AGENT",
        description="Which agent generated this alert"
    )
    change_type: str = Field(
        ...,
        description="Type of change: 'weather', 'traffic', 'venue_closure'"
    )
    message: str = Field(..., description="Human-readable explanation")
    trigger_value: str = Field(
        ...,
        description="The specific value that triggered alert (e.g. 'rain_heavy')"
    )
    severity: AlertSeverity = Field(..., description="[cite: 72]")
    
    # Context payload
    affected_plan_id: str = Field(..., description="Which TripPlan is affected")
    payload: EnvironmentState = Field(
        ...,
        description="The current environment snapshot that triggered this alert"
    )
    
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class ValidationResult(BaseModel):
    """
    Output of Validator.validate_constraints().
    Not explicitly in PDF but required by interface definition (PDF Page 3).
    
    Purpose:
    - Gate-keeping before DRAFT -> VERIFIED transition
    - Provide actionable feedback to user
    - Calculate preference matching score for ranking multiple plans
    """
    is_valid: bool = Field(..., description="Whether plan passes all hard constraints")
    violations: List[str] = Field(
        default=[],
        description=(
            "Hard constraint violations that MUST be fixed. "
            "Examples: ['Budget exceeded by $50', 'No halal restaurants in itinerary']"
        )
    )
    warnings: List[str] = Field(
        default=[],
        description=(
            "Soft warnings (not blocking but worth user attention). "
            "Examples: ['Tight 10-min transition between activities', 'High traffic expected at 5pm']"
        )
    )
    score: float = Field(
        ge=0.0,
        le=1.0,
        description=(
            "Overall quality score (0.0-1.0) based on preference matching. "
            "Calculated by Validator.calculate_score(). "
            "Used to rank multiple plan candidates from Simulator."
        )
    )
    details: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Additional structured info (e.g. budget breakdown, time analysis)"
    )

# ============================================================================
# SECTION 4: API INTERFACE MODELS (Request/Response DTOs)
# ============================================================================
# Purpose: Define the contracts for FastAPI endpoints (PDF Page 5)

class PlanGenerationRequest(BaseModel):
    """
    Input for POST /api/plan/generate (PDF Page 5)
    
    Example:
    {
        "intent": "Plan a romantic date in SF this Friday evening, budget $200",
        "user_id": "user_123",  // Optional: to load existing profile
        "preferences": {        // Optional: override/supplement profile
            "budget_limit": 200,
            "dietary_restrictions": ["vegan"]
        }
    }
    """
    intent: str = Field(
        ...,
        description="User's natural language planning request"
    )
    user_id: Optional[str] = Field(
        default=None,
        description="If provided, system will load existing UserProfile"
    )
    preferences: Optional[Dict[str, Any]] = Field(
        default=None,
        description=(
            "Partial or full preference overrides. "
            "Will be merged with UserProfile if user_id is provided. "
            "Can be used for one-off plans without creating a full profile."
        )
    )

class PlanGenerationResponse(BaseModel):
    """
    Output for POST /api/plan/generate
    
    Success case:
    {
        "success": true,
        "data": { <TripPlan JSON> },
        "validation": { <ValidationResult JSON> }
    }
    
    Failure case:
    {
        "success": false,
        "error": "Invalid budget constraint",
        "data": null
    }
    """
    success: bool
    data: Optional[TripPlan] = None
    validation: Optional[ValidationResult] = None
    error: Optional[str] = None

# ============================================================================
# CONFIGURATION & UTILITIES
# ============================================================================

class Config:
    """Pydantic model configuration"""
    json_encoders = {
        datetime: lambda v: v.isoformat()
    }
    use_enum_values = True  # Serialize enums as strings
