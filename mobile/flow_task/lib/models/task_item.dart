enum TaskPriority { low, medium, high }
class TaskItem {
  const TaskItem({required this.id, required this.title, required this.category, required this.priority, required this.isCompleted, this.description, this.dueDate});
  final int id; final String title; final String category; final TaskPriority priority; final bool isCompleted; final String? description; final DateTime? dueDate;
  factory TaskItem.fromJson(Map<String,dynamic> json) => TaskItem(
    id: json['id'] as int, title: json['title'] as String, category: json['category'] as String,
    priority: TaskPriority.values.byName((json['priority'] as String).toLowerCase()),
    isCompleted: json['isCompleted'] as bool, description: json['description'] as String?,
    dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String));
}