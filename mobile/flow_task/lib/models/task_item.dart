enum TaskPriority { low, medium, high }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.isCompleted,
    this.description,
    this.dueDate,
    this.completedAt,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  final String id;
  final String title;
  final String category;
  final TaskPriority priority;
  final bool isCompleted;
  final String? description;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int reminderHour;
  final int reminderMinute;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final rawPriority =
        (json['priority'] as String? ?? 'medium').toLowerCase();

    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == rawPriority,
      orElse: () => TaskPriority.medium,
    );

    DateTime? dueDate;
    final rawDueDate = json['dueDate'];

    if (rawDueDate is DateTime) {
      dueDate = rawDueDate;
    } else if (rawDueDate is String && rawDueDate.isNotEmpty) {
      dueDate = DateTime.tryParse(rawDueDate);
    }

    DateTime? completedAt;
    final rawCompletedAt = json['completedAt'];

    if (rawCompletedAt is DateTime) {
      completedAt = rawCompletedAt;
    } else if (rawCompletedAt is String && rawCompletedAt.isNotEmpty) {
      completedAt = DateTime.tryParse(rawCompletedAt);
    }

    return TaskItem(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Geral',
      priority: priority,
      isCompleted: json['isCompleted'] as bool? ?? false,
      description: json['description'] as String?,
      dueDate: dueDate,
      completedAt: completedAt,
      reminderHour: json['reminderHour'] as int? ?? 9,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
    );
  }
}
