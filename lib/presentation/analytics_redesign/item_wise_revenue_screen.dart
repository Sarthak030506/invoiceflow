import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ItemWiseRevenueScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String dateRange;

  const ItemWiseRevenueScreen({
    Key? key,
    required this.items,
    required this.dateRange,
  }) : super(key: key);

  @override
  State<ItemWiseRevenueScreen> createState() => _ItemWiseRevenueScreenState();
}

class _ItemWiseRevenueScreenState extends State<ItemWiseRevenueScreen> {
  String _sortBy = 'revenue'; // revenue, quantity, name
  bool _sortAscending = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> get _sortedItems {
    var items = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final itemName = (item['itemName'] as String? ?? '').toLowerCase();
      return itemName.contains(_searchQuery.toLowerCase());
    }).toList();

    items.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'revenue':
          comparison = ((a['revenue'] as double?) ?? 0.0)
              .compareTo((b['revenue'] as double?) ?? 0.0);
          break;
        case 'quantity':
          comparison = ((a['quantitySold'] as int?) ?? 0)
              .compareTo((b['quantitySold'] as int?) ?? 0);
          break;
        case 'name':
          comparison = (a['itemName'] as String? ?? '')
              .compareTo(b['itemName'] as String? ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return items;
  }

  double get _totalRevenue {
    return _sortedItems.fold(0.0, (sum, item) => sum + ((item['revenue'] as double?) ?? 0.0));
  }

  int get _totalQuantity {
    return _sortedItems.fold(0, (sum, item) => sum + ((item['quantitySold'] as int?) ?? 0));
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = _sortedItems;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item-wise Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.dateRange,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = false;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'revenue',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'revenue'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Revenue'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'quantity'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Quantity'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Name'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(4.w),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Summary cards
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Revenue',
                    _formatCurrency(_totalRevenue),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Items',
                    sortedItems.length.toString(),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Qty',
                    _totalQuantity.toString(),
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: sortedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No items found'
                              : 'No items match your search',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: sortedItems.length,
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      return _buildItemCard(item, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int rank) {
    final itemName = item['itemName'] as String? ?? 'Unknown';
    final revenue = (item['revenue'] as double?) ?? 0.0;
    final quantity = (item['quantitySold'] as int?) ?? 0;
    final avgPrice = quantity > 0 ? revenue / quantity : 0.0;
    
    print('ItemCard - $itemName: Revenue=$revenue, Qty=$quantity, AvgPrice=$avgPrice');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.amber.withOpacity(0.2) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: rank <= 3 ? Colors.amber.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Revenue',
                    _formatCurrency(revenue),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Quantity',
                    quantity.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Price',
                    avgPrice > 0 ? _formatCurrency(avgPrice) : '₹0.00',
                    Icons.price_check,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
