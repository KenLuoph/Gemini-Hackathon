# backend/app/api/test_routes.py

from fastapi import APIRouter
from app.schemas.domain import EnvironmentState
from app.services.mock_manager import mock_manager
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/env/set")
async def set_test_environment(state: EnvironmentState):
    """
    [TEST INTERFACE]
    Force the backend to perceive a specific environment state.
    Useful for testing 'Rainy' logic without waiting for real rain.
    """
    mock_manager.set_override(state)
    return {"status": "success", "message": f"Environment locked to: {state.weather_condition}"}

@router.post("/env/clear")
async def clear_test_environment():
    """
    [TEST INTERFACE]
    Clear any overrides and revert to real/default data.
    """
    mock_manager.clear_override()
    return {"status": "success", "message": "Environment overrides cleared. Back to real mode."}