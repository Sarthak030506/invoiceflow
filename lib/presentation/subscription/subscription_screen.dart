import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invoiceflow/providers/subscription_provider.dart';
import 'package:invoiceflow/models/subscription_model.dart';
import 'package:invoiceflow/widgets/premium_badge.dart';
import 'package:invoiceflow/widgets/coming_soon_dialog.dart';
import 'package:invoiceflow/presentation/subscription/upgrade_dialog.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.subscription == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscription = provider.subscription;
          if (subscription == null) {
            return const Center(child: Text('Failed to load subscription'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current plan card
                _buildCurrentPlanCard(context, subscription, provider),

                const SizedBox(height: 24),

                // Usage stats (if free tier)
                if (subscription.tier == SubscriptionTier.free) ...[
                  _buildUsageStats(context, subscription),
                  const SizedBox(height: 24),
                ],

                // Trial banner (if in trial)
                if (subscription.isTrial) ...[
                  _buildTrialBanner(context, provider),
                  const SizedBox(height: 24),
                ],

                // Features comparison
                _buildFeaturesComparison(context, subscription),

                const SizedBox(height: 24),

                // Upgrade button (if not premium)
                if (!provider.isPremium) ...[
                  _buildUpgradeButton(context, provider),
                ],

                // Manage subscription (if premium)
                if (provider.isPremium && !subscription.isTrial) ...[
                  _buildManageSubscription(context, subscription, provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    BuildContext context,
    SubscriptionModel subscription,
    SubscriptionProvider provider,
  ) {
    final isPremium = provider.isPremium;
    final isTrial = subscription.isTrial;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Plan',
                  style: TextStyle(
                    fontSize: 16,
                    color: isPremium ? Colors.white : Colors.grey[600],
                  ),
                ),
                if (isPremium)
                  const PremiumBadge(showText: true, text: 'PREMIUM'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isPremium ? 'Premium Plan' : 'Free Plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isPremium ? Colors.white : Colors.black,
              ),
            ),
            if (isTrial) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${provider.trialDaysRemaining} days left in trial',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (isPremium && !isTrial && subscription.endDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Renews on ${_formatDate(subscription.endDate!)}',
                style: TextStyle(
                  color: isPremium ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats(
    BuildContext context,
    SubscriptionModel subscription,
  ) {
    final ocrScans = subscription.features.ocrScansRemaining;
    final ocrLimit = subscription.usageLimits.ocrScansPerMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Usage',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('OCR Scans'),
                    Text(
                      '$ocrScans / $ocrLimit remaining',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ocrScans > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ocrScans / ocrLimit,
                  backgroundColor: Colors.grey[200],
                  color: ocrScans > 2 ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialBanner(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Trial Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoying Premium? Upgrade before trial ends to keep all features!',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesComparison(
    BuildContext context,
    SubscriptionModel subscription,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildFeatureRow('Invoice Management', true, true),
              _buildFeatureRow('Inventory Tracking', true, true),
              _buildFeatureRow('Customer Management', true, true),
              _buildFeatureRow('Analytics Dashboard', true, true),
              const Divider(),
              _buildFeatureRow(
                'OCR Scanning',
                subscription.tier == SubscriptionTier.free,
                true,
                freeDetail: '5 scans/month',
                premiumDetail: 'Unlimited',
              ),
              _buildFeatureRow('AI Business Insights', false, true),
              _buildFeatureRow('Payment Risk Prediction', false, true),
              _buildFeatureRow('Inventory Forecasting', false, true),
              _buildFeatureRow('Priority Support', false, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
    String feature,
    bool free,
    bool premium, {
    String? freeDetail,
    String? premiumDetail,
    bool comingSoon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: Text(feature)),
                if (comingSoon) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SOON',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (free)
                  Icon(Icons.check, color: Colors.green[600], size: 20)
                else
                  Icon(Icons.close, color: Colors.grey[400], size: 20),
                if (freeDetail != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    freeDetail,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (premium)
                  const Icon(Icons.check, color: Color(0xFFFFD700), size: 20)
                else
                  Icon(Icons.close, color: Colors.grey[400], size: 20),
                if (premiumDetail != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    premiumDetail,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _showUpgradeDialog(context),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
        ),
        child: const Text(
          'Upgrade to Premium',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildManageSubscription(
    BuildContext context,
    SubscriptionModel subscription,
    SubscriptionProvider provider,
  ) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.receipt),
          title: const Text('Subscription Details'),
          subtitle: Text('Plan ID: ${subscription.subscriptionId ?? "N/A"}'),
        ),
        if (subscription.status != SubscriptionStatus.cancelled)
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancel Subscription'),
            subtitle: const Text('Downgrade to free at end of period'),
            onTap: () => _showCancelDialog(context, provider),
          ),
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeDialog(),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'Your Premium features will remain active until the end of your billing period. After that, your account will be downgraded to the Free plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Premium'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.cancelSubscription();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Subscription cancelled successfully'
                          : 'Failed to cancel subscription',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
