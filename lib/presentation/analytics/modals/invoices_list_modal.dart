import 'package:flutter/material.dart';

class InvoicesListModal extends StatelessWidget {
  Color _getColorShade(Color color, int shade) {
    if (color is MaterialColor) {
      return color[shade] ?? color;
    }
    return color;
  }
  final String invoiceType;

  const InvoicesListModal({Key? key, required this.invoiceType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSales = invoiceType == 'sales';
    final title = isSales ? 'Sales Invoices' : 'Purchase Invoices';
    final icon = isSales ? Icons.receipt : Icons.shopping_cart;
    final color = isSales ? Colors.blue : Colors.green;

    return Container(
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
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isSales) ..._buildSalesInvoices() else ..._buildPurchaseInvoices(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSalesInvoices() {
    return [
      _buildInvoiceCard('INV-2024-001', '₹2,450', 'Today, 2:30 PM', Colors.blue),
      _buildInvoiceCard('INV-2024-002', '₹1,890', 'Today, 11:15 AM', Colors.blue),
      _buildInvoiceCard('INV-2024-003', '₹3,200', 'Yesterday, 4:45 PM', Colors.blue),
      _buildInvoiceCard('INV-2024-004', '₹950', 'Yesterday, 10:20 AM', Colors.blue),
      _buildInvoiceCard('INV-2024-005', '₹5,670', '2 days ago', Colors.blue),
      _buildInvoiceCard('INV-2024-006', '₹1,230', '2 days ago', Colors.blue),
      _buildInvoiceCard('INV-2024-007', '₹2,890', '3 days ago', Colors.blue),
    ];
  }

  List<Widget> _buildPurchaseInvoices() {
    return [
      _buildInvoiceCard('PUR-2024-001', '₹15,000', 'Today, 9:00 AM', Colors.green),
      _buildInvoiceCard('PUR-2024-002', '₹8,500', 'Yesterday, 3:30 PM', Colors.green),
      _buildInvoiceCard('PUR-2024-003', '₹22,000', '2 days ago', Colors.green),
      _buildInvoiceCard('PUR-2024-004', '₹12,300', '3 days ago', Colors.green),
      _buildInvoiceCard('PUR-2024-005', '₹18,750', '4 days ago', Colors.green),
      _buildInvoiceCard('PUR-2024-006', '₹9,200', '5 days ago', Colors.green),
    ];
  }

  Widget _buildInvoiceCard(String invoiceNo, String amount, String date, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              invoiceType == 'sales' ? Icons.receipt : Icons.shopping_cart,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceNo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getColorShade(color, 800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getColorShade(color, 600),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getColorShade(color, 800),
            ),
          ),
        ],
      ),
    );
  }
}