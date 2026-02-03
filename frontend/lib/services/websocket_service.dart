import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/alert_signal.dart';
import '../models/trip_plan.dart';

/// WebSocket service for real-time alert notifications
/// 
/// Connects to backend WebSocket endpoint to receive:
/// - Weather/traffic alerts
/// - Automatic plan updates
/// - Status changes
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  Timer? _reconnectTimer;
  String? _currentPlanId;
  bool _isDisposed = false;

  /// Stream of incoming messages
  Stream<WebSocketMessage> get messageStream {
    _messageController ??= StreamController<WebSocketMessage>.broadcast();
    return _messageController!.stream;
  }

  /// Connect to WebSocket for a specific plan
  /// 
  /// Example:
  /// ```dart
  /// wsService.connect(planId);
  /// wsService.messageStream.listen((message) {
  ///   if (message.type == 'plan_updated') {
  ///     // Handle plan update
  ///   }
  /// });
  /// ```
  void connect(String planId) {
    if (_isDisposed) return;

    _currentPlanId = planId;
    final wsUrl = '${AppConfig.wsUrl}${AppConfig.apiPrefix}${AppConfig.alertsEndpoint(planId)}';

    try {
      if (AppConfig.enableDebugLogging) {
        print('🔌 Connecting to WebSocket: $wsUrl');
      }

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      if (AppConfig.enableDebugLogging) {
        print('✅ WebSocket connected for plan: $planId');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('❌ WebSocket connection failed: $e');
      }
      _scheduleReconnect();
    }
  }

  /// Disconnect WebSocket
  void disconnect() {
    if (AppConfig.enableDebugLogging) {
      print('🔌 Disconnecting WebSocket');
    }

    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _currentPlanId = null;
  }

  /// Send message to server (e.g., ping)
  void send(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  /// Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(jsonData);

      if (AppConfig.enableDebugLogging) {
        print('📩 WebSocket message received: ${message.type}');
      }

      _messageController?.add(message);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('❌ Failed to parse WebSocket message: $e');
      }
    }
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    if (AppConfig.enableDebugLogging) {
      print('❌ WebSocket error: $error');
    }

    _scheduleReconnect();
  }

  /// Handle WebSocket close
  void _handleDone() {
    if (AppConfig.enableDebugLogging) {
      print('🔌 WebSocket connection closed');
    }

    if (!_isDisposed && _currentPlanId != null) {
      _scheduleReconnect();
    }
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_isDisposed || _currentPlanId == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(AppConfig.wsReconnectDelay, () {
      if (AppConfig.enableDebugLogging) {
        print('🔄 Attempting WebSocket reconnect...');
      }
      connect(_currentPlanId!);
    });
  }

  /// Dispose resources
  void dispose() {
    _isDisposed = true;
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}

/// WebSocket message wrapper
class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;

  const WebSocketMessage({
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  /// Check if this is an alert message
  bool get isAlert => type == 'alert';

  /// Check if this is a plan update
  bool get isPlanUpdate => type == 'plan_updated';

  /// Check if this is a status change
  bool get isStatusChange => type == 'status_change';

  /// Parse as AlertSignal (if type is 'alert')
  /// Backend sends { "type": "alert", "data": { ...alert fields } }
  AlertSignal? get asAlert {
    if (isAlert || isPlanUpdate) {
      try {
        final alertMap = data['alert'] ?? data;
        if (alertMap is Map<String, dynamic>) {
          return AlertSignal.fromJson(alertMap);
        }
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse as updated TripPlan (if type is 'plan_updated')
  TripPlan? get asUpdatedPlan {
    if (isPlanUpdate) {
      try {
        final planMap = data['updated_plan'] ?? data;
        if (planMap is Map<String, dynamic>) {
          return TripPlan.fromJson(planMap);
        }
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() => 'WebSocketMessage(type: $type)';
}