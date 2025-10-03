import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/product_categories.dart';
import '../models/return_model.dart';
import './firestore_service.dart';

class AnalyticsService {
  final FirestoreService _fs = FirestoreService.instance;
  
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
  
  // Get customer purchase history and analytics
  // Add methods needed by analytics_screen.dart
  Future<List<Map<String, dynamic>>> getFilteredAnalytics(String dateRange, {bool salesOnly = true}) async {
    try {
      final allInvoices = await _fs.getAllInvoices();
      
      // Filter invoices by date range
      final DateTime startDate = _calculateStartDate(dateRange);
      
      // Filter invoices by date and type
      final invoices = allInvoices.where((invoice) {
        final isAfterDate = invoice.date.isAfter(startDate.subtract(const Duration(days: 1))); // Include the start date
        if (salesOnly) {
          return isAfterDate && (invoice.invoiceType.toLowerCase() == 'sales');
        }
        return isAfterDate;
      }).toList();
      
      print('Found ${invoices.length} invoices for date range: $dateRange (salesOnly: $salesOnly)');
      
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
      final allInvoices = await _fs.getAllInvoices();

      // Filter invoices by date range
      final DateTime startDate = _calculateStartDate(dateRange);
      final filteredInvoices = allInvoices.where((invoice) =>
          invoice.date.isAfter(startDate)).toList();

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
    final allInvoices = await _fs.getAllInvoices();
    final customers = await _fs.getAllCustomers();

    // Filter invoices by date range
    final DateTime startDate = _calculateStartDate(dateRange);
    final invoices = allInvoices.where((invoice) =>
        invoice.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();

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
        'revenueChange': 5.2, // Mock trend data
        'itemsSoldChange': 3.8,
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
    final List<Map<String, dynamic>> result = [];

    for (final customer in customers) {
      final List<InvoiceModel> invoices = await _fs.getInvoicesByCustomerId(customer.id);

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
      final allInvoices = await _fs.getAllInvoices();
      final allCustomers = await _fs.getAllCustomers();

      // Filter invoices by date range
      final DateTime startDate = _calculateStartDate(dateRange);

      // Filter invoices by date and type
      final invoices = allInvoices.where((invoice) {
        final isAfterDate = invoice.date.isAfter(startDate.subtract(const Duration(days: 1)));
        if (salesOnly) {
          return isAfterDate && (invoice.invoiceType.toLowerCase() == 'sales');
        }
        return isAfterDate;
      }).toList();

      print('Found ${invoices.length} invoices for customer-wise revenue (date range: $dateRange, salesOnly: $salesOnly)');

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
}