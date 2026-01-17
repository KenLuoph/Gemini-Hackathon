"""
FastAPI 应用入口
启动命令: uvicorn main:app --reload
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import router

app = FastAPI(
    title="Gemini Life Planner API",
    description="基于 Gemini AI 的智能生活规划助手",
    version="1.0.0"
)

# CORS 配置，允许 Flutter 前端访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境需要指定具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(router, prefix="/api/v1")


@app.get("/")
async def root():
    """健康检查接口"""
    return {
        "status": "ok",
        "message": "Gemini Life Planner API is running"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

