import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/date_range_selector.dart';

class RevenueDetailModal extends StatefulWidget {
  final DateRange selectedRange;
  final int? customDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const RevenueDetailModal({
    Key? key,
    required this.selectedRange,
    this.customDays,
    this.customStartDate,
    this.customEndDate,
  }) : super(key: key);

  @override
  State<RevenueDetailModal> createState() => _RevenueDetailModalState();
}

class _RevenueDetailModalState extends State<RevenueDetailModal> {
  late DateRange _selectedRange;
  int? _customDays;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.selectedRange;
    _customDays = widget.customDays;
    _customStartDate = widget.customStartDate;
    _customEndDate = widget.customEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Details',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          DateRangeSelector(
            selectedRange: _selectedRange,
            customDays: _customDays,
            customStartDate: _customStartDate,
            customEndDate: _customEndDate,
            onRangeChanged: (range, {int? days, DateTime? start, DateTime? end}) {
              setState(() {
                _selectedRange = range;
                _customDays = days;
                _customStartDate = start;
                _customEndDate = end;
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueChart(),
                  SizedBox(height: 4.h),
                  _buildItemwiseBreakdown(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 12.w, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'Revenue Over Time Chart',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Chart implementation goes here',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemwiseBreakdown() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item-wise Breakdown',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              itemCount: _getItemBreakdown().length,
              itemBuilder: (context, index) {
                final item = _getItemBreakdown()[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 2.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${item['quantity']} units sold',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${item['revenue']}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getItemBreakdown() {
    return [
      {'name': 'Paper bag', 'quantity': 45, 'revenue': '4,050'},
      {'name': 'Garbage bag big', 'quantity': 23, 'revenue': '2,530'},
      {'name': 'White phenyl', 'quantity': 12, 'revenue': '2,160'},
      {'name': 'Glass cleaner', 'quantity': 8, 'revenue': '1,760'},
      {'name': 'Tissue box', 'quantity': 5, 'revenue': '2,550'},
    ];
  }
}