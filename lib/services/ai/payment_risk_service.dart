import 'package:flutter/foundation.dart';
import 'package:invoiceflow/models/payment_risk_model.dart';
import 'package:invoiceflow/models/invoice_model.dart';
import 'package:invoiceflow/models/customer_model.dart';
import 'package:invoiceflow/services/firestore_service.dart';
import 'package:invoiceflow/services/customer_service.dart';

/// Service for predicting payment risk for customers
class PaymentRiskService {
  static PaymentRiskService? _instance;
  PaymentRiskService._internal();

  static PaymentRiskService get instance {
    _instance ??= PaymentRiskService._internal();
    return _instance!;
  }

  final FirestoreService _firestoreService = FirestoreService.instance;
  final CustomerService _customerService = CustomerService.instance;

  // Risk factor weights
  static const double _daysOverdueWeight = 0.35;
  static const double _paymentHistoryWeight = 0.30;
  static const double _creditRatioWeight = 0.20;
  static const double _invoiceSizeWeight = 0.15;

  /// Generate payment risk report for all customers with outstanding balances
  Future<PaymentRiskReport> generateRiskReport() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final customersWithDues =
          customers.where((c) => c.outstandingAmount > 0.01).toList();

      final riskScores = <PaymentRiskScore>[];

      for (final customer in customersWithDues) {
        final score = await calculateCustomerRisk(customer);
        if (score != null) {
          riskScores.add(score);
        }
      }

