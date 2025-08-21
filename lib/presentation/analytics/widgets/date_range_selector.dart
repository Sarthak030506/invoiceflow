import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

enum DateRange { last7Days, last30Days, last3Months, customDays, customRange }

class DateRangeSelector extends StatelessWidget {
  final DateRange selectedRange;
  final int? customDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Function(DateRange, {int? days, DateTime? start, DateTime? end}) onRangeChanged;

  const DateRangeSelector({
    Key? key,
    required this.selectedRange,
    this.customDays,
    this.customStartDate,
    this.customEndDate,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('Last 7 Days', DateRange.last7Days),
            SizedBox(width: 2.w),
            _buildChip('Last 30 Days', DateRange.last30Days),
            SizedBox(width: 2.w),
            _buildChip('Last 3 Months', DateRange.last3Months),
            SizedBox(width: 2.w),
            _buildCustomDaysChip(),
            SizedBox(width: 2.w),
            _buildDateRangeChip(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, DateRange range) {
    final isSelected = selectedRange == range;
    return GestureDetector(
      onTap: () => onRangeChanged(range),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDaysChip() {
    final isSelected = selectedRange == DateRange.customDays;
    final displayText = isSelected && customDays != null ? 'Last $customDays Days' : 'Last ... Days';
    
    return GestureDetector(
      onTap: () => _showCustomDaysDialog(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 1.w),
            Icon(
              Icons.edit,
              size: 4.w,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeChip(BuildContext context) {
    final isSelected = selectedRange == DateRange.customRange;
    String displayText = 'Custom Range';
    
    if (isSelected && customStartDate != null && customEndDate != null) {
      final start = '${customStartDate!.day}/${customStartDate!.month}';
      final end = '${customEndDate!.day}/${customEndDate!.month}';
      displayText = '$start - $end';
    }
    
    return GestureDetector(
      onTap: () => _showDateRangePicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayText,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 1.w),
            Icon(
              Icons.calendar_today,
              size: 4.w,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDaysDialog() {
    // Implementation for custom days picker
  }

  void _showDateRangePicker(BuildContext context) {
    // Implementation for date range picker
  }
}