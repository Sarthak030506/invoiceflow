import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class AnalyticsChartsWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> insights;

  const AnalyticsChartsWidget({
    Key? key,
    required this.data,
    required this.insights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesVsPurchasesChart(context),
          SizedBox(height: 4.h),
          _buildRevenueTrendChart(context),
          SizedBox(height: 4.h),
          _buildTopSellingItemsChart(context),
          SizedBox(height: 4.h),
          _buildOutstandingPaymentsChart(context),
        ],
      ),
    );
  }

  Widget _buildSalesVsPurchasesChart(BuildContext context) {
    final salesVsPurchases = data['salesVsPurchases'] as Map<String, dynamic>? ?? {};
    final sales = (salesVsPurchases['sales'] as double?) ?? 0.0;
    final purchases = (salesVsPurchases['purchases'] as double?) ?? 0.0;

    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales vs Purchases',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Revenue comparison between sales and purchase invoices',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 30.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (sales > purchases ? sales : purchases) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text('Sales');
                            case 1:
                              return Text('Purchases');
                            default:
                              return Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: sales,
                          color: Colors.blue,
                          width: 20.w,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: purchases,
                          color: Colors.green,
                          width: 20.w,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTrendChart(BuildContext context) {
    final revenueTrend = data['revenueTrend'] as List<dynamic>? ?? [];
    final maxRevenue = revenueTrend.isEmpty ? 1000.0 : revenueTrend.map((e) => (e['revenue'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Daily revenue performance for the selected period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 30.h,
              child: revenueTrend.isEmpty
                  ? Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: revenueTrend.length * 15.w,
                        child: BarChart(
                      BarChartData(
                        maxY: maxRevenue * 1.2,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxRevenue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 12.w,
                              getTitlesWidget: (value, meta) {
                                if (value >= 1000) {
                                  return Text('₹${(value / 1000).toStringAsFixed(0)}k',
                                      style: TextStyle(fontSize: 10.sp));
                                }
                                return Text('₹${value.toInt()}',
                                    style: TextStyle(fontSize: 10.sp));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < revenueTrend.length) {
                                  final dateStr = revenueTrend[index]['date'] as String;
                                  final date = DateTime.parse(dateStr);
                                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  return Text(dayNames[date.weekday - 1],
                                      style: TextStyle(fontSize: 10.sp));
                                }
                                return Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Theme.of(context).colorScheme.primary,
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final revenue = rod.toY;
                              return BarTooltipItem(
                                '₹${revenue.toStringAsFixed(0)}',
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        barGroups: revenueTrend.asMap().entries.map((entry) {
                          final index = entry.key;
                          final revenue = (entry.value['revenue'] as double?) ?? 0.0;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: revenue,
                                color: Theme.of(context).colorScheme.primary,
                                width: 4.w,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSellingItemsChart(BuildContext context) {
    final topItems = data['topSellingItems'] as List<dynamic>? ?? [];
    final maxRevenue = topItems.isEmpty ? 1000.0 : topItems.map((e) => (e['revenue'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Selling Items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Best performing products by revenue generation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 35.h,
              child: topItems.isEmpty
                  ? Center(child: Text('No data available'))
                  : ListView.builder(
                      itemCount: topItems.length > 5 ? 5 : topItems.length,
                      itemBuilder: (context, index) {
                        final item = topItems[index] as Map<String, dynamic>;
                        final itemName = (item['itemName'] as String?) ?? 'Unknown';
                        final revenue = (item['revenue'] as double?) ?? 0.0;
                        final barWidth = (revenue / maxRevenue) * 60.w;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item name
                              Text(
                                itemName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              // Bar with revenue
                              Row(
                                children: [
                                  Container(
                                    height: 4.h,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    '₹${revenue.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingPaymentsChart(BuildContext context) {
    final outstandingPayments = data['outstandingPayments'] as Map<String, dynamic>? ?? {};
    final paid = (outstandingPayments['paid'] as double?) ?? 0.0;
    final remaining = (outstandingPayments['remaining'] as double?) ?? 0.0;
    final total = paid + remaining;
    final paidPercentage = total > 0 ? (paid / total * 100) : 0.0;
    final remainingPercentage = total > 0 ? (remaining / total * 100) : 0.0;

    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Payments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Payment collection status for sales invoices',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 3.h),
            SizedBox(
              height: 35.h,
              child: total == 0
                  ? Center(child: Text('No payment data available'))
                  : Row(
                      children: [
                        // Donut Chart with Center Text
                        Expanded(
                          flex: 3,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 12.w,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.green.shade600,
                                      value: paid,
                                      title: '${paidPercentage.toStringAsFixed(0)}%',
                                      radius: 8.w,
                                      titleStyle: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: Colors.red.shade400,
                                      value: remaining,
                                      title: '${remainingPercentage.toStringAsFixed(0)}%',
                                      radius: 8.w,
                                      titleStyle: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Center Text
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${remaining.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Pending',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Legend and Stats
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Total Amount
                              Text(
                                'Total: ₹${total.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              // Collected
                              Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 4.w,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Collected',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '₹${paid.toStringAsFixed(0)} (${paidPercentage.toStringAsFixed(1)}%)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.5.h),
                              // Pending
                              Row(
                                children: [
                                  Container(
                                    width: 4.w,
                                    height: 4.w,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pending',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '₹${remaining.toStringAsFixed(0)} (${remainingPercentage.toStringAsFixed(1)}%)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.red.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 2.h),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Collected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                SizedBox(width: 6.w),
                Row(
                  children: [
                    Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Pending',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}