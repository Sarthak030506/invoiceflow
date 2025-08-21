import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class DateRangePickerWidget extends StatelessWidget {
  final String selectedRange;
  final Function(String) onRangeChanged;

  const DateRangePickerWidget({
    Key? key,
    required this.selectedRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateRanges = [
      'Last 7 days',
      'Last 30 days',
      'Last 3 months',
      'Last 6 months',
      'Last year',
      'All time',
    ];

    return Container(
      height: 5.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dateRanges.length,
        itemBuilder: (context, index) {
          final range = dateRanges[index];
          final isSelected = selectedRange == range;

          return Container(
            margin: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              selected: isSelected,
              label: Text(range),
              onSelected: (selected) {
                if (selected) {
                  onRangeChanged(range);
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected ? theme.colorScheme.primary : theme.dividerColor,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
