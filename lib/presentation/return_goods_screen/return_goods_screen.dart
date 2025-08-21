import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/invoice_model.dart';
import 'return_reason_screen.dart';

class ReturnGoodsScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const ReturnGoodsScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<ReturnGoodsScreen> createState() => _ReturnGoodsScreenState();
}

class _ReturnGoodsScreenState extends State<ReturnGoodsScreen> {
  Map<String, int> returnQuantities = {};
  
  @override
  void initState() {
    super.initState();
    for (final item in widget.invoice.items) {
      returnQuantities[item.name] = 0;
    }
  }

  bool get hasSelectedItems => returnQuantities.values.any((qty) => qty > 0);
  
  double get totalReturnValue {
    double total = 0.0;
    for (final item in widget.invoice.items) {
      final returnQty = returnQuantities[item.name] ?? 0;
      total += (item.price * returnQty);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Return Goods'),
            Text(
              'Invoice #${widget.invoice.invoiceNumber}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 1: Select Items for Return',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Choose items and quantities to return',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: widget.invoice.items.length,
              itemBuilder: (context, index) {
                final item = widget.invoice.items[index];
                final returnQty = returnQuantities[item.name] ?? 0;
                final isSelected = returnQty > 0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.orange.shade600,
                                size: 5.w,
                              ),
                            if (isSelected) SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.orange.shade700 : null,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 2.h),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Original: ${item.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: returnQty > 0 ? () {
                                      setState(() {
                                        returnQuantities[item.name] = returnQty - 1;
                                      });
                                    } : null,
                                    icon: Icon(
                                      Icons.remove,
                                      color: returnQty > 0 ? Colors.orange.shade600 : Colors.grey,
                                    ),
                                  ),
                                  Container(
                                    width: 12.w,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$returnQty',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.orange.shade700 : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: returnQty < item.quantity ? () {
                                      setState(() {
                                        returnQuantities[item.name] = returnQty + 1;
                                      });
                                    } : null,
                                    icon: Icon(
                                      Icons.add,
                                      color: returnQty < item.quantity ? Colors.orange.shade600 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        if (isSelected) ...[
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Return Value:'),
                                Text(
                                  '₹${(item.price * returnQty).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (hasSelectedItems)
            Container(
              padding: EdgeInsets.all(4.w),
              color: Colors.orange.shade600,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Return Value:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${totalReturnValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReturnReasonScreen(
                                invoice: widget.invoice,
                                returnQuantities: returnQuantities,
                                totalReturnValue: totalReturnValue,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange.shade600,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                        child: Text(
                          'Continue to Next Step',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
}