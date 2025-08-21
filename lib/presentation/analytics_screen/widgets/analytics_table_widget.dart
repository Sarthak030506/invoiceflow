import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnalyticsTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String searchQuery;
  final String sortColumn;
  final bool sortAscending;
  final Function(String) onSearchChanged;
  final Function(String) onSortChanged;

  const AnalyticsTableWidget({
    Key? key,
    required this.data,
    required this.searchQuery,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  State<AnalyticsTableWidget> createState() => _AnalyticsTableWidgetState();
}

class _AnalyticsTableWidgetState extends State<AnalyticsTableWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'All';
            break;
          case 1:
            _currentFilter = 'Sales';
            break;
          case 2:
            _currentFilter = 'Purchase';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> filtered = widget.data;

    // Filter by invoice type
    if (_currentFilter != 'All') {
      filtered = filtered.where((item) {
        final invoiceType = item['invoiceType']?.toString().toLowerCase();
        return invoiceType == _currentFilter.toLowerCase();
      }).toList();
    }

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) => (item['itemName'] as String)
              .toLowerCase()
              .contains(widget.searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(4.w),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
        
        // Tab bar for Sales/Purchase separation
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurface,
            labelStyle: theme.textTheme.labelLarge,
            unselectedLabelStyle: theme.textTheme.labelMedium,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.all_inclusive, size: 18),
                    SizedBox(width: 1.w),
                    Text('All'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 18),
                    SizedBox(width: 1.w),
                    Text('Sales'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory, size: 18),
                    SizedBox(width: 1.w),
                    Text('Purchase'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Summary cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'Total Items',
                  _filteredData.length.toString(),
                  Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'Total Amount',
                  '₹${_filteredData.fold<double>(0.0, (sum, item) => sum + ((item['revenue'] ?? 0.0) as double)).toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Data table
        Expanded(
          child: _filteredData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _currentFilter == 'Sales' 
                            ? Icons.shopping_cart_outlined
                            : _currentFilter == 'Purchase'
                                ? Icons.inventory_outlined
                                : Icons.table_chart_outlined,
                        size: 15.w,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No ${_currentFilter.toLowerCase()} data available',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_currentFilter != 'All') ...[
                        SizedBox(height: 1.h),
                        Text(
                          'Try switching to a different tab or check your invoice data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      sortColumnIndex: _getSortColumnIndex(),
                      sortAscending: widget.sortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            'Item Name',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSort: (columnIndex, ascending) => 
                              widget.onSortChanged('itemName'),
                        ),
                        DataColumn(
                          label: Text(
                            'Type',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSort: (columnIndex, ascending) => 
                              widget.onSortChanged('invoiceType'),
                        ),
                        DataColumn(
                          label: Text(
                            'Quantity',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          numeric: true,
                          onSort: (columnIndex, ascending) => 
                              widget.onSortChanged('quantitySold'),
                        ),
                        DataColumn(
                          label: Text(
                            'Total Amount',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          numeric: true,
                          onSort: (columnIndex, ascending) => 
                              widget.onSortChanged('revenue'),
                        ),
                        DataColumn(
                          label: Text(
                            'Avg Price',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          numeric: true,
                          onSort: (columnIndex, ascending) => 
                              widget.onSortChanged('averagePrice'),
                        ),
                      ],
                      rows: _filteredData.map((item) => DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 35.w,
                              child: Text(
                                item['itemName']?.toString() ?? 'Unknown',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: (item['invoiceType']?.toString().toLowerCase() == 'sales')
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (item['invoiceType']?.toString() ?? 'Unknown').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: (item['invoiceType']?.toString().toLowerCase() == 'sales')
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              (item['quantitySold'] ?? 0).toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${((item['revenue'] ?? 0.0) as double).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${((item['averagePrice'] ?? 0.0) as double).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, String title, String value, IconData icon) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Icon(
              icon,
              size: 6.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _getSortColumnIndex() {
    switch (widget.sortColumn) {
      case 'itemName':
        return 0;
      case 'invoiceType':
        return 1;
      case 'quantitySold':
        return 2;
      case 'revenue':
        return 3;
      case 'averagePrice':
        return 4;
      default:
        return 3; // Default to total amount
    }
  }
}