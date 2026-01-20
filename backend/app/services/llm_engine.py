# backend/app/services/llm_engine.py

import os
import json
import logging
from datetime import datetime
import google.generativeai as genai
from dotenv import load_dotenv

# Import our rigid data structure
from app.schemas import TripPlan, GeoLocation

# Load environment variables
load_dotenv()

# Configure Logging
logger = logging.getLogger(__name__)

# Initialize Gemini Client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY not found in environment variables.")

genai.configure(api_key=GEMINI_API_KEY)

# --- SYSTEM PROMPT DEFINITION ---
# This acts as the "Constitution" for the AI Agent.
# It enforces the role of a Senior Travel Architect.
SYSTEM_INSTRUCTION = """
You are a Senior Travel Architect & Life Planner AI.
Your goal is to create a detailed, executable trip plan based on user requests.

CRITICAL OUTPUT RULES:
1. You MUST output a single valid JSON object.
2. The JSON MUST strictly match the 'TripPlan' schema structure.
3. 'reasoning_path': Before planning, explain your logic here. Why this location? Why this time?
4. 'risk_score': For each activity, estimate a risk score (0.0 - 1.0). 
   - Indoor/Low stakes = 0.1
   - Outdoor/Weather dependent = 0.8
   - Tight schedule = 0.6
5. 'alternatives': Always provide 1-2 backup options for high-risk activities.
6. 'status': Always set initial status to 'draft'.

CURRENT CONTEXT:
- Today's Date: {current_date}
- User Location: {user_location_str}
"""

class LLMEngine:
    def __init__(self):
        # We use gemini-1.5-pro for complex reasoning and JSON adherence
        self.model = genai.GenerativeModel(
            model_name="gemini-1.5-pro-latest",
            system_instruction=SYSTEM_INSTRUCTION.format(
                current_date=datetime.now().strftime("%Y-%m-%d %A"),
                user_location_str="Unknown" # Default, can be updated per request
            )
        )

    def generate_plan(self, user_query: str, user_location: GeoLocation = None) -> TripPlan:
        """
        Orchestrates the LLM call to convert natural language into a structured TripPlan.
        """
        
        # 1. Construct the prompt with dynamic context
        location_str = f"{user_location.address} ({user_location.lat}, {user_location.lng})" if user_location else "Unknown"
        
        # We reinforce the schema requirement in the user prompt as well
        prompt = f"""
        User Request: "{user_query}"
        User Current Location: {location_str}

        Task: Generate a full TripPlan JSON. 
        Ensure 'plan_id' is a unique UUID string.
        Ensure 'status' is 'draft'.
        """

        try:
            logger.info(f"Sending request to Gemini: {user_query}")
            
            # 2. Call Gemini with JSON enforcement
            response = self.model.generate_content(
                prompt,
                generation_config={
                    "response_mime_type": "application/json",
                    "temperature": 0.7, # Slightly creative but grounded
                }
            )

            # 3. Parse and Validate
            # The response.text is a JSON string. We parse it into a dict, 
            # then feed it to Pydantic for rigorous validation.
            raw_json = json.loads(response.text)
            
            logger.info("Gemini response received. Validating against Schema...")
            
            # This step will raise an error if Gemini hallucinated a bad field
            validated_plan = TripPlan(**raw_json)
            
            logger.info(f"Plan generated successfully: {validated_plan.plan_id}")
            return validated_plan

        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode JSON from Gemini: {e}")
            raise ValueError("AI generated invalid JSON format.")
        except Exception as e:
            logger.error(f"LLM Engine Error: {e}")
            raise e

# Singleton instance for easy import
llm_engine = LLMEngine()