# Gemini Life Planner

## 项目简介
基于 Gemini AI 的智能生活规划助手

## 技术栈
- **后端**: FastAPI + Python
- **前端**: Flutter
- **AI模型**: Google Gemini API

## 项目结构
```
gemini-life-planner/
├── backend/          # 后端核心逻辑
└── frontend/         # Flutter 移动端
```

## 快速开始

### 后端设置
```bash
cd backend
pip install -r requirements.txt
# 配置 .env 文件中的 GEMINI_API_KEY
python main.py
```

### 前端设置
```bash
cd frontend
flutter pub get
flutter run
```

## API 文档
启动后端后访问: http://localhost:8000/docs

## 开发计划
- Week 1: 核心 Gemini 交互功能
- Week 2: 外部 API 集成（地图、天气等）

