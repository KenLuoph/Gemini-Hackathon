# backend/app/services/llm_client.py

import os
import logging
import time
from dotenv import load_dotenv, find_dotenv
from google import genai
from google.genai import types

# Force reload environment variables from .env file
load_dotenv(find_dotenv(), override=True)
logger = logging.getLogger(__name__)

class GeminiClient:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            logger.error("CRITICAL: GEMINI_API_KEY is missing.")
            raise ValueError("GEMINI_API_KEY not found.")
        
        self.client = genai.Client(api_key=api_key)
        
        # [ARCHITECT UPDATE - 2026 STANDARD]
        # Use the latest Gemini 3 Flash model according to Tier 1 account permissions
        # Release date: Dec 2025
        # Features: Ultra-fast, low latency, high quota (Pay-as-you-go required)
        self.model_name = "gemini-3-flash" 

    async def generate_json(self, prompt: str) -> str:
        max_retries = 2
        for attempt in range(max_retries + 1):
            try:
                logger.info(f"Sending request to Gemini ({self.model_name})... Attempt {attempt+1}")
                
                response = self.client.models.generate_content(
                    model=self.model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        # Disable safety filters to ensure smooth business logic
                        safety_settings=[
                            types.SafetySetting(
                                category="HARM_CATEGORY_HATE_SPEECH",
                                threshold="BLOCK_NONE"
                            ),
                            types.SafetySetting(
                                category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                                threshold="BLOCK_NONE"
                            ),
                            types.SafetySetting(
                                category="HARM_CATEGORY_DANGEROUS_CONTENT",
                                threshold="BLOCK_NONE"
                            ),
                            types.SafetySetting(
                                category="HARM_CATEGORY_HARASSMENT",
                                threshold="BLOCK_NONE"
                            )
                        ]
                    )
                )
                
                return response.text
                
            except Exception as e:
                error_str = str(e)
                # 429 error handling (Quota Exceeded)
                if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                    logger.warning(f"Quota Hit (429). Tier 1 account required for {self.model_name}.")
                    if attempt < max_retries:
                        time.sleep(2)
                        continue
                
                logger.error(f"Gemini API Call Failed: {e}")
                raise e

# Singleton instance
llm_client = GeminiClient()