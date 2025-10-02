import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/analytics_service.dart';
import '../widgets/date_range_selector.dart';

class ItemwiseRevenueModal extends StatefulWidget {
  final DateRange selectedRange;
  final int? customDays;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ItemwiseRevenueModal({
    Key? key,
    required this.selectedRange,
    this.customDays,
    this.customStartDate,
    this.customEndDate,
  }) : super(key: key);

  @override
  State<ItemwiseRevenueModal> createState() => _ItemwiseRevenueModalState();
}

class _ItemwiseRevenueModalState extends State<ItemwiseRevenueModal> {
  String _sortBy = 'revenue';
  bool _sortAscending = false;
  String _filterCategory = 'All';
  
  // Add key to force FutureBuilder refresh when filters change
  String get _cacheKey => '${widget.selectedRange}_${widget.customDays}_${widget.customStartDate}_${widget.customEndDate}_${_sortBy}_${_sortAscending}_${_filterCategory}';
  
  // Store the future to avoid rebuilding on every setState
  late Future<List<Map<String, dynamic>>> _analyticsFuture;
  
  @override
  void initState() {
    super.initState();
    _refreshData();
  }
  
  void _refreshData() {
    _analyticsFuture = _getFilteredAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item-wise Revenue',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _refreshData(); // Manual refresh
                        });
                      },
                      icon: Icon(Icons.refresh),
                      tooltip: 'Refresh Data',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildFilterControls(),
          Expanded(child: _buildRevenueTable()),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              items: const [
                DropdownMenuItem(value: 'revenue', child: Text('Revenue')),
                DropdownMenuItem(value: 'quantity', child: Text('Quantity')),
                DropdownMenuItem(value: 'name', child: Text('Name')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _refreshData(); // Refresh data when sort changes
                });
              },
            ),
          ),
          SizedBox(width: 3.w),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _refreshData(); // Refresh data when sort order changes
              });
            },
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              foregroundColor: Colors.blue,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterCategory,
              decoration: InputDecoration(
                labelText: 'Filter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Items')),
                DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
                DropdownMenuItem(value: 'Containers', child: Text('Containers')),
              ],
              onChanged: (value) {
                setState(() {
                  _filterCategory = value!;
                  _refreshData(); // Refresh data when filter changes
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_cacheKey), // Force rebuild when cache key changes
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        }

        final items = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(4.w),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildTableHeader();
            final item = items[index - 1];
            return _buildTableRow(item, index % 2 == 0);
          },
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Revenue', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, bool isEven) {
    print('DEBUG _buildTableRow - item keys: ${item.keys}');
    print('DEBUG _buildTableRow - item data: $item');
    print('DEBUG _buildTableRow - quantitySold value: ${item['quantitySold']}');
    print('DEBUG _buildTableRow - quantity value: ${item['quantity']}');

    final quantity = item['quantitySold'] as int? ?? item['quantity'] as int? ?? 0;
    final rate = (item['rate'] as num?)?.toDouble() ?? 0.0;
    final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;

    print('DEBUG _buildTableRow - final quantity: $quantity');

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isEven ? Colors.grey[50] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item['name'] ?? 'Unknown Item')),
          Expanded(child: Text(quantity.toString(), textAlign: TextAlign.center)),
          Expanded(child: Text('₹${rate.toStringAsFixed(2)}', textAlign: TextAlign.center)),
          Expanded(
            child: Text(
              '₹${revenue.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryForItem(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('bag')) return 'Bags';
    if (name.contains('tissue') || name.contains('clean')) return 'Cleaning';
    if (name.contains('plate') || name.contains('container')) return 'Containers';
    return 'Other';
  }

  Future<List<Map<String, dynamic>>> _getFilteredAnalytics() async {
    print('====== MODAL _getFilteredAnalytics CALLED ======');
    final analyticsService = AnalyticsService();

    // Enhanced date range handling
    String dateRange = 'All time';
    print('Selected range: ${widget.selectedRange}');

    if (widget.selectedRange == DateRange.today) {
      dateRange = 'Today';
    } else if (widget.selectedRange == DateRange.last7Days) {
      dateRange = 'Last 7 days';
    } else if (widget.selectedRange == DateRange.last30Days) {
      dateRange = 'Last 30 days';
    } else if (widget.selectedRange == DateRange.last3Months) {
      dateRange = 'Last 90 days';
    } else if (widget.selectedRange == DateRange.customDays) {
      // Handle custom days
      if (widget.customDays != null) {
        if (widget.customDays! <= 7) {
          dateRange = 'Last 7 days';
        } else if (widget.customDays! <= 30) {
          dateRange = 'Last 30 days';
        } else {
          dateRange = 'Last 90 days';
        }
      }
    } else if (widget.selectedRange == DateRange.customRange) {
      // Handle custom date range
      if (widget.customStartDate != null && widget.customEndDate != null) {
        // For now, calculate the difference and map to closest range
        final difference = widget.customEndDate!.difference(widget.customStartDate!).inDays;
        if (difference <= 7) {
          dateRange = 'Last 7 days';
        } else if (difference <= 30) {
          dateRange = 'Last 30 days';
        } else {
          dateRange = 'Last 90 days';
        }
      }
    }

    print('Using date range: $dateRange');

    try {
      // Always get fresh data from the database
      final analytics = await analyticsService.getFilteredAnalytics(dateRange, salesOnly: true);
      print('Raw analytics data received: ${analytics.length} items');

      List<Map<String, dynamic>> items = [];
      for (var item in analytics) {
        print('DEBUG MODAL - Raw item from analytics: $item');

        final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
        final rate = (item['averagePrice'] as num?)?.toDouble() ?? 0.0;
        final quantity = item['quantitySold'] as int? ?? 0;
        final name = item['itemName'] as String? ?? 'Unknown Item';

        // Debug: Print the data we're processing
        print('Processing analytics item - Name: $name, Qty: $quantity, Rate: $rate, Revenue: $revenue');

        // Add all items with valid revenue, even if quantity is 0 (for debugging)
        if (revenue > 0) {
          final itemMap = {
            'name': name,
            'quantity': quantity, // Keep original quantity, even if 0
            'quantitySold': quantity, // Add quantitySold field for consistency
            'rate': rate,
            'revenue': revenue,
            'category': _getCategoryForItem(name),
          };
          items.add(itemMap);
          print('Added item to list: $itemMap');
        } else {
          print('Skipping item $name - Revenue: $revenue');
        }
      }

      print('DEBUG MODAL - Total items in list: ${items.length}');
      if (items.isNotEmpty) {
        print('DEBUG MODAL - First item in list: ${items[0]}');
      }

      print('Total items after processing: ${items.length}');

      // Apply filter
      if (_filterCategory != 'All') {
        items = items.where((i) => i['category'] == _filterCategory).toList();
        print('Items after category filter: ${items.length}');
      }

      // Sorting
      items.sort((a, b) {
        final aVal = a[_sortBy];
        final bVal = b[_sortBy];
        if (aVal is num && bVal is num) {
          return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        } else if (aVal is String && bVal is String) {
          return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        return 0;
      });

      print('Final items to display: ${items.length}');
      return items;
    } catch (e) {
      print('Error in _getFilteredAnalytics: $e');
      return [];
    }
  }
}
