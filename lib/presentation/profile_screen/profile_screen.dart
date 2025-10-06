import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Profile tab index
  String _userName = '';
  String _userEmail = '';
  String _lastSyncTime = '';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _darkModeEnabled = false;
  bool _isLoading = false;

  // Mock user data
  final Map<String, dynamic> _mockUserData = {
    "fullName": "Sarah Johnson",
    "email": "sarah.johnson@example.com",
    "profileImage": null, // Use initials-based avatar instead
    "isEmailVerified": true,
    "lastSyncTime": "2025-07-09 17:45:00",
    "appVersion": "1.2.3",
    "joinDate": "2024-03-15"
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data from SharedPreferences or use mock data
      _userName =
          prefs.getString('user_name') ?? (_mockUserData['fullName'] as String);
      _userEmail =
          prefs.getString('user_email') ?? (_mockUserData['email'] as String);
      _lastSyncTime = prefs.getString('last_sync_time') ??
          (_mockUserData['lastSyncTime'] as String);
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;

      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading user data: \$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSyncData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().toString().substring(0, 19);
      await prefs.setString('last_sync_time', currentTime);

      setState(() {
        _lastSyncTime = currentTime;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      setState(() {
        _notificationsEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                value ? 'Notifications enabled' : 'Notifications disabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling notifications: \$e');
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', value);

      setState(() {
        _biometricEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Biometric authentication enabled'
                : 'Biometric authentication disabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling biometric: \$e');
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode_enabled', value);

      setState(() {
        _darkModeEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling dark mode: \$e');
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Simulate logout delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/invoices-list-screen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/analytics-screen');
        break;
      case 3:
        // Already on profile screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  ProfileHeaderWidget(
                    userName: _userName,
                    userEmail: _userEmail,
                    profileImageUrl: _mockUserData['profileImage'] as String?,
                    isEmailVerified: _mockUserData['isEmailVerified'] as bool,
                  ),
                  SizedBox(height: 2.h),
                  SettingsSectionWidget(
                    title: 'Account Management',
                    items: [
                      SettingsItem(
                        icon: 'edit',
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit Profile feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'lock',
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Change Password feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'notifications',
                        title: 'Notification Settings',
                        subtitle:
                            _notificationsEnabled ? 'Enabled' : 'Disabled',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                      ),
                      if (!kIsWeb) ...[
                        SettingsItem(
                          icon: 'notification_add',
                          title: 'Test Follow-up Notification',
                          subtitle: 'Send a test notification for follow-ups',
                          onTap: () async {
                            await NotificationService().testFollowUpNotification(context);
                          },
                        ),
                        SettingsItem(
                          icon: 'notification_add',
                          title: 'Test Purchase Notification',
                          subtitle: 'Send a test notification for unpaid purchases',
                          onTap: () async {
                            await NotificationService().testUnpaidPurchaseNotification(context);
                          },
                        ),
                      ] else ...[
                        SettingsItem(
                          icon: 'info',
                          title: 'Notification Tests',
                          subtitle: 'Not available on web platform',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifications are not supported on web'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                      SettingsItem(
                        icon: 'fingerprint',
                        title: 'Biometric Authentication',
                        subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                        trailing: Switch(
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SettingsSectionWidget(
                    title: 'App Settings',
                    items: [
                      SettingsItem(
                        icon: 'sync',
                        title: 'Data Sync',
                        subtitle: 'Last sync: \$_lastSyncTime',
                        trailing: IconButton(
                          onPressed: _refreshSyncData,
                          icon: CustomIconWidget(
                            iconName: 'refresh',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      SettingsItem(
                        icon: 'download',
                        title: 'Export Data',
                        subtitle: 'Download your data as CSV',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export Data feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'info',
                        title: 'App Version',
                        subtitle: 'Version ${_mockUserData['appVersion']}',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are using the latest version'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'dark_mode',
                        title: 'Dark Mode',
                        subtitle: _darkModeEnabled ? 'Enabled' : 'Disabled',
                        trailing: Switch(
                          value: _darkModeEnabled,
                          onChanged: _toggleDarkMode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SettingsSectionWidget(
                    title: 'Support',
                    items: [
                      SettingsItem(
                        icon: 'help',
                        title: 'Help & FAQ',
                        subtitle: 'Get answers to common questions',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Help & FAQ feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'contact_support',
                        title: 'Contact Support',
                        subtitle: 'Get help from our team',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Contact Support feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      SettingsItem(
                        icon: 'privacy_tip',
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Privacy Policy feature coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  LogoutButtonWidget(
                    onPressed: _showLogoutDialog,
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;
          
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/invoices-list-screen');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/analytics-screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/customers-screen');
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }
}
