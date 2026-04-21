class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}
  Future<void> scheduleDailyFollowUpReminder() async {}
  Future<void> scheduleDailyUnpaidInvoiceReminder() async {}
  Future<void> scheduleAllDailyNotifications() async {}
  Future<void> checkAndNotifyPendingPayments() async {}
  Future<Map<String, dynamic>> getNotificationStatus() async {
    return {
      'notificationsEnabled': false,
      'pendingFollowUpsCount': 0,
      'unpaidPurchaseInvoicesCount': 0,
      'scheduledNotificationsCount': 0,
      'note': 'Notifications are not supported on Flutter Web in this build.'
    };
  }
  Future<void> initialize() async {}
  Future<void> cancelAllNotifications() async {}
}


