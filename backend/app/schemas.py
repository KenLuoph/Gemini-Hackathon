# /backend/app/schemas.py

from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from enum import Enum

# --- [PDF Section 4 Alignment] Lifecycle Status ---
class PlanStatus(str, Enum):
    DRAFT = "draft"           # Initial creation
    VALIDATING = "validating" # Checking by Validator
    VERIFIED = "verified"     # Validation passed, waiting for user confirmation
    ACTIVE = "active"         # Confirmed by user, Watchdog monitoring
    COMPLETED = "completed"
    CANCELLED = "cancelled"

# --- Basic Components ---
class GeoLocation(BaseModel):
    lat: float = Field(..., description="Latitude")
    lng: float = Field(..., description="Longitude")
    address: str = Field(..., description="Human readable address")

class BudgetCategory(str, Enum):
    FOOD = "food"
    TRANSPORT = "transport"
    TICKET = "ticket"
    SHOPPING = "shopping"
    OTHER = "other"

class BudgetInfo(BaseModel):
    amount: float = Field(..., description="Estimated cost")
    currency: str = Field(default="USD", description="ISO Currency Code")
    category: BudgetCategory

# --- Core Activity Model ---
class ActivityItem(BaseModel):
    activity_name: str = Field(..., description="Name of the activity")
    time_slot: str = Field(..., description="ISO start time or duration")
    description: Optional[str] = None
    location: GeoLocation
    budget: BudgetInfo
    
    # [Week 1 Requirement] 
    constraints: Optional[Dict[str, bool]] = Field(default=None)
    risk_score: float = Field(default=0.0, ge=0.0, le=1.0)

# --- [PDF Alignment] Top-level Planning Model ---
class TripPlan(BaseModel):
    plan_id: str = Field(..., description="UUID")
    title: str = Field(..., description="Trip title")
    
    # [NEW] State machine field, aligned to PDF Lifecycle
    status: PlanStatus = Field(default=PlanStatus.DRAFT, description="Current lifecycle state")
    
    reasoning_path: str = Field(..., description="Chain of Thought")
    main_itinerary: List[ActivityItem]
    alternatives: List[ActivityItem] = []

class UserRequest(BaseModel):
    user_id: str
    query: str
    user_location: Optional[GeoLocation] = None