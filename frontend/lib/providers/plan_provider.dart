import 'package:flutter/foundation.dart';

import '../models/trip_plan.dart';
import '../models/validation_result.dart';
import '../models/alert_signal.dart';
import '../models/plan_status.dart';
import '../models/alert_severity.dart'; 
import '../services/api_client.dart';
import '../services/websocket_service.dart';

/// State management for trip planning
/// 
/// Manages:
/// - Current trip plan
/// - Loading states
/// - Alerts and notifications
/// - WebSocket connection
class PlanProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final WebSocketService _wsService;

  PlanProvider({
    ApiClient? apiClient,
    WebSocketService? wsService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _wsService = wsService ?? WebSocketService() {
    _initWebSocket();
  }

  // ========================================================================
  // STATE VARIABLES
  // ========================================================================

  TripPlan? _currentPlan;
  ValidationResult? _currentValidation;
  bool _isLoading = false;
  String? _errorMessage;
  final List<AlertSignal> _alerts = [];

  // ========================================================================
  // GETTERS
  // ========================================================================

  TripPlan? get currentPlan => _currentPlan;
  ValidationResult? get validation => _currentValidation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AlertSignal> get alerts => List.unmodifiable(_alerts);
  
  bool get hasPlan => _currentPlan != null;
  bool get hasError => _errorMessage != null;
  bool get hasAlerts => _alerts.isNotEmpty;
  
  /// Has critical alerts
  bool get hasCriticalAlert {
    return _alerts.any((alert) => alert.severity == AlertSeverity.critical);
  }

  // ========================================================================
  // ACTIONS
  // ========================================================================

  /// Generate a new trip plan
  Future<void> createPlan({
    required String intent,
    double? budgetLimit,
    List<String>? preferences,
    bool? sensitiveToRain,
    List<String>? dietaryRestrictions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.generatePlan(
        intent: intent,
        budgetLimit: budgetLimit,
        preferences: preferences,
        sensitiveToRain: sensitiveToRain,
        dietaryRestrictions: dietaryRestrictions,
      );

      if (response.success && response.data != null) {
        _currentPlan = response.data;
        _currentValidation = response.validation;
        _errorMessage = null;

        if (kDebugMode) {
          print('✅ Plan generated: ${_currentPlan!.planId}');
          print('📊 Validation score: ${_currentValidation?.score}');
        }
      } else {
        _errorMessage = response.error ?? 'Failed to generate plan';
      }
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
      if (kDebugMode) {
        print('❌ API Error: $e');
      }
    } catch (e) {
      _errorMessage = 'Unexpected error occurred';
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm and activate plan (starts monitoring)
  Future<void> confirmPlan() async {
    if (_currentPlan == null) {
      _errorMessage = 'No plan to confirm';
      notifyListeners();
      return;
    }

    if (_currentPlan!.status != PlanStatus.verified) {
      _errorMessage = 'Plan must be verified before confirmation';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiClient.confirmPlan(_currentPlan!.planId);

      if (result['monitoring_started'] == true) {
        // Update local plan status
        _currentPlan = _currentPlan!.copyWith(
          status: PlanStatus.active,
        );

        // Connect to WebSocket for real-time updates
        _wsService.connect(_currentPlan!.planId);

        if (kDebugMode) {
          print('✅ Plan confirmed and monitoring started');
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
      if (kDebugMode) {
        print('❌ Confirmation error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually swap an activity with an alternative
  void swapActivity(String originalActivityId, String alternativeActivityId) {
    if (_currentPlan == null) return;

    // Find the alternative
    final alternative = _currentPlan!.alternatives.firstWhere(
      (alt) => alt.activityId == alternativeActivityId,
      orElse: () => throw Exception('Alternative not found'),
    );

    // Find and replace in main itinerary
    final updatedItinerary = _currentPlan!.mainItinerary.map((activity) {
      if (activity.activityId == originalActivityId) {
        return alternative;
      }
      return activity;
    }).toList();

    _currentPlan = _currentPlan!.copyWith(
      mainItinerary: updatedItinerary,
    );

    if (kDebugMode) {
      print('🔄 Activity swapped manually');
    }

    notifyListeners();
  }

  /// Clear current plan
  void clearPlan() {
    _currentPlan = null;
    _currentValidation = null;
    _errorMessage = null;
    _alerts.clear();
    _wsService.disconnect();
    notifyListeners();
  }

  /// Dismiss error message
  void dismissError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dismiss specific alert
  void dismissAlert(AlertSignal alert) {
    _alerts.remove(alert);
    notifyListeners();
  }

  /// Dismiss all alerts
  void dismissAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  // ========================================================================
  // WEBSOCKET HANDLING
  // ========================================================================

  void _initWebSocket() {
    _wsService.messageStream.listen(_handleWebSocketMessage);
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    if (kDebugMode) {
      print('📨 WebSocket message: ${message.type}');
    }

    if (message.isAlert) {
      // Add alert to list
      final alert = message.asAlert;
      if (alert != null) {
        _alerts.add(alert);
        notifyListeners();
      }
    } else if (message.isPlanUpdate) {
      // Automatic plan update
      final updatedPlan = message.asUpdatedPlan;
      final alert = message.asAlert;

      if (updatedPlan != null) {
        _currentPlan = updatedPlan;

        if (alert != null) {
          _alerts.add(alert);
        }

        if (kDebugMode) {
          print('🔄 Plan automatically updated due to: ${alert?.message}');
        }

        notifyListeners();
      }
    }
  }

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

    @override
    void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}