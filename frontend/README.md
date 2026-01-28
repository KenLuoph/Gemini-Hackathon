# Gemini Life Planner - Frontend

Flutter mobile application for AI-powered trip planning with real-time monitoring.

## Features

- 🎯 Natural language trip planning
- 🤖 AI-powered itinerary generation
- 💰 Budget validation and scoring
- 🌧️ Weather-aware activity suggestions
- 📱 Real-time alert notifications (WebSocket)
- 🔄 Emergency re-planning
- 🗺️ Geographic optimization

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **HTTP Client**: http package
- **WebSocket**: web_socket_channel
- **Backend API**: FastAPI (Python)

## Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- iOS Simulator / Android Emulator / Physical Device

### Installation
```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run code generation (for JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Backend Configuration

Edit `lib/config/app_config.dart` to set your backend URL:
```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:8000';  // Development
  // static const String baseUrl = 'http://10.0.2.2:8000';  // Android Emulator
  // static const String baseUrl = 'http://YOUR_IP:8000';   // Physical Device
}
```

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── config/
│   └── app_config.dart       # Configuration
├── models/
│   ├── trip_plan.dart        # TripPlan data model
│   ├── activity_item.dart    # ActivityItem model
│   ├── validation_result.dart
│   └── ...                   # Other models
├── services/
│   ├── api_client.dart       # REST API client
│   └── websocket_service.dart # WebSocket service
├── providers/
│   └── plan_provider.dart    # State management
├── screens/
│   ├── home_screen.dart      # Input screen
│   ├── loading_screen.dart   # Loading state
│   └── plan_detail_screen.dart # Plan display
└── widgets/
    ├── activity_card.dart    # Reusable components
    └── alert_banner.dart
```

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Code Generation

When you modify model classes with JSON annotations:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## API Integration

### REST Endpoints

- `POST /api/plan/generate` - Generate trip plan
- `POST /api/plan/{id}/confirm` - Activate monitoring
- `GET /api/plan/{id}` - Retrieve plan

### WebSocket

- `WS /api/ws/alerts/{plan_id}` - Real-time alerts

## Troubleshooting

### Common Issues

**Problem**: Cannot connect to backend  
**Solution**: 
- Ensure backend is running: `curl http://localhost:8000/health`
- For Android Emulator, use `10.0.2.2` instead of `localhost`
- For physical device, use your computer's local IP

**Problem**: JSON serialization errors  
**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Problem**: WebSocket connection fails  
**Solution**: 
- Check firewall settings
- Verify WebSocket URL format: `ws://` not `http://`

## Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request

## License

MIT License - See LICENSE file for details

## Team

Gemini Hackathon Team - 2026