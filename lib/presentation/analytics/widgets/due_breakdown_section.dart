import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../modals/customers_dues_modal.dart';
import '../modals/itemwise_outstanding_modal.dart';
import '../modals/due_by_area_modal.dart';
import '../modals/aging_analysis_modal.dart';

class DueBreakdownSection extends StatelessWidget {
  const DueBreakdownSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.red.shade700, size: 24),
              SizedBox(width: 2.w),
              Text(
                'Outstanding Dues — Where is Your Money?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 3.w,
            childAspectRatio: 1.1,
            children: [
              _buildDueCard(
                context,
                'Customers With Dues',
                '₹45,200',
                '12 customers',
                Icons.people,
                Colors.red,
                () => _showCustomersDues(context),
              ),
              _buildDueCard(
                context,
                'Itemwise Outstanding',
                '₹28,500',
                'By product breakdown',
                Icons.inventory,
                Colors.orange,
                () => _showItemwiseOutstanding(context),
              ),
              _buildDueCard(
                context,
                'Due by Area',
                '₹18,300',
                '5 markets/areas',
                Icons.location_on,
                Colors.purple,
                () => _showDueByArea(context),
              ),
              _buildDueCard(
                context,
                'Aging Analysis',
                '₹73,700',
                'Overdue breakdown',
                Icons.schedule,
                Colors.blue,
                () => _showAgingAnalysis(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueCard(
    BuildContext context,
    String title,
    String amount,
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
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
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
              amount,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 1.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomersDues(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomersDuesModal(),
    );
  }

  void _showItemwiseOutstanding(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ItemwiseOutstandingModal(),
    );
  }

  void _showDueByArea(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DueByAreaModal(),
    );
  }

  void _showAgingAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AgingAnalysisModal(),
    );
  }
}