import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import 'package:flutter/services.dart';

import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/invoice_service.dart';
import '../../services/edit_invoice_service.dart';
import '../../services/pdf_service.dart';
import './widgets/invoice_action_buttons_widget.dart';
import './widgets/invoice_header_card_widget.dart';
import './widgets/invoice_items_table_widget.dart';
import './widgets/invoice_payment_info_widget.dart';
import './widgets/invoice_revenue_widget.dart';
import './widgets/invoice_summary_widget.dart';
import './widgets/whatsapp_reminder_button.dart';
import './widgets/edit_invoice_dialog.dart';
import '../return_goods_screen/return_goods_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = false;
  bool _isOffline = false;

  InvoiceModel? _invoice;
  late InvoiceService _invoiceService;
  final PdfService _pdfService = PdfService.instance;

  // Dummy controllers for read-only mode
  final TextEditingController _dummyController1 = TextEditingController();
  final TextEditingController _dummyController2 = TextEditingController();
  final TextEditingController _dummyController3 = TextEditingController();
  final TextEditingController _dummyController4 = TextEditingController();


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
        });
      }
    } catch (e) {
      // Handle error silently or show a subtle notification
      print('Error refreshing invoice data: $e');
    }
  }
  
  @override
  void dispose() {
    _dummyController1.dispose();
    _dummyController2.dispose();
    _dummyController3.dispose();
    _dummyController4.dispose();
    super.dispose();
  }

  Future<void> _shareInvoice() async {
    if (_invoice == null) return;

    HapticFeedback.mediumImpact();

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate and share PDF
      await _pdfService.shareInvoicePdf(_invoice!);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      FeedbackAnimations.showSuccess(
        context,
        message: 'PDF shared successfully',
      );
      HapticFeedbackUtil.success();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      FeedbackAnimations.showError(
        context,
        message: 'Failed to share PDF: ${e.toString()}',
      );
      HapticFeedbackUtil.error();
    }
  }

  Future<void> _markAsPaid() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            SizedBox(width: 2.w),
            Text('Mark as Paid?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will update the invoice to:'),
            SizedBox(height: 1.h),
            Text('• Status: Paid in Full'),
            Text('• Amount Paid: ₹${_invoice!.adjustedTotal.toStringAsFixed(2)}'),
            SizedBox(height: 1.h),
            Text('Are you sure?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

      if (!mounted) return;

      setState(() {
        _invoice = updatedInvoice;
        _isLoading = false;
      });

      FeedbackAnimations.showSuccess(
        context,
        message: 'Invoice marked as paid successfully',
      );
      HapticFeedbackUtil.success();
    } catch (e) {
      if (!mounted) return;

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

  Future<void> _downloadPdf() async {
    if (_invoice == null) return;

    HapticFeedbackUtil.trigger();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 2.h),
              Text('Downloading PDF...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Generate and download PDF
      final filePath = await _pdfService.downloadInvoicePdf(_invoice!);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show success feedback with file path
      FeedbackAnimations.showSuccess(
        context,
        message: 'PDF downloaded successfully',
      );
      HapticFeedbackUtil.success();

      // Optionally show a snackbar with the file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: $filePath'),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error feedback
      FeedbackAnimations.showError(
        context,
        message: 'Failed to download PDF: ${e.toString()}',
      );
      HapticFeedbackUtil.error();
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

  void _showEditInvoiceDialog() {
    if (_invoice == null) return;

    showDialog(
      context: context,
      builder: (context) => EditInvoiceDialog(
        invoice: _invoice!,
        onInvoiceUpdated: (updatedInvoice) {
          setState(() {
            _invoice = updatedInvoice;
          });
        },
      ),
    );
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
          // Edit Invoice Button
          if (_invoice!.status.toLowerCase() != 'cancelled')
            IconButton(
              onPressed: _showEditInvoiceDialog,
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit Invoice',
            ),
          if (_isOffline)
            Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: Icon(Icons.cloud_off, color: Colors.white70, size: 20),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
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
            constraints: BoxConstraints(minHeight: 15.h, maxHeight: 22.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 2.h),

          // Table skeleton
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 20.h, maxHeight: 28.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(height: 2.h),

          // Summary skeleton
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 12.h, maxHeight: 18.h),
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
                isEditMode: false,
                clientNameController: _dummyController1,
                invoiceDateController: _dummyController2,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Items Table with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 1,
            child: RepaintBoundary(
              child: InvoiceItemsTableWidget(
                items: _invoice!.items.map((item) => item.toJson()).toList(),
                isEditMode: false,
                onItemsChanged: (items) {}, // Dummy callback
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Summary Section with animation
          FluidAnimations.createStaggeredListAnimation(
            index: 2,
            child: InvoiceSummaryWidget(
              invoice: _invoice!,
              isEditMode: false,
              notesController: _dummyController3,
              taxRateController: _dummyController4,
              editedItems: [],
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
          if (_invoice!.invoiceType == 'sales' &&
              _invoice!.customerPhone != null && _invoice!.customerPhone!.isNotEmpty)
            WhatsAppReminderButton(
              invoice: _invoice!,
              shopName: 'Your Shop Name', // Replace with actual shop name from settings
              shopContact: '+91 9876543210', // Replace with actual shop contact from settings
            ),

          SizedBox(height: 2.h),

          // Return Goods Button
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
          InvoiceActionButtonsWidget(
            onShare: _shareInvoice,
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
