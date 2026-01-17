"""
API 路由定义
定义所有的 HTTP 端点
"""
from fastapi import APIRouter, HTTPException
from app.schemas import PlanRequest, PlanResponse, Plan, Task, ChatMessage
from app.services.llm_engine import gemini_engine
import json
from datetime import datetime
import uuid

router = APIRouter()


@router.post("/plan/generate", response_model=PlanResponse)
async def generate_plan(request: PlanRequest):
    """
    生成生活计划
    
    Args:
        request: 包含用户需求的请求
        
    Returns:
        生成的计划
    """
    try:
        # 调用 Gemini 生成计划
        plan_text = await gemini_engine.generate_plan(
            user_input=request.user_input,
            context=request.context
        )
        
        # 解析 JSON（这里需要处理 Gemini 返回的格式）
        # 简化版本：直接返回文本，实际需要解析为 Plan 对象
        try:
            plan_data = json.loads(plan_text)
            plan = Plan(**plan_data)
        except json.JSONDecodeError:
            # 如果 Gemini 没有返回有效 JSON，创建一个默认计划
            plan = Plan(
                plan_id=str(uuid.uuid4()),
                title="生成的计划",
                description=plan_text[:200],
                tasks=[]
            )
        
        return PlanResponse(
            success=True,
            message="计划生成成功",
            data=plan
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"生成计划失败: {str(e)}")


@router.post("/chat")
async def chat(message: ChatMessage):
    """
    对话接口
    
    Args:
        message: 用户消息
        
    Returns:
        AI 回复
    """
    try:
        response_text = await gemini_engine.chat_conversation(message.content)
        
        return {
            "success": True,
            "message": "回复成功",
            "data": {
                "role": "assistant",
                "content": response_text,
                "timestamp": datetime.now().isoformat()
            }
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"对话失败: {str(e)}")


@router.get("/plan/{plan_id}", response_model=PlanResponse)
async def get_plan(plan_id: str):
    """
    获取指定计划
    
    Args:
        plan_id: 计划ID
        
    Returns:
        计划详情
    """
    # TODO: 实现计划存储和检索
    raise HTTPException(status_code=501, detail="功能开发中")


@router.put("/plan/{plan_id}")
async def update_plan(plan_id: str, plan: Plan):
    """
    更新计划
    
    Args:
        plan_id: 计划ID
        plan: 更新的计划数据
        
    Returns:
        更新结果
    """
    # TODO: 实现计划更新
    raise HTTPException(status_code=501, detail="功能开发中")

