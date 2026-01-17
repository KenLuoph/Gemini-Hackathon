"""
Gemini AI 交互核心引擎
负责与 Google Gemini API 的所有交互
"""
import os
import google.generativeai as genai
from typing import Optional, List, Dict
from dotenv import load_dotenv

load_dotenv()


class GeminiEngine:
    """Gemini AI 引擎"""
    
    def __init__(self):
        """初始化 Gemini 客户端"""
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')
        self.chat = None
    
    async def generate_plan(self, user_input: str, context: Optional[Dict] = None) -> str:
        """
        根据用户输入生成生活规划
        
        Args:
            user_input: 用户的需求描述
            context: 上下文信息
            
        Returns:
            生成的计划（JSON 字符串）
        """
        # 构建 prompt
        prompt = self._build_prompt(user_input, context)
        
        # 调用 Gemini API
        response = self.model.generate_content(prompt)
        
        return response.text
    
    async def chat_conversation(self, message: str, history: Optional[List[Dict]] = None) -> str:
        """
        对话式交互
        
        Args:
            message: 用户消息
            history: 对话历史
            
        Returns:
            AI 回复
        """
        if not self.chat:
            self.chat = self.model.start_chat(history=history or [])
        
        response = self.chat.send_message(message)
        return response.text
    
    def _build_prompt(self, user_input: str, context: Optional[Dict] = None) -> str:
        """
        构建发送给 Gemini 的提示词
        
        Args:
            user_input: 用户输入
            context: 上下文
            
        Returns:
            完整的 prompt
        """
        base_prompt = f"""
你是一个专业的生活规划助手。请根据用户的需求，生成一个详细的生活计划。

用户需求：{user_input}

请以 JSON 格式返回计划，包含以下字段：
- plan_id: 计划唯一标识
- title: 计划标题
- description: 计划描述
- tasks: 任务列表
  - id: 任务ID
  - title: 任务标题
  - description: 任务描述
  - start_time: 开始时间（ISO 格式）
  - end_time: 结束时间（ISO 格式）
  - priority: 优先级（low/medium/high）
  - status: 状态（pending）
  - location: 地点（如果适用）

请确保生成的计划合理、可执行。
"""
        
        if context:
            base_prompt += f"\n\n上下文信息：{context}"
        
        return base_prompt


# 单例模式
gemini_engine = GeminiEngine()

