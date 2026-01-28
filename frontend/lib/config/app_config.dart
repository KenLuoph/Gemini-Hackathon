/// Application Configuration
/// 
/// Centralized configuration for API endpoints and app settings.
class AppConfig {
  // Backend API Configuration
  static const String baseUrl = 'http://127.0.0.1:8000';  
  
  // For Android Emulator, use:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For physical device, use your computer's IP:
  // static const String baseUrl = 'http://192.168.1.XXX:8000';
  
  static const String apiPrefix = '/api';
  
  // WebSocket Configuration
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws');
  
  // Endpoints
  static const String planGenerateEndpoint = '/plan/generate';
  static const String planConfirmEndpoint = '/plan/{id}/confirm';
  static const String planDetailEndpoint = '/plan/{id}';
  
  // WebSocket endpoint
  static String alertsEndpoint(String planId) => '/ws/alerts/$planId';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  
  // App Metadata
  static const String appName = 'Gemini Life Planner';
  static const String appVersion = '1.0.0';
  
  // Feature Flags
  static const bool enableWebSocket = true;
  static const bool enableDebugLogging = true;
}