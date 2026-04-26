import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/navigator_key.dart';
import '../routes/app_routes.dart';
import '../utils/app_logger.dart';
import './invoice_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _tag = 'NotificationService';

  // Max per-category to stay under iOS 64-notification limit.
  static const int _maxPerCategory = 30;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    AppLogger.debug('NotificationService initialized', _tag);
  }

  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('invoice:')) return;

    final invoiceId = payload.substring('invoice:'.length);
    if (invoiceId.isEmpty) return;

    try {
      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final invoice = invoices.firstWhere(
        (i) => i.id == invoiceId,
        orElse: () => throw StateError('Invoice $invoiceId not found'),
      );
      navigatorKey.currentState?.pushNamed(
        AppRoutes.invoiceDetailScreen,
        arguments: invoice,
      );
    } catch (e, st) {
      AppLogger.error(
          'Notification deep link failed for invoiceId=$invoiceId', _tag, e, st);
    }
  }

  Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Stable notification ID derived from invoice ID.
  // hashCode gives a consistent value per string within a session;
  // modulo keeps it in a safe positive int range.
  int _notificationId(String invoiceId) =>
      invoiceId.hashCode.abs() % 2000000000;

  Future<void> scheduleDailyFollowUpReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('notifications_enabled') ?? true)) return;

      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final pending = _getPendingFollowUps(invoices).take(_maxPerCategory);

      for (final invoice in pending) {
        await _notificationsPlugin.zonedSchedule(
          _notificationId(invoice.id),
          'Follow-up Reminder',
          'Invoice #${invoice.invoiceNumber} — ₹${invoice.remainingAmount.toStringAsFixed(2)} pending',
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
          payload: 'invoice:${invoice.id}',
        );
      }

      AppLogger.debug(
          'Scheduled ${pending.length} follow-up notifications', _tag);
    } catch (e, st) {
      AppLogger.error('scheduleDailyFollowUpReminder failed', _tag, e, st);
    }
  }

  Future<void> scheduleDailyUnpaidInvoiceReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('notifications_enabled') ?? true)) return;

      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final unpaid = _getUnpaidPurchaseInvoices(invoices).take(_maxPerCategory);

      for (final invoice in unpaid) {
        await _notificationsPlugin.zonedSchedule(
          _notificationId(invoice.id),
          'Unpaid Purchase Invoice',
          'Invoice #${invoice.invoiceNumber} — ₹${invoice.remainingAmount.toStringAsFixed(2)} due',
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
          payload: 'invoice:${invoice.id}',
        );
      }

      AppLogger.debug(
          'Scheduled ${unpaid.length} unpaid-purchase notifications', _tag);
    } catch (e, st) {
      AppLogger.error(
          'scheduleDailyUnpaidInvoiceReminder failed', _tag, e, st);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  List<dynamic> _getPendingFollowUps(List<dynamic> invoices) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return invoices.where((invoice) {
      if (invoice.invoiceType != 'sales' || invoice.remainingAmount <= 0) {
        return false;
      }
      if (invoice.followUpDate == null) {
        final invoiceDate = DateTime(
            invoice.date.year, invoice.date.month, invoice.date.day);
        return today.difference(invoiceDate).inDays >= 7;
      }
      final followUpDate = DateTime(invoice.followUpDate!.year,
          invoice.followUpDate!.month, invoice.followUpDate!.day);
      return !followUpDate.isAfter(today);
    }).toList();
  }

  List<dynamic> _getUnpaidPurchaseInvoices(List<dynamic> invoices) =>
      invoices
          .where((i) =>
              i.invoiceType == 'purchase' && i.remainingAmount > 0)
          .toList();

  Future<void> scheduleAllDailyNotifications() async {
    // Cancel all previously scheduled notifications so stale paid invoices
    // don't keep firing. Fresh schedule reflects current invoice state.
    await _notificationsPlugin.cancelAll();
    await scheduleDailyFollowUpReminder();
    await scheduleDailyUnpaidInvoiceReminder();
  }

  Future<void> checkAndNotifyPendingPayments() async {
    await scheduleAllDailyNotifications();
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      final invoices = await InvoiceService.instance.fetchAllInvoices();
      final pendingFollowUps = _getPendingFollowUps(invoices);
      final unpaidPurchaseInvoices = _getUnpaidPurchaseInvoices(invoices);
      final pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();
      return {
        'notificationsEnabled': notificationsEnabled,
        'pendingFollowUpsCount': pendingFollowUps.length,
        'unpaidPurchaseInvoicesCount': unpaidPurchaseInvoices.length,
        'scheduledNotificationsCount': pendingNotifications.length,
        'scheduledNotifications': pendingNotifications
            .map((n) => {
                  'id': n.id,
                  'title': n.title,
                  'body': n.body,
                  'payload': n.payload,
                })
            .toList(),
        'nextFollowUpTime': '10:00 AM daily',
        'nextUnpaidPurchaseTime': '2:00 PM daily',
      };
    } catch (e, st) {
      AppLogger.error('getNotificationStatus failed', _tag, e, st);
      return {
        'error': e.toString(),
        'notificationsEnabled': false,
        'pendingFollowUpsCount': 0,
        'unpaidPurchaseInvoicesCount': 0,
        'scheduledNotificationsCount': 0,
      };
    }
  }

  Future<void> initialize() async => init();

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
