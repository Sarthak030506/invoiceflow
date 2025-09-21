import './notification_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Schedule both types of daily notifications
    await notificationService.scheduleAllDailyNotifications();
    
    print('BackgroundService: All daily notifications scheduled');
  }

  static Future<void> refreshNotifications() async {
    final notificationService = NotificationService();
    await notificationService.scheduleAllDailyNotifications();
    print('BackgroundService: Notifications refreshed');
  }

  static Future<void> cancelAllTasks() async {
    await NotificationService().cancelAllNotifications();
    print('BackgroundService: All notifications cancelled');
  }

  static Future<Map<String, dynamic>> getStatus() async {
    return await NotificationService().getNotificationStatus();
  }
}