import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import '../../widgets/enhanced_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      // Load user data from Firebase Auth if available
      if (user != null) {
        _userName = user.displayName ?? user.email?.split('@').first ?? 'User';
        _userEmail = user.email ?? '';
      } else {
        // Fallback to SharedPreferences or mock data
        _userName = prefs.getString('user_name') ?? (_mockUserData['fullName'] as String);
        _userEmail = prefs.getString('user_email') ?? (_mockUserData['email'] as String);
      }

      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error loading user data: \$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Firebase
      if (mounted) {
        await context.read<AuthProvider>().signOut();
      }

      // Navigate to root (AuthGate will handle showing LoginScreen)
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                  SizedBox(height: 4.h),
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
