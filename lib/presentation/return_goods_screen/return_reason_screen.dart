import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/invoice_model.dart';
import 'return_summary_screen.dart';

class ReturnReasonScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final Map<String, int> returnQuantities;
  final double totalReturnValue;

  const ReturnReasonScreen({
    Key? key,
    required this.invoice,
    required this.returnQuantities,
    required this.totalReturnValue,
  }) : super(key: key);

  @override
  State<ReturnReasonScreen> createState() => _ReturnReasonScreenState();
}

class _ReturnReasonScreenState extends State<ReturnReasonScreen> {
  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  final List<Map<String, dynamic>> returnReasons = [
    {'label': 'Damaged Goods', 'color': Colors.red},
    {'label': 'Wrong Item Delivered', 'color': Colors.orange},
    {'label': 'Customer Changed Mind', 'color': Colors.blue},
    {'label': 'Defective', 'color': Colors.purple},
    {'label': 'Excess Stock', 'color': Colors.green},
    {'label': 'Other', 'color': Colors.grey},
  ];

  bool get isFormValid {
    if (selectedReason == null) return false;
    if (selectedReason == 'Other' && customReasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    customReasonController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Return Reason'),
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
                  'Step 2: Specify Return Reason',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Select reason and add details for the return',
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
                  // Return Summary
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        ...widget.returnQuantities.entries
                            .where((entry) => entry.value > 0)
                            .map((entry) {
                          final item = widget.invoice.items.firstWhere(
                            (item) => item.name == entry.key,
                          );
                          return Padding(
                            padding: EdgeInsets.only(bottom: 0.5.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${entry.key} × ${entry.value}'),
                                Text('₹${(item.price * entry.value).toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }).toList(),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Return Value:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${widget.totalReturnValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Reason Selection
                  Text(
                    'Return Reason *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: returnReasons.map((reason) {
                      final isSelected = selectedReason == reason['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedReason = reason['label'];
                            if (reason['label'] != 'Other') {
                              customReasonController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? reason['color'].withOpacity(0.2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected 
                                  ? reason['color']
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: reason['color'],
                                  size: 4.w,
                                ),
                              if (isSelected) SizedBox(width: 1.w),
                              Text(
                                reason['label'],
                                style: TextStyle(
                                  color: isSelected 
                                      ? reason['color']
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Custom Reason Field
                  if (selectedReason == 'Other') ...[
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Please specify reason *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.orange.shade600),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],

                  SizedBox(height: 3.h),

                  // Additional Notes
                  Text(
                    'Additional Notes (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'Add any additional details about the return...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange.shade600),
                      ),
                    ),
                    maxLines: 3,
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFormValid ? () {
                    final reason = selectedReason == 'Other' 
                        ? customReasonController.text.trim()
                        : selectedReason!;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReturnSummaryScreen(
                          invoice: widget.invoice,
                          returnQuantities: widget.returnQuantities,
                          totalReturnValue: widget.totalReturnValue,
                          returnReason: reason,
                          notes: notesController.text.trim().isNotEmpty 
                              ? notesController.text.trim() 
                              : null,
                        ),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}