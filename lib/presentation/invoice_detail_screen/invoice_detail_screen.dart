import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import 'package:flutter/services.dart';

import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/invoice_service.dart';
import './widgets/invoice_action_buttons_widget.dart';
import './widgets/invoice_header_card_widget.dart';
import './widgets/invoice_items_table_widget.dart';
import './widgets/invoice_payment_info_widget.dart';
import './widgets/invoice_revenue_widget.dart';
import './widgets/invoice_summary_widget.dart';
import './widgets/whatsapp_reminder_button.dart';
import '../return_goods_screen/return_goods_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isOffline = false;

  InvoiceModel? _invoice;
  late InvoiceService _invoiceService;
  
  // Controllers for editable fields
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  
  // List to track edited items
  List<Map<String, dynamic>> _editedItems = [];


  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService.instance;
    
    // InvoiceModel must be passed as arguments from the list screen
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is InvoiceModel) {
        setState(() {
          _invoice = args;
          _initControllers();
          _editedItems = _invoice!.items.map((item) => item.toJson()).toList();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh invoice data when returning from other screens
    if (_invoice != null) {
      _refreshInvoiceData();
    }
  }

  Future<void> _refreshInvoiceData() async {
    if (_invoice == null) return;
    try {
      // Get the latest invoice data from the database
      final allInvoices = await _invoiceService.fetchAllInvoices();
      final updatedInvoice = allInvoices.firstWhere(
        (invoice) => invoice.id == _invoice!.id,
        orElse: () => _invoice!,
      );
      
      // Only update if the invoice has actually changed
      if (updatedInvoice.updatedAt.isAfter(_invoice!.updatedAt)) {
        setState(() {
          _invoice = updatedInvoice;
          _initControllers();
          _editedItems = _invoice!.items.map((item) => item.toJson()).toList();
        });
      }
    } catch (e) {
      // Handle error silently or show a subtle notification
      print('Error refreshing invoice data: $e');
    }
  }
  
  void _initControllers() {
    if (_invoice == null) return;
    _clientNameController.text = _invoice!.clientName;
    _invoiceDateController.text = _invoice!.getFormattedDate();
    _notesController.text = _invoice!.notes ?? '';
    _taxRateController.text = _invoice!.taxRate.toStringAsFixed(1);
  }
  
  @override
  void dispose() {
    _clientNameController.dispose();
    _invoiceDateController.dispose();
    _notesController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      
      if (_isEditMode) {
        // Reset controllers to current invoice values when entering edit mode
        _initControllers();
        _editedItems = _invoice!.items.map((item) => item.toJson()).toList();
      }
    });

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditMode ? "Edit mode enabled" : "Edit mode disabled")),
    );
  }

  void _shareInvoice() {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Generating PDF and opening share sheet...")),
    );

    // Simulate PDF generation and sharing
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invoice shared successfully")),
        );
      }
    });
  }

  void _markAsPaid() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });
    try {
      final updatedInvoice = _invoice!.copyWith(
        status: 'paid',
        amountPaid: _invoice!.adjustedTotal,
        updatedAt: DateTime.now(),
      );
      await _invoiceService.updateInvoice(updatedInvoice);
      setState(() {
        _invoice = updatedInvoice;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invoice marked as paid")),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error marking as paid: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadPdf() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Generating and downloading PDF...")),
    );
    // Simulate PDF generation and download
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF downloaded successfully")),
      );
    }
  }

  void _deleteInvoice() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });
    try {
      await _invoiceService.deleteInvoice(_invoice!.id);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invoice deleted successfully")),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting invoice: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _duplicateInvoice() {
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invoice duplicated successfully")),
    );
  }
  
  void _processReturn() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.keyboard_return_rounded,
              color: Colors.orange.shade600,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Return Goods'),
          ],
        ),
        content: Text(
          'Process return for Invoice #${_invoice!.invoiceNumber}?\n\nThis will create a return entry for this ${_invoice!.invoiceType} invoice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReturnGoodsScreen(invoice: _invoice!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: Text('Process Return'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tax rate once
      final double taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
      
      // Prepare data outside of setState for better performance
      final List<InvoiceItem> updatedItems = _editedItems.map((itemMap) {
        return InvoiceItem(
          name: itemMap['name'] ?? '',
          quantity: itemMap['quantity'] ?? 1,
          price: (itemMap['price'] ?? 0.0).toDouble(),
        );
      }).toList();
      
      // Calculate new revenue based on items
      final double newRevenue = updatedItems.fold(
        0.0, 
        (sum, item) => sum + (item.price * item.quantity)
      );
      
      // Create updated invoice
      final updatedInvoice = _invoice!.copyWith(
        clientName: _clientNameController.text,
        notes: _notesController.text,
        items: updatedItems,
        revenue: newRevenue,
        updatedAt: DateTime.now(),
      );
      
      // Save to database in a separate isolate or compute if possible
      await _invoiceService.updateInvoice(updatedInvoice);
      
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      // Update the state
      setState(() {
        _invoice = updatedInvoice;
        _isLoading = false;
        _isEditMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invoice updated successfully")),
      );
    } catch (e) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating invoice: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard while arguments load
    if (_invoice == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Invoice'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _invoice!.invoiceType == 'sales' ? Colors.blue.shade700 : Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _invoice!.invoiceNumber,
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_invoice!.invoiceType.toUpperCase()} INVOICE',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: Icon(Icons.cloud_off, color: Colors.white70, size: 20),
            ),
          if (_isEditMode)
            Container(
              margin: EdgeInsets.only(right: 2.w),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _invoice!.invoiceType == 'sales' ? Colors.blue.shade700 : Colors.green.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text("Save", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: !_isEditMode
          ? TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: FloatingActionButton(
                    onPressed: _toggleEditMode,
                    backgroundColor: _invoice!.invoiceType == 'sales' ? Colors.blue.shade600 : Colors.green.shade600,
                    child: Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Header skeleton
          Container(
            width: double.infinity,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),

          // Table skeleton
          Container(
            width: double.infinity,
            height: 25.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 3.h),

          // Summary skeleton
          Container(
            width: double.infinity,
            height: 15.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _invoice?.status.toLowerCase() == 'paid'
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: (_invoice?.status.toLowerCase() == 'paid' ? Colors.green : Colors.orange).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _invoice?.status.toLowerCase() == 'paid' ? Icons.check_circle : Icons.schedule,
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _invoice?.status.toUpperCase() ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Modified Badge (if invoice has been modified)
          if (_invoice?.modifiedFlag ?? false && _invoice?.modifiedAt != null)
            FluidAnimations.createStaggeredListAnimation(
              index: 0,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice Modified',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Modified on: ${_invoice?.modifiedAt?.day}/${_invoice?.modifiedAt?.month}/${_invoice?.modifiedAt?.year} - ${_invoice?.modifiedReason ?? 'Unknown reason'}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          SizedBox(height: 3.h),
          // Invoice Header Card with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 0,
            child: RepaintBoundary(
              child: InvoiceHeaderCardWidget(
                invoice: _invoice!,
                isEditMode: _isEditMode,
                clientNameController: _clientNameController,
                invoiceDateController: _invoiceDateController,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Items Table with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 1,
            child: RepaintBoundary(
              child: InvoiceItemsTableWidget(
                items: _isEditMode ? _editedItems : _invoice!.items.map((item) => item.toJson()).toList(),
                isEditMode: _isEditMode,
                onItemsChanged: (updatedItems) {
                  setState(() {
                    _editedItems = updatedItems;
                  });
                },
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Summary Section with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 2,
            child: InvoiceSummaryWidget(
              invoice: _invoice!,
              isEditMode: _isEditMode,
              notesController: _notesController,
              taxRateController: _taxRateController,
              editedItems: _editedItems,
            ),
          ),

          SizedBox(height: 3.h),
          
          // Payment Information Section with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 3,
            child: InvoicePaymentInfoWidget(invoice: _invoice!),
          ),
          
          SizedBox(height: 4.h),

          // WhatsApp Reminder Button (only for sales invoices with customer phone)
          if (!_isEditMode && _invoice!.invoiceType == 'sales' && 
              _invoice!.customerPhone != null && _invoice!.customerPhone!.isNotEmpty)
            WhatsAppReminderButton(
              invoice: _invoice!,
              shopName: 'Your Shop Name', // Replace with actual shop name from settings
              shopContact: '+91 9876543210', // Replace with actual shop contact from settings
            ),
            
          SizedBox(height: 2.h),
            
          // Return Goods Button
          if (!_isEditMode)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 2.h),
              child: OutlinedButton.icon(
                onPressed: () => _processReturn(),
                icon: Icon(
                  Icons.keyboard_return_rounded,
                  color: Colors.orange.shade600,
                  size: 5.w,
                ),
                label: Text(
                  'Return Goods',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.shade300, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
          // Action Buttons
          if (!_isEditMode)
            InvoiceActionButtonsWidget(
              onEdit: _toggleEditMode,
              onShare: _shareInvoice,
              onDuplicate: _duplicateInvoice,
              onMarkAsPaid: _markAsPaid,
              onDownloadPdf: _downloadPdf,
              onDelete: _deleteInvoice,
            ),

          SizedBox(height: 10.h), // Bottom padding for FAB
        ],
      ),
    );
  }
}
