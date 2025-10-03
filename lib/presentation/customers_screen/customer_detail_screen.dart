import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../services/customer_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/app_loading_indicator.dart';
import './widgets/customer_invoice_item.dart';
import './widgets/whatsapp_due_reminder_button.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final CustomerService _customerService = CustomerService.instance;
  final AnalyticsService _analyticsService = AnalyticsService();
  
  CustomerModel? _customer;
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  double _totalOutstanding = 0.0;
  Map<String, dynamic>? _customerAnalytics;
  
  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }
  
  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customer = await _customerService.getCustomerById(widget.customerId);
      final invoices = await _customerService.getCustomerInvoices(widget.customerId);
      final analytics = await _analyticsService.getCustomerAnalytics(widget.customerId);
      
      double outstanding = 0.0;
      for (final invoice in invoices) {
        if (invoice.invoiceType == 'sales') {
          outstanding += invoice.remainingAmount;
        }
      }
      
      setState(() {
        _customer = customer;
        _invoices = invoices;
        _totalOutstanding = outstanding;
        _customerAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onInvoiceTap(InvoiceModel invoice) {
    Navigator.pushNamed(
      context,
      '/invoice-detail-screen',
      arguments: invoice,
    ).then((_) => _loadCustomerData());
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppTheme.lightTheme.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Delete Customer'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${_customer!.name}?\n\nThis will remove the customer from all associated invoices. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCustomer();
            },
            style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
              backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.error),
              foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onError),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    try {
      await _customerService.deleteCustomer(_customer!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        title: Text(
          _customer?.name ?? 'Customer Details',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (_customer != null)
            IconButton(
              onPressed: () => _showDeleteConfirmation(),
              icon: Icon(
                Icons.delete_outline,
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? _buildCustomerNotFound()
              : _buildCustomerDetails(),
    );
  }
  
  Widget _buildCustomerNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 20.w,
            color: Colors.grey,
          ),
          SizedBox(height: 2.h),
          Text(
            'Customer not found',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: Theme.of(context).elevatedButtonTheme.style,
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomerDetails() {
    return RefreshIndicator(
      onRefresh: _loadCustomerData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
              Card(
                elevation: AppTheme.lightTheme.cardTheme.elevation,
                color: AppTheme.lightTheme.cardTheme.color,
                shape: AppTheme.lightTheme.cardTheme.shape,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 2.h),
                      _buildInfoRow('Name', _customer!.name),
                      SizedBox(height: 1.h),
                      _buildInfoRow('Phone', _customer!.phoneNumber),
                      SizedBox(height: 1.h),
                      _buildOutstandingBalanceRow(),
                      SizedBox(height: 1.h),
                      _buildInfoRow(
                        'Total Invoices',
                        _invoices.length.toString(),
                      ),
                      if (_totalOutstanding > 0) ...[  
                        SizedBox(height: 2.h),
                        WhatsAppDueReminderButton(
                          customer: _customer!,
                          totalDue: _totalOutstanding,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 3.h),
              
              // Customer Analytics Section
              if (_customerAnalytics != null && _customerAnalytics!['metrics'] != null)
                Card(
                  elevation: AppTheme.lightTheme.cardTheme.elevation,
                  color: AppTheme.lightTheme.cardTheme.color,
                  shape: AppTheme.lightTheme.cardTheme.shape,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Analytics',
                          style: AppTheme.lightTheme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 2.h),
                        _buildInfoRow(
                          'Total Spent', 
                          '₹${((_customerAnalytics!['metrics']['totalSpent'] as num).toDouble()).toStringAsFixed(2)}'
                        ),
                        SizedBox(height: 1.h),
                        _buildInfoRow(
                          'Average Invoice', 
                          '₹${((_customerAnalytics!['metrics']['averageInvoiceValue'] as num).toDouble()).toStringAsFixed(2)}'
                        ),
                        if (_customerAnalytics!['topItems'] != null && 
                            (_customerAnalytics!['topItems'] as List).isNotEmpty) ...[  
                          SizedBox(height: 2.h),
                          Text(
                            'Most Purchased Items',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          ..._buildTopItemsList(),
                        ],
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: 3.h),
              
              // Invoices Section
              Text(
                'Invoice History',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 2.h),
              
              _invoices.isEmpty
                  ? _buildEmptyInvoices()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        return CustomerInvoiceItem(
                          invoice: invoice,
                          onTap: () => _onInvoiceTap(invoice),
                          shopName: 'Your Shop Name', // Replace with actual shop name from settings
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOutstandingBalanceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Outstanding Balance',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '₹${_totalOutstanding.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _totalOutstanding > 0
                      ? AppTheme.getWarningColor(true)
                      : AppTheme.getSuccessColor(true),
                ),
              ),
              if (_totalOutstanding > 0) ...[
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: () => _showEditDueDialog(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.blue.shade700),
                        SizedBox(width: 1.w),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showEditDueDialog() {
    final TextEditingController controller = TextEditingController(
      text: _totalOutstanding.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    BlurredModal.show(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Due Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Customer: ${_customer!.name}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'New Due Amount',
                prefixText: '₹',
                hintText: '0.00',
                helperText: 'Current due: ₹${_totalOutstanding.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount < 0) {
                  return 'Amount cannot be negative';
                }
                if (amount > _totalOutstanding) {
                  return 'New amount cannot be greater than current due';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: PrimaryButton(
                    text: 'Update',
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newAmount = double.parse(controller.text);
                        Navigator.pop(context);
                        await _updateDueAmount(newAmount);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDueAmount(double newDue) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _customerService.adjustOutstandingBalance(_customer!.id, newDue);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success feedback
      FeedbackAnimations.showSuccess(
        context,
        message: 'Due updated: ₹${newDue.toStringAsFixed(2)}',
      );
      HapticFeedbackUtil.success();

      // Reload customer data in background
      _loadCustomerData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      FeedbackAnimations.showError(
        context,
        message: 'Update failed: ${e.toString()}',
      );
      HapticFeedbackUtil.error();
    }
  }

  Widget _buildEmptyInvoices() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 15.w,
            color: Colors.grey,
          ),
          SizedBox(height: 2.h),
          Text(
            'No invoices found for this customer',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildTopItemsList() {
    final topItems = _customerAnalytics!['topItems'] as List;
    return topItems.map((item) => Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item['name'] as String,
              style: AppTheme.lightTheme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x${item['quantity']}',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}