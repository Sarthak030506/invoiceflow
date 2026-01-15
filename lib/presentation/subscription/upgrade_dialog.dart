import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invoiceflow/providers/subscription_provider.dart';
import 'package:invoiceflow/services/payment_service.dart';
import 'package:invoiceflow/widgets/premium_badge.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class UpgradeDialog extends StatefulWidget {
  const UpgradeDialog({super.key});

  @override
  State<UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<UpgradeDialog> {
  String _selectedPlan = 'monthly';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  void _initializePayment() {
    PaymentService.instance.initializeRazorpay(
      onPaymentSuccess: _handlePaymentSuccess,
      onPaymentError: _handlePaymentError,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);

    try {
      // Verify and upgrade subscription
      await PaymentService.instance.handlePaymentSuccess(response, _selectedPlan);

      // Refresh subscription in provider
      if (mounted) {
        await Provider.of<SubscriptionProvider>(context, listen: false).refresh();

        Navigator.pop(context); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Premium! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _startPayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await PaymentService.instance.createSubscriptionOrder(
        plan: _selectedPlan,
        userEmail: user.email ?? '',
        userPhone: user.phoneNumber ?? '',
        userName: user.displayName ?? 'User',
      );
    } catch (e) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Upgrade to',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  PremiumBadge(size: 20, text: 'PREMIUM'),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Unlock all AI-powered features',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Plan selection
              _buildPlanSelector(),

              const SizedBox(height: 24),

              // Features list
              _buildFeaturesList(),

              const SizedBox(height: 24),

              // Trial offer (if available)
              Consumer<SubscriptionProvider>(
                builder: (context, provider, _) {
                  return FutureBuilder<bool>(
                    future: provider.isTrialAvailable(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Column(
                          children: [
                            _buildTrialOffer(),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _startPayment,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Pay ${PaymentService.getPriceDisplay(_selectedPlan)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Secure payment badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Secure payment via Razorpay',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPlanOption(
            'monthly',
            'Monthly',
            '₹${PaymentService.MONTHLY_PRICE}',
            'per month',
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildPlanOption(
            'yearly',
            'Yearly',
            '₹${PaymentService.YEARLY_PRICE}',
            'per year',
            badge: 'SAVE 16%',
            subtitle: PaymentService.getYearlyPricePerMonth(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(
    String value,
    String title,
    String price,
    String period, {
    String? badge,
    String? subtitle,
  }) {
    final isSelected = _selectedPlan == value;

    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPlan,
              onChanged: (val) => setState(() => _selectedPlan = val!),
              activeColor: const Color(0xFFFFD700),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFFFFD700) : Colors.black,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium includes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('Unlimited OCR scanning'),
          _buildFeatureItem('AI Business Insights'),
          _buildFeatureItem('Payment Risk Prediction'),
          _buildFeatureItem('Inventory Forecasting'),
          _buildFeatureItem('Priority Support'),
          _buildFeatureItem('All future AI features'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTrialOffer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Start with a 7-day free trial!',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // PaymentService cleanup is handled globally
    super.dispose();
  }
}
