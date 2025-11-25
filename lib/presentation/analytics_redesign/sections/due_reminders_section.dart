import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/skeleton_loader.dart';
import '../../../services/customer_service.dart';

class DueRemindersSection extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic> outstandingPayments;
  const DueRemindersSection({
    Key? key,
    required this.isLoading,
    required this.outstandingPayments,
  }) : super(key: key);

  @override
  State<DueRemindersSection> createState() => _DueRemindersSectionState();
}

class _DueRemindersSectionState extends State<DueRemindersSection> {
  bool _isCustomerView = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('dueRemindersSection'),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Due Reminders',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              _buildTabSelector(),
            ],
          ),
          SizedBox(height: 16),
          widget.isLoading
              ? SkeletonLoader.dueReminderCard()
              : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('By Customer', true),
          _buildTabButton('By Item', false),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isCustomer) {
    final isSelected = _isCustomerView == isCustomer;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCustomerView = isCustomer;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.red : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isCustomerView
          ? _buildCustomerBucketsList()
          : _buildItemBucketsList(),
    );
  }

  Widget _buildCustomerBucketsList() {
    final buckets = _getOverdueCustomerBuckets();

    if (buckets.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: buckets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bucket = buckets[index];
        return GestureDetector(
          onTap: () => _showCustomerBucketDetail(bucket),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bucket['color'],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bucket['label'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${bucket['count']} customers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(bucket['amount']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: bucket['color'],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemBucketsList() {
    final buckets = _getOverdueItemBuckets();

    if (buckets.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: buckets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bucket = buckets[index];
        return GestureDetector(
          onTap: () => _showItemBucketDetail(bucket),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bucket['color'],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bucket['label'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${bucket['count']} items',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(bucket['amount']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: bucket['color'],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'No overdue payments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            'Great job! Everything is on track.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerBucketDetail(Map<String, dynamic> bucket) {
    final customers = _getCustomersInBucket(bucket['key']);

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
                  Icon(Icons.people, color: bucket['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Customers - ${bucket['label']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${bucket['count']} customers • ${_formatCurrency(bucket['amount'])}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Dismissible(
                    key: Key('customer_${customer['name']}_$index'),
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.email, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.green,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.phone, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _sendReminder(customer);
                      } else {
                        _callCustomer(customer);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          customer['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${customer['invoiceCount']} unpaid invoices'),
                            Text(
                              'Last invoice: ${customer['lastInvoiceDate']}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(customer['amount']),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: bucket['color'],
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _viewLedger(customer),
                              child: const Text('View Ledger', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
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

  void _showItemBucketDetail(Map<String, dynamic> bucket) {
    final items = _getItemsInBucket(bucket['key']);

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
                  Icon(Icons.inventory, color: bucket['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Items - ${bucket['label']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${bucket['count']} items • ${_formatCurrency(bucket['amount'])}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['debtorCount']} debtors'),
                          Text(
                            'Last sold: ${item['lastSoldDate']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Text(
                        _formatCurrency(item['amount']),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: bucket['color'],
                          fontSize: 16,
                        ),
                      ),
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

  // Data methods
  List<Map<String, dynamic>> _getOverdueCustomerBuckets() {
    final buckets = widget.outstandingPayments['customerBuckets'] as Map<String, dynamic>? ?? {};
    return [
      {
        'label': '1-7 days',
        'count': buckets['1-7']?['count'] ?? 5,
        'amount': buckets['1-7']?['amount'] ?? 12500.0,
        'color': Colors.orange,
        'key': '1-7',
      },
      {
        'label': '8-30 days',
        'count': buckets['8-30']?['count'] ?? 8,
        'amount': buckets['8-30']?['amount'] ?? 28000.0,
        'color': Colors.red,
        'key': '8-30',
      },
      {
        'label': '31-60 days',
        'count': buckets['31-60']?['count'] ?? 3,
        'amount': buckets['31-60']?['amount'] ?? 15200.0,
        'color': Colors.red[700],
        'key': '31-60',
      },
      {
        'label': '60+ days',
        'count': buckets['60+']?['count'] ?? 2,
        'amount': buckets['60+']?['amount'] ?? 8900.0,
        'color': Colors.red[900],
        'key': '60+',
      },
    ];
  }

  List<Map<String, dynamic>> _getOverdueItemBuckets() {
    final buckets = widget.outstandingPayments['itemBuckets'] as Map<String, dynamic>? ?? {};
    return [
      {
        'label': '1-7 days',
        'count': buckets['1-7']?['count'] ?? 12,
        'amount': buckets['1-7']?['amount'] ?? 8500.0,
        'color': Colors.orange,
        'key': '1-7',
      },
      {
        'label': '8-30 days',
        'count': buckets['8-30']?['count'] ?? 18,
        'amount': buckets['8-30']?['amount'] ?? 22000.0,
        'color': Colors.red,
        'key': '8-30',
      },
      {
        'label': '31-60 days',
        'count': buckets['31-60']?['count'] ?? 7,
        'amount': buckets['31-60']?['amount'] ?? 11200.0,
        'color': Colors.red[700],
        'key': '31-60',
      },
      {
        'label': '60+ days',
        'count': buckets['60+']?['count'] ?? 4,
        'amount': buckets['60+']?['amount'] ?? 6800.0,
        'color': Colors.red[900],
        'key': '60+',
      },
    ];
  }

  List<Map<String, dynamic>> _getCustomersInBucket(String bucketKey) {
    final customers = widget.outstandingPayments['customers'] as List<dynamic>? ?? [];
    return customers
        .where((c) => c['daysBucket'] == bucketKey)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  List<Map<String, dynamic>> _getItemsInBucket(String bucketKey) {
    final items = widget.outstandingPayments['items'] as List<dynamic>? ?? [];
    return items
        .where((i) => i['daysBucket'] == bucketKey)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // Action methods
  Future<void> _sendReminder(Map<String, dynamic> customer) async {
    try {
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      final totalDue = customer['amount'] as double? ?? 0.0;

      final message = '''Hello ${customer['name']},

This is a friendly reminder regarding your outstanding balance.

Total Due: ₹${totalDue.toStringAsFixed(2)}

Please arrange for the payment at your earliest convenience.

Thank you for your business!

📱 Download InvoiceFlow app:
https://play.google.com/store/apps/details?id=com.invoiceflow.app''';

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      if (phoneNumber.startsWith('+')) {
        phoneNumber = phoneNumber.substring(1);
      }

      if (phoneNumber.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber)) {
        phoneNumber = '91$phoneNumber';
      }

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';
      final whatsappUri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening WhatsApp for ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp. Please install WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reminder: ${e.toString()}')),
      );
    }
  }

  Future<void> _callCustomer(Map<String, dynamic> customer) async {
    try {
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      if (customerData.phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No phone number found for ${customer['name']}')),
        );
        return;
      }

      String phoneNumber = customerData.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      final telUrl = 'tel:$phoneNumber';
      final telUri = Uri.parse(telUrl);

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling ${customer['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calling customer: ${e.toString()}')),
      );
    }
  }

  Future<void> _viewLedger(Map<String, dynamic> customer) async {
    try {
      // Get customer ID by name
      final customerService = CustomerService.instance;
      final allCustomers = await customerService.getAllCustomers();
      final customerData = allCustomers.firstWhere(
        (c) => c.name == customer['name'],
        orElse: () => throw Exception('Customer not found'),
      );

      // Navigate to customer detail screen
      Navigator.pushNamed(
        context,
        '/customer-detail-screen',
        arguments: customerData.id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening ledger: ${e.toString()}')),
      );
    }
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

