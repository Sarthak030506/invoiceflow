import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './invoice_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const int _dailyFollowUpId = 1;
  static const int _unpaidInvoiceId = 2;
  static const int _testNotificationId = 99;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
  }

  void _onNotificationTapped(NotificationResponse response) {
    switch (response.payload) {
      case 'pending_follow_ups':
        break;
      case 'unpaid_purchase_invoices':
        break;
      case 'pending_invoices':
      default:
        break;
    }
  }

  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyFollowUpReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) {
        await _notificationsPlugin.cancel(_dailyFollowUpId);
        return;
      }

      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final pendingFollowUps = await _getPendingFollowUps(invoices);
      await _notificationsPlugin.cancel(_dailyFollowUpId);
      if (pendingFollowUps.isEmpty) return;

      await _notificationsPlugin.zonedSchedule(
        _dailyFollowUpId,
        'Follow-up Reminder',
        'You have ${pendingFollowUps.length} invoice${pendingFollowUps.length > 1 ? 's' : ''} requiring follow-up today',
        _nextInstanceOfTime(10, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'follow_up_reminders',
            'Follow-up Reminders',
            channelDescription: 'Daily reminders for invoice follow-ups',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'pending_follow_ups',
      );
    } catch (_) {}
  }

  Future<void> scheduleDailyUnpaidInvoiceReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) {
        await _notificationsPlugin.cancel(_unpaidInvoiceId);
        return;
      }

      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final unpaidPurchaseInvoices = await _getUnpaidPurchaseInvoices(invoices);
      await _notificationsPlugin.cancel(_unpaidInvoiceId);
      if (unpaidPurchaseInvoices.isEmpty) return;

      final totalAmount = unpaidPurchaseInvoices.fold<double>(0.0, (sum, invoice) => sum + invoice.remainingAmount);

      await _notificationsPlugin.zonedSchedule(
        _unpaidInvoiceId,
        'Unpaid Purchase Invoices',
        '${unpaidPurchaseInvoices.length} unpaid purchase invoice${unpaidPurchaseInvoices.length > 1 ? 's' : ''} (₹${totalAmount.toStringAsFixed(2)})',
        _nextInstanceOfTime(14, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'unpaid_purchase_reminders',
            'Unpaid Purchase Reminders',
            channelDescription: 'Daily reminders for unpaid purchase invoices',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'unpaid_purchase_invoices',
      );
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<List<dynamic>> _getPendingFollowUps(List<dynamic> invoices) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return invoices.where((invoice) {
      if (invoice.invoiceType != 'sales' || invoice.remainingAmount <= 0) return false;
      if (invoice.followUpDate == null) {
        final invoiceDate = DateTime(invoice.date.year, invoice.date.month, invoice.date.day);
        final daysSinceInvoice = today.difference(invoiceDate).inDays;
        return daysSinceInvoice >= 7;
      }
      final followUpDate = DateTime(
        invoice.followUpDate!.year,
        invoice.followUpDate!.month,
        invoice.followUpDate!.day,
      );
      return followUpDate.isBefore(today) || followUpDate.isAtSameMomentAs(today);
    }).toList();
  }

  Future<List<dynamic>> _getUnpaidPurchaseInvoices(List<dynamic> invoices) async {
    return invoices.where((invoice) => invoice.invoiceType == 'purchase' && invoice.remainingAmount > 0).toList();
  }

  Future<void> scheduleAllDailyNotifications() async {
    await scheduleDailyFollowUpReminder();
    await scheduleDailyUnpaidInvoiceReminder();
  }

  Future<void> checkAndNotifyPendingPayments() async {
    await scheduleAllDailyNotifications();
  }

  @deprecated
  Future<void> scheduleDailyReminder(int pendingInvoiceCount) async {
    await scheduleDailyFollowUpReminder();
  }

  Future<void> testFollowUpNotification([BuildContext? context]) async {
    final invoices = await InvoiceService.instance.fetchAllInvoices();
    final pendingFollowUps = await _getPendingFollowUps(invoices);
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('test_notifications', 'Test Notifications', channelDescription: 'Test notifications for follow-ups', importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    final message = pendingFollowUps.isEmpty ? 'No pending follow-ups found' : 'TEST: ${pendingFollowUps.length} invoice${pendingFollowUps.length > 1 ? 's' : ''} requiring follow-up';
    await _notificationsPlugin.show(_testNotificationId, 'Follow-up Test', message, notificationDetails, payload: 'pending_follow_ups');
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow-up test notification sent!'), backgroundColor: Colors.blue, duration: Duration(seconds: 2)));
    }
  }

  Future<void> testUnpaidPurchaseNotification([BuildContext? context]) async {
    final invoices = await InvoiceService.instance.fetchAllInvoices();
    final unpaidPurchaseInvoices = await _getUnpaidPurchaseInvoices(invoices);
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails('test_notifications', 'Test Notifications', channelDescription: 'Test notifications for unpaid purchases', importance: Importance.high, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    final totalAmount = unpaidPurchaseInvoices.fold<double>(0.0, (sum, invoice) => sum + invoice.remainingAmount);
    final message = unpaidPurchaseInvoices.isEmpty ? 'No unpaid purchase invoices found' : 'TEST: ${unpaidPurchaseInvoices.length} unpaid purchase invoice${unpaidPurchaseInvoices.length > 1 ? 's' : ''} (₹${totalAmount.toStringAsFixed(2)})';
    await _notificationsPlugin.show(_testNotificationId + 1, 'Unpaid Purchase Test', message, notificationDetails, payload: 'unpaid_purchase_invoices');
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unpaid purchase test notification sent!'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final pendingFollowUps = await _getPendingFollowUps(invoices);
      final unpaidPurchaseInvoices = await _getUnpaidPurchaseInvoices(invoices);
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      return {
        'notificationsEnabled': notificationsEnabled,
        'pendingFollowUpsCount': pendingFollowUps.length,
        'unpaidPurchaseInvoicesCount': unpaidPurchaseInvoices.length,
        'scheduledNotificationsCount': pendingNotifications.length,
        'scheduledNotifications': pendingNotifications.map((n) => {'id': n.id, 'title': n.title, 'body': n.body, 'payload': n.payload}).toList(),
        'nextFollowUpTime': '10:00 AM daily',
        'nextUnpaidPurchaseTime': '2:00 PM daily',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'notificationsEnabled': false,
        'pendingFollowUpsCount': 0,
        'unpaidPurchaseInvoicesCount': 0,
        'scheduledNotificationsCount': 0,
      };
    }
  }

  Future<void> initialize() async {
    await init();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}


