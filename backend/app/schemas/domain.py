# backend/app/schemas/domain.py

from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from enum import Enum
from datetime import datetime
import uuid

# --- Enums (Based on PDF Page 2 & 4) ---

class PlanStatus(str, Enum):
    """Lifecycle states from PDF Page 4 [cite: 131-139]"""
    DRAFT = "draft"
    VALIDATING = "validating"
    VERIFIED = "verified"
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class ActivityType(str, Enum):
    """From PDF Page 2 ActivityItem [cite: 51]"""
    INDOOR = "Indoor"
    OUTDOOR = "Outdoor"

class AlertSeverity(str, Enum):
    """From PDF Page 2 AlertSignal [cite: 72]"""
    INFO = "INFO"
    WARNING = "WARNING"
    CRITICAL = "CRITICAL"

# --- Shared Components ---

class GeoLocation(BaseModel):
    """Standard component for Location [cite: 48]"""
    lat: float
    lng: float
    address: str

class BudgetInfo(BaseModel):
    """Standard component for Budget [cite: 50]"""
    amount: float
    currency: str = "USD"
    category: str = "general"

# --- Domain Models (PDF Page 2) ---

class ActivityItem(BaseModel):
    """
    Atomic unit of a plan.
    Strictly follows PDF Page 2 definition [cite: 46-51].
    """
    activity_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str = Field(..., description="Activity name [cite: 49]")
    time_slot: str = Field(..., description="Time duration e.g. '10:00-11:00' [cite: 47]")
    location: GeoLocation = Field(..., description="[cite: 48]")
    budget: BudgetInfo = Field(..., description="[cite: 50]")
    type: ActivityType = Field(..., description="Indoor/Outdoor [cite: 51]")
    
    # Extra fields for Logic (not strictly in Class Diagram but implied by Logic)
    description: Optional[str] = None

class TripPlan(BaseModel):
    """
    The core object passed between Agents.
    Strictly follows PDF Page 2 definition [cite: 34-39].
    """
    plan_id: str = Field(..., description="UUID [cite: 35]")
    name: str = Field(..., description="Plan title [cite: 36]")
    status: PlanStatus = Field(default=PlanStatus.DRAFT, description="[cite: 39]")
    
    main_itinerary: List[ActivityItem] = Field(..., description="[cite: 37]")
    alternatives: List[ActivityItem] = Field(default=[], description="[cite: 38]")

class UserProfile(BaseModel):
    """
    Used by Validator Agent.
    Strictly follows PDF Page 2 definition .
    """
    user_id: str
    budget_limit: float
    preferences: List[str]
    sensitive_to_rain: bool = False

class EnvironmentState(BaseModel):
    """
    Used by Data Scout.
    Strictly follows PDF Page 2 definition [cite: 57-61].
    """
    location_id: str
    timestamp: datetime
    weather_condition: str
    traffic_level: str

class AlertSignal(BaseModel):
    """
    Triggered by Scout, consumed by Orchestrator.
    Strictly follows PDF Page 2 definition [cite: 68-72].
    """
    change_type: str
    message: str
    trigger_value: str
    severity: AlertSeverity

# --- API Interaction Models (PDF Page 5) ---

class PlanGenerationRequest(BaseModel):
    """
    Strictly follows PDF Page 5 API Spec.
    Input: {"intent": "...", "preferences": {...}}
    """
    intent: str
    preferences: UserProfile # Reusing UserProfile as the structure for preferences