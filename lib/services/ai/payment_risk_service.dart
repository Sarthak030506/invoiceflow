import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:invoiceflow/models/payment_risk_model.dart';
import 'package:invoiceflow/models/customer_model.dart';
import 'package:invoiceflow/services/firestore_service.dart';
import 'package:invoiceflow/services/customer_service.dart';

/// Service for predicting payment risk using Gemini AI
class PaymentRiskService {
  static PaymentRiskService? _instance;
  PaymentRiskService._internal();

  static PaymentRiskService get instance {
    _instance ??= PaymentRiskService._internal();
    return _instance!;
  }

  final FirestoreService _firestoreService = FirestoreService.instance;
  final CustomerService _customerService = CustomerService.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate AI-powered payment risk report
  Future<PaymentRiskReport> generateRiskReport() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final customersWithDues =
          customers.where((c) => c.outstandingAmount > 0.01).toList();

      if (customersWithDues.isEmpty) {
        return PaymentRiskReport(
          customerRisks: [],
          summary: PaymentRiskSummary(
            totalAtRisk: 0,
            criticalCount: 0,
            highRiskCount: 0,
            mediumRiskCount: 0,
            lowRiskCount: 0,
            recommendation: 'Great! No outstanding payments.',
          ),
          isAIPowered: true,
        );
      }

      // Prepare detailed customer data for AI
      final customerDataForAI = <Map<String, dynamic>>[];

      for (final customer in customersWithDues) {
        final invoices = await _firestoreService.getInvoicesByCustomerId(customer.id);
        final salesInvoices = invoices.where((i) => i.invoiceType == 'sales').toList();

        // Calculate metrics
        final paidInvoices = salesInvoices.where((i) => i.isFullyPaid).length;
        final unpaidInvoices = salesInvoices.where((i) => !i.isFullyPaid).toList();
        int maxDaysOverdue = 0;
        for (final inv in unpaidInvoices) {
          final days = DateTime.now().difference(inv.date).inDays;
          if (days > maxDaysOverdue) maxDaysOverdue = days;
        }

        customerDataForAI.add({
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phoneNumber,
          'totalSpent': customer.totalSpent,
          'totalPaid': customer.totalPaid,
          'outstanding': customer.outstandingAmount,
          'invoiceCount': customer.invoiceCount,
          'paidInvoicesCount': paidInvoices,
          'unpaidInvoicesCount': unpaidInvoices.length,
          'maxDaysOverdue': maxDaysOverdue,
          'lastPurchaseDate': customer.lastPurchaseDate?.toIso8601String(),
        });
      }

