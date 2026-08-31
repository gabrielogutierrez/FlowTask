import '../core/api_client.dart';
import '../models/task_item.dart';
class TaskService {
  TaskService(this.api); final ApiClient api;
  Future<List<TaskItem>> list({
  String search = '',
  bool? completed,
}) async {
  final params = <String, String>{};

  if (search.trim().isNotEmpty) {
    params['search'] = search.trim();
  }

  if (completed != null) {
    params['completed'] = completed.toString();
  }

  final query = params.isEmpty
      ? ''
      : '?${Uri(queryParameters: params).query}';

  final data = await api.get('/tasks$query') as List;

  return data
      .map(
        (x) => TaskItem.fromJson(
          x as Map<String, dynamic>,
        ),
      )
      .toList();
}
  Future<void> create({
  required String title,
  String? description,
  String category = 'Geral',
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
}) async {
  final priorityText = switch (priority) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  await api.post('/tasks', {
    'title': title,
    'description': description,
    'category': category,
    'priority': priorityText,
    'dueDate': dueDate?.toIso8601String(),
  });
}
  Future<void> toggle(int id) async => api.patch('/tasks/$id/toggle');
  Future<void> remove(int id) async => api.delete('/tasks/$id');
  Future<void> update({
  required int id,
  required String title,
  String? description,
  required String category,
  required TaskPriority priority,
  DateTime? dueDate,
}) async {
  final priorityText = switch (priority) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  await api.put('/tasks/$id', {
    'title': title,
    'description': description,
    'category': category,
    'priority': priorityText,
    'dueDate': dueDate?.toIso8601String(),
  });
}
}