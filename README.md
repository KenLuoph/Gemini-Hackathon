# Gemini Life Planner

AI-powered trip planning with real-time monitoring. The backend uses a 3-phase workflow (Scout → Simulator → Validator) driven by Google Gemini, and the Flutter app provides planning, alerts, and plan management.

Interactive Demo(No AI Connected): https://rename-butter-12998403.figma.site


## Features

- **Dynamic trip planning** — Generate day plans from natural-language intents (e.g. “romantic date in SF, budget $200”).
- **3-phase orchestration** — Scout gathers context, Simulator produces candidate plans, Validator scores and validates.
- **Real-time alerts** — WebSocket-based alerts for plan changes, weather, or constraints.
- **REST API** — FastAPI backend with OpenAPI docs at `/docs`.

## Tech Stack

| Layer   | Stack                    |
|--------|---------------------------|
| Backend | FastAPI, Python 3.11, Uvicorn |
| Frontend | Flutter (Dart 3.x)       |
| AI      | Google Gemini API (`google-genai`) |

## Prerequisites

- **Python 3.11.13** (recommended; 3.11+ supported)
- **Flutter SDK** (3.0+) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Google Gemini API key** — [Get an API key](https://ai.google.dev/)

## Project Structure

```
Gemini-Hackathon/
├── backend/                 # FastAPI application
│   ├── app/
│   │   ├── agents/          # Scout, Simulator, Validator
│   │   ├── api/             # REST & WebSocket routes
│   │   ├── schemas/         # Pydantic models (domain, events, user)
│   │   └── services/        # LLM client, orchestrator, tools
│   ├── main.py              # App entry point
│   └── requirements.txt
├── frontend/                # Flutter app (gemini_life_planner)
│   ├── lib/
│   │   ├── config/          # App config
│   │   ├── models/          # Trip plan, alerts, etc.
│   │   ├── providers/       # State (plan_provider, app_state)
│   │   ├── screens/         # Planner, plans list, detail, settings
│   │   ├── services/        # API client, WebSocket
│   │   └── widgets/         # Activity card, alert banner, etc.
│   └── pubspec.yaml
└── README.md
```

## Backend Requirements

From `backend/requirements.txt`:

- `fastapi==0.109.2`
- `uvicorn[standard]==0.27.1`
- `pydantic==2.6.1`
- `google-genai==0.3.0`
- `python-dotenv==1.0.1`
- `httpx==0.26.0`

## Frontend Dependencies (main)

- `provider` — state management  
- `http` — HTTP client  
- `web_socket_channel` — WebSocket  
- `json_annotation` / `json_serializable` — JSON  
- `intl` — date/time  
- `flutter_svg`, `url_launcher`, etc.

See `frontend/pubspec.yaml` for full list and versions.

---

## Quick Start

### 1. Backend

```bash
cd backend
python3.11 -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Create a `.env` in `backend/` (or set env vars):

```env
GEMINI_API_KEY=your_api_key_here
```

Run the API with **Uvicorn**:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

- API base: `http://localhost:8000`
- Docs: `http://localhost:8000/docs`
- WebSocket alerts: `ws://localhost:8000/api/ws/alerts/{plan_id}`

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run
```

Choose your target (e.g. Chrome, iOS simulator, Android emulator) when prompted. For web:

```bash
flutter run -d chrome
```

Ensure the app’s API base URL points to `http://localhost:8000` (or your backend URL) in `frontend/lib/config/app_config.dart` (or equivalent).

---

## API Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Health / service info |
| GET | `/health` | Detailed health check |
| POST | `/api/plan/generate` | Generate trip plan from intent |
| GET | `/api/plan/{plan_id}` | Get plan by ID |
| WebSocket | `/api/ws/alerts/{plan_id}` | Real-time alerts for a plan |

Full request/response schemas and try-it-out: **http://localhost:8000/docs**.

---

## Environment

- **Python**: 3.11.13 (or 3.11+).
- **Backend**: run from repo root or from `backend/`; if from repo root use `uvicorn backend.main:app` or run from `backend/` with `uvicorn main:app` as above.
- **Frontend**: requires Flutter SDK and a device or browser for `flutter run`.

---

## License

See repository for license information.
