# check_models.py
import os
from dotenv import load_dotenv
from google import genai

load_dotenv("backend/.env") # 指向您的 .env 文件位置

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("❌ Error: API Key not found. Check your .env path.")
    exit(1)

client = genai.Client(api_key=api_key)

print(f"✅ Authenticated. Listing available models for your Key...")
try:
    # 列出所有支持 generateContent 的模型
    for m in client.models.list():
        if "generateContent" in m.supported_generation_methods:
            print(f" - {m.name}")
except Exception as e:
    print(f"❌ Failed to list models: {e}")