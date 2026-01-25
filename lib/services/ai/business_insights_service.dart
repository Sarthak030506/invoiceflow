import 'package:flutter/foundation.dart';
import 'package:invoiceflow/models/ai_insight_model.dart';
import 'package:invoiceflow/models/invoice_model.dart';
import 'package:invoiceflow/services/firestore_service.dart';
import 'package:invoiceflow/services/inventory_service.dart';
import 'package:invoiceflow/services/customer_service.dart';

/// Service for generating AI-powered business insights
class BusinessInsightsService {
  static BusinessInsightsService? _instance;
  BusinessInsightsService._internal();

  static BusinessInsightsService get instance {
    _instance ??= BusinessInsightsService._internal();
    return _instance!;
  }

  final FirestoreService _firestoreService = FirestoreService.instance;
  final InventoryService _inventoryService = InventoryService();
  final CustomerService _customerService = CustomerService.instance;

  /// Generate comprehensive business insights report
  Future<BusinessInsightsReport> generateInsights() async {
    try {
      final insights = <AIInsight>[];

      // Get data for analysis
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));

      // Get invoices for different periods
      final currentPeriodInvoices = await _firestoreService.getInvoicesByDateRange(
        startDate: thirtyDaysAgo,
        endDate: now,
      );
      final previousPeriodInvoices = await _firestoreService.getInvoicesByDateRange(
        startDate: sixtyDaysAgo,
        endDate: thirtyDaysAgo,
      );

      // Generate various insights
      insights.addAll(await _generateRevenueInsights(
        currentPeriodInvoices,
        previousPeriodInvoices,
      ));
      insights.addAll(await _generateProductInsights(currentPeriodInvoices));
      insights.addAll(await _generateCustomerInsights());
      insights.addAll(await _generateInventoryInsights());
      insights.addAll(await _generatePaymentInsights(currentPeriodInvoices));

      // Sort by priority
      insights.sort((a, b) {
        final priorityOrder = {
          InsightPriority.high: 0,
          InsightPriority.medium: 1,
          InsightPriority.low: 2,
        };
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      });

