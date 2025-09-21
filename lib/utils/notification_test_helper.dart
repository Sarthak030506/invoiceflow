import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';

/// Helper class for testing notification functionality
class NotificationTestHelper {
  static final NotificationService _notificationService = NotificationService();

  /// Test all notification types
  static Future<void> testAllNotifications(BuildContext context) async {
    try {
      // Test follow-up notification
      await _notificationService.testFollowUpNotification(context);
      
      // Wait a bit before sending the next notification
      await Future.delayed(Duration(seconds: 2));
      
      // Test unpaid purchase notification
      await _notificationService.testUnpaidPurchaseNotification(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All test notifications sent successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing notifications: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Get detailed notification status
  static Future<void> showNotificationStatus(BuildContext context) async {
    try {
      final status = await _notificationService.getNotificationStatus();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Notification Status'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusItem('Notifications Enabled', status['notificationsEnabled'].toString()),
                _buildStatusItem('Pending Follow-ups', status['pendingFollowUpsCount'].toString()),
                _buildStatusItem('Unpaid Purchase Invoices', status['unpaidPurchaseInvoicesCount'].toString()),
                _buildStatusItem('Scheduled Notifications', status['scheduledNotificationsCount'].toString()),
                _buildStatusItem('Follow-up Time', status['nextFollowUpTime'] ?? 'Not set'),
                _buildStatusItem('Unpaid Purchase Time', status['nextUnpaidPurchaseTime'] ?? 'Not set'),
                
                if (status['scheduledNotifications'] != null && status['scheduledNotifications'].isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('Scheduled Notifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...status['scheduledNotifications'].map<Widget>((notification) => 
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text('• ${notification['title']}: ${notification['body']}', 
                        style: TextStyle(fontSize: 12)),
                    ),
                  ).toList(),
                ],
                
                if (status['error'] != null) ...[
                  SizedBox(height: 16),
                  Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(status['error'], style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await BackgroundService.refreshNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notifications refreshed'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting notification status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Schedule immediate test notifications (for debugging)
  static Future<void> scheduleImmediateTestNotifications() async {
    try {
      // Schedule a test notification for 5 seconds from now
      await _notificationService.scheduleDailyFollowUpReminder();
      await _notificationService.scheduleDailyUnpaidInvoiceReminder();
      
      print('Test notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling test notifications: $e');
    }
  }
}