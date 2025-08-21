import 'package:flutter/material.dart';
import '../widgets/glass_modal.dart';

class CustomersDuesModal extends StatelessWidget {
  const CustomersDuesModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassModal(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Customers With Dues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                _buildCustomerCard('Rajesh Kumar', '₹12,500', '15 days overdue', Colors.red),
                _buildCustomerCard('Priya Sharma', '₹8,750', '8 days overdue', Colors.orange),
                _buildCustomerCard('Amit Singh', '₹6,200', '22 days overdue', Colors.red),
                _buildCustomerCard('Sunita Devi', '₹5,800', '5 days overdue', Colors.orange),
                _buildCustomerCard('Ravi Gupta', '₹4,950', '12 days overdue', Colors.orange),
                _buildCustomerCard('Meera Joshi', '₹3,200', '3 days overdue', Colors.green),
                _buildCustomerCard('Vikram Yadav', '₹2,800', '18 days overdue', Colors.red),
                _buildCustomerCard('Kavita Patel', '₹1,000', '2 days overdue', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(String name, String amount, String overdue, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to customer detail
      },
      child: Container(
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overdue,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSubtitleColor(color),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(color),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_forward_ios, size: 14, color: _getIconColor(color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTextColor(Color color) {
    if (color == Colors.red) return Colors.red.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.green) return Colors.green.shade800;
    return Colors.grey.shade800;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.red) return Colors.red.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.green) return Colors.green.shade600;
    return Colors.grey.shade600;
  }

  Color _getIconColor(Color color) {
    if (color == Colors.red) return Colors.red.shade400;
    if (color == Colors.orange) return Colors.orange.shade400;
    if (color == Colors.green) return Colors.green.shade400;
    return Colors.grey.shade400;
  }
}