      // Call Firebase Function with Gemini AI
      final callable = _functions.httpsCallable('predictPaymentRisk');
      final result = await callable.call({'customers': customerDataForAI});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception('AI risk prediction failed');
      }

      final aiResponse = data['data'] as Map<String, dynamic>;
      final assessments = aiResponse['riskAssessments'] as List<dynamic>? ?? [];
      final summaryData = aiResponse['summary'] as Map<String, dynamic>? ?? {};

      // Convert AI response to PaymentRiskScore objects
      final riskScores = assessments.map((item) {
        final map = item as Map<String, dynamic>;
        final customerId = map['customerId'] ?? '';
        final customer = customersWithDues.firstWhere(
          (c) => c.id == customerId,
          orElse: () => customersWithDues.first,
        );

        return PaymentRiskScore(
          customerId: customerId,
          customerName: map['customerName'] ?? customer.name,
          customerPhone: customer.phoneNumber,
          riskScore: ((map['riskScore'] as num?) ?? 50).toDouble().clamp(0, 100),
          totalOutstanding: (map['outstandingAmount'] as num?)?.toDouble() ?? customer.outstandingAmount,
          overdueInvoices: 0,
          maxDaysOverdue: 0,
          avgPaymentDelay: 0,
          totalInvoices: customer.invoiceCount,
          onTimePayments: 0,
          riskFactors: (map['factors'] as List<dynamic>?)
              ?.map((f) => RiskFactor(
                    name: f.toString(),
                    description: f.toString(),
                    impact: 0,
                    type: RiskFactorType.daysOverdue,
                  ))
              .toList() ?? [],
          recommendedAction: map['recommendation'] ?? 'Follow up on payment.',
          aiPredictedDays: (map['predictedPaymentDays'] as num?)?.toInt(),
        );
      }).toList();

      // Sort by risk score
      riskScores.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      return PaymentRiskReport(
        customerRisks: riskScores,
        summary: PaymentRiskSummary(
          totalAtRisk: (summaryData['totalAtRisk'] as num?)?.toDouble() ??
              riskScores.fold(0.0, (sum, r) => sum + r.totalOutstanding),
          criticalCount: (summaryData['criticalCount'] as num?)?.toInt() ??
              riskScores.where((r) => r.riskLevel == RiskLevel.critical).length,
          highRiskCount: (summaryData['highRiskCount'] as num?)?.toInt() ??
              riskScores.where((r) => r.riskLevel == RiskLevel.high).length,
          mediumRiskCount: riskScores.where((r) => r.riskLevel == RiskLevel.medium).length,
          lowRiskCount: riskScores.where((r) => r.riskLevel == RiskLevel.low).length,
          recommendation: summaryData['recommendation'] ?? 'Prioritize high-risk customers.',
        ),
        isAIPowered: true,
      );
    } catch (e) {
      debugPrint('Error generating AI risk report: $e');
      return _generateFallbackReport();
    }
  }

  /// Fallback risk calculation if AI fails
  Future<PaymentRiskReport> _generateFallbackReport() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final customersWithDues =
          customers.where((c) => c.outstandingAmount > 0.01).toList();

      final riskScores = <PaymentRiskScore>[];

      for (final customer in customersWithDues) {
        final score = await _calculateCustomerRiskFallback(customer);
        if (score != null) {
          riskScores.add(score);
        }
      }

      riskScores.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      return PaymentRiskReport(
        customerRisks: riskScores,
        summary: PaymentRiskSummary(
          totalAtRisk: riskScores.fold(0.0, (sum, r) => sum + r.totalOutstanding),
          criticalCount: riskScores.where((r) => r.riskLevel == RiskLevel.critical).length,
          highRiskCount: riskScores.where((r) => r.riskLevel == RiskLevel.high).length,
          mediumRiskCount: riskScores.where((r) => r.riskLevel == RiskLevel.medium).length,
          lowRiskCount: riskScores.where((r) => r.riskLevel == RiskLevel.low).length,
          recommendation: 'Basic analysis. AI unavailable.',
        ),
        isAIPowered: false,
      );
    } catch (e) {
      debugPrint('Fallback risk report error: $e');
      return PaymentRiskReport(
        customerRisks: [],
        summary: PaymentRiskSummary(
          totalAtRisk: 0,
          criticalCount: 0,
          highRiskCount: 0,
          mediumRiskCount: 0,
          lowRiskCount: 0,
          recommendation: 'Unable to generate report.',
        ),
        isAIPowered: false,
      );
    }
  }

  Future<PaymentRiskScore?> _calculateCustomerRiskFallback(CustomerModel customer) async {
    try {
      final invoices = await _firestoreService.getInvoicesByCustomerId(customer.id);
      final salesInvoices = invoices.where((i) => i.invoiceType == 'sales').toList();

      if (salesInvoices.isEmpty) return null;

      final riskFactors = <RiskFactor>[];
      double totalScore = 0;

      // Days overdue factor
      final unpaidInvoices = salesInvoices.where((i) => !i.isFullyPaid).toList();
      int maxDaysOverdue = 0;
      for (final inv in unpaidInvoices) {
        final days = DateTime.now().difference(inv.date).inDays;
        if (days > maxDaysOverdue) maxDaysOverdue = days;
      }

      if (maxDaysOverdue > 60) {
        totalScore += 35;
        riskFactors.add(RiskFactor(
          name: 'Severely Overdue',
          description: '$maxDaysOverdue days overdue',
          impact: 35,
          type: RiskFactorType.daysOverdue,
        ));
      } else if (maxDaysOverdue > 30) {
        totalScore += 25;
        riskFactors.add(RiskFactor(
          name: 'Overdue',
          description: '$maxDaysOverdue days overdue',
          impact: 25,
          type: RiskFactorType.daysOverdue,
        ));
      }

      // Credit ratio factor
      final creditRatio = customer.outstandingAmount / (customer.totalSpent > 0 ? customer.totalSpent : 1);
      if (creditRatio > 0.5) {
        totalScore += 30;
        riskFactors.add(RiskFactor(
          name: 'High Credit Ratio',
          description: '${(creditRatio * 100).toStringAsFixed(0)}% outstanding',
          impact: 30,
          type: RiskFactorType.creditRatio,
        ));
      } else if (creditRatio > 0.3) {
        totalScore += 15;
      }

      // Amount factor
      if (customer.outstandingAmount > 10000) {
        totalScore += 20;
        riskFactors.add(RiskFactor(
          name: 'Large Amount',
          description: '₹${customer.outstandingAmount.toStringAsFixed(0)} outstanding',
          impact: 20,
          type: RiskFactorType.invoiceSize,
        ));
      }

      return PaymentRiskScore(
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phoneNumber,
        riskScore: totalScore.clamp(0, 100),
        totalOutstanding: customer.outstandingAmount,
        overdueInvoices: unpaidInvoices.length,
        maxDaysOverdue: maxDaysOverdue,
        avgPaymentDelay: 0,
        totalInvoices: salesInvoices.length,
        onTimePayments: salesInvoices.where((i) => i.isFullyPaid).length,
        riskFactors: riskFactors,
        recommendedAction: _getRecommendation(totalScore),
      );
    } catch (e) {
      return null;
    }
  }

  String _getRecommendation(double score) {
    if (score >= 80) return 'Call immediately. Consider stopping credit.';
    if (score >= 60) return 'Follow up within 2-3 days.';
    if (score >= 40) return 'Send WhatsApp reminder this week.';
    return 'Standard follow-up cycle.';
  }

  /// Get customers by risk level
  Future<List<PaymentRiskScore>> getCustomersByRiskLevel(RiskLevel level) async {
    final report = await generateRiskReport();
    return report.customerRisks.where((c) => c.riskLevel == level).toList();
  }
}
