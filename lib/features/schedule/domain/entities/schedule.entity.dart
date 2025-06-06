// lib/features/schedule/domain/entities/schedule.entity.dart
import '../../../../core/utils/date_utils.dart';

enum SchedulePriority { low, medium, high }

extension SchedulePriorityExtension on SchedulePriority {
  String get displayName {
    switch (this) {
      case SchedulePriority.low:
        return 'Low';
      case SchedulePriority.medium:
        return 'Medium';
      case SchedulePriority.high:
        return 'High';
    }
  }

  String get value {
    switch (this) {
      case SchedulePriority.low:
        return 'low';
      case SchedulePriority.medium:
        return 'medium';
      case SchedulePriority.high:
        return 'high';
    }
  }

  static SchedulePriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return SchedulePriority.low;
      case 'medium':
        return SchedulePriority.medium;
      case 'high':
        return SchedulePriority.high;
      default:
        return SchedulePriority.medium;
    }
  }
}

class Schedule {
  final String id;
  final String workspaceId;
  final String userId;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String color;
  final String icon;
  final SchedulePriority priority;
  final String? assignedTo;
  final bool isCompleted;
  final bool isRecurring;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for UI
  final String? assignedToName;
  final String? assignedToEmail;

  const Schedule({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.color,
    required this.icon,
    required this.priority,
    this.assignedTo,
    required this.isCompleted,
    required this.isRecurring,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToName,
    this.assignedToEmail,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
      color: json['color'] as String,
      icon: json['icon'] as String,
      priority: SchedulePriorityExtension.fromString(json['priority'] as String),
      assignedTo: json['assignedTo'] as String?,
      isCompleted: json['isCompleted'] == true,
      isRecurring: json['isRecurring'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      assignedToName: json['assignedToName'] as String?,
      assignedToEmail: json['assignedToEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'title': title,
      'description': description,
      'date': AppDateUtils.formatForApi(date),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'color': color,
      'icon': icon,
      'priority': priority.value,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'isRecurring': isRecurring,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
    };
  }

  // Computed properties
  DateTime get effectiveEndTime {
    return endTime ?? startTime.add(Duration(minutes: durationMinutes));
  }

  bool get isToday {
    return AppDateUtils.isToday(date);
  }

  bool get isTomorrow {
    return AppDateUtils.isTomorrow(date);
  }

  bool get isOverdue {
    if (isCompleted) return false;
    return effectiveEndTime.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    return startTime.isAfter(DateTime.now()) && !isCompleted;
  }

  bool get isInProgress {
    final now = DateTime.now();
    return !isCompleted &&
        startTime.isBefore(now) &&
        effectiveEndTime.isAfter(now);
  }

  Duration get remainingTime {
    if (isCompleted) return Duration.zero;
    final now = DateTime.now();
    if (effectiveEndTime.isBefore(now)) return Duration.zero;
    return effectiveEndTime.difference(now);
  }

  Duration get duration {
    return Duration(minutes: durationMinutes);
  }

  String get timeRange {
    final start = AppDateUtils.formatTimeForDisplay(startTime);
    final end = AppDateUtils.formatTimeForDisplay(effectiveEndTime);
    return '$start - $end';
  }

  String get displayDate {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return AppDateUtils.formatSmart(date);
  }

  bool get isAssigned {
    return assignedTo != null && assignedTo!.isNotEmpty;
  }

  // Copy with method
  Schedule copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? color,
    String? icon,
    SchedulePriority? priority,
    String? assignedTo,
    bool? isCompleted,
    bool? isRecurring,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedToName,
    String? assignedToEmail,
  }) {
    return Schedule(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      isCompleted: isCompleted ?? this.isCompleted,
      isRecurring: isRecurring ?? this.isRecurring,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Schedule &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Schedule{id: $id, title: $title, date: $date, isCompleted: $isCompleted}';
  }
}

// Request models for API
class CreateScheduleRequest {
  final String title;
  final String? description;
  final DateTime date;
  final DateTime startTime;
  final int durationMinutes;
  final String color;
  final String icon;
  final SchedulePriority priority;
  final String? assignedTo;

  const CreateScheduleRequest({
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.color,
    required this.icon,
    required this.priority,
    this.assignedTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': AppDateUtils.formatForApi(date),
      'startTime': AppDateUtils.formatTimeForApi(startTime),
      'durationMinutes': durationMinutes,
      'color': color,
      'icon': icon,
      'priority': priority.value,
      'assignedTo': assignedTo,
    };
  }
}

class UpdateScheduleRequest {
  final String? title;
  final String? description;
  final DateTime? date;
  final DateTime? startTime;
  final int? durationMinutes;
  final String? color;
  final String? icon;
  final SchedulePriority? priority;
  final String? assignedTo;

  const UpdateScheduleRequest({
    this.title,
    this.description,
    this.date,
    this.startTime,
    this.durationMinutes,
    this.color,
    this.icon,
    this.priority,
    this.assignedTo,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (date != null) json['date'] = AppDateUtils.formatForApi(date!);
    if (startTime != null) json['startTime'] = startTime!.toIso8601String();
    if (durationMinutes != null) json['durationMinutes'] = durationMinutes;
    if (color != null) json['color'] = color;
    if (icon != null) json['icon'] = icon;
    if (priority != null) json['priority'] = priority!.value;
    if (assignedTo != null) json['assignedTo'] = assignedTo;

    return json;
  }
}

// Helper class for schedule constants
class ScheduleConstants {
  static const List<String> defaultColors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FECA57', // Yellow
    '#FF9FF3', // Pink
    '#54A0FF', // Light Blue
    '#5F27CD', // Purple
  ];

  static const List<String> defaultIcons = [
    'work',
    'meeting',
    'call',
    'exercise',
    'study',
    'personal',
    'travel',
    'health',
  ];

  static const Map<String, String> iconLabels = {
    'work': 'Work',
    'meeting': 'Meeting',
    'call': 'Call',
    'exercise': 'Exercise',
    'study': 'Study',
    'personal': 'Personal',
    'travel': 'Travel',
    'health': 'Health',
  };
}