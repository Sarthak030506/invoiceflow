import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
import './choose_items_invoice_screen.dart';

class InvoiceTypeSelectionScreen extends StatefulWidget {
  const InvoiceTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceTypeSelectionScreen> createState() => _InvoiceTypeSelectionScreenState();
}

class _InvoiceTypeSelectionScreenState extends State<InvoiceTypeSelectionScreen> {
  final InvoiceService _invoiceService = InvoiceService.instance;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Invoice Type'),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What type of invoice do you want to create?',
              style: AppTheme.lightTheme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            _buildInvoiceTypeButton(
              context,
              'Sales Invoice',
              'For invoices when selling items to customers',
              'sales',
              Colors.blue.shade100,
              Icons.shopping_cart_outlined,
            ),
            SizedBox(height: 3.h),
            _buildInvoiceTypeButton(
              context,
              'Purchase Invoice',
              'For invoices when buying stock to update inventory',
              'purchase',
              Colors.green.shade100,
              Icons.inventory_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceTypeButton(
    BuildContext context,
    String title,
    String subtitle,
    String invoiceType,
    Color backgroundColor,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push<InvoiceModel>(
          context,
          MaterialPageRoute(
            builder: (context) => ChooseItemsInvoiceScreen(invoiceType: invoiceType),
          ),
        ).then((invoice) async {
          if (invoice != null) {
            try {
              // Notify parent screen about the new invoice
              Navigator.pop(context, invoice);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 10.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    subtitle,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}