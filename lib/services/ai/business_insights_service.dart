import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:invoiceflow/models/ai_insight_model.dart';
import 'package:invoiceflow/services/firestore_service.dart';
import 'package:invoiceflow/services/inventory_service.dart';
import 'package:invoiceflow/services/customer_service.dart';

/// Service for generating AI-powered business insights using Gemini
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
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate AI-powered business insights using Gemini
  Future<BusinessInsightsReport> generateInsights() async {
    try {
      // Gather data to send to AI
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get recent invoices
      final invoices = await _firestoreService.getInvoicesByDateRange(
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      // Prepare invoice data summary for AI
      final invoiceData = invoices.map((inv) => {
        'type': inv.invoiceType,
        'total': inv.total,
        'paid': inv.amountPaid,
        'status': inv.status,
        'date': inv.date.toIso8601String(),
        'items': inv.items.map((i) => {'name': i.name, 'qty': i.quantity, 'price': i.price}).toList(),
      }).toList();

      // Get customers with outstanding balances
      final customers = await _customerService.getAllCustomers();
      final customerData = customers.map((c) => {
        'name': c.name,
        'totalSpent': c.totalSpent,
        'totalPaid': c.totalPaid,
        'outstanding': c.outstandingAmount,
        'invoiceCount': c.invoiceCount,
      }).toList();

      // Get inventory status
      final items = await _inventoryService.getAllItems();
      final lowStockItems = await _inventoryService.getLowStockItems();
      final inventoryData = {
        'totalItems': items.length,
        'lowStockCount': lowStockItems.length,
        'items': items.take(20).map((i) => {
          'name': i.name,
          'stock': i.currentStock,
          'reorderPoint': i.reorderPoint,
          'avgCost': i.avgCost,
        }).toList(),
      };

      // Call Firebase Function with Gemini AI
      final callable = _functions.httpsCallable('generateBusinessInsights');
      final result = await callable.call({
        'invoiceData': invoiceData,
        'customerData': customerData,
        'inventoryData': inventoryData,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception('AI insights generation failed');
      }

      final aiResponse = data['data'] as Map<String, dynamic>;
      final insightsList = aiResponse['insights'] as List<dynamic>? ?? [];
      final summary = aiResponse['summary'] as String? ?? '';

      // Convert AI response to AIInsight objects
      final insights = insightsList.map((item) {
        final map = item as Map<String, dynamic>;
        return AIInsight(
          id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: _parseInsightType(map['type']),
          category: _parseCategory(map['category']),
          title: map['title'] ?? '',
          description: map['description'] ?? '',
          value: (map['value'] as num?)?.toDouble(),
          changePercent: (map['changePercent'] as num?)?.toDouble(),
          isPositive: map['isPositive'] ?? true,
          priority: _parsePriority(map['priority']),
          actionText: map['actionText'],
        );
      }).toList();

      return BusinessInsightsReport(
        insights: insights,
        summary: summary,
        generatedAt: DateTime.now(),
        isAIPowered: true,
      );
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
      // Fallback to basic insights if AI fails
      return _generateFallbackInsights();
    }
  }

  InsightType _parseInsightType(String? type) {
    switch (type?.toLowerCase()) {
      case 'trend':
        return InsightType.trend;
      case 'alert':
        return InsightType.alert;
      case 'opportunity':
        return InsightType.opportunity;
      case 'recommendation':
        return InsightType.recommendation;
      default:
        return InsightType.general;
    }
  }

  InsightCategory _parseCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'revenue':
        return InsightCategory.revenue;
      case 'products':
        return InsightCategory.products;
      case 'customers':
        return InsightCategory.customers;
      case 'inventory':
        return InsightCategory.inventory;
      case 'payments':
        return InsightCategory.payments;
      default:
        return InsightCategory.revenue;
    }
  }

  InsightPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return InsightPriority.high;
      case 'medium':
        return InsightPriority.medium;
      case 'low':
        return InsightPriority.low;
      default:
        return InsightPriority.medium;
    }
  }

  /// Fallback insights if AI call fails
  Future<BusinessInsightsReport> _generateFallbackInsights() async {
    final insights = <AIInsight>[];

    try {
      final customers = await _customerService.getAllCustomers();
      final customersWithDues = customers.where((c) => c.outstandingAmount > 0).toList();

      if (customersWithDues.isNotEmpty) {
        final totalOutstanding = customersWithDues.fold<double>(
          0, (sum, c) => sum + c.outstandingAmount);

        insights.add(AIInsight(
          id: 'outstanding_dues',
          type: InsightType.alert,
          category: InsightCategory.payments,
          title: '₹${totalOutstanding.toStringAsFixed(0)} Outstanding',
          description: '${customersWithDues.length} customers have pending payments. Follow up to improve cash flow.',
          value: totalOutstanding,
          isPositive: false,
          priority: InsightPriority.high,
        ));
      }

      final lowStock = await _inventoryService.getLowStockItems();
      if (lowStock.isNotEmpty) {
        insights.add(AIInsight(
          id: 'low_stock',
          type: InsightType.alert,
          category: InsightCategory.inventory,
          title: '${lowStock.length} Items Low on Stock',
          description: 'These items need restocking soon to avoid stockouts.',
          value: lowStock.length.toDouble(),
          isPositive: false,
          priority: InsightPriority.high,
        ));
      }
    } catch (e) {
      debugPrint('Fallback insights error: $e');
    }

    return BusinessInsightsReport(
      insights: insights,
      summary: 'Basic insights generated. AI analysis unavailable.',
      generatedAt: DateTime.now(),
      isAIPowered: false,
    );
  }
}
