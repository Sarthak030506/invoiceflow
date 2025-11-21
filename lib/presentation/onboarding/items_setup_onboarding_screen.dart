import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../catalogue/business_type_selection_screen.dart';
import 'import_methods/csv_upload_screen.dart';
import 'import_methods/manual_entry_screen.dart';
import 'import_methods/demo_items_screen.dart';
import 'import_methods/template_download_screen.dart';

class ItemsSetupOnboardingScreen extends StatefulWidget {
  final bool isFirstTimeSetup;
  
  const ItemsSetupOnboardingScreen({
    Key? key,
    this.isFirstTimeSetup = true,
  }) : super(key: key);

  @override
  State<ItemsSetupOnboardingScreen> createState() => _ItemsSetupOnboardingScreenState();
}

class _ItemsSetupOnboardingScreenState extends State<ItemsSetupOnboardingScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Set up your Items'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 4.h),
              
              // Import Options
              _buildImportOptions(),
              
              SizedBox(height: 4.h),
              
              // Skip option
              if (widget.isFirstTimeSetup) _buildSkipOption(),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_outlined,
                size: 8.w,
                color: Colors.blue[600],
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  widget.isFirstTimeSetup 
                    ? 'Welcome to InvoiceFlow!'
                    : 'Set up your Items',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Choose how you’d like to add your product list. You can always edit or add more later.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an import method:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),

        // Business Type Selection (RECOMMENDED)
        _buildOptionCard(
          icon: Icons.store,
          title: 'Choose Business Type',
          subtitle: 'Select your business type and get pre-filled catalogue with 100+ items',
          color: Colors.purple,
          onTap: () => _navigateToImportMethod(const BusinessTypeSelectionScreen(isFirstTimeSetup: true)),
          isRecommended: true,
        ),

        // CSV/Excel Upload
        _buildOptionCard(
          icon: Icons.upload_file_rounded,
          title: 'Upload Excel/CSV',
          subtitle: 'Import your items from a spreadsheet file.',
          color: Colors.green,
          onTap: () => _navigateToImportMethod(const CsvUploadScreen()),
        ),

        // Manual Entry
        _buildOptionCard(
          icon: Icons.edit_note_rounded,
          title: 'Manual Entry',
          subtitle: 'Type items in one at a time or in bulk.',
          color: Colors.orange,
          onTap: () => _navigateToImportMethod(const ManualEntryScreen()),
        ),

        // Demo List
        _buildOptionCard(
          icon: Icons.inventory_2_rounded,
          title: 'Demo Catalogue',
          subtitle: 'Restaurant & hotel supplies catalogue with 133 items',
          color: Colors.teal,
          onTap: () => _navigateToImportMethod(const DemoItemsScreen()),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isOptional = false,
    bool isRecommended = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isRecommended ? 4 : 2,
        shadowColor: color.withOpacity(isRecommended ? 0.3 : 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRecommended ? color : color.withOpacity(0.2),
                width: isRecommended ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 6.w,
                    color: color,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (isRecommended) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          if (isOptional) ...[
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 4.w,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipOption() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.skip_next_rounded,
            size: 6.w,
            color: Colors.grey[600],
          ),
          SizedBox(height: 1.h),
          Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'You can set up your items later from the settings',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _skipSetup(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[700],
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Skip Setup',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImportMethod(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    
    if (result == true) {
      // Import was successful, mark onboarding as complete
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  void _skipSetup() {
    // Mark onboarding as complete even if skipped
    context.read<AuthProvider>().completeOnboarding();
  }
}
