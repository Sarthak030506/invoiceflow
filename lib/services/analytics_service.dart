import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/product_categories.dart';
import '../models/return_model.dart';
import './firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnalyticsService {
  final FirestoreService _fs = FirestoreService.instance;

  // Cache expiry duration (30 minutes for better performance, still reasonable for multi-device sync)
  static const int _cacheExpiryMinutes = 30;

  /// Invalidate all analytics cache
  Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('analytics_cache_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    print('✓ Analytics cache cleared (${keys.length} entries)');
  }

  /// Force refresh analytics (bypasses cache)
  /// Call this when user explicitly requests fresh data
  Future<List<Map<String, dynamic>>> refreshFilteredAnalytics(String dateRange, {bool salesOnly = true}) async {
    // Invalidate cache first
    await invalidateCache();
    // Then compute fresh
    return await getFilteredAnalytics(dateRange, salesOnly: salesOnly);
  }

  /// Get cached data or compute and cache
  Future<T?> _getCached<T>(String cacheKey, Future<T> Function() compute) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('analytics_cache_$cacheKey');
    final cachedTime = prefs.getInt('analytics_cache_time_$cacheKey');

    // Check if cache is valid
    if (cachedJson != null && cachedTime != null) {
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
      if (age < _cacheExpiryMinutes * 60 * 1000) {
        try {
          return jsonDecode(cachedJson) as T;
        } catch (e) {
          print('Cache decode error for $cacheKey: $e');
        }
      }
    }

    // Compute fresh data
    final result = await compute();

    // Cache the result
    try {
      await prefs.setString('analytics_cache_$cacheKey', jsonEncode(result));
      await prefs.setInt('analytics_cache_time_$cacheKey', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Cache encode error for $cacheKey: $e');
    }

    return result;
  }

  DateTime _calculateStartDate(String dateRange) {
    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        // Start of today (midnight)
        return DateTime(now.year, now.month, now.day);
      case 'Last 7 days':
        return now.subtract(Duration(days: 7));
      case 'Last 30 days':
        return now.subtract(Duration(days: 30));
      case 'Last 90 days':
        return now.subtract(Duration(days: 90));
      case 'This year':
        return DateTime(now.year, 1, 1);
      case 'All time':
      default:
        return DateTime(2000, 1, 1); // Very old date to include all
    }
  }

  DateTime _calculatePreviousPeriodStartDate(String dateRange, DateTime currentStartDate) {
    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        // Previous day
        return currentStartDate.subtract(Duration(days: 1));
      case 'Last 7 days':
        // Previous 7 days (8-14 days ago)
        return now.subtract(Duration(days: 14));
      case 'Last 30 days':
        // Previous 30 days (31-60 days ago)
        return now.subtract(Duration(days: 60));
      case 'Last 90 days':
        // Previous 90 days (91-180 days ago)
        return now.subtract(Duration(days: 180));
      case 'This year':
        // Previous year
        return DateTime(now.year - 1, 1, 1);
      case 'All time':
      default:
        // No previous period for "All time"
        return DateTime(2000, 1, 1);
    }
  }

  // Get customer purchase history and analytics
  // Add methods needed by analytics_screen.dart
  Future<List<Map<String, dynamic>>> getFilteredAnalytics(String dateRange, {bool salesOnly = true}) async {
    // Use cache for analytics
    final cacheKey = 'filtered_analytics_${dateRange}_${salesOnly}';
    final cached = await _getCached<List<dynamic>>(cacheKey, () async => await _computeFilteredAnalytics(dateRange, salesOnly));

    return cached?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> _computeFilteredAnalytics(String dateRange, bool salesOnly) async {
    try {
      // SCALABILITY FIX: Use date-filtered query instead of fetching all invoices
      final DateTime startDate = _calculateStartDate(dateRange);

      final invoices = await _fs.getInvoicesByDateRange(
        startDate: startDate,
        invoiceType: salesOnly ? 'sales' : null,
        limit: 5000, // Safety limit
      );

      print('Found ${invoices.length} invoices for date range: $dateRange (salesOnly: $salesOnly)');

      // Warn if result may be truncated
      if (invoices.length >= 5000) {
        print('⚠️ WARNING: Analytics may be incomplete. Result limit (5000) reached. Consider narrower date range.');
      }
      
      if (invoices.isEmpty) {
        print('No invoices found for the selected date range');
        return [];
      }
      
      // Track items by name
      final Map<String, Map<String, dynamic>> itemAnalytics = {};
      
      for (final invoice in invoices) {
        if (invoice.items.isEmpty) {
          print('Invoice ${invoice.id} has no items');
          continue;
        }
        
        // Skip non-sales invoices when salesOnly is true (should be handled by the filter above)
        if (salesOnly && invoice.invoiceType.toLowerCase() != 'sales') {
          continue;
        }
        
        for (final item in invoice.items) {
          final quantity = item.quantity;
          final price = item.price;
          
          // Skip items with zero or negative quantity
          if (quantity <= 0) {
            continue;
          }
           
          final itemName = item.name.trim();
          if (itemName.isEmpty) {
            print('Skipping empty item name');
            continue;
          }
          
          final itemTotal = price * quantity;
          
          print('Processing item: $itemName, Qty: $quantity, Price: $price, Total: $itemTotal');
          
          if (!itemAnalytics.containsKey(itemName)) {
            itemAnalytics[itemName] = {
              'itemName': itemName,
              'quantitySold': 0,
              'revenue': 0.0,
              'averagePrice': 0.0,
            };
          }
          
          itemAnalytics[itemName]!['quantitySold'] = (itemAnalytics[itemName]!['quantitySold'] as int) + quantity;
          itemAnalytics[itemName]!['revenue'] = (itemAnalytics[itemName]!['revenue'] as double) + itemTotal;
          
          // Recalculate average price
          final totalQuantity = itemAnalytics[itemName]!['quantitySold'] as int;
          final totalRevenue = itemAnalytics[itemName]!['revenue'] as double;
          final avgPrice = (totalQuantity > 0 && totalRevenue > 0) ? (totalRevenue / totalQuantity) : 0.0;
          itemAnalytics[itemName]!['averagePrice'] = double.parse(avgPrice.toStringAsFixed(2));
          
          print('Item: $itemName, Qty: $totalQuantity, Revenue: $totalRevenue, AvgPrice: $avgPrice');
        }
      }
      
      // Skip returns processing for now to debug average price issue
      print('Skipping returns processing for debugging');

      // Filter out any items that somehow ended up with 0 or negative quantity
      final filteredResult = itemAnalytics.values
          .where((item) => (item['quantitySold'] as int) > 0)
          .map((item) {
            final itemMap = Map<String, dynamic>.from(item);
            // Ensure average price is calculated correctly for final result
            final qty = itemMap['quantitySold'] as int;
            final rev = itemMap['revenue'] as double;
            final calculatedAvgPrice = (qty > 0 && rev > 0) ? (rev / qty) : 0.0;
            itemMap['averagePrice'] = double.parse(calculatedAvgPrice.toStringAsFixed(2));
            
            print('Final mapping - ${itemMap['itemName']}: Qty=$qty, Rev=$rev, CalculatedAvg=$calculatedAvgPrice, FinalAvg=${itemMap['averagePrice']}');
            return itemMap;
          })
          .toList();

      // Sort by revenue (highest first)
      filteredResult.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      print('Returning ${filteredResult.length} items with analytics data (after returns adjustment)');
      for (final item in filteredResult) {
        print('Item: ${item['itemName']}, Qty: ${item['quantitySold']}, Revenue: ${item['revenue']}');
      }

      return filteredResult;
    } catch (e) {
      print('Error in getFilteredAnalytics: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getChartAnalytics(String dateRange) async {
    try {
      // SCALABILITY FIX: Use date-filtered query
      final DateTime startDate = _calculateStartDate(dateRange);
      final filteredInvoices = await _fs.getInvoicesByDateRange(
        startDate: startDate,
        limit: 5000,
      );

      // Warn if result may be truncated
      if (filteredInvoices.length >= 5000) {
        print('⚠️ WARNING: Chart analytics may be incomplete. Result limit (5000) reached.');
      }

      if (filteredInvoices.isEmpty) {
        return {
          'salesVsPurchases': {'sales': 0.0, 'purchases': 0.0},
          'revenueTrend': [],
          'topSellingItems': [],
          'outstandingPayments': {'paid': 0.0, 'remaining': 0.0},
        };
      }

      // Sales vs Purchases
      double salesRevenue = 0.0;
      double purchaseRevenue = 0.0;

      // Outstanding Payments
      double totalPaid = 0.0;
      double totalRemaining = 0.0;

      // Revenue Trend (group by date)
      Map<String, double> dailyRevenue = {};

      // Top Items aggregation
      Map<String, double> itemRevenue = {};
      Map<String, int> itemQuantity = {};

      for (final invoice in filteredInvoices) {
        final dateKey = '${invoice.date.year}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.day.toString().padLeft(2, '0')}';

        // Use effectiveRevenue (adjustedTotal) instead of calculating from items
        // This properly accounts for refund adjustments
        final invoiceRevenue = invoice.effectiveRevenue;

        // Top items (only for sales) - still track gross items for item-level analytics
        // Note: These will be adjusted for returns in a separate method
        if (invoice.invoiceType == 'sales') {
          for (final item in invoice.items) {
            final quantity = item.quantity;
            final price = item.price;

            // Skip items with zero or negative quantity
            if (quantity <= 0) {
              continue;
            }

            final itemTotal = price * quantity;
            final itemName = item.name;
            itemRevenue[itemName] = (itemRevenue[itemName] ?? 0.0) + itemTotal;
            itemQuantity[itemName] = (itemQuantity[itemName] ?? 0) + quantity;
          }
        }

        if (invoice.invoiceType == 'sales') {
          salesRevenue += invoiceRevenue;
          totalPaid += invoice.amountPaid;
          totalRemaining += invoice.remainingAmount;
          // Revenue trend (only sales)
          dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + invoiceRevenue;
        } else {
          // For purchase invoices, calculate from items (no refund adjustments on purchases)
          double purchaseInvoiceRevenue = 0.0;
          for (final item in invoice.items) {
            if (item.quantity > 0) {
              purchaseInvoiceRevenue += item.price * item.quantity;
            }
          }
          purchaseRevenue += purchaseInvoiceRevenue;
        }
      }
      
      // Subtract returns from item analytics
      try {
        final allReturns = await _fs.getReturns();
        final returnsInDateRange = allReturns.where((ret) =>
            ret.returnDate.isAfter(startDate) && ret.returnType == 'sales').toList();

        for (final returnModel in returnsInDateRange) {
          for (final returnItem in returnModel.items) {
            final itemName = returnItem.name;
            if (itemRevenue.containsKey(itemName)) {
              itemRevenue[itemName] = (itemRevenue[itemName]! - returnItem.totalValue).clamp(0.0, double.infinity);
              itemQuantity[itemName] = ((itemQuantity[itemName]! - returnItem.quantity)).clamp(0, 999999999);
            }
          }
        }
      } catch (e) {
        print('Error processing returns in chart analytics: $e');
      }

      // Convert revenue trend to list
      final revenueTrend = dailyRevenue.entries
          .map((entry) => {
                'date': entry.key,
                'revenue': entry.value,
              })
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      // Top 5 selling items (after returns adjustment)
      final topSellingItems = itemRevenue.entries
          .where((entry) => entry.value > 0)  // Only include items with positive revenue
          .map((entry) => {
                'itemName': entry.key,
                'revenue': entry.value,
                'quantitySold': itemQuantity[entry.key] ?? 0,
              })
          .toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double))
        ..take(5)
        ..toList();
      
      
      return {
        'salesVsPurchases': {
          'sales': salesRevenue,
          'purchases': purchaseRevenue,
        },
        'revenueTrend': revenueTrend,
        'topSellingItems': topSellingItems,
        'outstandingPayments': {
          'paid': totalPaid,
          'remaining': totalRemaining,
        },
      };
    } catch (e) {
      print('Error in getChartAnalytics: $e');
      return {
        'salesVsPurchases': {'sales': 0.0, 'purchases': 0.0},
        'revenueTrend': [],
        'topSellingItems': [],
        'outstandingPayments': {'paid': 0.0, 'remaining': 0.0},
      };
    }
  }
  
  Future<Map<String, dynamic>> fetchPerformanceInsights(String dateRange) async {
    // SCALABILITY FIX: Use date-filtered query
    final DateTime startDate = _calculateStartDate(dateRange);
    final invoices = await _fs.getInvoicesByDateRange(
      startDate: startDate,
      limit: 5000,
    );

    // Warn if result may be truncated
    if (invoices.length >= 5000) {
      print('⚠️ WARNING: Performance insights may be incomplete. Result limit (5000) reached.');
    }

    final customers = await _fs.getAllCustomers();

    // Calculate insights
    Set<String> uniqueItems = {};
    Map<String, double> clientRevenue = {};
    Map<String, int> clientInvoiceCount = {};
    double totalRevenue = 0.0;
    int salesCount = 0;
    int purchaseCount = 0;
    double salesRevenue = 0.0;
    double purchaseRevenue = 0.0;

    for (final invoice in invoices) {
      // Track unique items
      for (final item in invoice.items) {
        if (item.quantity > 0) {
          uniqueItems.add(item.name);
        }
      }

      // Only count sales revenue for total revenue (use effectiveRevenue for refund adjustments)
      if (invoice.invoiceType == 'sales') {
        final invoiceRevenue = invoice.effectiveRevenue;
        totalRevenue += invoiceRevenue;
        salesCount++;
        salesRevenue += invoiceRevenue;

        // Track client revenue (only sales)
        final clientName = invoice.clientName;
        clientRevenue[clientName] = (clientRevenue[clientName] ?? 0.0) + invoiceRevenue;
        clientInvoiceCount[clientName] = (clientInvoiceCount[clientName] ?? 0) + 1;
      } else {
        // For purchase invoices, calculate from items (no refund adjustments)
        double invoiceRevenue = 0.0;
        for (final item in invoice.items) {
          if (item.quantity > 0) {
            invoiceRevenue += item.price * item.quantity;
          }
        }
        purchaseCount++;
        purchaseRevenue += invoiceRevenue;
      }
    }
    
    // Top clients
    final topClients = clientRevenue.entries.map((entry) => {
      'clientName': entry.key,
      'totalRevenue': entry.value,
      'invoiceCount': clientInvoiceCount[entry.key] ?? 0,
      'averageInvoiceValue': (clientInvoiceCount[entry.key] ?? 0) > 0 
          ? entry.value / (clientInvoiceCount[entry.key] ?? 1) 
          : 0.0,
    }).toList();
    
    topClients.sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));

    // Calculate previous period revenue for comparison
    final DateTime previousStartDate = _calculatePreviousPeriodStartDate(dateRange, startDate);
    final previousInvoices = await _fs.getInvoicesByDateRange(
      startDate: previousStartDate,
      endDate: startDate,
      limit: 5000,
    );

    double previousRevenue = 0.0;
    int previousItemsSold = 0;
    for (final invoice in previousInvoices) {
      if (invoice.invoiceType == 'sales') {
        previousRevenue += invoice.effectiveRevenue;
        previousItemsSold += invoice.items.fold(0, (sum, item) => sum + item.quantity);
      }
    }

    // Calculate percentage changes
    double revenueChange = 0.0;
    if (previousRevenue > 0) {
      revenueChange = ((totalRevenue - previousRevenue) / previousRevenue) * 100;
    } else if (totalRevenue > 0) {
      revenueChange = 100.0; // If previous was 0 but current has revenue, it's 100% increase
    }

    final currentItemsSold = invoices.where((inv) => inv.invoiceType == 'sales')
        .fold(0, (sum, inv) => sum + inv.items.fold(0, (s, item) => s + item.quantity));
    double itemsSoldChange = 0.0;
    if (previousItemsSold > 0) {
      itemsSoldChange = ((currentItemsSold - previousItemsSold) / previousItemsSold) * 100;
    } else if (currentItemsSold > 0) {
      itemsSoldChange = 100.0;
    }

    // Top revenue items (use same date range)
    final analytics = await getFilteredAnalytics(dateRange);
    final topRevenueItems = analytics.take(5).map((item) => {
      'itemName': item['itemName'],
      'revenue': item['revenue'],
      'quantitySold': item['quantitySold'],
      'category': ProductCategories.getCategoryForProduct(item['itemName']),
    }).toList();

    return {
      'insights': {
        'totalUniqueItems': uniqueItems.length,
        'totalCategories': ProductCategories.getAllCategories().length,
        'totalClients': customers.length,
        'averageRevenuePerItem': uniqueItems.isNotEmpty ? totalRevenue / uniqueItems.length : 0.0
      },
      'trends': {
        'revenueChange': revenueChange,
        'itemsSoldChange': itemsSoldChange,
      },
      'topRevenueItems': topRevenueItems,
      'topClients': topClients.take(5).toList(),
      'categoryPerformance': {
        'General': {
          'itemCount': uniqueItems.length,
          'totalQuantity': invoices.where((inv) => inv.invoiceType == 'sales').fold(0, (sum, inv) => sum + inv.items.fold(0, (s, item) => s + item.quantity)),
          'totalRevenue': salesRevenue,
        }
      },
      'invoiceTypeBreakdown': {
        'salesCount': salesCount,
        'purchaseCount': purchaseCount,
        'salesRevenue': salesRevenue,
        'purchaseRevenue': purchaseRevenue
      }
    };
  }
  
  Future<Map<String, dynamic>> getCustomerAnalytics(String customerId) async {
    final List<InvoiceModel> invoices = await _fs.getInvoicesByCustomerId(customerId);
    final CustomerModel? customer = await _fs.getCustomerById(customerId);

    if (customer == null) {
      return {
        'error': 'Customer not found',
      };
    }

    // Calculate key metrics
    double totalSpent = 0.0;
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;
    int totalInvoices = invoices.length;
    DateTime? firstPurchaseDate;
    DateTime? lastPurchaseDate;

    // Most purchased items tracking
    Map<String, int> itemPurchaseCount = {};

    for (final invoice in invoices) {
      // Use adjustedTotal for accurate spending (accounts for refund adjustments)
      final invoiceTotal = invoice.adjustedTotal;

      // Track item purchases (gross quantities - before returns)
      for (final item in invoice.items) {
        if (item.quantity > 0) {
          final itemName = item.name;
          itemPurchaseCount[itemName] = (itemPurchaseCount[itemName] ?? 0) + item.quantity;
        }
      }

      totalSpent += invoiceTotal;
      totalPaid += invoice.amountPaid;

      // Track purchase dates
      if (firstPurchaseDate == null || invoice.date.isBefore(firstPurchaseDate)) {
        firstPurchaseDate = invoice.date;
      }
      if (lastPurchaseDate == null || invoice.date.isAfter(lastPurchaseDate)) {
        lastPurchaseDate = invoice.date;
      }
    }

    totalOutstanding = totalSpent - totalPaid;
    
    // Sort items by purchase frequency
    final sortedItems = itemPurchaseCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topItems = sortedItems.take(5).map((entry) => {
      'name': entry.key,
      'quantity': entry.value,
    }).toList();
    
    return {
      'customer': {
        'id': customer.id,
        'name': customer.name,
        'phoneNumber': customer.phoneNumber,
        'createdAt': customer.createdAt.toIso8601String(),
      },
      'metrics': {
        'totalSpent': totalSpent,
        'totalPaid': totalPaid,
        'totalOutstanding': totalOutstanding,
        'totalInvoices': totalInvoices,
        'firstPurchase': firstPurchaseDate?.toIso8601String(),
        'lastPurchase': lastPurchaseDate?.toIso8601String(),
        'averageInvoiceValue': totalInvoices > 0 ? totalSpent / totalInvoices : 0,
      },
      'topItems': topItems,
    };
  }
  
  // Get aggregated customer data for all customers
  Future<List<Map<String, dynamic>>> getCustomerAggregatedData() async {
    final List<CustomerModel> customers = await _fs.getAllCustomers();

    // SCALABILITY FIX: Use date-filtered query (last 2 years) instead of all invoices
    final allInvoices = await _fs.getInvoicesByDateRange(
      startDate: DateTime.now().subtract(Duration(days: 730)), // Last 2 years
      limit: 10000, // Safety limit
    );

    // Warn if result may be truncated
    if (allInvoices.length >= 10000) {
      print('⚠️ WARNING: Customer aggregated data may be incomplete. Result limit (10000) reached.');
    }

    // Group invoices by customer ID
    final Map<String, List<InvoiceModel>> invoicesByCustomer = {};
    for (final invoice in allInvoices) {
      final customerId = invoice.customerId ?? 'unknown';
      if (!invoicesByCustomer.containsKey(customerId)) {
        invoicesByCustomer[customerId] = [];
      }
      invoicesByCustomer[customerId]!.add(invoice);
    }

    final List<Map<String, dynamic>> result = [];

    for (final customer in customers) {
      final invoices = invoicesByCustomer[customer.id] ?? [];

      double totalSpent = 0.0;
      double totalPaid = 0.0;
      int invoiceCount = invoices.length;

      for (final invoice in invoices) {
        // Use adjustedTotal for accurate spending (accounts for refund adjustments)
        totalSpent += invoice.adjustedTotal;
        totalPaid += invoice.amountPaid;
      }

      result.add({
        'customerId': customer.id,
        'customerName': customer.name,
        'phoneNumber': customer.phoneNumber,
        'invoiceCount': invoiceCount,
        'totalSpent': totalSpent,
        'totalPaid': totalPaid,
        'outstandingAmount': totalSpent - totalPaid,
      });
    }

    // Sort by total spent (descending)
    result.sort((a, b) => (b['totalSpent'] as double).compareTo(a['totalSpent'] as double));

    return result;
  }

  // Get customer-wise revenue breakdown with date range filtering
  Future<List<Map<String, dynamic>>> getCustomerWiseRevenue(String dateRange, {bool salesOnly = true}) async {
    try {
      // SCALABILITY FIX: Use date-filtered query
      final DateTime startDate = _calculateStartDate(dateRange);

      final invoices = await _fs.getInvoicesByDateRange(
        startDate: startDate,
        invoiceType: salesOnly ? 'sales' : null,
        limit: 5000,
      );

      print('Found ${invoices.length} invoices for customer-wise revenue (date range: $dateRange, salesOnly: $salesOnly)');

      // Warn if result may be truncated
      if (invoices.length >= 5000) {
        print('⚠️ WARNING: Customer-wise revenue may be incomplete. Result limit (5000) reached.');
      }

      final allCustomers = await _fs.getAllCustomers();

      if (invoices.isEmpty) {
        print('No invoices found for the selected date range');
        return [];
      }

      // Track customer analytics
      final Map<String, Map<String, dynamic>> customerAnalytics = {};

      for (final invoice in invoices) {
        // Skip non-sales invoices when salesOnly is true
        if (salesOnly && invoice.invoiceType.toLowerCase() != 'sales') {
          continue;
        }

        final customerId = invoice.customerId ?? 'unknown';
        final customerName = invoice.clientName.trim().isEmpty ? 'Unknown Customer' : invoice.clientName.trim();

        // Use effectiveRevenue (adjustedTotal) for accurate revenue after refunds
        final invoiceRevenue = invoice.effectiveRevenue;

        // Count total quantity of items
        int totalQuantity = 0;
        for (final item in invoice.items) {
          if (item.quantity > 0) {
            totalQuantity += item.quantity;
          }
        }

        if (!customerAnalytics.containsKey(customerId)) {
          customerAnalytics[customerId] = {
            'customerId': customerId,
            'customerName': customerName,
            'customerPhone': invoice.customerPhone ?? '',
            'invoiceCount': 0,
            'totalQuantity': 0,
            'totalRevenue': 0.0,
            'totalPaid': 0.0,
            'outstandingAmount': 0.0,
          };
        }

        customerAnalytics[customerId]!['invoiceCount'] = (customerAnalytics[customerId]!['invoiceCount'] as int) + 1;
        customerAnalytics[customerId]!['totalQuantity'] = (customerAnalytics[customerId]!['totalQuantity'] as int) + totalQuantity;
        customerAnalytics[customerId]!['totalRevenue'] = (customerAnalytics[customerId]!['totalRevenue'] as double) + invoiceRevenue;
        customerAnalytics[customerId]!['totalPaid'] = (customerAnalytics[customerId]!['totalPaid'] as double) + invoice.amountPaid;
        customerAnalytics[customerId]!['outstandingAmount'] = (customerAnalytics[customerId]!['outstandingAmount'] as double) + invoice.remainingAmount;

        // Debug logging for Dadu (Tejas)
        if (customerName.toLowerCase().contains('dadu') || customerName.toLowerCase().contains('tejas')) {
          print('DEBUG ${customerName} Invoice: ${invoice.invoiceNumber}');
          print('  Total: ${invoice.total}, RefundAdj: ${invoice.refundAdjustment}, Paid: ${invoice.amountPaid}');
          print('  AdjustedTotal: ${invoice.adjustedTotal}, RemainingAmount: ${invoice.remainingAmount}');
          print('  Running Outstanding: ${customerAnalytics[customerId]!['outstandingAmount']}');
        }
      }

      // Add pending refunds tracking
      try {
        final allReturns = await _fs.getReturns();
        final returnsInDateRange = allReturns.where((ret) =>
            ret.returnDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            ret.returnType == 'sales' &&
            !ret.isApplied).toList();

        for (final returnModel in returnsInDateRange) {
          final customerId = returnModel.customerId ?? 'unknown';
          if (customerAnalytics.containsKey(customerId)) {
            if (!customerAnalytics[customerId]!.containsKey('pendingRefunds')) {
              customerAnalytics[customerId]!['pendingRefunds'] = 0.0;
            }
            customerAnalytics[customerId]!['pendingRefunds'] =
                (customerAnalytics[customerId]!['pendingRefunds'] as double) + returnModel.refundAmount;
          }
        }
      } catch (e) {
        print('Error processing pending refunds in customer analytics: $e');
      }

      // Convert to list and filter out customers with 0 revenue
      final filteredResult = customerAnalytics.values
          .where((customer) => (customer['totalRevenue'] as double) > 0)
          .map((customer) {
            final result = Map<String, dynamic>.from(customer);
            // Ensure pendingRefunds field exists
            if (!result.containsKey('pendingRefunds')) {
              result['pendingRefunds'] = 0.0;
            }
            return result;
          })
          .toList();

      // Sort by revenue (highest first)
      filteredResult.sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));

      print('Returning ${filteredResult.length} customers with revenue data');
      for (final customer in filteredResult.take(5)) {
        print('Customer: ${customer['customerName']}, Invoices: ${customer['invoiceCount']}, Revenue: ${customer['totalRevenue']}, Paid: ${customer['totalPaid']}, Outstanding: ${customer['outstandingAmount']}, Pending Refunds: ${customer['pendingRefunds']}');
      }

      return filteredResult;
    } catch (e) {
      print('Error in getCustomerWiseRevenue: $e');
      return [];
    }
  }

  /// Get overdue payments organized by aging buckets (customer and item view)
  Future<Map<String, dynamic>> getOverduePaymentsBuckets() async {
    try {
      final invoices = await _fs.getAllInvoices();
      final now = DateTime.now();

      // Customer buckets data
      Map<String, Map<String, dynamic>> customerBuckets = {
        '1-7': {'count': 0, 'amount': 0.0},
        '8-30': {'count': 0, 'amount': 0.0},
        '31-60': {'count': 0, 'amount': 0.0},
        '60+': {'count': 0, 'amount': 0.0},
      };

      // Item buckets data
      Map<String, Map<String, dynamic>> itemBuckets = {
        '1-7': {'count': 0, 'amount': 0.0},
        '8-30': {'count': 0, 'amount': 0.0},
        '31-60': {'count': 0, 'amount': 0.0},
        '60+': {'count': 0, 'amount': 0.0},
      };

      // Track customer details
      Map<String, Map<String, dynamic>> customerDetails = {};
      // Track item details
      Map<String, Map<String, dynamic>> itemDetails = {};

      for (final invoice in invoices) {
        // Only process sales invoices with balance due
        if (invoice.invoiceType != 'sales' || invoice.paymentStatus != PaymentStatus.balanceDue) {
          continue;
        }

        final remainingAmount = invoice.remainingAmount;
        if (remainingAmount <= 0) continue;

        // Calculate days overdue (use followUpDate if available, otherwise invoice date)
        final dueDate = invoice.followUpDate ?? invoice.date;
        final daysOverdue = now.difference(dueDate).inDays;

        if (daysOverdue < 1) continue; // Not overdue yet

        // Determine bucket
        String bucket;
        if (daysOverdue <= 7) {
          bucket = '1-7';
        } else if (daysOverdue <= 30) {
          bucket = '8-30';
        } else if (daysOverdue <= 60) {
          bucket = '31-60';
        } else {
          bucket = '60+';
        }

        // Update customer buckets
        final customerId = invoice.customerId ?? invoice.clientName; // fallback to name if no ID
        final customerName = invoice.clientName;

        if (!customerDetails.containsKey(customerId)) {
          customerDetails[customerId] = {
            'name': customerName,
            'amount': 0.0,
            'invoiceCount': 0,
            'daysBucket': bucket,
            'lastInvoiceDate': invoice.date,
            'daysOverdue': daysOverdue,
          };
        }

        customerDetails[customerId]!['amount'] =
            (customerDetails[customerId]!['amount'] as double) + remainingAmount;
        customerDetails[customerId]!['invoiceCount'] =
            (customerDetails[customerId]!['invoiceCount'] as int) + 1;

        // Use the oldest bucket for the customer
        final existingBucket = customerDetails[customerId]!['daysBucket'] as String;
        final bucketOrder = ['1-7', '8-30', '31-60', '60+'];
        if (bucketOrder.indexOf(bucket) > bucketOrder.indexOf(existingBucket)) {
          customerDetails[customerId]!['daysBucket'] = bucket;
        }

        // Update item buckets
        for (final item in invoice.items) {
          if (item.quantity <= 0) continue;

          final itemName = item.name;
          final itemAmount = (item.price * item.quantity) * (remainingAmount / invoice.total);

          if (!itemDetails.containsKey(itemName)) {
            itemDetails[itemName] = {
              'name': itemName,
              'amount': 0.0,
              'debtorCount': <String>{}, // Set of customer IDs
              'daysBucket': bucket,
              'lastSoldDate': invoice.date,
              'daysOverdue': daysOverdue,
            };
          }

          itemDetails[itemName]!['amount'] =
              (itemDetails[itemName]!['amount'] as double) + itemAmount;
          (itemDetails[itemName]!['debtorCount'] as Set<String>).add(customerId ?? 'Unknown');

          // Use the oldest bucket for the item
          final existingBucket = itemDetails[itemName]!['daysBucket'] as String;
          final bucketOrder = ['1-7', '8-30', '31-60', '60+'];
          if (bucketOrder.indexOf(bucket) > bucketOrder.indexOf(existingBucket)) {
            itemDetails[itemName]!['daysBucket'] = bucket;
          }
        }
      }

      // Aggregate customer buckets
      for (final customer in customerDetails.values) {
        final bucket = customer['daysBucket'] as String;
        customerBuckets[bucket]!['count'] = (customerBuckets[bucket]!['count'] as int) + 1;
        customerBuckets[bucket]!['amount'] =
            (customerBuckets[bucket]!['amount'] as double) + (customer['amount'] as double);
      }

      // Aggregate item buckets
      for (final item in itemDetails.values) {
        final bucket = item['daysBucket'] as String;
        itemBuckets[bucket]!['count'] = (itemBuckets[bucket]!['count'] as int) + 1;
        itemBuckets[bucket]!['amount'] =
            (itemBuckets[bucket]!['amount'] as double) + (item['amount'] as double);
      }

      // Convert customer details to list with formatted data
      final customersList = customerDetails.values.map((c) {
        return {
          'name': c['name'],
          'amount': c['amount'],
          'invoiceCount': c['invoiceCount'],
          'daysBucket': c['daysBucket'],
          'lastInvoiceDate': _formatDate(c['lastInvoiceDate'] as DateTime),
          'daysOverdue': c['daysOverdue'],
        };
      }).toList();

      // Convert item details to list with formatted data
      final itemsList = itemDetails.values.map((i) {
        return {
          'name': i['name'],
          'amount': i['amount'],
          'debtorCount': (i['debtorCount'] as Set<String>).length,
          'daysBucket': i['daysBucket'],
          'lastSoldDate': _formatDate(i['lastSoldDate'] as DateTime),
          'daysOverdue': i['daysOverdue'],
        };
      }).toList();

      return {
        'customerBuckets': customerBuckets,
        'itemBuckets': itemBuckets,
        'customers': customersList,
        'items': itemsList,
      };
    } catch (e) {
      print('Error in getOverduePaymentsBuckets: $e');
      return {
        'customerBuckets': {},
        'itemBuckets': {},
        'customers': [],
        'items': [],
      };
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}