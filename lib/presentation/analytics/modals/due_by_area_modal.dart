import 'package:flutter/material.dart';

class DueByAreaModal extends StatelessWidget {
  const DueByAreaModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.location_on, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Due by Market/Area',
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
                _buildAreaCard('Main Market', '₹18,500', '5 customers', Colors.purple),
                _buildAreaCard('Gandhi Nagar', '₹12,200', '3 customers', Colors.blue),
                _buildAreaCard('Station Road', '₹8,900', '2 customers', Colors.green),
                _buildAreaCard('Civil Lines', '₹6,700', '1 customer', Colors.orange),
                _buildAreaCard('Industrial Area', '₹4,200', '1 customer', Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard(String area, String amount, String customers, Color color) {
    return GestureDetector(
      onTap: () {
        // Show customers in this area
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customers,
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
    if (color == Colors.purple) return Colors.purple.shade800;
    if (color == Colors.blue) return Colors.blue.shade800;
    if (color == Colors.green) return Colors.green.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.teal) return Colors.teal.shade800;
    return Colors.grey.shade800;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.purple) return Colors.purple.shade600;
    if (color == Colors.blue) return Colors.blue.shade600;
    if (color == Colors.green) return Colors.green.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.teal) return Colors.teal.shade600;
    return Colors.grey.shade600;
  }

  Color _getIconColor(Color color) {
    if (color == Colors.purple) return Colors.purple.shade400;
    if (color == Colors.blue) return Colors.blue.shade400;
    if (color == Colors.green) return Colors.green.shade400;
    if (color == Colors.orange) return Colors.orange.shade400;
    if (color == Colors.teal) return Colors.teal.shade400;
    return Colors.grey.shade400;
  }
}