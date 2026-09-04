import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    final currentTimeZone =
        await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(currentTimeZone.identifier),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
Future<void> showTestNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'flowtask_test',
    'Testes do FlowTask',
    channelDescription: 'Canal usado para testar notificações',
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  await _notifications.show(
  id: 1,
  title: 'FlowTask 🔔',
  body: 'As notificações estão funcionando!',
  notificationDetails: details,
);
}
Future<void> scheduleTestNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'flowtask_tasks',
    'Lembretes de tarefas',
    channelDescription: 'Lembretes das tarefas do FlowTask',
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  await _notifications.zonedSchedule(
    id: 2,
    title: 'FlowTask 🔔',
    body: 'Teste de notificação agendada!',
    scheduledDate: tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 10),
    ),
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}
int _notificationId(String taskId) {
  var hash = 0;

  for (final code in taskId.codeUnits) {
    hash = ((hash * 31) + code) & 0x7fffffff;
  }

  return hash;
}

Future<void> scheduleTaskNotification({
  required String taskId,
  required String title,
  required DateTime dueDate,
  int hour = 9,
  int minute = 0,
}) async {
  final notificationId = _notificationId(taskId);

  final scheduledDate = tz.TZDateTime(
  tz.local,
  dueDate.year,
  dueDate.month,
  dueDate.day,
  hour,
  minute,
);

  await _notifications.cancel(
    id: notificationId,
  );

  if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
    return;
  }

  const androidDetails = AndroidNotificationDetails(
    'flowtask_tasks',
    'Lembretes de tarefas',
    channelDescription: 'Lembretes das tarefas do FlowTask',
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  await _notifications.zonedSchedule(
    id: notificationId,
    title: 'FlowTask 🔔',
    body: '$title vence hoje.',
    scheduledDate: scheduledDate,
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: taskId,
  );
}

Future<void> cancelTaskNotification(String taskId) async {
  await _notifications.cancel(
    id: _notificationId(taskId),
  );
}

    
  }