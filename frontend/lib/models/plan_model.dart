/// Plan 数据模型
/// 对应后端的 Pydantic Schema

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String priority;
  final String status;
  final String? location;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.priority = 'medium',
    this.status = 'pending',
    this.location,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'priority': priority,
      'status': status,
      'location': location,
    };
  }
}

class Plan {
  final String planId;
  final String title;
  final String? description;
  final List<Task> tasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.planId,
    required this.title,
    this.description,
    required this.tasks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      planId: json['plan_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((task) => Task.fromJson(task as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'title': title,
      'description': description,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

