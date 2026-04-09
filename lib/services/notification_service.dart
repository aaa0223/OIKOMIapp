import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';
import '../models/tgl_state.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // iOS上限64件のうち本アプリが使う最大件数
  static const int _maxNotifications = 60;

  static Future<void> init() async {
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);
  }

  static Future<void> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleNotificationsForTask(Task task) async {
    await cancelNotificationsForTask(task.id);

    final pending = await _plugin.pendingNotificationRequests();
    int remaining = _maxNotifications - pending.length;
    if (remaining <= 0) return;

    final transitions = [
      TGLState.someday,
      TGLState.reality,
      TGLState.noEscape,
      TGLState.war,
    ];

    for (final (index, targetState) in transitions.indexed) {
      if (remaining <= 0) break;
      final triggerTime = _calculateTransitionTime(task, targetState);
      if (triggerTime == null || !triggerTime.isAfter(DateTime.now())) continue;

      await _scheduleNotification(
        id: _notificationId(task.id, index),
        task: task,
        state: targetState,
        triggerTime: triggerTime,
      );
      remaining--;
    }
  }

  static Future<void> cancelNotificationsForTask(String taskId) async {
    for (int i = 0; i < 4; i++) {
      await _plugin.cancel(_notificationId(taskId, i));
    }
  }

  static DateTime? _calculateTransitionTime(Task task, TGLState state) {
    final threshold = _thresholdFor(state);
    final T = task.requiredHours;
    final M = task.avoidance.toDouble();

    final requiredSlack = (T * M) / threshold;
    final requiredD = T + requiredSlack;

    return task.deadline.subtract(
      Duration(milliseconds: (requiredD * 3600 * 1000).toInt()),
    );
  }

  static double _thresholdFor(TGLState state) {
    switch (state) {
      case TGLState.someday:  return TGLThresholds.peaceful;
      case TGLState.reality:  return TGLThresholds.someday;
      case TGLState.noEscape: return TGLThresholds.reality;
      case TGLState.war:      return TGLThresholds.noEscape;
      default:                return double.infinity;
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required Task task,
    required TGLState state,
    required DateTime triggerTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      task.title,
      _notificationMessage(state),
      tz.TZDateTime.from(triggerTime, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String _notificationMessage(TGLState state) {
    switch (state) {
      case TGLState.someday:  return '未来の自分が泣いてる';
      case TGLState.reality:  return 'そろそろ現実を見ようか';
      case TGLState.noEscape: return '逃げ場なくなりました';
      case TGLState.war:      return '戦争です。以上。';
      default:                return '';
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  static Future<void> rescheduleAllNotifications(List<Task> tasks) async {
    await _plugin.cancelAll();
    for (final task in tasks) {
      await scheduleNotificationsForTask(task);
    }
  }

  static int _notificationId(String taskId, int stateIndex) {
    return (taskId.hashCode.abs() % 1000000) * 10 + stateIndex;
  }
}
