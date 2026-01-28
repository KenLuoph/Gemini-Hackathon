/// Activity type enumeration (Indoor/Outdoor)
/// Mirrors backend ActivityType enum from domain.py
enum ActivityType {
  indoor('indoor'),
  outdoor('outdoor');

  const ActivityType(this.value);
  final String value;

  /// Convert from string value
  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value.toLowerCase(),
      orElse: () => ActivityType.indoor,
    );
  }

  /// Human-readable label
  String get label {
    switch (this) {
      case ActivityType.indoor:
        return 'Indoor';
      case ActivityType.outdoor:
        return 'Outdoor';
    }
  }

  /// Icon representation
  String get icon {
    switch (this) {
      case ActivityType.indoor:
        return '🏠';
      case ActivityType.outdoor:
        return '🌳';
    }
  }
}