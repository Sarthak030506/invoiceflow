import 'package:flutter/material.dart';
import 'package:invoiceflow/models/ai_insight_model.dart';
import 'package:invoiceflow/services/ai/business_insights_service.dart';

class BusinessInsightsTab extends StatefulWidget {
  const BusinessInsightsTab({super.key});

  @override
  State<BusinessInsightsTab> createState() => _BusinessInsightsTabState();
}

class _BusinessInsightsTabState extends State<BusinessInsightsTab> {
  bool _isLoading = true;
  BusinessInsightsReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await BusinessInsightsService.instance.generateInsights();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load insights: $e';
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
            Text('Analyzing your business data...'),
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
              onPressed: _loadInsights,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_report == null || _report!.insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No insights available yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create more invoices to generate insights',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          ..._report!.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInsightCard(insight),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildSummaryItem(
              '${_report!.totalInsights}',
              'Total Insights',
              Icons.lightbulb,
              Colors.blue,
            ),
            _buildDivider(),
            _buildSummaryItem(
              '${_report!.highPriorityCount}',
              'High Priority',
              Icons.priority_high,
              Colors.red,
            ),
            _buildDivider(),
            _buildSummaryItem(
              _formatTime(_report!.generatedAt),
              'Updated',
              Icons.access_time,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: insight.actionText != null
            ? () => _handleInsightAction(insight)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildInsightIcon(insight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildCategoryChip(insight.category),
                      ],
                    ),
                  ),
                  _buildPriorityIndicator(insight.priority),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              if (insight.changePercent != null) ...[
                const SizedBox(height: 12),
                _buildChangeIndicator(insight),
              ],
              if (insight.actionText != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _handleInsightAction(insight),
                      child: Text(insight.actionText!),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightIcon(AIInsight insight) {
    IconData icon;
    Color color;

    switch (insight.type) {
      case InsightType.trend:
        icon = Icons.trending_up;
        color = insight.isPositive ? Colors.green : Colors.red;
        break;
      case InsightType.alert:
        icon = Icons.warning_amber;
        color = Colors.orange;
        break;
      case InsightType.opportunity:
        icon = Icons.star;
        color = Colors.amber;
        break;
      case InsightType.milestone:
        icon = Icons.emoji_events;
        color = Colors.purple;
        break;
      case InsightType.recommendation:
        icon = Icons.lightbulb;
        color = Colors.blue;
        break;
      case InsightType.general:
        icon = Icons.info;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildCategoryChip(InsightCategory category) {
    String label;
    switch (category) {
      case InsightCategory.revenue:
        label = 'Revenue';
        break;
      case InsightCategory.products:
        label = 'Products';
        break;
      case InsightCategory.customers:
        label = 'Customers';
        break;
      case InsightCategory.inventory:
        label = 'Inventory';
        break;
      case InsightCategory.payments:
        label = 'Payments';
        break;
      case InsightCategory.growth:
        label = 'Growth';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildPriorityIndicator(InsightPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case InsightPriority.high:
        color = Colors.red;
        text = 'HIGH';
        break;
      case InsightPriority.medium:
        color = Colors.orange;
        text = 'MED';
        break;
      case InsightPriority.low:
        color = Colors.green;
        text = 'LOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChangeIndicator(AIInsight insight) {
    final isPositive = insight.isPositive;
    final changePercent = insight.changePercent!;

    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: isPositive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          '${changePercent.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'vs last period',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _handleInsightAction(AIInsight insight) {
    // Navigate based on insight category
    switch (insight.category) {
      case InsightCategory.inventory:
        Navigator.pushNamed(context, '/inventory-screen');
        break;
      case InsightCategory.customers:
        Navigator.pushNamed(context, '/customers-screen');
        break;
      case InsightCategory.payments:
        Navigator.pushNamed(context, '/invoices-list-screen');
        break;
      default:
        Navigator.pushNamed(context, '/analytics-screen');
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
