import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final DateTimeRange? selectedDateRange;
  final RangeValues revenueRange;
  final String? selectedInvoiceType;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged<RangeValues> onRevenueRangeChanged;
  final ValueChanged<String?> onInvoiceTypeChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterBottomSheetWidget({
    Key? key,
    required this.selectedDateRange,
    required this.revenueRange,
    this.selectedInvoiceType,
    required this.onDateRangeChanged,
    required this.onRevenueRangeChanged,
    required this.onInvoiceTypeChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late DateTimeRange? _tempDateRange;
  late RangeValues _tempRevenueRange;
  String? _tempInvoiceType;

  @override
  void initState() {
    super.initState();
    _tempDateRange = widget.selectedDateRange;
    _tempRevenueRange = widget.revenueRange;
    _tempInvoiceType = widget.selectedInvoiceType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeSection(),
                  SizedBox(height: 3.h),
                  _buildInvoiceTypeSection(),
                  SizedBox(height: 3.h),
                  _buildRevenueRangeSection(),
                  SizedBox(height: 4.h),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter Invoices',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: _selectDateRange,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tempDateRange == null
                      ? 'Select date range'
                      : '${_formatDate(_tempDateRange!.start)} - ${_formatDate(_tempDateRange!.end)}',
                  style: _tempDateRange == null
                      ? AppTheme.lightTheme.inputDecorationTheme.hintStyle
                      : AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_tempDateRange != null) ...[
          SizedBox(height: 1.h),
          TextButton(
            onPressed: () {
              setState(() {
                _tempDateRange = null;
              });
            },
            child: const Text('Clear date range'),
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice Type',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildInvoiceTypeOption('All', null),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildInvoiceTypeOption('Sales', 'sales'),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildInvoiceTypeOption('Purchase', 'purchase'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTypeOption(String label, String? value) {
    final isSelected = _tempInvoiceType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _tempInvoiceType = value;
        });
        widget.onInvoiceTypeChanged(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.lightTheme.colorScheme.primary : AppTheme.lightTheme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.lightTheme.colorScheme.primary : AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Range',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${_tempRevenueRange.start.toInt()}',
              style: AppTheme.financialDataStyle(isLight: true, fontSize: 14),
            ),
            Text(
              '₹${_tempRevenueRange.end.toInt()}',
              style: AppTheme.financialDataStyle(isLight: true, fontSize: 14),
            ),
          ],
        ),
        RangeSlider(
          values: _tempRevenueRange,
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '₹${_tempRevenueRange.start.toInt()}',
            '₹${_tempRevenueRange.end.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _tempRevenueRange = values;
            });
          },
          activeColor: AppTheme.lightTheme.colorScheme.primary,
          inactiveColor: AppTheme.lightTheme.colorScheme.outline,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _tempDateRange = null;
                _tempRevenueRange = const RangeValues(0, 10000);
                _tempInvoiceType = null;
              });
              widget.onDateRangeChanged(_tempDateRange);
              widget.onRevenueRangeChanged(_tempRevenueRange);
              widget.onInvoiceTypeChanged(_tempInvoiceType);
              widget.onClearFilters();
            },
            child: const Text('Clear All'),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onDateRangeChanged(_tempDateRange);
              widget.onRevenueRangeChanged(_tempRevenueRange);
              widget.onInvoiceTypeChanged(_tempInvoiceType);
              widget.onApplyFilters();
            },
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _tempDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tempDateRange = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}