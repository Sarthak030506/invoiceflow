import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import './invoice_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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
    if (response.payload == 'pending_invoices') {
      // Handle navigation to pending invoices screen
      print('Notification tapped: Navigate to pending invoices');
    }
  }

  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder(int pendingInvoiceCount) async {
    // Cancel existing reminders first
    await _notificationsPlugin.cancel(0);
    
    if (pendingInvoiceCount == 0) {
      return; // Don't schedule if no pending invoices
    }

    await _notificationsPlugin.zonedSchedule(
      0,
      'Payment Follow-up',
      'You have $pendingInvoiceCount invoice${pendingInvoiceCount > 1 ? 's' : ''} to check on today',
      _nextInstanceOf10AM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Payment Reminders',
          channelDescription: 'Daily reminders for pending payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'pending_invoices',
    );
  }

  tz.TZDateTime _nextInstanceOf10AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> checkAndNotifyPendingPayments() async {
    try {
      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final pendingInvoices = invoices.where((invoice) => 
        invoice.invoiceType == 'sales' && 
        invoice.remainingAmount > 0 &&
        (invoice.followUpDate == null || 
         DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isBefore(today) ||
         DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isAtSameMomentAs(today))
      ).toList();

      await scheduleDailyReminder(pendingInvoices.length);
    } catch (e) {
      print('Error checking pending payments: $e');
    }
  }

  Future<void> testNotification([BuildContext? context]) async {
    try {
      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final pendingInvoices = invoices.where((invoice) => 
        invoice.invoiceType == 'sales' && 
        invoice.remainingAmount > 0 &&
        (invoice.followUpDate == null || 
         DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isBefore(today) ||
         DateTime(invoice.followUpDate!.year, invoice.followUpDate!.month, invoice.followUpDate!.day).isAtSameMomentAs(today))
      ).toList();

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notifications',
          'Test Notifications',
          channelDescription: 'Test notifications for pending payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final message = pendingInvoices.isEmpty 
          ? 'No pending payments found'
          : 'You have ${pendingInvoices.length} invoice${pendingInvoices.length > 1 ? 's' : ''} to check on today';

      await _notificationsPlugin.show(
        1,
        'Payment Follow-up',
        message,
        notificationDetails,
        payload: 'pending_invoices',
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mobile notification sent! Check notification tray'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<void> initialize() async {
    await init();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}