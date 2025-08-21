import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../modals/total_skus_modal.dart';
import '../modals/inventory_value_modal.dart';
import '../modals/low_stock_modal.dart';
import '../modals/stock_duration_modal.dart';
import '../modals/stock_category_modal.dart';

class InventoryAnalyticsSection extends StatelessWidget {
  const InventoryAnalyticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          child: Text(
            'Inventory Analytics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 3.w,
            childAspectRatio: 1.3,
            children: [
              _buildInventoryCard(
                context,
                'Total SKUs',
                '133',
                'Active items',
                Icons.inventory_2,
                Colors.blue,
                () => _showTotalSKUs(context),
              ),
              _buildInventoryCard(
                context,
                'Inventory Value',
                '₹1,24,500',
                'Current worth',
                Icons.account_balance_wallet,
                Colors.green,
                () => _showInventoryValue(context),
              ),
              _buildInventoryCard(
                context,
                'Low-Stock Items',
                '8',
                'Need reorder',
                Icons.warning,
                Colors.red,
                () => _showLowStock(context),
              ),
              _buildInventoryCard(
                context,
                'Avg Stock Duration',
                '28 Days',
                'Stock turnover',
                Icons.schedule,
                Colors.orange,
                () => _showStockDuration(context),
              ),
              _buildInventoryCard(
                context,
                'Stock by Category',
                '6 Categories',
                'Distribution',
                Icons.category,
                Colors.purple,
                () => _showStockCategory(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
              ],
            ),
            SizedBox(height: 2.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 1.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTotalSKUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TotalSKUsModal(),
    );
  }

  void _showInventoryValue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InventoryValueModal(),
    );
  }

  void _showLowStock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LowStockModal(),
    );
  }

  void _showStockDuration(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StockDurationModal(),
    );
  }

  void _showStockCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StockCategoryModal(),
    );
  }
}