import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../../models/invoice_model.dart';
import '../../models/return_model.dart';
import '../../services/return_service.dart';

class ReturnSummaryScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final Map<String, int> returnQuantities;
  final double totalReturnValue;
  final String returnReason;
  final String? notes;

  const ReturnSummaryScreen({
    Key? key,
    required this.invoice,
    required this.returnQuantities,
    required this.totalReturnValue,
    required this.returnReason,
    this.notes,
  }) : super(key: key);

  @override
  State<ReturnSummaryScreen> createState() => _ReturnSummaryScreenState();
}

class _ReturnSummaryScreenState extends State<ReturnSummaryScreen> {
  late TextEditingController refundController;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    refundController = TextEditingController(
      text: widget.totalReturnValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    refundController.dispose();
    super.dispose();
  }

  double get refundAmount => double.tryParse(refundController.text) ?? 0.0;

  Future<void> _processReturn() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Generate return number
      final returnNumber = await ReturnService.instance.generateReturnNumber(widget.invoice.invoiceType);

      // Create return items list
      final returnItems = <ReturnItem>[];
      for (final entry in widget.returnQuantities.entries) {
        if (entry.value > 0) {
          final item = widget.invoice.items.firstWhere((i) => i.name == entry.key);
          returnItems.add(ReturnItem(
            name: item.name,
            quantity: entry.value,
            price: item.price,
            totalValue: item.price * entry.value,
          ));
        }
      }

      // Create return model
      final returnModel = ReturnModel(
        id: const Uuid().v4(),
        returnNumber: returnNumber,
        invoiceId: widget.invoice.id,
        invoiceNumber: widget.invoice.invoiceNumber,
        customerName: widget.invoice.clientName,
        customerId: widget.invoice.customerId,
        customerPhone: widget.invoice.customerPhone,
        invoiceDate: widget.invoice.date,
        returnDate: DateTime.now(),
        returnType: widget.invoice.invoiceType,
        items: returnItems,
        returnReason: widget.returnReason,
        notes: widget.notes,
        totalReturnValue: widget.totalReturnValue,
        refundAmount: refundAmount,
        isApplied: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save return to database
      await ReturnService.instance.createReturn(returnModel);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to invoice detail
      Navigator.of(context).popUntil((route) {
        return route.settings.name == '/invoice-detail-screen' || route.isFirst;
      });

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing return: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSalesReturn = widget.invoice.invoiceType == 'sales';
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Return Summary'),
            Text(
              'Invoice #${widget.invoice.invoiceNumber}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3: Financial & Stock Impact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Review the impact before confirming return',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Return Details
                  _buildSectionCard(
                    'Return Details',
                    [
                      _buildDetailRow('Return Reason:', widget.returnReason),
                      if (widget.notes?.isNotEmpty == true)
                        _buildDetailRow('Notes:', widget.notes!),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Items Being Returned
                  _buildSectionCard(
                    'Items Being Returned',
                    widget.returnQuantities.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) {
                      final item = widget.invoice.items.firstWhere(
                        (item) => item.name == entry.key,
                      );
                      return _buildItemRow(
                        item.name,
                        'Qty: ${entry.value}',
                        '₹${(item.price * entry.value).toStringAsFixed(2)}',
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Financial Impact
                  _buildSectionCard(
                    'Financial Impact',
                    [
                      _buildDetailRow(
                        'Original ${isSalesReturn ? 'Sales' : 'Purchase'} ${isSalesReturn ? 'Value' : 'Cost'}:',
                        '₹${widget.invoice.total.toStringAsFixed(2)}',
                        valueColor: Colors.grey.shade700,
                        isBold: true,
                      ),
                      _buildDetailRow(
                        'Value of Returned Goods:',
                        '₹${widget.totalReturnValue.toStringAsFixed(2)}',
                        valueColor: Colors.red.shade600,
                        isBold: true,
                      ),
                      if (isSalesReturn) ...[
                        SizedBox(height: 2.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSalesReturn ? 'Amount Refunded:' : 'Amount Expected from Distributor:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            TextFormField(
                              controller: refundController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '₹',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.orange.shade600),
                                ),
                                hintText: isSalesReturn ? 'Enter refund amount' : 'Enter expected amount',
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Stock Impact
                  _buildSectionCard(
                    'Inventory Impact',
                    [
                      Row(
                        children: [
                          Icon(
                            isSalesReturn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                            color: isSalesReturn ? Colors.green.shade600 : Colors.red.shade600,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Items ${isSalesReturn ? 'Added Back to' : 'Removed From'} Stock:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      ...widget.returnQuantities.entries
                          .where((entry) => entry.value > 0)
                          .map((entry) => Padding(
                                padding: EdgeInsets.only(left: 4.w, top: 0.5.h),
                                child: _buildDetailRow(
                                  '• ${entry.key}',
                                  '${isSalesReturn ? '+' : '-'}${entry.value}',
                                  valueColor: isSalesReturn ? Colors.green.shade600 : Colors.red.shade600,
                                ),
                              )),
                    ],
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (isSalesReturn && refundAmount != widget.totalReturnValue)
                    Container(
                      padding: EdgeInsets.all(3.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Refund amount differs from return value by ₹${(refundAmount - widget.totalReturnValue).abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Confirm Return',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 2.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, String quantity, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name),
          ),
          Expanded(
            child: Text(
              quantity,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}