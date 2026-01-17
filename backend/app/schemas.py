"""
Pydantic 数据模型
定义 API 请求/响应的数据结构，对应前端的 JSON 格式
"""
from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime


class PlanRequest(BaseModel):
    """用户请求生成计划"""
    user_input: str = Field(..., description="用户的需求描述")
    context: Optional[dict] = Field(None, description="上下文信息（用户偏好、历史等）")


class Task(BaseModel):
    """单个任务"""
    id: str = Field(..., description="任务唯一标识")
    title: str = Field(..., description="任务标题")
    description: Optional[str] = Field(None, description="任务详细描述")
    start_time: Optional[datetime] = Field(None, description="开始时间")
    end_time: Optional[datetime] = Field(None, description="结束时间")
    priority: Optional[str] = Field("medium", description="优先级：low/medium/high")
    status: str = Field("pending", description="状态：pending/in_progress/completed")
    location: Optional[str] = Field(None, description="地点信息")


class Plan(BaseModel):
    """完整的生活计划"""
    plan_id: str = Field(..., description="计划唯一标识")
    title: str = Field(..., description="计划标题")
    description: Optional[str] = Field(None, description="计划描述")
    tasks: List[Task] = Field(default_factory=list, description="任务列表")
    created_at: datetime = Field(default_factory=datetime.now, description="创建时间")
    updated_at: datetime = Field(default_factory=datetime.now, description="更新时间")


class PlanResponse(BaseModel):
    """API 响应"""
    success: bool = Field(..., description="是否成功")
    message: str = Field(..., description="响应消息")
    data: Optional[Plan] = Field(None, description="计划数据")


class ChatMessage(BaseModel):
    """聊天消息"""
    role: str = Field(..., description="角色：user/assistant")
    content: str = Field(..., description="消息内容")
    timestamp: datetime = Field(default_factory=datetime.now, description="时间戳")

