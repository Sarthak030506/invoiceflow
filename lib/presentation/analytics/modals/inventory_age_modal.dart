import 'package:flutter/material.dart';

class InventoryAgeModal extends StatelessWidget {
  const InventoryAgeModal({Key? key}) : super(key: key);

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
                Icon(Icons.hourglass_empty, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Inventory Age Analysis',
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
                _buildAgeCard('Unsold Item', '45 Days', Colors.red.shade100, Colors.red),
                _buildAgeCard('Rice Bag 25kg', '38 Days', Colors.orange.shade100, Colors.orange),
                _buildAgeCard('Wheat Flour 10kg', '32 Days', Colors.orange.shade100, Colors.orange),
                _buildAgeCard('Sugar 1kg', '28 Days', Colors.yellow.shade100, Colors.amber),
                _buildAgeCard('Cooking Oil 1L', '25 Days', Colors.yellow.shade100, Colors.amber),
                _buildAgeCard('Tea Powder 250g', '22 Days', Colors.green.shade100, Colors.green),
                _buildAgeCard('Salt 1kg', '18 Days', Colors.green.shade100, Colors.green),
                _buildAgeCard('Turmeric Powder', '15 Days', Colors.green.shade100, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeCard(String itemName, String age, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(textColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last sold $age ago',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getSubtitleColor(textColor),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              age,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(Color color) {
    if (color == Colors.red) return Colors.red.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.amber) return Colors.amber.shade800;
    if (color == Colors.green) return Colors.green.shade800;
    return Colors.grey.shade800;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.red) return Colors.red.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.amber) return Colors.amber.shade600;
    if (color == Colors.green) return Colors.green.shade600;
    return Colors.grey.shade600;
  }
}