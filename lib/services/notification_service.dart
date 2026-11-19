import 'dart:async';

/// Abstract service defining notification capabilities for Pomodo.
abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleTimerNotification({
    required String title,
    required String body,
    required Duration scheduledAfter,
  });
  Future<void> cancelAllNotifications();
}

/// Default implementation providing a clean mock/stub until external push plugins are attached.
class AppNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {
    // Initialization hook for local notifications plugin
  }

  @override
  Future<void> scheduleTimerNotification({
    required String title,
    required String body,
    required Duration scheduledAfter,
  }) async {
    // Schedules local system notification for timer completion
  }

  @override
  Future<void> cancelAllNotifications() async {
    // Clears pending notification queue
  }
}
