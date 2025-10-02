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
                      return _buildCustomerCard(customer, index + 1);
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

  Widget _buildCustomerCard(Map<String, dynamic> customer, int rank) {
    final customerName = customer['customerName'] as String? ?? 'Unknown';
    final customerPhone = customer['customerPhone'] as String? ?? '';
    final revenue = (customer['totalRevenue'] as double?) ?? 0.0;
    final invoiceCount = (customer['invoiceCount'] as int?) ?? 0;
    final totalQuantity = (customer['totalQuantity'] as int?) ?? 0;
    final outstanding = (customer['outstandingAmount'] as double?) ?? 0.0;
    final paid = (customer['totalPaid'] as double?) ?? 0.0;

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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: rank <= 3 ? Colors.amber.shade800 : Colors.green.shade700,
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
                  _formatCurrency(revenue),
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
                        child: _buildStatColumn(
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
                        child: _buildStatColumn(
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
                        child: _buildStatColumn(
                          'Paid',
                          _formatCurrency(paid),
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
                        child: _buildStatColumn(
                          outstanding >= 0 ? 'Outstanding' : 'Credit',
                          _formatCurrency(outstanding.abs()),
                          outstanding >= 0 ? Icons.schedule : Icons.credit_score,
                          outstanding > 0 ? Colors.orange : (outstanding < 0 ? Colors.blue : Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
