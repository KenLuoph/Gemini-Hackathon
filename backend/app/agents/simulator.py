# backend/app/agents/simulator.py
# Version: 2.0
# Last Updated: 2026-01-27
# Changes: Complete structure alignment, emergency_replan, system_instruction usage

import json
import logging
import uuid
from datetime import datetime
from typing import List
from app.services.llm_client import llm_client
from app.schemas.domain import (
    TripPlan, 
    ActivityItem,
    UserProfile, 
    PlanStatus, 
    EnvironmentState,
    AlertSignal,
    AlertSeverity,
    WeatherCode,
    ActivityType
)

logger = logging.getLogger(__name__)

# ============================================================================
# SYSTEM INSTRUCTION (Week 1 Weekend Todo Requirement)
# ============================================================================
# This is the "Constitution" that persists across all Gemini calls

SIMULATOR_SYSTEM_INSTRUCTION = """
You are an elite AI Travel Planner with expertise in:
- Operations Research (route optimization, time management)
- Budget Management (allocation strategies, contingency planning)
- Risk Assessment (weather sensitivity, traffic patterns)
- Market Economics (realistic pricing for services and venues)

MANDATORY OPERATIONAL RULES:

1. Geographic Logic Validation:
   - Calculate realistic travel time between locations
   - Flag transitions requiring >30 minutes within a 10-minute slot
   - Use standard speeds: 40 km/h urban, 100 km/h highway
   - Prefer clustered activities to minimize travel

2. Budget Calculation with REALISTIC PRICING:
   - Always include 10% safety buffer: B_buffer = B_total × 0.1
   - Break down by categories: food, transport, entertainment, accommodation
   - Ensure total ≤ user's budget_limit
   
   ⚠️ CRITICAL: USE REAL MARKET PRICES ⚠️
   
   You MUST use AUTHENTIC prices based on actual market rates in 2026:
   
   **DINING:**
   - Michelin 3-star dinner: $300-500 per person
   - Michelin 1-2 star dinner: $150-300 per person
   - Fine dining (non-Michelin): $80-150 per person
   - Mid-range restaurant: $40-80 per person
   - Casual dining: $20-40 per person
   - Fast food / food trucks: $10-20 per person
   
   **TRANSPORTATION:**
   - Helicopter tour (SF Bay): $250-500 per person
   - Private jet charter: $5,000-15,000 per flight
   - Limousine service: $100-300 per hour
   - Luxury car rental: $200-400 per day
   - Standard rideshare: $15-40 per trip
   - Public transit: $3-10 per trip
   
   **EXPERIENCES:**
   - Private yacht charter: $1,000-5,000 per day
   - Hot air balloon ride: $200-400 per person
   - Spa treatment (luxury): $150-300 per session
   - Wine tasting (premium): $50-150 per person
   - Museum admission: $15-30 per person
   - Movie theater: $15-25 per person
   
   **ACCOMMODATION:**
   - Five-star hotel: $400-1,000 per night
   - Four-star hotel: $200-400 per night
   - Mid-range hotel: $100-200 per night
   - Budget hotel: $50-100 per night
   
   **PRICING INTEGRITY RULES:**
   
   a) If user requests HIGH-END services (Michelin, helicopter, yacht, luxury) 
      that EXCEED their stated budget:
      - DO NOT artificially reduce prices to fit budget
      - DO NOT create "budget versions" of luxury experiences
      - DO NOT suggest "viewing from outside" as alternatives
      - INSTEAD: Generate the REALISTIC plan with REAL prices
      - LET THE VALIDATOR detect the budget violation
      - Example: User wants "Michelin dinner + helicopter" with $100 budget
        → Generate: Michelin $200 + Helicopter $300 = $500 total
        → Validator will flag: "Budget exceeded by $400"
   
   b) If you CANNOT provide the requested experience within budget:
      - DO NOT fake it with unrealistic low prices
      - INSTEAD: Generate the closest REALISTIC alternative
      - Example: User wants "luxury yacht" with $200 budget
        → Generate: "Bay cruise on public ferry" ($50) + "Waterfront dining" ($100)
        → Explain in reasoning_path why substitution was made
   
   c) NEVER use these deceptive tactics:
      - "Visit outside Michelin restaurant" ($0)
      - "Watch helicopters from viewpoint" ($0)
      - "Budget-friendly luxury experience" ($20)
      - "Affordable private yacht alternative" ($50)
      
   d) If budget is clearly insufficient for user's intent:
      - Use your best judgment to either:
        Option A: Generate realistic plan that WILL exceed budget (Validator catches it)
        Option B: Suggest genuinely comparable experiences at realistic prices
      - ALWAYS maintain pricing integrity

3. Weather Contingency Protocol:
   
   ⚠️ CRITICAL WEATHER SENSITIVITY RULES ⚠️
   
   A. If user is sensitive_to_rain (sensitive_to_rain: true):
      - This is a HARD CONSTRAINT, not a suggestion
      - User's explicit intent keywords (like "outdoor", "hiking", "beach") 
        should be REINTERPRETED as "weather-proof versions of these experiences"
      - MANDATORY ACTIONS:
        * ALL activities in main_itinerary MUST be Indoor type
        * If user requests outdoor-specific activities (hiking, beach, park):
          → Substitute with indoor equivalents:
            - "Hiking" → "Indoor climbing gym" or "Treadmill scenic video"
            - "Beach picnic" → "Indoor picnic-style dining at waterfront restaurant"
            - "Park walk" → "Botanical conservatory" or "Indoor garden"
        * Generate outdoor versions ONLY in alternatives list
        * In reasoning_path, explain: "User is sensitive to rain, so I converted 
          all outdoor activities to weather-proof indoor alternatives"
      - EXAMPLE TRANSFORMATION:
        User: "Plan hiking and beach picnic" + sensitive_to_rain: true
        ❌ WRONG: Generate outdoor hiking + beach activities
        ✅ RIGHT: Generate "Rock climbing gym" + "Seafood restaurant with bay views"
   
   B. If current weather is RAIN_HEAVY or STORM:
      - ALL main_itinerary activities MUST be Indoor type
      - Generate outdoor activities only in alternatives list
   
   C. For OUTDOOR activities with risk_score > 0.7:
      - MUST provide INDOOR alternative in alternatives list
      - Alternative must match time slot (±30 min acceptable)
      - Alternative budget ≤ original budget × 1.2
   
   D. Standard weather handling (user NOT sensitive, weather is good):
      - Balance indoor and outdoor activities normally
      - Provide alternatives for flexibility

4. Output Requirements:
   - MUST return valid JSON matching TripPlan schema
   - Include reasoning_path with chain-of-thought explanation
   - Set appropriate risk_score for each activity (0.0-1.0):
     * Outdoor activities in variable weather: 0.6-0.9
     * Indoor activities: 0.1-0.3
     * Activities dependent on specific conditions: 0.5-0.8
   - Generate at least 2 alternatives for flexibility
   - If you made pricing substitutions, EXPLAIN in reasoning_path

5. Quality Standards:
   - Activities should flow logically (no backtracking)
   - Time slots must not overlap
   - Include transition buffers (≥15 min between activities)
   - Optimize for geographic clustering when possible
   - Prioritize unique, memorable experiences over generic options

6. Transparency & Honesty:
   - If user's budget is insufficient for their stated desires:
     * State this clearly in reasoning_path
     * Explain what compromises were made
     * Suggest what budget WOULD be needed for original intent
   - Example reasoning_path:
     "User requested Michelin dinner ($250) and helicopter tour ($400) with $100 budget. 
     This is not feasible. I substituted with: upscale bistro ($80) and scenic bay cruise ($50), 
     which captures the romantic, elevated experience within budget. 
     To achieve the original plan, a budget of ~$700 would be required."

Remember: Your credibility depends on HONEST pricing and REALISTIC planning. 
It's better to exceed budget and let Validator flag it than to provide 
unrealistic "fake luxury" experiences that mislead users.
"""

