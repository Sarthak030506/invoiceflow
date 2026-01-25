import 'package:flutter/material.dart';
import 'package:invoiceflow/widgets/premium_badge.dart';

class FeatureGateOverlay extends StatelessWidget {
  final String featureName;
  final String description;
  final List<String> benefits;
  final VoidCallback onUpgrade;
  final VoidCallback? onCancel;

  const FeatureGateOverlay({
    super.key,
    required this.featureName,
    required this.description,
    required this.benefits,
    required this.onUpgrade,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Feature name with badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  featureName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                const PremiumBadge(size: 14, text: 'PRO'),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            const SizedBox(height: 24),

            // Benefits list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: benefits.map((benefit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: onCancel != null ? 1 : 2,
                  child: FilledButton(
                    onPressed: onUpgrade,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Upgrade to Premium'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show feature gate overlay
  static void show({
    required BuildContext context,
    required String featureName,
    required String description,
    required List<String> benefits,
    required VoidCallback onUpgrade,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => FeatureGateOverlay(
        featureName: featureName,
        description: description,
        benefits: benefits,
        onUpgrade: onUpgrade,
        onCancel: onCancel ?? () => Navigator.pop(context),
      ),
    );
  }

  /// Show OCR feature gate
  static void showOCRGate(
    BuildContext context,
    VoidCallback onUpgrade, {
    bool limitReached = false,
  }) {
    show(
      context: context,
      featureName: 'Invoice OCR Scanner',
      description: limitReached
          ? 'You\'ve used all 5 free scans this month. Upgrade to Premium for unlimited scanning!'
          : 'Scan receipts instantly and auto-fill invoices with AI-powered OCR.',
      benefits: [
        'Unlimited receipt scanning',
        'Auto-fill invoice details',
        'Fuzzy item matching',
        'Save 5 minutes per invoice',
      ],
      onUpgrade: onUpgrade,
    );
  }

  /// Show AI Insights feature gate
  static void showInsightsGate(
    BuildContext context,
    VoidCallback onUpgrade,
  ) {
    show(
      context: context,
      featureName: 'AI Business Insights',
      description:
          'Get personalized recommendations and grow your business with AI-powered insights.',
      benefits: [
        'Daily business insights',
        'Revenue optimization tips',
        'Anomaly detection',
        'Action recommendations',
      ],
      onUpgrade: onUpgrade,
    );
  }

  /// Show Payment Risk feature gate
  static void showRiskGate(
    BuildContext context,
    VoidCallback onUpgrade,
  ) {
    show(
      context: context,
      featureName: 'Payment Risk Prediction',
      description:
          'Prioritize collections and improve cash flow with AI-powered risk scoring.',
      benefits: [
        'Predict payment delays',
        'Prioritized follow-up list',
        'Smart WhatsApp reminders',
        'Improve collection rate',
      ],
      onUpgrade: onUpgrade,
    );
  }

  /// Show Inventory Forecast feature gate
  static void showForecastGate(
    BuildContext context,
    VoidCallback onUpgrade,
  ) {
    show(
      context: context,
      featureName: 'Inventory Forecasting',
      description:
          'Prevent stockouts and reduce costs with AI-powered demand prediction.',
      benefits: [
        '30-day demand forecast',
        'Dynamic reorder alerts',
        'Dead stock identification',
        'Optimize inventory costs',
      ],
      onUpgrade: onUpgrade,
    );
  }
}
