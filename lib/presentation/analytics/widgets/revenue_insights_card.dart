import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../modals/itemwise_revenue_modal.dart';
import '../modals/category_revenue_modal.dart';
import '../modals/top_items_modal.dart';
import 'animated_counter.dart';
import 'insights_badge.dart';
import 'date_range_selector.dart';

class RevenueInsightsCard extends StatelessWidget {
  final DateRange selectedRange;
  final int? customDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const RevenueInsightsCard({
    Key? key,
    required this.selectedRange,
    this.customDays,
    this.customStartDate,
    this.customEndDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.insights, color: Colors.blue.shade700, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  "Today's Revenue at a Glance",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              InsightsBadge(
                text: 'Peak Day!',
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedCounter(
                      value: '₹8,450',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Total Revenue Today',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    SizedBox(height: 3.w),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.w,
                      children: [
                        _buildChip('Itemwise', Icons.bar_chart, () => _showItemwiseRevenue(context)),
                        _buildChip('Category', Icons.category, () => _showCategoryRevenue(context)),
                        _buildChip('Top Items', Icons.trending_up, () => _showTopItems(context)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart, size: 40, color: Colors.blue.shade400),
                      SizedBox(height: 1.w),
                      Text(
                        'Revenue\nDistribution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemwiseRevenue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemwiseRevenueModal(
        selectedRange: selectedRange,
        customDays: customDays,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      ),
    );
  }

  void _showCategoryRevenue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryRevenueModal(),
    );
  }

  void _showTopItems(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopItemsModal(),
    );
  }
}

