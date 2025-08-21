import 'package:flutter/material.dart';

class CategoryRevenueModal extends StatelessWidget {
  const CategoryRevenueModal({Key? key}) : super(key: key);

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
                Icon(Icons.category, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Category Revenue',
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
                _buildCategoryCard('Groceries', '₹3,200', '38%', Colors.green),
                _buildCategoryCard('Beverages', '₹1,850', '22%', Colors.blue),
                _buildCategoryCard('Snacks', '₹1,400', '17%', Colors.orange),
                _buildCategoryCard('Personal Care', '₹950', '11%', Colors.purple),
                _buildCategoryCard('Household', '₹750', '9%', Colors.teal),
                _buildCategoryCard('Others', '₹300', '3%', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, String revenue, String percentage, Color color) {
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
            child: Icon(Icons.category, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage of total revenue',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getSubtitleColor(color),
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextColor(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(Color color) {
    if (color == Colors.green) return Colors.green.shade800;
    if (color == Colors.blue) return Colors.blue.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.purple) return Colors.purple.shade800;
    if (color == Colors.teal) return Colors.teal.shade800;
    return Colors.grey.shade800;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.green) return Colors.green.shade600;
    if (color == Colors.blue) return Colors.blue.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.purple) return Colors.purple.shade600;
    if (color == Colors.teal) return Colors.teal.shade600;
    return Colors.grey.shade600;
  }
}