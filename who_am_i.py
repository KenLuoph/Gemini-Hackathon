# who_am_i.py (路径修复版)
import os
from pathlib import Path
from dotenv import load_dotenv
from google import genai

# 1. 智能查找 .env 文件
# 先找 backend/.env (架构规范位置)
env_path = Path("backend/.env")
if not env_path.exists():
    # 再找当前目录 .env (防呆设计)
    env_path = Path(".env")

if env_path.exists():
    print(f"📂 成功加载配置文件: {env_path.absolute()}")
    load_dotenv(dotenv_path=env_path, override=True)
else:
    print("❌ 严重错误：在 backend/ 目录和当前目录下都没找到 .env 文件！")
    print("请确认您是否创建了 .env 文件？")
    exit(1)

# 2. 读取 Key
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("❌ Error: 文件找到了，但里面没有 GEMINI_API_KEY 变量。请检查文件内容。")
    exit(1)

print(f"🔑 Key 校验: ...{api_key[-4:]}")

# 3. 验证权限
client = genai.Client(api_key=api_key)
print("📡 正在向 Google 验证权限...")

try:
    models = list(client.models.list())
    # 过滤出支持生成的模型
    gen_models = [m.name for m in models if "generateContent" in m.supported_generation_methods]
    
    if gen_models:
        print(f"🎉 验证成功！您的 Key 拥有 {len(gen_models)} 个模型的权限。")
        if "models/gemini-1.5-flash" in gen_models:
            print("✅ gemini-1.5-flash 就在其中！代码可以跑通了。")
        else:
            print("⚠️ 注意：列表中没有 Flash，但有其他模型。")
    else:
        print("⚠️ 连接成功，但模型列表为空 (Key 权限不足)。")

except Exception as e:
    print(f"❌ API 调用失败: {e}")