import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invoiceflow/providers/subscription_provider.dart';
import 'package:invoiceflow/presentation/ai_hub/tabs/business_insights_tab.dart';
import 'package:invoiceflow/presentation/ai_hub/tabs/payment_risk_tab.dart';
import 'package:invoiceflow/presentation/ai_hub/tabs/inventory_forecast_tab.dart';

class AIHubScreen extends StatefulWidget {
  final int initialTab;

  const AIHubScreen({super.key, this.initialTab = 0});

  @override
  State<AIHubScreen> createState() => _AIHubScreenState();
}

class _AIHubScreenState extends State<AIHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        final isPremium = subscriptionProvider.isPremium;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 24),
                const SizedBox(width: 8),
                const Text('AI Hub'),
                if (isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.lightbulb_outline),
                  text: 'Insights',
                ),
                Tab(
                  icon: Icon(Icons.warning_amber),
                  text: 'Risk',
                ),
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: 'Forecast',
                ),
              ],
            ),
          ),
          body: isPremium
              ? TabBarView(
                  controller: _tabController,
                  children: const [
                    BusinessInsightsTab(),
                    PaymentRiskTab(),
                    InventoryForecastTab(),
                  ],
                )
              : _buildUpgradePrompt(context),
        );
      },
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock AI-powered insights, payment risk prediction, and inventory forecasting with Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/subscription'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.lightbulb_outline, 'text': 'AI Business Insights'},
      {'icon': Icons.warning_amber, 'text': 'Payment Risk Prediction'},
      {'icon': Icons.trending_up, 'text': 'Inventory Forecasting'},
      {'icon': Icons.camera_alt, 'text': 'Unlimited OCR Scans'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                feature['text'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 20,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
