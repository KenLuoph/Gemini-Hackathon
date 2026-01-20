import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content

# Define the Tool Schema for Gemini Function Calling
# This strictly mirrors the Pydantic models in schemas.py
plan_tool = content.Tool(
    function_declarations=[
        content.FunctionDeclaration(
            name="create_travel_plan",
            description="Generate a detailed travel itinerary including budget, geolocation, and alternatives.",
            parameters=content.Schema(
                type=content.Type.OBJECT,
                properties={
                    "plan_id": content.Schema(
                        type=content.Type.STRING, 
                        description="Unique ID for the plan"
                    ),
                    "trip_name": content.Schema(
                        type=content.Type.STRING, 
                        description="Name of the trip (e.g., 'Weekend in SF')"
                    ),
                    # 1. Main Itinerary (List of Activities)
                    "main_itinerary": content.Schema(
                        type=content.Type.ARRAY,
                        description="Primary sequence of activities",
                        items=content.Schema(
                            type=content.Type.OBJECT,
                            properties={
                                "id": content.Schema(type=content.Type.STRING),
                                "time_slot": content.Schema(type=content.Type.STRING),
                                "activity_name": content.Schema(type=content.Type.STRING),
                                "description": content.Schema(type=content.Type.STRING),
                                # Nested Object: Location
                                "location": content.Schema(
                                    type=content.Type.OBJECT,
                                    properties={
                                        "address": content.Schema(type=content.Type.STRING),
                                        "lat": content.Schema(type=content.Type.NUMBER),
                                        "lng": content.Schema(type=content.Type.NUMBER),
                                    },
                                    required=["address"]
                                ),
                                # Nested Object: Budget
                                "budget": content.Schema(
                                    type=content.Type.OBJECT,
                                    properties={
                                        "amount": content.Schema(type=content.Type.NUMBER),
                                        "currency": content.Schema(type=content.Type.STRING),
                                        "category": content.Schema(type=content.Type.STRING),
                                    },
                                    required=["amount", "currency"]
                                )
                            },
                            required=["time_slot", "activity_name", "location", "budget"]
                        )
                    ),
                    # 2. Alternatives / Plan B (Crucial for Dynamic Logic)
                    "alternatives": content.Schema(
                        type=content.Type.ARRAY,
                        description="Backup activities to use if main plan fails (e.g., bad weather)",
                        items=content.Schema(
                            type=content.Type.OBJECT,
                            # Same structure as main activity
                            properties={
                                "id": content.Schema(type=content.Type.STRING),
                                "time_slot": content.Schema(type=content.Type.STRING),
                                "activity_name": content.Schema(type=content.Type.STRING, description="Alternative activity"),
                                "description": content.Schema(type=content.Type.STRING, description="Why pick this? (e.g. Indoor option)"),
                                "location": content.Schema(
                                    type=content.Type.OBJECT,
                                    properties={
                                        "address": content.Schema(type=content.Type.STRING),
                                        "lat": content.Schema(type=content.Type.NUMBER),
                                        "lng": content.Schema(type=content.Type.NUMBER),
                                    },
                                    required=["address"]
                                ),
                                "budget": content.Schema(
                                    type=content.Type.OBJECT,
                                    properties={
                                        "amount": content.Schema(type=content.Type.NUMBER),
                                        "currency": content.Schema(type=content.Type.STRING),
                                        "category": content.Schema(type=content.Type.STRING),
                                    },
                                    required=["amount"]
                                )
                            },
                            required=["activity_name", "location"]
                        )
                    )
                },
                required=["trip_name", "main_itinerary", "alternatives"]
            )
        )
    ]
)