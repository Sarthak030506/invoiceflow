import 'package:flutter/material.dart';

class ComingSoonDialog extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const ComingSoonDialog({
    super.key,
    required this.featureName,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.blue[700],
              ),
            ),

            const SizedBox(height: 20),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Feature name
            Text(
              featureName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'re working hard to bring this feature to you soon!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show AI Insights coming soon
  static void showInsightsComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ComingSoonDialog(
        featureName: 'AI Business Insights',
        description:
            'Get personalized recommendations and smart insights to grow your business with AI-powered analytics.',
        icon: Icons.lightbulb_outline,
      ),
    );
  }

  /// Show Payment Risk coming soon
  static void showRiskComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ComingSoonDialog(
        featureName: 'Payment Risk Prediction',
        description:
            'Prioritize collections and improve cash flow with AI-powered payment risk scoring and smart follow-ups.',
        icon: Icons.warning_amber,
      ),
    );
  }

  /// Show Inventory Forecast coming soon
  static void showForecastComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ComingSoonDialog(
        featureName: 'Inventory Forecasting',
        description:
            'Prevent stockouts and reduce costs with AI-powered demand prediction and dynamic reorder alerts.',
        icon: Icons.trending_up,
      ),
    );
  }

  /// Generic coming soon dialog
  static void show(BuildContext context, {
    required String featureName,
    required String description,
    IconData icon = Icons.stars,
  }) {
    showDialog(
      context: context,
      builder: (context) => ComingSoonDialog(
        featureName: featureName,
        description: description,
        icon: icon,
      ),
    );
  }
}
