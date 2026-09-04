import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_item.dart';
import 'notification_service.dart';

class TaskService {
  TaskService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  User _currentUser() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    return user;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  TaskItem _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final dueDate = _readDate(data['dueDate']);
    final completedAt = _readDate(data['completedAt']);

    final priorityText =
        (data['priority'] as String? ?? 'medium').toLowerCase();

    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityText,
      orElse: () => TaskPriority.medium,
    );

    return TaskItem(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: data['category'] as String? ?? 'Geral',
      priority: priority,
      isCompleted: data['isCompleted'] as bool? ?? false,
      dueDate: dueDate,
      completedAt: completedAt,
      reminderHour: data['reminderHour'] as int? ?? 9,
      reminderMinute: data['reminderMinute'] as int? ?? 0,
    );
  }

  Stream<List<TaskItem>> watch() {
    final user = _currentUser();

    return _tasks
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_fromDocument)
              .toList(),
        );
  }

  Future<List<TaskItem>> list({
    String search = '',
    bool? completed,
  }) async {
    final user = _currentUser();

    final snapshot = await _tasks
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .get();

    var result = snapshot.docs
        .map(_fromDocument)
        .toList();

    final normalizedSearch = search.trim().toLowerCase();

    if (normalizedSearch.isNotEmpty) {
      result = result.where((task) {
        final text =
            '${task.title} ${task.description ?? ''} ${task.category}'
                .toLowerCase();

        return text.contains(normalizedSearch);
      }).toList();
    }

    if (completed != null) {
      result = result
          .where(
            (task) => task.isCompleted == completed,
          )
          .toList();
    }

    return result;
  }

  Future<void> create({
    required String title,
    String? description,
    String category = 'Geral',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    int reminderHour = 9,
    int reminderMinute = 0,
  }) async {
    final user = _currentUser();
    final cleanDescription = description?.trim();

    final reference = await _tasks.add({
      'userId': user.uid,
      'title': title.trim(),
      'description':
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
      'category': category,
      'priority': priority.name,
      'isCompleted': false,
      'dueDate':
          dueDate == null
              ? null
              : Timestamp.fromDate(dueDate),
      'completedAt': null,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (dueDate != null) {
      await NotificationService.instance.scheduleTaskNotification(
        taskId: reference.id,
        title: title.trim(),
        dueDate: dueDate,
        hour: reminderHour,
        minute: reminderMinute,
      );
    }
  }

  Future<void> toggle(String id) async {
    final reference = _tasks.doc(id);
    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw Exception('Tarefa não encontrada.');
    }

    final data = snapshot.data();
    final currentValue =
        data?['isCompleted'] as bool? ?? false;

    final newValue = !currentValue;

    await reference.update({
      'isCompleted': newValue,
      'completedAt':
          newValue ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedSnapshot = await reference.get();
    final updatedData = updatedSnapshot.data();

    final isCompleted =
        updatedData?['isCompleted'] as bool? ?? false;

    final dueDate = _readDate(updatedData?['dueDate']);
    final title =
        updatedData?['title'] as String? ?? 'Tarefa';
    final reminderHour =
        updatedData?['reminderHour'] as int? ?? 9;
    final reminderMinute =
        updatedData?['reminderMinute'] as int? ?? 0;

    if (isCompleted || dueDate == null) {
      await NotificationService.instance
          .cancelTaskNotification(id);
    } else {
      await NotificationService.instance
          .scheduleTaskNotification(
        taskId: id,
        title: title,
        dueDate: dueDate,
        hour: reminderHour,
        minute: reminderMinute,
      );
    }
  }

  Future<void> remove(String id) async {
    await NotificationService.instance
        .cancelTaskNotification(id);

    await _tasks.doc(id).delete();
  }

  Future<void> update({
    required String id,
    required String title,
    String? description,
    required String category,
    required TaskPriority priority,
    DateTime? dueDate,
    int reminderHour = 9,
    int reminderMinute = 0,
  }) async {
    final cleanDescription = description?.trim();

    await _tasks.doc(id).update({
      'title': title.trim(),
      'description':
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
      'category': category,
      'priority': priority.name,
      'dueDate':
          dueDate == null
              ? null
              : Timestamp.fromDate(dueDate),
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await _tasks.doc(id).get();
    final isCompleted =
        snapshot.data()?['isCompleted'] as bool? ?? false;

    if (isCompleted || dueDate == null) {
      await NotificationService.instance
          .cancelTaskNotification(id);
    } else {
      await NotificationService.instance
          .scheduleTaskNotification(
        taskId: id,
        title: title.trim(),
        dueDate: dueDate,
        hour: reminderHour,
        minute: reminderMinute,
      );
    }
  }
}
