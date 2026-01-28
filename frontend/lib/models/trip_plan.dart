import 'activity_item.dart';
import 'plan_status.dart';

/// Complete trip plan model
/// Mirrors backend TripPlan from domain.py
class TripPlan {
  final String planId;
  final String name;
  final PlanStatus status;
  final List<ActivityItem> mainItinerary;
  final List<ActivityItem> alternatives;
  final String? reasoningPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripPlan({
    required this.planId,
    required this.name,
    required this.status,
    required this.mainItinerary,
    required this.alternatives,
    this.reasoningPath,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      status: PlanStatus.fromString(json['status'] as String),
      mainItinerary: (json['main_itinerary'] as List<dynamic>)
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reasoningPath: json['reasoning_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'name': name,
      'status': status.value,
      'main_itinerary': mainItinerary.map((e) => e.toJson()).toList(),
      'alternatives': alternatives.map((e) => e.toJson()).toList(),
      'reasoning_path': reasoningPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Total budget across all activities
  double get totalBudget {
    return mainItinerary.fold(
      0.0,
      (sum, activity) => sum + activity.budget.amount,
    );
  }

  /// Number of activities
  int get activityCount => mainItinerary.length;

  /// Has alternatives
  bool get hasAlternatives => alternatives.isNotEmpty;

  /// Copy with updated fields
  TripPlan copyWith({
    String? planId,
    String? name,
    PlanStatus? status,
    List<ActivityItem>? mainItinerary,
    List<ActivityItem>? alternatives,
    String? reasoningPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripPlan(
      planId: planId ?? this.planId,
      name: name ?? this.name,
      status: status ?? this.status,
      mainItinerary: mainItinerary ?? this.mainItinerary,
      alternatives: alternatives ?? this.alternatives,
      reasoningPath: reasoningPath ?? this.reasoningPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'TripPlan($name, $activityCount activities, status: ${status.value})';
}