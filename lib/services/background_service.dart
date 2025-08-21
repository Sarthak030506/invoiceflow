import './notification_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.checkAndNotifyPendingPayments();
  }

  static Future<void> cancelAllTasks() async {
    await NotificationService().cancelAllNotifications();
  }
}