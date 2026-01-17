"""
外部 API 工具集成
Week 2 实现：Google Maps API、天气 API 等
"""
import os
from typing import Optional, Dict
import httpx
from dotenv import load_dotenv

load_dotenv()


class MapsService:
    """Google Maps API 服务（Week 2）"""
    
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_MAPS_API_KEY")
        self.base_url = "https://maps.googleapis.com/maps/api"
    
    async def get_location_info(self, address: str) -> Optional[Dict]:
        """
        获取地点信息
        
        Args:
            address: 地址
            
        Returns:
            地点详细信息
        """
        # TODO: Week 2 实现
        pass
    
    async def calculate_route(self, origin: str, destination: str) -> Optional[Dict]:
        """
        计算路线
        
        Args:
            origin: 起点
            destination: 终点
            
        Returns:
            路线信息
        """
        # TODO: Week 2 实现
        pass


class WeatherService:
    """天气 API 服务（Week 2）"""
    
    def __init__(self):
        self.api_key = os.getenv("WEATHER_API_KEY")
        self.base_url = "https://api.weatherapi.com/v1"
    
    async def get_weather_forecast(self, location: str, days: int = 7) -> Optional[Dict]:
        """
        获取天气预报
        
        Args:
            location: 地点
            days: 预报天数
            
        Returns:
            天气信息
        """
        # TODO: Week 2 实现
        pass


# 服务实例
maps_service = MapsService()
weather_service = WeatherService()

