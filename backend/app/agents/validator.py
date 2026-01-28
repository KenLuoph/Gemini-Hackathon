# backend/app/agents/validator.py
# Version: 1.0
# Last Updated: 2026-01-27
# Purpose: Constraint validation and quality scoring (PDF Page 3 Phase 3)

import logging
from typing import List, Dict, Any
from datetime import datetime, timedelta

from app.schemas.domain import (
    TripPlan,
    ActivityItem,
    UserProfile,
    ValidationResult,
    ActivityType
)

logger = logging.getLogger(__name__)

class ValidatorAgent:
    """
    The Gatekeeper: Validates plans against user constraints and scores quality.
    
    Responsibilities (PDF Page 3):
    1. validate_constraints(): Check hard constraints (budget, time, dietary)
    2. calculate_score(): Evaluate preference matching and plan quality
    3. _check_budget(): Budget validation logic
    4. _check_time_conflicts(): Timeline feasibility
    5. _check_dietary_restrictions(): Food constraint validation
    
    Design Principles:
    - Fail-Fast: Hard constraint violations block VERIFIED status
    - Soft Warnings: Advisory feedback that doesn't block
    - Transparent Scoring: Explainable quality metrics
    """
    
    def __init__(self):
        # Constraint thresholds
        self.BUDGET_BUFFER_PERCENT = 0.10  # Allow 10% over budget as warning
        self.MIN_TRANSITION_TIME = 15      # Minimum minutes between activities
        self.MAX_DAILY_ACTIVITIES = 8      # Prevent overloaded schedules
    
    async def validate_constraints(
        self,
        plan: TripPlan,
        profile: UserProfile
    ) -> ValidationResult:
        """
        Comprehensive constraint validation.
        
        Flow (PDF Page 3):
        1. Check budget compliance
        2. Check time conflicts
        3. Check dietary restrictions
        4. Check mobility constraints
        5. Generate warnings for soft issues
        6. Calculate overall quality score
        
        Args:
            plan: TripPlan from Simulator (status=DRAFT)
            profile: UserProfile with constraints
        
        Returns:
            ValidationResult with is_valid, violations, warnings, score
        """
        logger.info(f"🔍 Validating plan {plan.plan_id}")
        
        violations: List[str] = []
        warnings: List[str] = []
        details: Dict[str, Any] = {}
        
        # ===== Hard Constraint Checks =====
        
        # 1. Budget Validation
        budget_result = self._check_budget(plan, profile)
        if not budget_result["valid"]:
            violations.extend(budget_result["violations"])
        warnings.extend(budget_result["warnings"])
        details["budget_breakdown"] = budget_result["breakdown"]
        
        # 2. Time Conflict Detection
        time_result = self._check_time_conflicts(plan)
        if not time_result["valid"]:
            violations.extend(time_result["violations"])
        warnings.extend(time_result["warnings"])
        
        # 3. Dietary Restrictions
        if profile.dietary_restrictions:
            dietary_result = self._check_dietary_restrictions(
                plan, 
                profile.dietary_restrictions
            )
            if not dietary_result["valid"]:
                violations.extend(dietary_result["violations"])
            warnings.extend(dietary_result["warnings"])
        
        # 4. Mobility Constraints
        if profile.mobility_constraints:
            mobility_result = self._check_mobility_constraints(
                plan,
                profile.mobility_constraints
            )
            if not mobility_result["valid"]:
                violations.extend(mobility_result["violations"])
            warnings.extend(mobility_result["warnings"])
        
        # 5. Weather Sensitivity
        if profile.sensitive_to_rain:
            weather_result = self._check_weather_sensitivity(plan)
            warnings.extend(weather_result["warnings"])
        
        # ===== Quality Scoring =====
        score = self.calculate_score(plan, profile.preferences)
        
        # ===== Final Result =====
        is_valid = len(violations) == 0
        
        if is_valid:
            logger.info(
                f"✅ Validation passed | Score: {score:.2f} | "
                f"Warnings: {len(warnings)}"
            )
        else:
            logger.warning(
                f"❌ Validation failed | Violations: {len(violations)}"
            )
        
        return ValidationResult(
            is_valid=is_valid,
            violations=violations,
            warnings=warnings,
            score=score,
            details=details
        )
    
    def calculate_score(
        self,
        plan: TripPlan,
        preferences: List[str]
    ) -> float:
        """
        Calculate plan quality score (0.0-1.0).
        
        Scoring Factors:
        1. Preference Matching (40%): How well activities match user interests
        2. Activity Diversity (20%): Variety of activity types
        3. Time Optimization (20%): Efficient use of time, minimal gaps
        4. Budget Efficiency (10%): Good value for money
        5. Risk Mitigation (10%): Availability of alternatives
        
        Args:
            plan: TripPlan to score
            preferences: User interest tags (e.g., ["food", "art", "hiking"])
        
        Returns:
            Float score between 0.0 (poor) and 1.0 (excellent)
        """
        logger.debug(f"📊 Calculating quality score for plan {plan.plan_id}")
        
        scores = {
            "preference_match": 0.0,
            "diversity": 0.0,
            "time_optimization": 0.0,
            "budget_efficiency": 0.0,
            "risk_mitigation": 0.0
        }
        
        if not plan.main_itinerary:
            return 0.0
        
        # ===== 1. Preference Matching (40%) =====
        if preferences:
            preference_set = set(p.lower() for p in preferences)
            matched_activities = 0
            
            for activity in plan.main_itinerary:
                # Simple keyword matching (can be enhanced with NLP)
                activity_text = (activity.name + " " + (activity.description or "")).lower()
                if any(pref in activity_text for pref in preference_set):
                    matched_activities += 1
            
            scores["preference_match"] = matched_activities / len(plan.main_itinerary)
        else:
            scores["preference_match"] = 0.5  # Neutral if no preferences
        
        # ===== 2. Activity Diversity (20%) =====
        activity_types = set(act.type for act in plan.main_itinerary)
        budget_categories = set(act.budget.category for act in plan.main_itinerary)
        
        # More variety = higher score
        type_diversity = len(activity_types) / 2  # Max 2 types (Indoor/Outdoor)
        category_diversity = min(len(budget_categories) / 4, 1.0)  # Max 4 categories
        scores["diversity"] = (type_diversity + category_diversity) / 2
        
        # ===== 3. Time Optimization (20%) =====
        time_score = self._calculate_time_efficiency(plan)
        scores["time_optimization"] = time_score
        
        # ===== 4. Budget Efficiency (10%) =====
        # Activities should utilize budget well (not too cheap, not wasteful)
        total_budget = sum(act.budget.amount for act in plan.main_itinerary)
        avg_per_activity = total_budget / len(plan.main_itinerary)
        
        # Penalize if too cheap (< $20/activity) or too expensive (> $200/activity)
        if 20 <= avg_per_activity <= 200:
            scores["budget_efficiency"] = 1.0
        elif avg_per_activity < 20:
            scores["budget_efficiency"] = avg_per_activity / 20
        else:
            scores["budget_efficiency"] = max(0.5, 200 / avg_per_activity)
        
        # ===== 5. Risk Mitigation (10%) =====
        # Having alternatives improves score
        if plan.alternatives:
            alternative_ratio = len(plan.alternatives) / len(plan.main_itinerary)
            scores["risk_mitigation"] = min(alternative_ratio / 0.5, 1.0)  # 50% coverage = perfect
        else:
            scores["risk_mitigation"] = 0.0
        
        # ===== Weighted Final Score =====
        weights = {
            "preference_match": 0.40,
            "diversity": 0.20,
            "time_optimization": 0.20,
            "budget_efficiency": 0.10,
            "risk_mitigation": 0.10
        }
        
        final_score = sum(scores[k] * weights[k] for k in scores)
        
        logger.debug(
            f"Score breakdown: "
            f"Preference={scores['preference_match']:.2f}, "
            f"Diversity={scores['diversity']:.2f}, "
            f"Time={scores['time_optimization']:.2f}, "
            f"Budget={scores['budget_efficiency']:.2f}, "
            f"Risk={scores['risk_mitigation']:.2f} "
            f"→ Final={final_score:.2f}"
        )
        
        return round(final_score, 2)
    
    # ========================================================================
    # PRIVATE VALIDATION METHODS
    # ========================================================================
    
    def _check_budget(
        self,
        plan: TripPlan,
        profile: UserProfile
    ) -> Dict[str, Any]:
        """
        Validate budget constraints.
        
        Logic (Week 1 requirement):
        - Calculate total = sum of all activities
        - Add 10% buffer: B_buffer = B_total × 0.1
        - Total + Buffer must be ≤ profile.budget_limit
        
        Returns:
            {
                "valid": bool,
                "violations": List[str],
                "warnings": List[str],
                "breakdown": Dict
            }
        """
        violations = []
        warnings = []
        
        # Calculate totals by category
        breakdown = {}
        total = 0.0
        
        for activity in plan.main_itinerary:
            category = activity.budget.category
            amount = activity.budget.amount
            
            if category not in breakdown:
                breakdown[category] = 0.0
            breakdown[category] += amount
            total += amount
        
        # Add 10% buffer
        buffer = total * self.BUDGET_BUFFER_PERCENT
        total_with_buffer = total + buffer
        
        breakdown["subtotal"] = total
        breakdown["buffer_10%"] = buffer
        breakdown["total_with_buffer"] = total_with_buffer
        breakdown["user_limit"] = profile.budget_limit
        
        # Check violation
        if total_with_buffer > profile.budget_limit:
            overage = total_with_buffer - profile.budget_limit
            violations.append(
                f"Budget exceeded: ${total_with_buffer:.2f} "
                f"(limit: ${profile.budget_limit:.2f}, "
                f"over by: ${overage:.2f})"
            )
        
        # Warning if close to limit (within 5%)
        elif total_with_buffer > profile.budget_limit * 0.95:
            warnings.append(
                f"Budget usage high: ${total_with_buffer:.2f} "
                f"(95%+ of ${profile.budget_limit:.2f} limit)"
            )
        
        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "warnings": warnings,
            "breakdown": breakdown
        }
    
    def _check_time_conflicts(self, plan: TripPlan) -> Dict[str, Any]:
        """
        Detect time conflicts and insufficient transition buffers.
        
        Checks:
        1. No overlapping activities
        2. Minimum 15-min buffer between activities
        3. Realistic daily schedule (not overloaded)
        
        Returns:
            {
                "valid": bool,
                "violations": List[str],
                "warnings": List[str]
            }
        """
        violations = []
        warnings = []
        
        WRAPPER_KEYWORDS = ["transportation", "travel budget", "general", "overall"]
        
        activities_to_check = [
            act for act in plan.main_itinerary
            if not any(keyword in act.name.lower() for keyword in WRAPPER_KEYWORDS)
        ]
        
        if len(activities_to_check) > self.MAX_DAILY_ACTIVITIES:
            warnings.append(
                f"Schedule may be too packed: {len(activities_to_check)} activities "
                f"(recommended max: {self.MAX_DAILY_ACTIVITIES})"
            )
        
        # Parse time slots and check for conflicts
        # Format: "YYYY-MM-DD HH:MM - HH:MM" or "HH:MM - HH:MM"
        activities_with_times = []
        
        for i, activity in enumerate(plan.main_itinerary):
            try:
                time_slot = activity.time_slot
                
                # Simple parsing (can be enhanced with regex)
                if " - " in time_slot:
                    parts = time_slot.split(" - ")
                    if len(parts) == 2:
                        start_str, end_str = parts
                        
                        # Extract time only (ignore date for now)
                        if ":" in start_str and ":" in end_str:
                            activities_with_times.append({
                                "index": i,
                                "name": activity.name,
                                "start": start_str.split()[-1],  # Get last part (HH:MM)
                                "end": end_str.split()[0]        # Get first part (HH:MM)
                            })
            
            except Exception as e:
                warnings.append(
                    f"Could not parse time slot for activity {i+1}: {activity.time_slot}"
                )
        
        # Check transitions
        for i in range(len(activities_with_times) - 1):
            current = activities_with_times[i]
            next_act = activities_with_times[i + 1]
            
            try:
                # Simple time comparison (assumes same day)
                current_end_h, current_end_m = map(int, current["end"].split(":"))
                next_start_h, next_start_m = map(int, next_act["start"].split(":"))
                
                current_end_mins = current_end_h * 60 + current_end_m
                next_start_mins = next_start_h * 60 + next_start_m
                
                gap = next_start_mins - current_end_mins
                
                if gap < 0:
                    violations.append(
                        f"Time overlap: '{current['name']}' ends at {current['end']}, "
                        f"but '{next_act['name']}' starts at {next_act['start']}"
                    )
                elif gap < self.MIN_TRANSITION_TIME:
                    warnings.append(
                        f"Tight schedule: Only {gap} minutes between "
                        f"'{current['name']}' and '{next_act['name']}' "
                        f"(recommended: {self.MIN_TRANSITION_TIME}+ min)"
                    )
            
            except Exception as e:
                logger.debug(f"Time comparison failed: {e}")
        
        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "warnings": warnings
        }
    
    def _check_dietary_restrictions(
        self,
        plan: TripPlan,
        restrictions: List[str]
    ) -> Dict[str, Any]:
        """
        Validate dietary constraints for food activities.
        
        Restrictions examples: ["halal", "vegan", "gluten_free", "kosher"]
        
        Note: This is basic keyword matching. Production should use
        dedicated food database or Yelp API categories.
        
        Returns:
            {
                "valid": bool,
                "violations": List[str],
                "warnings": List[str]
            }
        """
        violations = []
        warnings = []
        
        # Find food-related activities
        food_activities = [
            act for act in plan.main_itinerary
            if act.budget.category == "food" or
               "restaurant" in act.name.lower() or
               "cafe" in act.name.lower() or
               "food" in act.name.lower()
        ]
        
        if not food_activities and any(r in ["halal", "kosher", "vegan"] for r in restrictions):
            warnings.append(
                f"No food activities found, but dietary restrictions specified: "
                f"{', '.join(restrictions)}"
            )
            return {"valid": True, "violations": [], "warnings": warnings}
        
        # Check each food activity
        for activity in food_activities:
            activity_text = (activity.name + " " + (activity.description or "")).lower()
            
            # Check if constraints field mentions dietary compliance
            if activity.constraints:
                constraints_text = str(activity.constraints).lower()
                activity_text += " " + constraints_text
            
            # Simple keyword matching (production needs better logic)
            for restriction in restrictions:
                restriction_lower = restriction.lower()
                
                if restriction_lower not in activity_text:
                    violations.append(
                        f"Activity '{activity.name}' may not meet dietary requirement: {restriction}"
                    )
        
        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "warnings": warnings
        }
    
    def _check_mobility_constraints(
        self,
        plan: TripPlan,
        constraints: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Validate mobility constraints.
        
        Constraints examples:
        {
            "wheelchair_accessible": true,
            "max_walking_distance_km": 2.0,
            "requires_parking": true
        }
        
        Returns:
            {
                "valid": bool,
                "violations": List[str],
                "warnings": List[str]
            }
        """
        violations = []
        warnings = []
        
        # Check wheelchair accessibility
        if constraints.get("wheelchair_accessible"):
            for activity in plan.main_itinerary:
                # Check if activity explicitly mentions accessibility
                if activity.constraints:
                    if not activity.constraints.get("wheelchair_accessible"):
                        warnings.append(
                            f"Activity '{activity.name}' accessibility not confirmed"
                        )
        
        # Check walking distance
        max_walking_km = constraints.get("max_walking_distance_km")
        if max_walking_km:
            # TODO: Calculate actual distances between activities using haversine
            # For now, just issue a generic warning
            warnings.append(
                f"Walking distance validation requires geographic calculation "
                f"(max allowed: {max_walking_km}km)"
            )
        
        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "warnings": warnings
        }
    
    def _check_weather_sensitivity(self, plan: TripPlan) -> Dict[str, Any]:
        """
        Check if plan adequately handles rain sensitivity.
        
        For sensitive_to_rain users:
        - Should have indoor alternatives for outdoor activities
        - Outdoor activities should have low risk_score
        
        Returns:
            {
                "warnings": List[str]
            }
        """
        warnings = []
        
        outdoor_activities = [
            act for act in plan.main_itinerary
            if act.type == ActivityType.OUTDOOR
        ]
        
        if outdoor_activities:
            # Check if alternatives exist
            indoor_alternatives = [
                act for act in plan.alternatives
                if act.type == ActivityType.INDOOR
            ]
            
            if not indoor_alternatives:
                warnings.append(
                    "User is rain-sensitive, but no indoor alternatives provided "
                    f"for {len(outdoor_activities)} outdoor activities"
                )
            
            # Check risk scores
            high_risk_outdoor = [
                act for act in outdoor_activities
                if act.risk_score > 0.7
            ]
            
            if high_risk_outdoor:
                warnings.append(
                    f"{len(high_risk_outdoor)} outdoor activities have high weather risk "
                    "(score > 0.7). Consider indoor alternatives."
                )
        
        return {"warnings": warnings}
    
    def _calculate_time_efficiency(self, plan: TripPlan) -> float:
        """
        Calculate how efficiently time is used.
        
        Factors:
        - Activity duration utilization
        - Gap minimization (but not too tight)
        - Balanced pacing
        
        Returns:
            Score 0.0-1.0
        """
        if len(plan.main_itinerary) < 2:
            return 0.5  # Neutral for single activity
        
        # Simple heuristic: penalize large gaps or too many short activities
        # Production would analyze actual time slots
        
        avg_activities_per_day = len(plan.main_itinerary)  # Assuming single day
        
        if 3 <= avg_activities_per_day <= 6:
            return 1.0  # Optimal
        elif avg_activities_per_day < 3:
            return 0.6  # Underutilized
        else:
            return 0.7  # Potentially rushed

# ============================================================================
# Singleton Instance Export
# ============================================================================
validator = ValidatorAgent()