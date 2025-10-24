import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/inventory_item_model.dart';
import '../../services/inventory_service.dart';
import '../../services/inventory_notification_service.dart';
import 'inventory_detail_screen.dart';
import 'add_items_directly_screen.dart';
import 'dart:async';

class InventoryScreen extends StatefulWidget {
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<InventoryItem> _allItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  StreamSubscription? _itemUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _setupRealTimeUpdates();
  }
  
  void _setupRealTimeUpdates() {
    _itemUpdateSubscription = InventoryNotificationService().itemUpdatedStream.listen((updatedItem) {
      setState(() {
        final index = _allItems.indexWhere((item) => item.id == updatedItem.id);
        if (index != -1) {
          _allItems[index] = updatedItem;
          _applySearchFilter();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _itemUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      _allItems = await _inventoryService.getAllItems();

      // OPTIMIZATION: Compute stock for all items in parallel instead of sequentially
      if (_allItems.isNotEmpty) {
        final stockComputations = _allItems.map((item) async {
          final actualStock = await _inventoryService.computeCurrentStock(item.id);
          if (actualStock != item.currentStock) {
            return item.copyWith(currentStock: actualStock);
          }
          return item;
        }).toList();

        // Wait for all parallel computations to complete
        _allItems = await Future.wait(stockComputations);
      }

      _applySearchFilter();
    } catch (e) {
      print('Error loading inventory: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _applySearchFilter() {
    final searchTerm = _searchController.text.toLowerCase();
    _filteredItems = _allItems
        .where((item) => item.name.toLowerCase().contains(searchTerm))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddItemsDirectlyScreen(),
                ),
              ).then((_) => _loadInventory()); // Refresh inventory when returning
            },
            tooltip: 'Add Items Directly',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _applySearchFilter();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(child: Text('No items found'))
                      : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: Icon(Icons.inventory_2,
                                      color: Colors.white),
                                ),
                                title: Text(item.name),
                                subtitle: Text('SKU: ${item.sku}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Stock: ${item.currentStock.toInt()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.currentStock <= item.reorderPoint
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '₹${item.avgCost.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/inventory/item/${item.id}',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemsDirectlyScreen(),
            ),
          ).then((_) => _loadInventory()); // Refresh inventory when returning
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add_box),
        label: Text('Add Items'),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _InventorySkeletonCard();
      },
    );
  }
}

class _InventorySkeletonCard extends StatefulWidget {
  @override
  State<_InventorySkeletonCard> createState() => _InventorySkeletonCardState();
}

class _InventorySkeletonCardState extends State<_InventorySkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar skeleton
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ],
                        colors: [
                          Colors.grey.shade300,
                          Colors.grey.shade100,
                          Colors.grey.shade300,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(color: Colors.grey[300]),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: double.infinity, height: 16),
                  SizedBox(height: 6),
                  _buildShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            // Trailing skeleton
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildShimmerBox(width: 80, height: 14),
                SizedBox(height: 4),
                _buildShimmerBox(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}