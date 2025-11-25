import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmbeddedItemWiseRevenue extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String dateRange;

  const EmbeddedItemWiseRevenue({
    Key? key,
    required this.items,
    required this.dateRange,
  }) : super(key: key);

  @override
  State<EmbeddedItemWiseRevenue> createState() => _EmbeddedItemWiseRevenueState();
}

class _EmbeddedItemWiseRevenueState extends State<EmbeddedItemWiseRevenue> {
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
    final sortedItems = _sortedItems;

    return Column(
      children: [
        // Controls Row (Search + Sort)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.sort, size: 24),
                ),
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
        ),

        // Summary cards
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
        sortedItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No items found'
                            : 'No items match your search',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  return _buildItemCard(item, index + 1);
                },
              ),
      ],
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.amber.withOpacity(0.2) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 12,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
