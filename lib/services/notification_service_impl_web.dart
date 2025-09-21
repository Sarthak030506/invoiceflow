import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {}
  Future<void> scheduleDailyFollowUpReminder() async {}
  Future<void> scheduleDailyUnpaidInvoiceReminder() async {}
  Future<void> scheduleAllDailyNotifications() async {}
  Future<void> checkAndNotifyPendingPayments() async {}
  @deprecated
  Future<void> scheduleDailyReminder(int pendingInvoiceCount) async {}
  Future<void> testFollowUpNotification([BuildContext? context]) async {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification: Follow-up reminders (Web simulation)'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> testUnpaidPurchaseNotification([BuildContext? context]) async {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification: Unpaid purchases (Web simulation)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
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


