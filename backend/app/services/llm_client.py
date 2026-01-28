# backend/app/services/llm_client.py
# Version: 2.0
# Last Updated: 2026-01-27
# Changes: Model fix, System Instructions, Async wrapper, Temperature control

import os
import logging
import time
import asyncio
from functools import partial
from typing import Optional
from dotenv import load_dotenv, find_dotenv
from google import genai
from google.genai import types

# Force reload environment variables from .env file
load_dotenv(find_dotenv(), override=True)
logger = logging.getLogger(__name__)

class GeminiClient:
    """
    Infrastructure layer wrapper for Google Gemini API.
    Provides JSON-enforced generation with retry logic and monitoring.
    
    Design Principles:
    1. Singleton pattern for resource efficiency
    2. Async-first for FastAPI compatibility
    3. Structured error handling with quota awareness
    4. Token usage tracking for cost control
    """
    
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            logger.error("CRITICAL: GEMINI_API_KEY is missing in .env file.")
            raise ValueError("GEMINI_API_KEY not found. Please configure backend/.env")
        
        self.client = genai.Client(api_key=api_key)
        
        # Model Configuration (Updated 2026-01-27)
        # Based on Dev Docs [2026-01-20] entry
        self.model_name = "gemini-2.5-pro"
        
        # Cost reference (as of 2026-01):
        # - Input: ~$0.075 per 1M tokens
        # - Output: ~$0.30 per 1M tokens
        # - Quota: 1000+ RPM (Tier 1 billing required)
        
        logger.info(f"GeminiClient initialized with model: {self.model_name}")
    
    async def generate_json(
        self,
        prompt: str,
        system_instruction: Optional[str] = None,
        temperature: float = 0.7,
        max_retries: int = 2
    ) -> str:
        """
        Generate structured JSON response from Gemini.
        
        Args:
            prompt: User's request or formatted data to process
            system_instruction: Persistent context/rules for the AI (Week 1 requirement)
            temperature: Randomness control (0.0=deterministic, 1.0=creative)
                - Use 0.1 for validation/checking
                - Use 0.7 for creative planning (default)
            max_retries: Number of retry attempts on quota errors
        
        Returns:
            Raw JSON string (caller must parse with Pydantic)
        
        Raises:
            ValueError: If API key missing
            RuntimeError: If Gemini API fails after retries
        """
        loop = asyncio.get_event_loop()
        
        for attempt in range(max_retries + 1):
            try:
                logger.info(
                    f"Gemini API Call (Attempt {attempt+1}/{max_retries+1}): "
                    f"Model={self.model_name}, Temp={temperature}"
                )
                
                # Run synchronous Gemini call in thread pool to avoid blocking event loop
                response = await loop.run_in_executor(
                    None,
                    partial(
                        self._sync_generate,
                        prompt,
                        system_instruction,
                        temperature
                    )
                )
                
                # Log token usage for cost tracking
                if hasattr(response, 'usage_metadata'):
                    usage = response.usage_metadata
                    logger.info(
                        f"Token Usage: Input={usage.prompt_token_count}, "
                        f"Output={usage.candidates_token_count}, "
                        f"Total={usage.total_token_count}"
                    )
                
                return response.text
                
            except Exception as e:
                error_str = str(e)
                
                # Handle quota exhaustion (429 / RESOURCE_EXHAUSTED)
                if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                    logger.warning(
                        f"Quota Hit (429 Error). "
                        f"Current model '{self.model_name}' requires Tier 1 billing. "
                        f"Retrying in 2 seconds... (Attempt {attempt+1})"
                    )
                    if attempt < max_retries:
                        await asyncio.sleep(2)  # Async sleep
                        continue
                    else:
                        raise RuntimeError(
                            "Gemini API quota exhausted after retries. "
                            "Please check billing status at console.cloud.google.com"
                        )
                
                # Handle model not found (404)
                elif "404" in error_str or "NOT_FOUND" in error_str:
                    logger.error(
                        f"Model '{self.model_name}' not found. "
                        "This may indicate API access issue or incorrect model name."
                    )
                    raise RuntimeError(f"Gemini model not accessible: {self.model_name}")
                
                # Generic error handling
                logger.error(f"Gemini API Call Failed: {e}")
                raise RuntimeError(f"Gemini generation failed: {e}")
    
    def _sync_generate(
        self,
        prompt: str,
        system_instruction: Optional[str],
        temperature: float
    ):
        """
        Internal synchronous wrapper for actual Gemini API call.
        This method runs in a thread pool executor.
        """
        # Build contents
        contents = prompt
        
        # Build config
        config = types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=temperature,
            top_p=0.95,
            top_k=40,
            
            # Safety settings (disabled for business logic)
            # Rationale: Travel planning content is inherently safe
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
        
        # Add system instruction if provided
        if system_instruction:
            config.system_instruction = system_instruction
        
        # Make the actual API call
        response = self.client.models.generate_content(
            model=self.model_name,
            contents=contents,
            config=config
        )
        
        return response

# ============================================================================
# Singleton Instance Export
# ============================================================================
# Usage in other modules:
#   from app.services.llm_client import llm_client
#   result = await llm_client.generate_json(prompt="...", temperature=0.3)

llm_client = GeminiClient()