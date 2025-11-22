import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';

class ItemsInsightsSection extends StatelessWidget { // Stateless as it doesn't seem to have internal state
  final bool isLoading;
  final Map<String, dynamic> performanceInsights;

  const ItemsInsightsSection({
    Key? key,
    required this.isLoading,
    required this.performanceInsights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('itemsInsightsSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items & Sales Insights',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          isLoading
              ? Column(
                  children: [
                    SkeletonLoader.kpiCard(icon: Icons.receipt_long, color: Colors.blue),
                    SizedBox(height: 12),
                    SkeletonLoader.kpiCard(icon: Icons.star, color: Colors.orange),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.kpiCard(icon: Icons.people, color: Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: SkeletonLoader.kpiCard(icon: Icons.category, color: Colors.teal)),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonLoader.kpiCard(icon: Icons.trending_up, color: Colors.green),
                  ],
                )
              : Column(
                  children: [
                    _buildInvoiceMixCard(),
                    SizedBox(height: 12),
                    _buildBestSellingItemsCard(context),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildCustomersCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoriesCard()),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildTrendsCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildInvoiceMixCard() {
    final invoiceBreakdown = _getInvoiceTypeBreakdown();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Invoice Mix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Count comparison
          Row(
            children: [
              Expanded(
                child: _buildMiniBar(
                  'Sales',
                  invoiceBreakdown['salesCount'] ?? 0,
                  Colors.blue,
                  (invoiceBreakdown['salesCount'] ?? 0) + (invoiceBreakdown['purchaseCount'] ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniBar(
                  'Purchase',
                  invoiceBreakdown['purchaseCount'] ?? 0,
                  Colors.green,
                  (invoiceBreakdown['salesCount'] ?? 0) + (invoiceBreakdown['purchaseCount'] ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Revenue comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Revenue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatCurrency(invoiceBreakdown['salesRevenue'] ?? 0.0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatCurrency(invoiceBreakdown['purchaseRevenue'] ?? 0.0),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellingItemsCard(BuildContext context) {
    final topItems = _getBestSellingItems();

    return GestureDetector(
      onTap: () => _showBestSellingItemsModal(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Best-Selling Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topItems.take(5).toList().asMap().entries.map(
              (entry) => _buildRankedItem(entry.key + 1, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersCard() {
    final insights = _getInsights();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.purple, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Customers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insights['totalClients']?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            'Total Clients',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    final insights = _getInsights();
    final categoryPerformance = _getCategoryPerformance();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            insights['totalCategories']?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            'Total Categories',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryPerformance.take(2).map(
            (category) => _buildCategoryItem(category),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard() {
    final trends = _getTrends();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.orange, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Trends',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTrendTile(
            'Revenue Change',
            trends['revenueChange'] ?? 0.0,
            '30-day comparison',
          ),
          const SizedBox(height: 12),
          _buildTrendTile(
            'Items Sold Change',
            trends['itemsSoldChange'] ?? 0.0,
            'vs previous period',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar(String label, int value, Color color, int total) {
    // Zero division protection
    final percentage = (total > 0 && value >= 0) ? (value / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 4,
              width: (percentage * 100).clamp(0.0, 100.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankedItem(int rank, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['itemName'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatCurrency((item['revenue'] as double?) ?? 0.0),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category.keys.first;
    final data = category[name] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '₹${((data['totalRevenue'] as double?) ?? 0.0 / 1000).toStringAsFixed(0)}K',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendTile(String title, double value, String subtitle) {
    final isPositive = value >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ],
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // Data extraction methods
  Map<String, dynamic> _getInvoiceTypeBreakdown() {
    final breakdown = performanceInsights['invoiceTypeBreakdown'] as Map<String, dynamic>? ?? {};
    return {
      'salesCount': breakdown['salesCount'] ?? 0,
      'purchaseCount': breakdown['purchaseCount'] ?? 0,
      'salesRevenue': breakdown['salesRevenue'] ?? 0.0,
      'purchaseRevenue': breakdown['purchaseRevenue'] ?? 0.0,
    };
  }

  List<Map<String, dynamic>> _getBestSellingItems() {
    final items = performanceInsights['topRevenueItems'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _getInsights() {
    final insights = performanceInsights['insights'] as Map<String, dynamic>? ?? {};
    return {
      'totalClients': insights['totalClients'] ?? 0,
      'totalCategories': insights['totalCategories'] ?? 0,
    };
  }

  List<Map<String, dynamic>> _getCategoryPerformance() {
    final categoryPerformance = performanceInsights['categoryPerformance'] as Map<String, dynamic>? ?? {};
    return categoryPerformance.entries.map((e) => {e.key: e.value}).toList();
  }

  Map<String, dynamic> _getTrends() {
    final trends = performanceInsights['trends'] as Map<String, dynamic>? ?? {};
    return {
      'revenueChange': trends['revenueChange'] ?? 0.0,
      'itemsSoldChange': trends['itemsSoldChange'] ?? 0.0,
    };
  }

  void _showBestSellingItemsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Best-Selling Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _getBestSellingItems().length,
                itemBuilder: (context, index) {
                  final item = _getBestSellingItems()[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Qty: ${item['quantitySold'] ?? 0} units',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency((item['revenue'] as double?) ?? 0.0),
                          style: const TextStyle(
                            fontSize: 16,
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
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
