import 'package:flutter/material.dart';
import 'package:invoiceflow/models/payment_risk_model.dart';
import 'package:invoiceflow/services/ai/payment_risk_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentRiskTab extends StatefulWidget {
  const PaymentRiskTab({super.key});

  @override
  State<PaymentRiskTab> createState() => _PaymentRiskTabState();
}

class _PaymentRiskTabState extends State<PaymentRiskTab> {
  bool _isLoading = true;
  PaymentRiskReport? _report;
  String? _error;
  RiskLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    _loadRiskData();
  }

  Future<void> _loadRiskData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await PaymentRiskService.instance.generateRiskReport();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load risk data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing payment patterns...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadRiskData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_report == null || _report!.customerRisks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'No payment risks detected!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All customers are up to date',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRiskData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const SizedBox(height: 16),
          ..._getFilteredCustomers().map((customer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCustomerRiskCard(customer),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Total at Risk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '₹${_report!.totalAtRisk.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRiskCountBadge(
                  'Critical',
                  _report!.criticalCount,
                  Colors.red,
                ),
                const SizedBox(width: 8),
                _buildRiskCountBadge(
                  'High',
                  _report!.highRiskCount,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildRiskCountBadge(
                  'Medium',
                  _report!.mediumRiskCount,
                  Colors.amber,
                ),
                const SizedBox(width: 8),
                _buildRiskCountBadge(
                  'Low',
                  _report!.lowRiskCount,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCountBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Critical', RiskLevel.critical),
          const SizedBox(width: 8),
          _buildFilterChip('High', RiskLevel.high),
          const SizedBox(width: 8),
          _buildFilterChip('Medium', RiskLevel.medium),
          const SizedBox(width: 8),
          _buildFilterChip('Low', RiskLevel.low),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RiskLevel? level) {
    final isSelected = _filterLevel == level;
    Color chipColor;

    switch (level) {
      case RiskLevel.critical:
        chipColor = Colors.red;
        break;
      case RiskLevel.high:
        chipColor = Colors.orange;
        break;
      case RiskLevel.medium:
        chipColor = Colors.amber;
        break;
      case RiskLevel.low:
        chipColor = Colors.green;
        break;
      case null:
        chipColor = Colors.blue;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterLevel = selected ? level : null;
        });
      },
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<PaymentRiskScore> _getFilteredCustomers() {
    if (_filterLevel == null) {
      return _report!.sortedByRisk;
    }
    return _report!.customerRisks
        .where((c) => c.riskLevel == _filterLevel)
        .toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  }

  Widget _buildCustomerRiskCard(PaymentRiskScore customer) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRiskScoreCircle(customer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        customer.customerPhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${customer.totalOutstanding.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Outstanding',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Risk factors
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customer.riskFactors.map((factor) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    factor.description,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
            if (customer.recommendedAction != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRiskColor(customer.riskLevel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 16,
                      color: _getRiskColor(customer.riskLevel),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer.recommendedAction!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getRiskColor(customer.riskLevel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(customer.customerPhone),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _sendWhatsAppReminder(customer),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Remind'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCircle(PaymentRiskScore customer) {
    final color = _getRiskColor(customer.riskLevel);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Text(
          '${customer.riskScore.toInt()}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.amber.shade700;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsAppReminder(PaymentRiskScore customer) async {
    final phone = customer.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = phone.length == 10 ? '91$phone' : phone;

    final message = Uri.encodeComponent(
      'Hi ${customer.customerName},\n\n'
      'This is a friendly reminder about your pending payment of '
      '₹${customer.totalOutstanding.toStringAsFixed(0)}.\n\n'
      'Please clear the dues at your earliest convenience.\n\n'
      'Thank you!',
    );

    final uri = Uri.parse('https://wa.me/$formattedPhone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
