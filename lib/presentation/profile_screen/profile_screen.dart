import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../../config/navigation_config.dart';
import '../../utils/responsive_helper.dart';
import '../../models/business_profile_model.dart';
import '../../services/business_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 4; // Profile is index 4
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = false;

  String? _profileImageUrl;
  bool _isEmailVerified = false;

  // Business profile state
  BusinessProfileModel? _businessProfile;
  bool _isSavingProfile = false;
  final _shopNameCtrl    = TextEditingController();
  final _ownerPhoneCtrl  = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _gstinCtrl       = TextEditingController();
  String? _businessType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    final profile = await BusinessProfileService.instance.getProfile();
    if (!mounted) return;
    setState(() {
      _businessProfile = profile;
      _shopNameCtrl.text   = profile?.shopName   ?? '';
      _ownerPhoneCtrl.text = profile?.ownerPhone ?? '';
      _addressCtrl.text    = profile?.address    ?? '';
      _gstinCtrl.text      = profile?.gstin      ?? '';
      _businessType        = profile?.businessType;
    });
  }

  Future<void> _saveBusinessProfile() async {
    final shopName  = _shopNameCtrl.text.trim();
    final phone     = _ownerPhoneCtrl.text.trim();
    final address   = _addressCtrl.text.trim();

    if (shopName.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop name, phone, and address are required.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final profile = BusinessProfileModel(
        shopName: shopName,
        ownerPhone: phone,
        address: address,
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        businessType: _businessType,
      );
      await BusinessProfileService.instance.saveProfile(profile);
      if (!mounted) return;
      setState(() => _businessProfile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Widget _buildBusinessSettingsCard() {
    final gstin = _gstinCtrl.text.trim();
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Settings',
                style: AppTheme.lightTheme.textTheme.titleMedium),
            SizedBox(height: 2.h),
            TextField(
              controller: _shopNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Shop / Business Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _ownerPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Owner Phone *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _gstinCtrl,
              decoration: const InputDecoration(
                labelText: 'GSTIN (optional — leave blank for non-GST mode)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (gstin.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              DropdownButtonFormField<String>(
                value: _businessType,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'proprietor',  child: Text('Proprietorship')),
                  DropdownMenuItem(value: 'partnership', child: Text('Partnership')),
                  DropdownMenuItem(value: 'pvt_ltd',     child: Text('Private Limited')),
                ],
                onChanged: (v) => setState(() => _businessType = v),
              ),
            ],
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingProfile ? null : _saveBusinessProfile,
                child: _isSavingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Business Profile'),
              ),
            ),
          ],
        ),
      ),
    );
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
        _profileImageUrl = user.photoURL;
        _isEmailVerified = user.emailVerified;
      } else {
        _userName = prefs.getString('user_name') ?? 'User';
        _userEmail = prefs.getString('user_email') ?? '';
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

  void _onNavigationTap(int index) {
    if (index == 4) return; // Already on Profile screen

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.homeDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.invoicesListScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.analyticsScreen);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.customersScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationChanged: _onNavigationTap,
      items: NavigationConfig.mainNavigationItems,
      appBar: AppBar(
        automaticallyImplyLeading: ResponsiveHelper.isMobile(context),
        title: Text(
          'Profile',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = ResponsiveHelper.isMobile(context) ? constraints.maxWidth : 600.0;
          return Center(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(maxWidth, MediaQuery.of(context).size.height),
              ),
              child: Container(
                width: maxWidth,
                child: _isLoading
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
                              profileImageUrl: _profileImageUrl,
                              isEmailVerified: _isEmailVerified,
                            ),
                            SizedBox(height: 3.h),
                            _buildBusinessSettingsCard(),
                            SizedBox(height: 3.h),
                            LogoutButtonWidget(
                              onPressed: _showLogoutDialog,
                            ),
                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
    );
  }
}
