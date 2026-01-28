/// Plan lifecycle status enumeration
/// Mirrors backend PlanStatus enum from domain.py
enum PlanStatus {
  draft('draft'),
  generating('generating'),
  validating('validating'),
  verified('verified'),
  active('active'),
  monitoring('monitoring'),
  completed('completed'),
  cancelled('cancelled');

  const PlanStatus(this.value);
  final String value;

  /// Convert from string value
  static PlanStatus fromString(String value) {
    return PlanStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PlanStatus.draft,
    );
  }

  /// Human-readable label
  String get label {
    switch (this) {
      case PlanStatus.draft:
        return 'Draft';
      case PlanStatus.generating:
        return 'Generating...';
      case PlanStatus.validating:
        return 'Validating...';
      case PlanStatus.verified:
        return 'Ready to Confirm';
      case PlanStatus.active:
        return 'Active';
      case PlanStatus.monitoring:
        return 'Monitoring';
      case PlanStatus.completed:
        return 'Completed';
      case PlanStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Status color indicator
  String get colorHex {
    switch (this) {
      case PlanStatus.draft:
      case PlanStatus.generating:
      case PlanStatus.validating:
        return '#FFA726'; // Orange
      case PlanStatus.verified:
        return '#66BB6A'; // Green
      case PlanStatus.active:
      case PlanStatus.monitoring:
        return '#42A5F5'; // Blue
      case PlanStatus.completed:
        return '#9E9E9E'; // Gray
      case PlanStatus.cancelled:
        return '#EF5350'; // Red
    }
  }
}