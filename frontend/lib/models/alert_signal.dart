import 'alert_severity.dart';

/// Alert signal from WebSocket
/// Mirrors backend AlertSignal from domain.py
class AlertSignal {
  final String source;
  final String changeType;
  final String message;
  final String triggerValue;
  final AlertSeverity severity;
  final String affectedPlanId;
  final DateTime timestamp;

  const AlertSignal({
    required this.source,
    required this.changeType,
    required this.message,
    required this.triggerValue,
    required this.severity,
    required this.affectedPlanId,
    required this.timestamp,
  });

  /// Create from JSON (handles partial payload from WebSocket test/mock)
  factory AlertSignal.fromJson(Map<String, dynamic> json) {
    return AlertSignal(
      source: json['source'] as String? ?? 'SCOUT_AGENT',
      changeType: json['change_type'] as String? ?? 'weather',
      message: json['message'] as String? ?? '',
      triggerValue: json['trigger_value'] as String? ?? '',
      severity: AlertSeverity.fromString(
          (json['severity'] as String?) ?? 'INFO',
      ),
      affectedPlanId: json['affected_plan_id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'change_type': changeType,
      'message': message,
      'trigger_value': triggerValue,
      'severity': severity.value,
      'affected_plan_id': affectedPlanId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// User-friendly change type label
  String get changeTypeLabel {
    switch (changeType.toLowerCase()) {
      case 'weather':
        return '🌦️ Weather Change';
      case 'traffic':
        return '🚗 Traffic Update';
      case 'temperature':
        return '🌡️ Temperature Change';
      default:
        return '📢 Update';
    }
  }

  @override
  String toString() =>
      'AlertSignal($severity: $message, planId: $affectedPlanId)';
}