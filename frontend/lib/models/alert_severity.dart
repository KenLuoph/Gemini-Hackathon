/// Alert severity enumeration
/// Mirrors backend AlertSeverity enum from domain.py
enum AlertSeverity {
  info('INFO'),
  warning('WARNING'),
  critical('CRITICAL');

  const AlertSeverity(this.value);
  final String value;

  /// Convert from string value
  static AlertSeverity fromString(String value) {
    return AlertSeverity.values.firstWhere(
      (severity) => severity.value == value.toUpperCase(),
      orElse: () => AlertSeverity.info,
    );
  }

  /// Human-readable label
  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  /// Color for UI display
  String get colorHex {
    switch (this) {
      case AlertSeverity.info:
        return '#2196F3'; // Blue
      case AlertSeverity.warning:
        return '#FF9800'; // Orange
      case AlertSeverity.critical:
        return '#F44336'; // Red
    }
  }

  /// Icon representation
  String get icon {
    switch (this) {
      case AlertSeverity.info:
        return 'ℹ️';
      case AlertSeverity.warning:
        return '⚠️';
      case AlertSeverity.critical:
        return '🚨';
    }
  }
}