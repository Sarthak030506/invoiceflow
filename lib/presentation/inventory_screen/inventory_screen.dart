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
      // Ensure current stock is computed for each item
      for (int i = 0; i < _allItems.length; i++) {
        final actualStock = await _inventoryService.computeCurrentStock(_allItems[i].id);
        if (actualStock != _allItems[i].currentStock) {
          _allItems[i] = _allItems[i].copyWith(currentStock: actualStock);
        }
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
          ? Center(child: CircularProgressIndicator())
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
}