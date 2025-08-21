import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'date_range_selector.dart';
import 'apple_card.dart';
import '../modals/revenue_detail_modal.dart';
import '../modals/itemwise_revenue_modal.dart';
import '../modals/inventory_age_modal.dart';
import '../modals/invoices_list_modal.dart';

class AnalyticsCardGrid extends StatelessWidget {
  final DateRange selectedRange;
  final int? customDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const AnalyticsCardGrid({
    Key? key,
    required this.selectedRange,
    this.customDays,
    this.customStartDate,
    this.customEndDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 4.w,
          mainAxisSpacing: 4.w,
          childAspectRatio: 1.2,
        ),
        itemCount: _getAnalyticsCards(context).length,
        itemBuilder: (context, index) {
          final cardData = _getAnalyticsCards(context)[index];
          return AppleCard(
            title: cardData['title'],
            value: cardData['value'],
            subtitle: cardData['subtitle'],
            icon: cardData['icon'],
            color: cardData['color'],
            trend: cardData['trend'],
            onTap: cardData['onTap'],
            insightText: cardData['insightText'],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getAnalyticsCards(BuildContext context) {
    return [
      {
        'title': 'Analytics Table',
        'value': 'View All',
        'subtitle': 'Complete analytics overview',
        'icon': Icons.table_chart,
        'color': Colors.blue,
        'trend': null,
        'onTap': () => _showAnalyticsTable(context),
      },
      {
        'title': "Today's Revenue",
        'value': '₹8,450',
        'subtitle': '+15.2% vs yesterday',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'trend': 15.2,
        'onTap': () => _showRevenueDetail(context),
        'insightText': 'Best Day!',
      },
      {
        'title': 'Item-wise Revenue',
        'value': '45 Items',
        'subtitle': 'Revenue breakdown by items',
        'icon': Icons.bar_chart,
        'color': Colors.orange,
        'trend': null,
        'onTap': () => _showItemwiseRevenue(context),
        'insightText': 'Top Revenue Item!',
      },
      {
        'title': 'Total Orders',
        'value': '23',
        'subtitle': '+3 new orders today',
        'icon': Icons.receipt_long,
        'color': Colors.purple,
        'trend': 8.5,
        'onTap': () {},
      },
      {
        'title': 'Low Stock Items',
        'value': '8',
        'subtitle': 'Need reorder',
        'icon': Icons.warning,
        'color': Colors.red,
        'trend': null,
        'onTap': () {},
        'insightText': 'Action Needed',
      },
      {
        'title': 'Inventory Value',
        'value': '₹1,24,500',
        'subtitle': 'Current stock worth',
        'icon': Icons.inventory,
        'color': Colors.teal,
        'trend': 2.1,
        'onTap': () {},
      },
      {
        'title': 'Inventory Age',
        'value': 'Unsold Item—45 Days',
        'subtitle': 'Oldest item in inventory',
        'icon': Icons.hourglass_empty,
        'color': Colors.amber,
        'trend': null,
        'onTap': () => _showInventoryAge(context),
        'insightText': null,
      },
      {
        'title': 'Sales Invoices',
        'value': '156',
        'subtitle': '23 this week',
        'icon': Icons.receipt,
        'color': Colors.blue,
        'trend': 8.2,
        'onTap': () => _showInvoicesList(context, 'sales'),
        'insightText': null,
      },
      {
        'title': 'Purchase Invoices',
        'value': '89',
        'subtitle': '12 this week',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'trend': 5.1,
        'onTap': () => _showInvoicesList(context, 'purchase'),
        'insightText': null,
      },
      {
        'title': 'Total Items',
        'value': '133',
        'subtitle': 'Items in catalog',
        'icon': Icons.inventory_2,
        'color': Colors.indigo,
        'trend': null,
        'onTap': () => _showItemCatalog(context),
        'insightText': null,
      },
    ];
  }
  
  void _showAnalyticsTable(BuildContext context) {
    // Navigate to existing analytics table implementation
    Navigator.pushNamed(context, '/analytics-table');
  }
  
  void _showRevenueDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RevenueDetailModal(
        selectedRange: selectedRange,
        customDays: customDays,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
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
  
  void _showInventoryAge(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventoryAgeModal(),
    );
  }
  
  void _showInvoicesList(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InvoicesListModal(invoiceType: type),
    );
  }
  
  void _showItemCatalog(BuildContext context) {
    Navigator.pushNamed(context, '/item-catalog');
  }
}