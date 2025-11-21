import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/skeleton_loader.dart';
import '../../../services/inventory_service.dart';
import '../../../services/firestore_service.dart';

class InventoryAnalyticsSection extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic> inventoryAnalytics;

  const InventoryAnalyticsSection({
    Key? key,
    required this.isLoading,
    required this.inventoryAnalytics,
  }) : super(key: key);

  @override
  State<InventoryAnalyticsSection> createState() => _InventoryAnalyticsSectionState();
}

class _InventoryAnalyticsSectionState extends State<InventoryAnalyticsSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inventorySection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Analytics',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          widget.isLoading
              ? Column(
                  children: [
                    SkeletonLoader.inventoryCard(),
                    SizedBox(height: 16),
                    SkeletonLoader.kpiCard(icon: Icons.inventory, color: Colors.indigo),
                    SizedBox(height: 16),
                    SkeletonLoader.kpiCard(icon: Icons.shopping_bag, color: Colors.purple),
                  ],
                )
              : Column(
                  children: [
                    _buildInventorySummaryCard(),
                    SizedBox(height: 16),
                    _buildMovementHealthCard(),
                    SizedBox(height: 16),
                    _buildHoldingCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryCard() {
    final totalItems = widget.inventoryAnalytics['totalItems'] ?? 0;
    final inventoryValue = widget.inventoryAnalytics['totalValue'] ?? 0.0;
    final lowStockCount = widget.inventoryAnalytics['lowStockCount'] ?? 0;
    final avgStockValue = widget.inventoryAnalytics['averageStockValue'] ?? 0.0;

    return Container(
      width: double.infinity,
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
              Icon(Icons.inventory_2, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Inventory Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildVerticalMetric('Total Items', totalItems.toString()),
          const SizedBox(height: 16),
          _buildVerticalMetric('Inventory Value', _formatCurrency(inventoryValue)),
          const SizedBox(height: 16),
          _buildLowStockMetric('Low-Stock Items', lowStockCount),
          const SizedBox(height: 16),
          _buildVerticalMetric('Avg/Item', 'â‚¹${avgStockValue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildMovementHealthCard() {
    return Container(
      width: double.infinity,
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
              Icon(Icons.trending_up, color: Colors.green[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Movement Health',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showMovementHealthModal,
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFastMovingItems(),
            builder: (context, snapshot) {
              final fastMoving = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.north_east, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fast Moving (${fastMoving.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...fastMoving.take(3).map((item) => _buildMovementItem(
                    item['name'] ?? 'Unknown',
                    '${item['saleCount']}x sold',
                    Colors.green[600]!,
                    () => _navigateToInventoryDetail(item),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getSlowMovingItems(),
            builder: (context, snapshot) {
              final slowMoving = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Slow Moving (${slowMoving.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...slowMoving.take(3).map((item) => _buildMovementItem(
                    item['name'] ?? 'Unknown',
                    '${item['daysInStock']}d old',
                    Colors.orange[600]!,
                    () => _navigateToInventoryDetail(item),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getUnsoldItems(),
      builder: (context, snapshot) {
        final unsoldItems = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return GestureDetector(
          onTap: () => _showUnsoldItemsModal(),
          child: Container(
            key: const Key('holdingCard'),
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
                    Icon(Icons.schedule, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Inventory Timeholding â€” Unsold Items Only',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isLoading ? 'Loading...' : '${unsoldItems.length} items',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: unsoldItems.isEmpty ? Colors.green : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? 'Checking inventory...' :
                  (unsoldItems.isEmpty ? 'All items moving well' : 'Currently unsold'),
                  style: TextStyle(
                    fontSize: 14,
                    color: unsoldItems.isEmpty ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
                if (!isLoading && unsoldItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...unsoldItems.take(3).map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            item['ageLabel'] ?? '${item['daysInStock']}d',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (unsoldItems.length > 3) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${unsoldItems.length - 3} more items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ] else if (!isLoading && unsoldItems.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Great! No stagnant inventory',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockMetric(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: count > 0 ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMovementItem(String name, String rate, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              rate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovementHealthModal() async {
    final fastMoving = await _getFastMovingItems();
    final slowMoving = await _getSlowMovingItems();

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
        child: DefaultTabController(
          length: 2,
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
                    const Expanded(
                      child: Text(
                        'Movement Health Analysis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.green,
                tabs: [
                  Tab(text: 'Fast Moving (${fastMoving.length})'),
                  Tab(text: 'Slow Moving (${slowMoving.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMovementList(fastMoving, true),
                    _buildMovementList(slowMoving, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementList(List<Map<String, dynamic>> items, bool isFastMoving) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = isFastMoving ? Colors.green : Colors.orange;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (isFastMoving) ...[
                Text(
                  'Sales: ${item['saleCount']} times (${item['totalSold']} units)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  'Turnover: ${item['turnoverRate'].toStringAsFixed(1)}x per week',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
                ),
              ] else ...[
                Text(
                  'Stock: ${item['currentStock']} units â€¢ Sales: ${item['totalSold']} units',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  item['lastSoldDate'] != null
                      ? 'Last sold: ${item['daysInStock']} days ago'
                      : 'Never sold in last 30 days',
                  style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFastMovingItems() async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      final inventoryService = InventoryService();
      final allItems = await inventoryService.getAllItems(); // This might be expensive if called repeatedly

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      Map<String, Map<String, dynamic>> itemSales = {};

      for (final invoice in allInvoices) {
        if (invoice.invoiceType == 'sales' &&
            invoice.date.isAfter(thirtyDaysAgo) &&
            invoice.status != 'cancelled') {

          for (final item in invoice.items) {
            final itemName = item.name;
            if (!itemSales.containsKey(itemName)) {
              itemSales[itemName] = {
                'totalSold': 0,
                'saleCount': 0,
                'lastSoldDate': invoice.date,
              };
            }

            itemSales[itemName]!['totalSold'] += item.quantity;
            itemSales[itemName]!['saleCount'] += 1;

            if (invoice.date.isAfter(itemSales[itemName]!['lastSoldDate'])) {
              itemSales[itemName]!['lastSoldDate'] = invoice.date;
            }
          }
        }
      }

      List<Map<String, dynamic>> fastMoving = [];

      for (final entry in itemSales.entries) {
        final itemName = entry.key;
        final salesData = entry.value;
        final saleCount = salesData['saleCount'] as int;
        final totalSold = salesData['totalSold'] as int;

        if (saleCount >= 2 || totalSold >= 10) {
          final turnoverRate = (saleCount / 4.3).toDouble();

          fastMoving.add({
            'name': itemName,
            'turnoverRate': turnoverRate,
            'saleCount': saleCount,
            'totalSold': totalSold,
            'lastSoldDate': salesData['lastSoldDate'],
            'id': itemName.toLowerCase().replaceAll(' ', '_'),
          });
        }
      }

      fastMoving.sort((a, b) => (b['turnoverRate'] as double).compareTo(a['turnoverRate'] as double));

      return fastMoving;
    } catch (e) {
      print('Error calculating fast moving items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getSlowMovingItems() async {
    try {
      final fs = FirestoreService.instance;
      final allInvoices = await fs.getAllInvoices();
      final inventoryService = InventoryService();
      final allItems = await inventoryService.getAllItems();

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      Map<String, Map<String, dynamic>> itemData = {};

      for (final item in allItems) {
        if (item.currentStock > 0) {
          itemData[item.name] = {
            'currentStock': item.currentStock,
            'lastUpdated': item.lastUpdated,
            'totalSold': 0,
            'saleCount': 0,
            'lastSoldDate': null,
          };
        }
      }

      for (final invoice in allInvoices) {
        if (invoice.invoiceType == 'sales' &&
            invoice.date.isAfter(thirtyDaysAgo) &&
            invoice.status != 'cancelled') {

          for (final item in invoice.items) {
            final itemName = item.name;
            if (itemData.containsKey(itemName)) {
              itemData[itemName]!['totalSold'] += item.quantity;
              itemData[itemName]!['saleCount'] += 1;

              if (itemData[itemName]!['lastSoldDate'] == null ||
                  invoice.date.isAfter(itemData[itemName]!['lastSoldDate'])) {
                itemData[itemName]!['lastSoldDate'] = invoice.date;
              }
            }
          }
        }
      }

      List<Map<String, dynamic>> slowMoving = [];

      for (final entry in itemData.entries) {
        final itemName = entry.key;
        final data = entry.value;
        final saleCount = data['saleCount'] as int;
        final totalSold = data['totalSold'] as int;

        if (saleCount < 2 && totalSold < 10) {
          final lastSoldDate = data['lastSoldDate'] as DateTime?;
          final daysInStock = lastSoldDate != null
              ? now.difference(lastSoldDate).inDays
              : now.difference(data['lastUpdated'] as DateTime).inDays;

          slowMoving.add({
            'name': itemName,
            'currentStock': data['currentStock'],
            'saleCount': saleCount,
            'totalSold': totalSold,
            'daysInStock': daysInStock,
            'lastSoldDate': lastSoldDate,
            'id': itemName.toLowerCase().replaceAll(' ', '_'),
          });
        }
      }

      slowMoving.sort((a, b) => (b['daysInStock'] as int).compareTo(a['daysInStock'] as int));

      return slowMoving;
    } catch (e) {
      print('Error calculating slow moving items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUnsoldItems() async {
    try {
      final inventoryService = InventoryService();
      final fs = FirestoreService.instance;

      final allItems = await inventoryService.getAllItems();
      final itemsWithStock = allItems.where((item) => item.currentStock > 0).toList();

      if (itemsWithStock.isEmpty) return [];

      final allInvoices = await fs.getAllInvoices();

      List<Map<String, dynamic>> unsoldItems = [];

      for (final item in itemsWithStock) {
        DateTime? lastTransactionDate;

        for (final invoice in allInvoices) {
          for (final invoiceItem in invoice.items) {
            if (invoiceItem.name == item.name) {
              if (lastTransactionDate == null || invoice.date.isAfter(lastTransactionDate)) {
                lastTransactionDate = invoice.date;
              }
            }
          }
        }

        final unsoldSinceDate = lastTransactionDate ?? item.lastUpdated;
        final now = DateTime.now();
        final ageInHours = now.difference(unsoldSinceDate).inHours;
        final ageInDays = now.difference(unsoldSinceDate).inDays;

        String ageLabel;
        if (ageInHours < 24) {
          ageLabel = 'Unsold ${ageInHours}h';
        } else if (ageInDays < 30) {
          ageLabel = 'Unsold ${ageInDays}d';
        } else if (ageInDays < 365) {
          final months = (ageInDays / 30).floor();
          ageLabel = 'Unsold ${months}mo';
        } else {
          final years = (ageInDays / 365).floor();
          ageLabel = 'Unsold ${years}y';
        }

        unsoldItems.add({
          'name': item.name,
          'daysInStock': ageInDays,
          'ageLabel': ageLabel,
          'quantity': item.currentStock.round(),
          'ageInHours': ageInHours,
          'unsoldSince': unsoldSinceDate,
        });
      }

      unsoldItems.sort((a, b) => (b['ageInHours'] as int).compareTo(a['ageInHours'] as int));

      return unsoldItems;
    } catch (e) {
      print('Error getting unsold items: $e');
      return [];
    }
  }

  void _showUnsoldItemsModal() async {
    final unsoldItems = await _getUnsoldItems();

    if (unsoldItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unsold items found')),
      );
      return;
    }

    final groupedItems = _groupItemsByAge(unsoldItems);

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
                  Icon(Icons.schedule, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Timeholding - Unsold Items',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${unsoldItems.length} items currently unsold',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (groupedItems['> 1 year']!.isNotEmpty)
                    _buildAgeSection('> 1 Year', groupedItems['> 1 year']!, Colors.red),
                  if (groupedItems['6-12 months']!.isNotEmpty)
                    _buildAgeSection('6-12 Months', groupedItems['6-12 months']!, Colors.orange),
                  if (groupedItems['3-6 months']!.isNotEmpty)
                    _buildAgeSection('3-6 Months', groupedItems['3-6 months']!, Colors.amber),
                  if (groupedItems['1-3 months']!.isNotEmpty)
                    _buildAgeSection('1-3 Months', groupedItems['1-3 months']!, Colors.yellow.shade800),
                  if (groupedItems['< 1 month']!.isNotEmpty)
                    _buildAgeSection('< 1 Month', groupedItems['< 1 month']!, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByAge(List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> groups = {
      '> 1 year': [],
      '6-12 months': [],
      '3-6 months': [],
      '1-3 months': [],
      '< 1 month': [],
    };

    for (final item in items) {
      final days = item['daysInStock'] as int;
      if (days > 365) {
        groups['> 1 year']!.add(item);
      } else if (days > 180) {
        groups['6-12 months']!.add(item);
      } else if (days > 90) {
        groups['3-6 months']!.add(item);
      } else if (days > 30) {
        groups['1-3 months']!.add(item);
      } else {
        groups['< 1 month']!.add(item);
      }
    }

    return groups;
  }

  Widget _buildAgeSection(String title, List<Map<String, dynamic>> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length} items',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Qty: ${item['quantity']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['ageLabel'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateToInventoryDetail(Map<String, dynamic> item) {
    Navigator.pushNamed(
      context,
      '/inventory_detail',
      arguments: {'itemId': item['id']},
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return 'â‚¹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return 'â‚¹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return 'â‚¹${amount.toStringAsFixed(0)}';
    }
  }
}

