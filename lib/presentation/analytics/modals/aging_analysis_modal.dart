import 'package:flutter/material.dart';

class AgingAnalysisModal extends StatelessWidget {
  const AgingAnalysisModal({Key? key}) : super(key: key);

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
                Icon(Icons.schedule, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Aging Analysis',
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
                _buildAgingCard('0-7 Days', '₹15,200', '4 customers', 'Recent dues', Colors.green),
                _buildAgingCard('8-30 Days', '₹22,800', '5 customers', 'Moderate risk', Colors.orange),
                _buildAgingCard('31-60 Days', '₹18,500', '2 customers', 'High risk', Colors.red),
                _buildAgingCard('61-90 Days', '₹12,200', '1 customer', 'Very high risk', Colors.red.shade700),
                _buildAgingCard('90+ Days', '₹5,000', '1 customer', 'Critical', Colors.red.shade900),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingCard(String period, String amount, String customers, String risk, Color color) {
    return GestureDetector(
      onTap: () {
        // Show customers in this aging bucket
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
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  period.split(' ')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$customers • $risk',
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
    if (color == Colors.green) return Colors.green.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.red) return Colors.red.shade800;
    return Colors.red.shade900;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.green) return Colors.green.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.red) return Colors.red.shade600;
    return Colors.red.shade700;
  }

  Color _getIconColor(Color color) {
    if (color == Colors.green) return Colors.green.shade400;
    if (color == Colors.orange) return Colors.orange.shade400;
    if (color == Colors.red) return Colors.red.shade400;
    return Colors.red.shade600;
  }
}