      // Sort by risk score (highest first)
      riskScores.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      return PaymentRiskReport(customerRisks: riskScores);
    } catch (e) {
      debugPrint('Error generating risk report: $e');
      return PaymentRiskReport(customerRisks: []);
    }
  }

  /// Calculate risk score for a specific customer
  Future<PaymentRiskScore?> calculateCustomerRisk(CustomerModel customer) async {
    try {
      // Get customer's invoices
      final invoices =
          await _firestoreService.getInvoicesByCustomerId(customer.id);

      if (invoices.isEmpty) return null;

      // Filter to sales invoices
      final salesInvoices =
          invoices.where((i) => i.invoiceType == 'sales' && i.status != 'cancelled').toList();

      if (salesInvoices.isEmpty) return null;

      // Calculate risk factors
      final riskFactors = <RiskFactor>[];
      double totalScore = 0;

      // 1. Days Overdue Factor (35%)
      final overdueData = _calculateOverdueFactor(salesInvoices);
      totalScore += overdueData['score'] * _daysOverdueWeight;
      if (overdueData['score'] > 0) {
        riskFactors.add(RiskFactor(
          name: 'Days Overdue',
          description: overdueData['description'],
          impact: overdueData['score'] * _daysOverdueWeight,
          type: RiskFactorType.daysOverdue,
        ));
      }

      // 2. Payment History Factor (30%)
      final historyData = _calculatePaymentHistoryFactor(salesInvoices);
      totalScore += historyData['score'] * _paymentHistoryWeight;
      riskFactors.add(RiskFactor(
        name: 'Payment History',
        description: historyData['description'],
        impact: historyData['score'] * _paymentHistoryWeight,
        type: RiskFactorType.paymentHistory,
      ));

      // 3. Credit Ratio Factor (20%)
      final creditData = _calculateCreditRatioFactor(customer);
      totalScore += creditData['score'] * _creditRatioWeight;
      if (creditData['score'] > 0) {
        riskFactors.add(RiskFactor(
          name: 'Credit Ratio',
          description: creditData['description'],
          impact: creditData['score'] * _creditRatioWeight,
          type: RiskFactorType.creditRatio,
        ));
      }

      // 4. Invoice Size Factor (15%)
      final sizeData = _calculateInvoiceSizeFactor(salesInvoices);
      totalScore += sizeData['score'] * _invoiceSizeWeight;
      if (sizeData['score'] > 0) {
        riskFactors.add(RiskFactor(
          name: 'Invoice Size',
          description: sizeData['description'],
          impact: sizeData['score'] * _invoiceSizeWeight,
          type: RiskFactorType.invoiceSize,
        ));
      }

      // Calculate additional metrics
      final unpaidInvoices =
          salesInvoices.where((i) => !i.isFullyPaid).toList();
      final overdueInvoices = unpaidInvoices.where((i) {
        final daysSince = DateTime.now().difference(i.date).inDays;
        return daysSince > 30;
      }).toList();

      int maxDaysOverdue = 0;
      for (final invoice in unpaidInvoices) {
        final days = DateTime.now().difference(invoice.date).inDays;
        if (days > maxDaysOverdue) maxDaysOverdue = days;
      }

      // Calculate on-time payments
      final paidInvoices = salesInvoices.where((i) => i.isFullyPaid).toList();
      int onTimePayments = 0;
      for (final invoice in paidInvoices) {
        // Consider on-time if paid within 30 days
        final daysToPay = invoice.updatedAt.difference(invoice.date).inDays;
        if (daysToPay <= 30) onTimePayments++;
      }

      // Get recommended action
      final recommendedAction = _getRecommendedAction(totalScore, overdueData);

      return PaymentRiskScore(
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phoneNumber,
        riskScore: totalScore.clamp(0, 100),
        totalOutstanding: customer.outstandingAmount,
        overdueInvoices: overdueInvoices.length,
        maxDaysOverdue: maxDaysOverdue,
        avgPaymentDelay: historyData['avgDelay'] ?? 0.0,
        totalInvoices: salesInvoices.length,
        onTimePayments: onTimePayments,
        riskFactors: riskFactors,
        recommendedAction: recommendedAction,
      );
    } catch (e) {
      debugPrint('Error calculating risk for customer ${customer.id}: $e');
      return null;
    }
  }

  /// Calculate days overdue risk factor
  Map<String, dynamic> _calculateOverdueFactor(List<InvoiceModel> invoices) {
    final unpaidInvoices = invoices.where((i) => !i.isFullyPaid).toList();

    if (unpaidInvoices.isEmpty) {
      return {'score': 0.0, 'description': 'No overdue invoices'};
    }

    int maxDaysOverdue = 0;
    double totalOverdue = 0;

    for (final invoice in unpaidInvoices) {
      final daysSince = DateTime.now().difference(invoice.date).inDays;
      if (daysSince > maxDaysOverdue) maxDaysOverdue = daysSince;
      if (daysSince > 30) {
        totalOverdue += invoice.remainingAmount;
      }
    }

    // Score based on max days overdue
    double score;
    String description;

    if (maxDaysOverdue > 90) {
      score = 100;
      description = '$maxDaysOverdue days overdue - Critical';
    } else if (maxDaysOverdue > 60) {
      score = 80;
      description = '$maxDaysOverdue days overdue - Very High';
    } else if (maxDaysOverdue > 30) {
      score = 60;
      description = '$maxDaysOverdue days overdue - High';
    } else if (maxDaysOverdue > 15) {
      score = 40;
      description = '$maxDaysOverdue days since invoice';
    } else {
      score = 20;
      description = 'Recent invoice ($maxDaysOverdue days)';
    }

    return {'score': score, 'description': description, 'totalOverdue': totalOverdue};
  }

  /// Calculate payment history risk factor
  Map<String, dynamic> _calculatePaymentHistoryFactor(
      List<InvoiceModel> invoices) {
    final paidInvoices = invoices.where((i) => i.isFullyPaid).toList();

    if (paidInvoices.isEmpty) {
      return {
        'score': 50.0,
        'description': 'No payment history',
        'avgDelay': 0.0
      };
    }

    // Calculate average days to pay
    double totalDays = 0;
    int latePayments = 0;

    for (final invoice in paidInvoices) {
      final daysToPay = invoice.updatedAt.difference(invoice.date).inDays;
      totalDays += daysToPay;
      if (daysToPay > 30) latePayments++;
    }

    final avgDays = totalDays / paidInvoices.length;
    final latePaymentRate = latePayments / paidInvoices.length;

    // Score based on payment behavior
    double score;
    String description;

    if (latePaymentRate > 0.7) {
      score = 90;
      description = '${(latePaymentRate * 100).toStringAsFixed(0)}% late payments';
    } else if (latePaymentRate > 0.5) {
      score = 70;
      description = 'Frequently late (${(latePaymentRate * 100).toStringAsFixed(0)}%)';
    } else if (latePaymentRate > 0.3) {
      score = 50;
      description = 'Sometimes late (${(latePaymentRate * 100).toStringAsFixed(0)}%)';
    } else if (latePaymentRate > 0.1) {
      score = 30;
      description = 'Usually on time';
    } else {
      score = 10;
      description = 'Excellent payment history';
    }

    return {'score': score, 'description': description, 'avgDelay': avgDays};
  }

  /// Calculate credit ratio risk factor
  Map<String, dynamic> _calculateCreditRatioFactor(CustomerModel customer) {
    if (customer.totalSpent == 0) {
      return {'score': 0.0, 'description': 'No credit history'};
    }

    final creditRatio = customer.outstandingAmount / customer.totalSpent;

    double score;
    String description;

    if (creditRatio > 0.7) {
      score = 90;
      description = '${(creditRatio * 100).toStringAsFixed(0)}% outstanding';
    } else if (creditRatio > 0.5) {
      score = 70;
      description = 'High credit utilization';
    } else if (creditRatio > 0.3) {
      score = 50;
      description = 'Moderate credit utilization';
    } else if (creditRatio > 0.1) {
      score = 30;
      description = 'Low credit utilization';
    } else {
      score = 10;
      description = 'Minimal outstanding';
    }

    return {'score': score, 'description': description};
  }

  /// Calculate invoice size risk factor
  Map<String, dynamic> _calculateInvoiceSizeFactor(List<InvoiceModel> invoices) {
    final unpaidInvoices = invoices.where((i) => !i.isFullyPaid).toList();

    if (unpaidInvoices.isEmpty) {
      return {'score': 0.0, 'description': 'No unpaid invoices'};
    }

    // Get largest unpaid invoice
    double maxUnpaid = 0;
    for (final invoice in unpaidInvoices) {
      if (invoice.remainingAmount > maxUnpaid) {
        maxUnpaid = invoice.remainingAmount;
      }
    }

    double score;
    String description;

    if (maxUnpaid > 50000) {
      score = 90;
      description = 'Large invoice (₹${maxUnpaid.toStringAsFixed(0)})';
    } else if (maxUnpaid > 20000) {
      score = 70;
      description = 'Significant amount (₹${maxUnpaid.toStringAsFixed(0)})';
    } else if (maxUnpaid > 10000) {
      score = 50;
      description = 'Moderate amount (₹${maxUnpaid.toStringAsFixed(0)})';
    } else if (maxUnpaid > 5000) {
      score = 30;
      description = 'Small amount (₹${maxUnpaid.toStringAsFixed(0)})';
    } else {
      score = 10;
      description = 'Minor amount (₹${maxUnpaid.toStringAsFixed(0)})';
    }

    return {'score': score, 'description': description};
  }

  /// Get recommended action based on risk score
  String _getRecommendedAction(double score, Map<String, dynamic> overdueData) {
    if (score >= 80) {
      return 'Call immediately. Consider stopping further credit.';
    } else if (score >= 60) {
      return 'Follow up within 2-3 days. Send payment reminder.';
    } else if (score >= 40) {
      return 'Send WhatsApp reminder this week.';
    } else {
      return 'Standard follow-up cycle.';
    }
  }

  /// Get customers sorted by risk level
  Future<List<PaymentRiskScore>> getCustomersByRiskLevel(
      RiskLevel level) async {
    final report = await generateRiskReport();
    return report.customerRisks
        .where((c) => c.riskLevel == level)
        .toList();
  }

  /// Get total amount at risk by level
  Future<Map<RiskLevel, double>> getAmountAtRiskByLevel() async {
    final report = await generateRiskReport();
    final result = <RiskLevel, double>{};

    for (final level in RiskLevel.values) {
      result[level] = report.customerRisks
          .where((c) => c.riskLevel == level)
          .fold(0, (sum, c) => sum + c.totalOutstanding);
    }

    return result;
  }
}
