import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CustomerWiseRevenueScreen extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final String dateRange;

  const CustomerWiseRevenueScreen({
    Key? key,
    required this.customers,
    required this.dateRange,
  }) : super(key: key);

  @override
  State<CustomerWiseRevenueScreen> createState() => _CustomerWiseRevenueScreenState();
}

class _CustomerWiseRevenueScreenState extends State<CustomerWiseRevenueScreen> {
  String _sortBy = 'revenue'; // revenue, invoices, name, outstanding
  bool _sortAscending = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> get _sortedCustomers {
    var customers = widget.customers.where((customer) {
      if (_searchQuery.isEmpty) return true;
      final customerName = (customer['customerName'] as String? ?? '').toLowerCase();
      final customerPhone = (customer['customerPhone'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return customerName.contains(query) || customerPhone.contains(query);
    }).toList();

    customers.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'revenue':
          comparison = ((a['totalRevenue'] as double?) ?? 0.0)
              .compareTo((b['totalRevenue'] as double?) ?? 0.0);
          break;
        case 'invoices':
          comparison = ((a['invoiceCount'] as int?) ?? 0)
              .compareTo((b['invoiceCount'] as int?) ?? 0);
          break;
        case 'outstanding':
          comparison = ((a['outstandingAmount'] as double?) ?? 0.0)
              .compareTo((b['outstandingAmount'] as double?) ?? 0.0);
          break;
        case 'name':
          comparison = (a['customerName'] as String? ?? '')
              .compareTo(b['customerName'] as String? ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return customers;
  }

  double get _totalRevenue {
    return _sortedCustomers.fold(0.0, (sum, customer) => sum + ((customer['totalRevenue'] as double?) ?? 0.0));
  }

  int get _totalInvoices {
    return _sortedCustomers.fold(0, (sum, customer) => sum + ((customer['invoiceCount'] as int?) ?? 0));
  }

  double get _totalOutstanding {
    return _sortedCustomers.fold(0.0, (sum, customer) => sum + ((customer['outstandingAmount'] as double?) ?? 0.0));
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedCustomers = _sortedCustomers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer-wise Revenue',
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
                value: 'invoices',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'invoices'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Invoices'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'outstanding',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'outstanding'
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sort by Outstanding'),
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
                hintText: 'Search customers...',
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
                  borderSide: const BorderSide(color: Colors.green, width: 2),
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
                    'Customers',
                    sortedCustomers.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Outstanding',
                    _formatCurrency(_totalOutstanding),
                    Icons.account_balance_wallet,
                    _totalOutstanding > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Customers list
          Expanded(
            child: sortedCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No customers found'
                              : 'No customers match your search',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: sortedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = sortedCustomers[index];
                      return CustomerCard(
                        customer: customer,
                        rank: index + 1,
                        formatCurrency: _formatCurrency,
                        buildStatColumn: _buildStatColumn,
                      );
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
            textAlign: TextAlign.center,
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

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class CustomerCard extends StatefulWidget {
  final Map<String, dynamic> customer;
  final int rank;
  final String Function(double) formatCurrency;
  final Widget Function(String, String, IconData, Color) buildStatColumn;

  const CustomerCard({
    Key? key,
    required this.customer,
    required this.rank,
    required this.formatCurrency,
    required this.buildStatColumn,
  }) : super(key: key);

  @override
  _CustomerCardState createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customer['customerName'] as String? ?? 'Unknown';
    final items = widget.customer['items'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: ExpansionTile(
        key: PageStorageKey(customerName),
        title: _buildCustomerCardTitle(),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          _buildPurchasedItemsList(items),
        ],
      ),
    );
  }

  Widget _buildCustomerCardTitle() {
    final customerName = widget.customer['customerName'] as String? ?? 'Unknown';
    final customerPhone = widget.customer['customerPhone'] as String? ?? '';
    final revenue = (widget.customer['totalRevenue'] as double?) ?? 0.0;
    final invoiceCount = (widget.customer['invoiceCount'] as int?) ?? 0;
    final totalQuantity = (widget.customer['totalQuantity'] as int?) ?? 0;
    final outstanding = (widget.customer['outstandingAmount'] as double?) ?? 0.0;
    final paid = (widget.customer['totalPaid'] as double?) ?? 0.0;
    final pendingRefunds = (widget.customer['pendingRefunds'] as double?) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.rank <= 3 ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#${widget.rank}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.rank <= 3 ? Colors.amber.shade800 : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (customerPhone.isNotEmpty)
                      Text(
                        customerPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                widget.formatCurrency(revenue),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: widget.buildStatColumn(
                        'Invoices',
                        invoiceCount.toString(),
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: widget.buildStatColumn(
                        'Items Purchased',
                        totalQuantity.toString(),
                        Icons.shopping_bag,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: widget.buildStatColumn(
                        'Paid',
                        widget.formatCurrency(paid),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: widget.buildStatColumn(
                        'Outstanding (This Period)',
                        widget.formatCurrency(outstanding.abs()),
                        Icons.schedule,
                        outstanding > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                // Show pending refunds if any (awaiting application to future invoices)
                if (pendingRefunds > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pending Refunds (to apply)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        Text(
                          widget.formatCurrency(pendingRefunds),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundDetailRow(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          widget.formatCurrency(amount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasedItemsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text('No items purchased in this period.')),
      );
    }

    // Group items by invoice ID
    final Map<String, List<Map<String, dynamic>>> itemsByInvoice = {};
    for (var item in items) {
      final invoiceId = item['invoiceId'] as String? ?? 'N/A';
      if (!itemsByInvoice.containsKey(invoiceId)) {
        itemsByInvoice[invoiceId] = [];
      }
      itemsByInvoice[invoiceId]!.add(item);
    }

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itemsByInvoice.entries.map((entry) {
          final invoiceId = entry.key;
          final invoiceItems = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Invoice: $invoiceId',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
              ),
              ...invoiceItems.map((item) {
                final itemName = item['itemName'] as String? ?? 'Unknown Item';
                final quantity = (item['quantity'] as int?) ?? 0;
                final amount = (item['amount'] as double?) ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(itemName, style: TextStyle(fontSize: 14))),
                      SizedBox(width: 16),
                      Text('Qty: $quantity', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                      SizedBox(width: 16),
                      Text(widget.formatCurrency(amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
              if (itemsByInvoice.keys.last != invoiceId) const Divider(thickness: 1, height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}