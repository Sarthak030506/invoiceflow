import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'widgets/date_range_selector.dart';
import 'widgets/analytics_card_grid.dart';
import 'widgets/revenue_insights_card.dart';
import 'widgets/inventory_analytics_section.dart';
import 'widgets/due_breakdown_section.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateRange _selectedRange = DateRange.last7Days;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _customDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: DateRangeSelector(
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
          ),
          RevenueInsightsCard(
            selectedRange: _selectedRange,
            customDays: _customDays,
            customStartDate: _customStartDate,
            customEndDate: _customEndDate,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AnalyticsCardGrid(
                    selectedRange: _selectedRange,
                    customDays: _customDays,
                    customStartDate: _customStartDate,
                    customEndDate: _customEndDate,
                  ),
                  const InventoryAnalyticsSection(),
                  const DueBreakdownSection(),
                  SizedBox(height: 8.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}