class SimulatorAgent:
    """
    The Brain: Generates optimized trip plans using Gemini.
    
    Responsibilities (PDF Page 3):
    1. generate_scenarios(): Initial plan generation
    2. emergency_replan(): Dynamic plan adjustment when alerts trigger
    3. _optimize_route(): Geographic sequencing (private helper)
    
    Design Principles:
    - Prompt Engineering: Strict JSON structure enforcement
    - Context Awareness: Weather/traffic influence on plan quality
    - Fail-Safe: Pydantic validation + post-processing corrections
    """
    
    async def run(
        self, 
        intent: str, 
        preferences: UserProfile, 
        environment: EnvironmentState
    ) -> TripPlan:
        """
        Main entry point: Generate initial TripPlan based on user intent.
        
        Flow (PDF Page 3 Sequence Diagram):
        1. Orchestrator calls this after Scout provides EnvironmentState
        2. Build context-aware prompt
        3. Call Gemini with system instruction
        4. Validate and post-process response
        5. Return TripPlan with status=DRAFT
        
        Args:
            intent: User's natural language request
            preferences: UserProfile from Validator
            environment: Current conditions from Scout
        
        Returns:
            TripPlan with status=DRAFT (ready for Validator)
        """
        logger.info(
            f"Simulator.run() started | "
            f"Weather: {environment.weather_code} | "
            f"Traffic: {environment.traffic_index}/10"
        )
        
        # ===== Step 1: Build Weather-Aware Instructions =====
        weather_instruction = self._build_weather_instruction(environment.weather_code)
        
        # ===== Step 2: Define Exact JSON Structure =====
        # This prevents Gemini from hallucinating field names
        json_structure_template = """
        {
            "plan_id": "auto-generated-uuid",
            "name": "Creative Trip Title",
            "status": "draft",
            "reasoning_path": "Your step-by-step thought process here",
            "main_itinerary": [
                {
                    "activity_id": "auto-generated-uuid",
                    "name": "Activity Name",
                    "time_slot": "YYYY-MM-DD HH:MM - HH:MM",
                    "type": "indoor" | "outdoor",
                    "location": {
                        "lat": 37.7749,
                        "lng": -122.4194,
                        "address": "Full street address"
                    },
                    "budget": {
                        "amount": 50.0,
                        "currency": "USD",
                        "category": "food" | "transport" | "entertainment" | "general"
                    },
                    "description": "Brief description",
                    "risk_score": 0.0 to 1.0,
                    "constraints": {},
                    "status": "pending"
                }
            ],
            "alternatives": [
                // At least 2 indoor backup activities
            ]
        }
        """
        
        # ===== Step 3: Build User Prompt =====
        user_prompt = f"""
        --- CURRENT CONTEXT ---
        Date/Time: {datetime.now().strftime("%Y-%m-%d %H:%M")}
        Location: {environment.location_id}
        Weather: {environment.weather_code.value} (Temp: {environment.temperature}°C)
        Traffic Level: {environment.traffic_index}/10
        
        --- USER REQUEST ---
        Intent: "{intent}"
        
        --- USER PREFERENCES ---
        Budget Limit: ${preferences.budget_limit}
        Interests: {', '.join(preferences.preferences)}
        Rain Sensitive: {preferences.sensitive_to_rain}
        Dietary Restrictions: {preferences.dietary_restrictions or 'None'}
        Mobility Constraints: {preferences.mobility_constraints or 'None'}
        
        --- SPECIAL INSTRUCTIONS ---
        {weather_instruction}
        
        --- OUTPUT FORMAT ---
        Generate a JSON object following this EXACT structure:
        {json_structure_template}
        
        CRITICAL REMINDERS:
        - Use "lat" and "lng" (NOT "latitude"/"longitude")
        - Use "indoor"/"outdoor" (lowercase)
        - risk_score: outdoor activities should be 0.6-0.9, indoor 0.1-0.3
        - Include reasoning_path to explain your planning logic
        """
        
        # ===== Step 4: Call Gemini =====
        try:
            raw_json = await llm_client.generate_json(
                prompt=user_prompt,
                system_instruction=SIMULATOR_SYSTEM_INSTRUCTION,
                temperature=0.7  # Balanced creativity
            )
            
            # ===== Step 5: Clean and Parse =====
            cleaned_json = raw_json.replace("```json", "").replace("```", "").strip()
            data = json.loads(cleaned_json)
            
            # ===== Step 6: Post-Processing =====
            # Force correct values for critical fields
            data["plan_id"] = str(uuid.uuid4())
            data["status"] = PlanStatus.DRAFT.value
            data["created_at"] = datetime.utcnow().isoformat()
            data["updated_at"] = datetime.utcnow().isoformat()
            
            # Ensure all activities have valid IDs and status
            for activity in data.get("main_itinerary", []):
                if not activity.get("activity_id"):
                    activity["activity_id"] = str(uuid.uuid4())
                if not activity.get("status"):
                    activity["status"] = "pending"
                # Default risk_score if missing
                if "risk_score" not in activity:
                    activity["risk_score"] = 0.5 if activity["type"] == "outdoor" else 0.2
            
            for activity in data.get("alternatives", []):
                if not activity.get("activity_id"):
                    activity["activity_id"] = str(uuid.uuid4())
                if not activity.get("status"):
                    activity["status"] = "pending"
            
            # ===== Step 7: Pydantic Validation =====
            plan = TripPlan(**data)
            
            logger.info(f"TripPlan generated successfully | ID: {plan.plan_id}")
            return plan
            
        except json.JSONDecodeError as e:
            logger.error(f"Gemini returned invalid JSON: {e}")
            logger.error(f"Raw response: {raw_json[:500]}...")
            raise ValueError("Gemini generated malformed JSON. Please retry.")
        
        except Exception as e:
            logger.error(f"Schema validation or processing failed: {e}")
            # 安全地记录原始响应（data可能未定义）
            try:
                logger.error(f"Raw JSON: {cleaned_json[:1000]}...")
            except:
                logger.error(f"Could not log cleaned JSON")
            raise RuntimeError(f"Plan generation failed: {e}")
    
    async def emergency_replan(
        self,
        original_plan: TripPlan,
        alert: AlertSignal
    ) -> TripPlan:
        """
        Dynamic re-planning triggered by Scout alerts.
        
        Flow (PDF Page 3 Watchdog Sequence):
        1. Scout detects critical change (e.g., rain → storm)
        2. Orchestrator calls this with AlertSignal
        3. Filter affected activities based on risk_score and type
        4. Swap with alternatives from original plan
        5. Return updated plan (keeps same plan_id)
        
        Strategy:
        - If severity=INFO: No changes, just log
        - If severity=WARNING: Mark affected activities with warning flag
        - If severity=CRITICAL: Immediately swap outdoor→indoor
        
        Args:
            original_plan: Current active plan
            alert: Alert signal from Scout
        
        Returns:
            Updated TripPlan (may be same if no changes needed)
        """
        logger.info(
            f"emergency_replan() triggered | "
            f"Alert: {alert.change_type} | "
            f"Severity: {alert.severity}"
        )
        
        # ===== Step 1: Assess Severity =====
        if alert.severity == AlertSeverity.INFO:
            logger.info("INFO level alert - no action needed")
            return original_plan
        
        # ===== Step 2: Identify Affected Activities =====
        current_weather = alert.payload.weather_code
        affected_activities = []
        
        for activity in original_plan.main_itinerary:
            # Critical weather + outdoor activity = must replace
            if (alert.severity == AlertSeverity.CRITICAL and
                activity.type == ActivityType.OUTDOOR and
                activity.risk_score > 0.6):
                affected_activities.append(activity)
            
            # Warning weather + high-risk outdoor = should replace
            elif (alert.severity == AlertSeverity.WARNING and
                  activity.type == ActivityType.OUTDOOR and
                  activity.risk_score > 0.8):
                affected_activities.append(activity)
        
        if not affected_activities:
            logger.info("No activities affected by this alert")
            return original_plan
        
        logger.info(f"Found {len(affected_activities)} activities to replace")
        
        # ===== Step 3: Find Suitable Alternatives =====
        updated_itinerary = original_plan.main_itinerary.copy()
        
        for affected in affected_activities:
            # Find best alternative match
            best_alternative = self._find_best_alternative(
                affected,
                original_plan.alternatives,
                current_weather
            )
            
            if best_alternative:
                # Swap in itinerary
                index = updated_itinerary.index(affected)
                updated_itinerary[index] = best_alternative
                logger.info(
                    f"Swapped: {affected.name} → {best_alternative.name}"
                )
            else:
                logger.warning(
                    f"No suitable alternative found for {affected.name}"
                )
        
        # ===== Step 4: Build Updated Plan =====
        updated_plan = original_plan.model_copy(deep=True)
        updated_plan.main_itinerary = updated_itinerary
        updated_plan.updated_at = datetime.utcnow()
        updated_plan.status = PlanStatus.ACTIVE  # Keep active after update
        
        # Add reasoning for audit trail
        if updated_plan.reasoning_path:
            updated_plan.reasoning_path += f"\n[AUTO-UPDATE {datetime.utcnow().isoformat()}]: Reacted to {alert.change_type} alert. Swapped {len(affected_activities)} outdoor activities."
        
        return updated_plan
    
    # ========================================================================
    # PRIVATE HELPER METHODS
    # ========================================================================
    
    def _build_weather_instruction(self, weather: WeatherCode) -> str:
        """Generate weather-specific planning instructions."""
        if weather in [WeatherCode.RAIN_HEAVY, WeatherCode.STORM]:
            return """
            ⚠️ SEVERE WEATHER ALERT:
            - ALL activities in main_itinerary MUST be Indoor type
            - Generate at least 3 outdoor alternatives with risk_score > 0.8
            - Prioritize venues with parking (minimize walking)
            """
        elif weather == WeatherCode.RAIN_LIGHT:
            return """
            🌧️ LIGHT RAIN CONDITIONS:
            - Prioritize Indoor activities but Outdoor acceptable if low-risk
            - Ensure alternatives list has indoor backups
            - Add 15-min buffer for transitions
            """
        elif weather == WeatherCode.CLEAR:
            return """
            ☀️ IDEAL WEATHER:
            - Balance Indoor and Outdoor activities
            - Outdoor activities can have higher risk_scores
            - Still provide 1-2 indoor alternatives for flexibility
            """
        else:
            return "Generate balanced indoor/outdoor mix with contingency alternatives."
    
    def _find_best_alternative(
        self,
        target_activity: ActivityItem,
        alternatives: List[ActivityItem],
        current_weather: WeatherCode
    ) -> ActivityItem | None:
        """
        Find best alternative match for a given activity.
        
        Matching criteria (priority order):
        1. Type: Must be Indoor if weather is severe
        2. Time: Should overlap with target time_slot
        3. Budget: Should be ≤ target budget × 1.2
        4. Category: Prefer same category (food→food)
        """
        indoor_alternatives = [
            alt for alt in alternatives
            if alt.type == ActivityType.INDOOR
        ]
        
        if not indoor_alternatives:
            logger.warning("No indoor alternatives available")
            return None
        
        # Simple heuristic: pick first indoor alternative
        # TODO: Implement scoring system for better matching
        return indoor_alternatives[0]

# ============================================================================
# Singleton Instance Export
# ============================================================================
simulator = SimulatorAgent()