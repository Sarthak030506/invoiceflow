import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'analytics_redesign_scaffold.dart';
import 'overview_kpis_screen.dart';
import '../../widgets/enhanced_bottom_nav.dart';

class AnalyticsMainScreen extends StatefulWidget {
  const AnalyticsMainScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsMainScreen> createState() => _AnalyticsMainScreenState();
}

class _AnalyticsMainScreenState extends State<AnalyticsMainScreen> {
  String selectedDateRange = 'last7';
  Map<String, DateTime>? customDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateChipsBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                _buildAnalyticsCard(
                  'Overview KPIs',
                  'Key performance metrics',
                  Icons.dashboard,
                  Colors.blue,
                  () => _openSection('overview'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Revenue',
                  'Sales and purchase analysis',
                  Icons.trending_up,
                  Colors.green,
                  () => _openSection('revenue'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Items & Sales Insights',
                  'Product performance data',
                  Icons.shopping_cart,
                  Colors.orange,
                  () => _openSection('items'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Inventory Analytics',
                  'Stock levels and movement',
                  Icons.inventory_2,
                  Colors.purple,
                  () => _openSection('inventory'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Due Reminders',
                  'Outstanding payments',
                  Icons.schedule,
                  Colors.red,
                  () => _openSection('due'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Analytics Table',
                  'Detailed data view',
                  Icons.table_chart,
                  Colors.teal,
                  () => _openSection('table'),
                ),
                SizedBox(height: 3.w),
                _buildAnalyticsCard(
                  'Charts',
                  'Visual data representation',
                  Icons.bar_chart,
                  Colors.indigo,
                  () => _openSection('charts'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: 2,
        onTap: _onBottomNavTap,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 2) return; // Already on Analytics
    
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/invoices-list-screen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/customers-screen');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }

  Widget _buildDateChipsBar() {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDateChip('Last 7 days', 'last7'),
            SizedBox(width: 2.w),
            _buildDateChip('Last 30 days', 'last30'),
            SizedBox(width: 2.w),
            _buildDateChip('Last 3 months', 'last90'),
            SizedBox(width: 2.w),
            _buildCustomChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = selectedDateRange == value;
    return GestureDetector(
      onTap: () => _onChipSelect(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomChip() {
    final theme = Theme.of(context);
    final isSelected = selectedDateRange == 'custom';
    final displayText = isSelected && customDateRange != null 
        ? '${customDateRange!['start']!.day}/${customDateRange!['start']!.month} - ${customDateRange!['end']!.day}/${customDateRange!['end']!.month}'
        : 'Custom…';
    
    return GestureDetector(
      onTap: _onCustomChipSelect,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                color: color,
                size: 6.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.w),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
          ],
        ),
      ),
    );
  }

  void _onChipSelect(String value) {
    setState(() {
      selectedDateRange = value;
      customDateRange = null;
    });
  }

  void _onCustomChipSelect() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: customDateRange != null 
          ? DateTimeRange(
              start: customDateRange!['start']!,
              end: customDateRange!['end']!,
            )
          : null,
    );
    
    if (picked != null) {
      setState(() {
        selectedDateRange = 'custom';
        customDateRange = {
          'start': picked.start,
          'end': picked.end,
        };
      });
    }
  }

  void _openSection(String section) {
    if (section == 'overview') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OverviewKpisScreen(
            selectedDateRange: selectedDateRange,
            customDateRange: customDateRange,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AnalyticsRedesignScaffold(
            initialSection: section,
            selectedDateRange: selectedDateRange,
            customDateRange: customDateRange,
          ),
        ),
      );
    }
  }
}