      return BusinessInsightsReport(insights: insights);
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return BusinessInsightsReport(insights: []);
    }
  }

  /// Generate revenue-related insights
  Future<List<AIInsight>> _generateRevenueInsights(
    List<InvoiceModel> currentPeriod,
    List<InvoiceModel> previousPeriod,
  ) async {
    final insights = <AIInsight>[];

    // Filter to sales invoices only
    final currentSales = currentPeriod
        .where((i) => i.invoiceType == 'sales' && i.status != 'cancelled')
        .toList();
    final previousSales = previousPeriod
        .where((i) => i.invoiceType == 'sales' && i.status != 'cancelled')
        .toList();

    // Calculate revenue
    final currentRevenue = currentSales.fold<double>(
      0,
      (sum, inv) => sum + inv.effectiveRevenue,
    );
    final previousRevenue = previousSales.fold<double>(
      0,
      (sum, inv) => sum + inv.effectiveRevenue,
    );

    // Revenue trend insight
    if (previousRevenue > 0) {
      final changePercent =
          ((currentRevenue - previousRevenue) / previousRevenue) * 100;
      final isPositive = changePercent >= 0;

      insights.add(AIInsight(
        id: 'revenue_trend',
        type: InsightType.trend,
        category: InsightCategory.revenue,
        title: isPositive ? 'Revenue Growing' : 'Revenue Declining',
        description: isPositive
            ? 'Your revenue is up ${changePercent.abs().toStringAsFixed(1)}% compared to last month. Great job!'
            : 'Revenue is down ${changePercent.abs().toStringAsFixed(1)}% compared to last month. Consider promotional offers.',
        value: currentRevenue,
        changePercent: changePercent,
        isPositive: isPositive,
        priority: changePercent.abs() > 20
            ? InsightPriority.high
            : InsightPriority.medium,
        actionText: isPositive ? null : 'View strategies',
      ));
    }

    // Average order value insight
    if (currentSales.isNotEmpty) {
      final avgOrderValue = currentRevenue / currentSales.length;
      final previousAvg = previousSales.isNotEmpty
          ? previousRevenue / previousSales.length
          : avgOrderValue;
      final avgChange = previousAvg > 0
          ? ((avgOrderValue - previousAvg) / previousAvg) * 100
          : 0.0;

      insights.add(AIInsight(
        id: 'avg_order_value',
        type: InsightType.trend,
        category: InsightCategory.revenue,
        title: 'Average Order Value',
        description:
            'Your average order is ₹${avgOrderValue.toStringAsFixed(0)}. '
            '${avgChange >= 0 ? "Up" : "Down"} ${avgChange.abs().toStringAsFixed(1)}% from last month.',
        value: avgOrderValue,
        changePercent: avgChange,
        isPositive: avgChange >= 0,
        priority: InsightPriority.low,
      ));
    }

    // Invoice count insight
    if (currentSales.isNotEmpty) {
      insights.add(AIInsight(
        id: 'invoice_count',
        type: InsightType.milestone,
        category: InsightCategory.revenue,
        title: '${currentSales.length} Invoices This Month',
        description:
            'You created ${currentSales.length} sales invoices this month, '
            'generating ₹${currentRevenue.toStringAsFixed(0)} in revenue.',
        value: currentSales.length.toDouble(),
        isPositive: true,
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Generate product-related insights
  Future<List<AIInsight>> _generateProductInsights(
    List<InvoiceModel> invoices,
  ) async {
    final insights = <AIInsight>[];

    // Aggregate product sales
    final productSales = <String, Map<String, dynamic>>{};
    for (final invoice in invoices.where((i) => i.invoiceType == 'sales')) {
      for (final item in invoice.items) {
        final key = item.name.toLowerCase();
        if (!productSales.containsKey(key)) {
          productSales[key] = {
            'name': item.name,
            'quantity': 0,
            'revenue': 0.0,
          };
        }
        productSales[key]!['quantity'] += item.quantity;
        productSales[key]!['revenue'] += item.totalPrice;
      }
    }

    if (productSales.isNotEmpty) {
      // Sort by revenue
      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) =>
            (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

      // Top selling product
      if (sortedProducts.isNotEmpty) {
        final topProduct = sortedProducts.first;
        final totalRevenue = sortedProducts.fold<double>(
          0,
          (sum, e) => sum + (e.value['revenue'] as double),
        );
        final contribution =
            ((topProduct.value['revenue'] as double) / totalRevenue) * 100;

        insights.add(AIInsight(
          id: 'top_product',
          type: InsightType.opportunity,
          category: InsightCategory.products,
          title: 'Top Seller: ${topProduct.value['name']}',
          description:
              '${topProduct.value['name']} contributes ${contribution.toStringAsFixed(1)}% '
              'of your revenue (₹${(topProduct.value['revenue'] as double).toStringAsFixed(0)}). '
              'Consider stocking up!',
          value: topProduct.value['revenue'] as double,
          isPositive: true,
          priority: InsightPriority.medium,
          actionText: 'View inventory',
          metadata: {'productName': topProduct.value['name']},
        ));
      }

      // Product diversity insight
      if (sortedProducts.length >= 3) {
        final top3Revenue = sortedProducts
            .take(3)
            .fold<double>(0, (sum, e) => sum + (e.value['revenue'] as double));
        final totalRevenue = sortedProducts.fold<double>(
          0,
          (sum, e) => sum + (e.value['revenue'] as double),
        );
        final top3Percent = (top3Revenue / totalRevenue) * 100;

        if (top3Percent > 70) {
          insights.add(AIInsight(
            id: 'product_concentration',
            type: InsightType.alert,
            category: InsightCategory.products,
            title: 'High Product Concentration',
            description:
                'Top 3 products account for ${top3Percent.toStringAsFixed(1)}% of revenue. '
                'Consider diversifying your product mix to reduce risk.',
            value: top3Percent,
            isPositive: false,
            priority: InsightPriority.medium,
            actionText: 'Explore products',
          ));
        }
      }
    }

    return insights;
  }

  /// Generate customer-related insights
  Future<List<AIInsight>> _generateCustomerInsights() async {
    final insights = <AIInsight>[];

    try {
      final customers = await _customerService.getAllCustomers();

      if (customers.isEmpty) return insights;

      // Top customers by spending
      final sortedBySpending = List.from(customers)
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      if (sortedBySpending.isNotEmpty) {
        final topCustomer = sortedBySpending.first;
        insights.add(AIInsight(
          id: 'top_customer',
          type: InsightType.recommendation,
          category: InsightCategory.customers,
          title: 'Top Customer: ${topCustomer.name}',
          description:
              '${topCustomer.name} has spent ₹${topCustomer.totalSpent.toStringAsFixed(0)} '
              'across ${topCustomer.invoiceCount} orders. Consider a loyalty reward!',
          value: topCustomer.totalSpent,
          isPositive: true,
          priority: InsightPriority.medium,
          actionText: 'View customer',
          metadata: {'customerId': topCustomer.id},
        ));
      }

      // Customer concentration risk
      if (customers.length >= 5) {
        final totalSpent =
            customers.fold<double>(0, (sum, c) => sum + c.totalSpent);
        final top5Spent = sortedBySpending
            .take(5)
            .fold<double>(0, (sum, c) => sum + c.totalSpent);
        final top5Percent =
            totalSpent > 0 ? (top5Spent / totalSpent) * 100 : 0.0;

        if (top5Percent > 50) {
          insights.add(AIInsight(
            id: 'customer_concentration',
            type: InsightType.alert,
            category: InsightCategory.customers,
            title: 'Customer Concentration Risk',
            description:
                'Top 5 customers represent ${top5Percent.toStringAsFixed(1)}% of revenue. '
                'Focus on acquiring new customers to diversify.',
            value: top5Percent,
            isPositive: false,
            priority: InsightPriority.high,
            actionText: 'View customers',
          ));
        }
      }

      // Customers with outstanding balances
      final customersWithDues =
          customers.where((c) => c.outstandingAmount > 0).toList();
      if (customersWithDues.isNotEmpty) {
        final totalOutstanding = customersWithDues.fold<double>(
          0,
          (sum, c) => sum + c.outstandingAmount,
        );

        insights.add(AIInsight(
          id: 'outstanding_dues',
          type: InsightType.alert,
          category: InsightCategory.payments,
          title: '₹${totalOutstanding.toStringAsFixed(0)} Outstanding',
          description:
              '${customersWithDues.length} customers have pending payments. '
              'Follow up to improve cash flow.',
          value: totalOutstanding,
          isPositive: false,
          priority: totalOutstanding > 10000
              ? InsightPriority.high
              : InsightPriority.medium,
          actionText: 'View dues',
        ));
      }
    } catch (e) {
      debugPrint('Error generating customer insights: $e');
    }

    return insights;
  }

  /// Generate inventory-related insights
  Future<List<AIInsight>> _generateInventoryInsights() async {
    final insights = <AIInsight>[];

    try {
      final lowStockItems = await _inventoryService.getLowStockItems();
      final allItems = await _inventoryService.getAllItems();

      // Low stock alert
      if (lowStockItems.isNotEmpty) {
        insights.add(AIInsight(
          id: 'low_stock_alert',
          type: InsightType.alert,
          category: InsightCategory.inventory,
          title: '${lowStockItems.length} Items Low on Stock',
          description:
              '${lowStockItems.map((i) => i.name).take(3).join(", ")}'
              '${lowStockItems.length > 3 ? " and ${lowStockItems.length - 3} more" : ""} '
              'need restocking soon.',
          value: lowStockItems.length.toDouble(),
          isPositive: false,
          priority: InsightPriority.high,
          actionText: 'Reorder now',
        ));
      }

      // Inventory value insight
      if (allItems.isNotEmpty) {
        final totalValue = allItems.fold<double>(
          0,
          (sum, item) => sum + (item.currentStock * item.avgCost),
        );

        insights.add(AIInsight(
          id: 'inventory_value',
          type: InsightType.general,
          category: InsightCategory.inventory,
          title: 'Inventory Value: ₹${totalValue.toStringAsFixed(0)}',
          description:
              'You have ${allItems.length} SKUs worth ₹${totalValue.toStringAsFixed(0)} in stock.',
          value: totalValue,
          isPositive: true,
          priority: InsightPriority.low,
        ));
      }
    } catch (e) {
      debugPrint('Error generating inventory insights: $e');
    }

    return insights;
  }

  /// Generate payment-related insights
  Future<List<AIInsight>> _generatePaymentInsights(
    List<InvoiceModel> invoices,
  ) async {
    final insights = <AIInsight>[];

    final salesInvoices =
        invoices.where((i) => i.invoiceType == 'sales').toList();

    if (salesInvoices.isEmpty) return insights;

    // Payment collection rate
    final totalBilled =
        salesInvoices.fold<double>(0, (sum, i) => sum + i.adjustedTotal);
    final totalCollected =
        salesInvoices.fold<double>(0, (sum, i) => sum + i.amountPaid);
    final collectionRate =
        totalBilled > 0 ? (totalCollected / totalBilled) * 100 : 100.0;

    insights.add(AIInsight(
      id: 'collection_rate',
      type: InsightType.trend,
      category: InsightCategory.payments,
      title: 'Collection Rate: ${collectionRate.toStringAsFixed(1)}%',
      description: collectionRate >= 80
          ? 'Great collection rate! Keep up the good work.'
          : 'Collection rate needs improvement. Follow up on pending payments.',
      value: collectionRate,
      isPositive: collectionRate >= 80,
      priority:
          collectionRate < 70 ? InsightPriority.high : InsightPriority.medium,
      actionText: collectionRate < 80 ? 'View pending' : null,
    ));

    // Payment method breakdown
    final paymentMethods = <String, int>{};
    for (final invoice in salesInvoices.where((i) => i.amountPaid > 0)) {
      paymentMethods[invoice.paymentMethod] =
          (paymentMethods[invoice.paymentMethod] ?? 0) + 1;
    }

    if (paymentMethods.isNotEmpty) {
      final topMethod = paymentMethods.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final topMethodPercent =
          (topMethod.value / paymentMethods.values.fold(0, (a, b) => a + b)) *
              100;

      insights.add(AIInsight(
        id: 'payment_method',
        type: InsightType.general,
        category: InsightCategory.payments,
        title: 'Most Used: ${topMethod.key} (${topMethodPercent.toStringAsFixed(0)}%)',
        description:
            '${topMethod.key} is your most popular payment method. '
            '${topMethod.key == "Cash" ? "Consider promoting digital payments." : "Great digital adoption!"}',
        value: topMethodPercent,
        isPositive: topMethod.key != 'Cash',
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }
}
