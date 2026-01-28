import 'activity_type.dart';
import 'geo_location.dart';
import 'budget_info.dart';

/// Single activity in a trip plan
/// Mirrors backend ActivityItem from domain.py
class ActivityItem {
  final String activityId;
  final String name;
  final String timeSlot;
  final GeoLocation location;
  final BudgetInfo budget;
  final ActivityType type;
  final String? description;
  final Map<String, dynamic>? constraints;
  final double riskScore;
  final String status;

  const ActivityItem({
    required this.activityId,
    required this.name,
    required this.timeSlot,
    required this.location,
    required this.budget,
    required this.type,
    this.description,
    this.constraints,
    required this.riskScore,
    required this.status,
  });

  /// Create from JSON
  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      activityId: json['activity_id'] as String,
      name: json['name'] as String,
      timeSlot: json['time_slot'] as String,
      location: GeoLocation.fromJson(json['location'] as Map<String, dynamic>),
      budget: BudgetInfo.fromJson(json['budget'] as Map<String, dynamic>),
      type: ActivityType.fromString(json['type'] as String),
      description: json['description'] as String?,
      constraints: json['constraints'] as Map<String, dynamic>?,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'name': name,
      'time_slot': timeSlot,
      'location': location.toJson(),
      'budget': budget.toJson(),
      'type': type.value,
      'description': description,
      'constraints': constraints,
      'risk_score': riskScore,
      'status': status,
    };
  }

  /// Risk level description
  String get riskLevel {
    if (riskScore < 0.3) return 'Low Risk';
    if (riskScore < 0.7) return 'Medium Risk';
    return 'High Risk';
  }

  /// Risk color indicator
  String get riskColorHex {
    if (riskScore < 0.3) return '#4CAF50'; // Green
    if (riskScore < 0.7) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Parse time slot to start time string
  String? get startTime {
    try {
      // Format: "2026-01-30 18:00 - 19:00" or "18:00 - 19:00"
      final parts = timeSlot.split(' - ');
      if (parts.isNotEmpty) {
        final startPart = parts[0].trim();
        // Extract time only (last part if contains date)
        final timeParts = startPart.split(' ');
        return timeParts.last;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  String toString() => 'ActivityItem($name, $timeSlot, ${budget.formatted})';
}