import '../utils/app_logger.dart';
import './notification_service.dart';

class BackgroundService {
  static const String _tag = 'BackgroundService';

  static Future<void> initialize() async {
    final svc = NotificationService();
    await svc.init();
    await svc.scheduleAllDailyNotifications();
    AppLogger.debug('All daily notifications scheduled', _tag);
  }

  static Future<void> refreshNotifications() async {
    await NotificationService().scheduleAllDailyNotifications();
    AppLogger.debug('Notifications refreshed', _tag);
  }

  static Future<void> cancelAllTasks() async {
    await NotificationService().cancelAllNotifications();
    AppLogger.debug('All notifications cancelled', _tag);
  }

  static Future<Map<String, dynamic>> getStatus() async {
    return NotificationService().getNotificationStatus();
  }
}
