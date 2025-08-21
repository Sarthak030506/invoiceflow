import 'package:dio/dio.dart';
import '../models/invoice_model.dart';

class GoogleSheetsService {
  static const String _baseUrl = String.fromEnvironment(
      'GOOGLE_SHEETS_BASE_URL',
      defaultValue: 'https://docs.google.com/spreadsheets/d');
  static const String _spreadsheetId = String.fromEnvironment(
      'GOOGLE_SHEETS_ID',
      defaultValue: '17Tj5xSMroxPDuuA0r8DZ5-DKgpENvv5ThMPVdQAdQFA');
  static const String _sheetName =
      String.fromEnvironment('GOOGLE_SHEETS_NAME', defaultValue: 'Sheet1');

  final Dio _dio;

  GoogleSheetsService() : _dio = Dio() {
    _dio.options.connectTimeout = Duration(seconds: 10);
    _dio.options.receiveTimeout = Duration(seconds: 10);
    _dio.options.headers = {
      'User-Agent': 'InvoiceFlow/1.0.0',
    };
  }

  /// Fetches invoice data from Google Sheets
  /// Returns a list of InvoiceModel objects
  Future<List<InvoiceModel>> fetchInvoicesFromSheets() async {
    try {
      final csvUrl = _buildCsvUrl();
      print('Fetching data from: $csvUrl');

      final response = await _dio.get(csvUrl);

      if (response.statusCode == 200) {
        return _parseCsvData(response.data);
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Error fetching Google Sheets data: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  /// Builds the CSV export URL for Google Sheets
  String _buildCsvUrl() {
    // Format: https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/export?format=csv&gid=0
    return '$_baseUrl/$_spreadsheetId/export?format=csv&gid=0';
  }

  /// Parses CSV data into InvoiceModel objects
  List<InvoiceModel> _parseCsvData(String csvData) {
    final lines = csvData.split('\n');
    if (lines.isEmpty) return [];

    final headers = _parseCsvLine(lines[0]);
    final invoices = <InvoiceModel>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final values = _parseCsvLine(line);
        if (values.length >= headers.length) {
          final rowData = <String, dynamic>{};

          for (int j = 0; j < headers.length; j++) {
            rowData[headers[j].toLowerCase().trim()] = values[j].trim();
          }

          // Map common column names to expected format
          final mappedData = _mapColumnNames(rowData);
          final invoice = InvoiceModel.fromGoogleSheetsRow(mappedData);
          invoices.add(invoice);
        }
      } catch (e) {
        print('Error parsing line $i: $e');
        continue;
      }
    }

    return invoices;
  }

  /// Parses a single CSV line handling quoted values
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    values.add(buffer.toString());
    return values;
  }

  /// Maps various column name formats to standardized names
  Map<String, dynamic> _mapColumnNames(Map<String, dynamic> rowData) {
    final mappedData = <String, dynamic>{};

    // Define column mappings
    final columnMappings = {
      'invoice_number': [
        'invoice number',
        'invoice_number',
        'invoicenumber',
        'inv_no'
      ],
      'client_name': [
        'client name',
        'client_name',
        'clientname',
        'customer',
        'company'
      ],
      'date': ['date', 'invoice_date', 'created_date', 'issue_date'],
      'revenue': ['revenue', 'total', 'amount', 'total_amount', 'value'],
      'status': ['status', 'payment_status', 'state'],
      'items': ['items', 'description', 'services', 'products'],
      'notes': ['notes', 'comments', 'remarks'],
      'created_at': ['created_at', 'created', 'date_created'],
      'updated_at': ['updated_at', 'updated', 'date_updated'],
    };

    // Map each standardized field
    for (final entry in columnMappings.entries) {
      final standardField = entry.key;
      final possibleColumns = entry.value;

      for (final column in possibleColumns) {
        if (rowData.containsKey(column)) {
          mappedData[standardField] = rowData[column];
          break;
        }
      }
    }

    // Generate ID if not present
    if (!mappedData.containsKey('id')) {
      mappedData['id'] = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }

    return mappedData;
  }

  /// Fetches recent invoices (last 10)
  Future<List<InvoiceModel>> fetchRecentInvoices() async {
    try {
      final allInvoices = await fetchInvoicesFromSheets();

      // Sort by date (newest first) and take the most recent 10
      allInvoices.sort((a, b) => b.date.compareTo(a.date));

      return allInvoices.take(10).toList();
    } catch (e) {
      print('Error fetching recent invoices: $e');
      rethrow;
    }
  }

  /// Fetches dashboard metrics from invoices
  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    try {
      final allInvoices = await fetchInvoicesFromSheets();

      if (allInvoices.isEmpty) {
        return {
          'totalItemsSold': 0,
          'totalRevenue': 0.0,
          'totalInvoices': 0,
          'itemsSoldChange': 0.0,
          'revenueChange': 0.0,
          'invoicesChange': 0.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }

      // Calculate total items sold
      int totalItemsSold = 0;
      for (final invoice in allInvoices) {
        totalItemsSold +=
            invoice.items.fold(0, (sum, item) => sum + item.quantity);
      }

      // Calculate total revenue
      double totalRevenue =
          allInvoices.fold(0.0, (sum, invoice) => sum + invoice.revenue);

      // Calculate changes (mock calculation - would need historical data for real changes)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      double itemsSoldChange =
          (random % 20) - 10; // Random change between -10 and +10
      double revenueChange =
          (random % 30) - 15; // Random change between -15 and +15
      double invoicesChange =
          (random % 10) - 5; // Random change between -5 and +5

      return {
        'totalItemsSold': totalItemsSold,
        'totalRevenue': totalRevenue,
        'totalInvoices': allInvoices.length,
        'itemsSoldChange': itemsSoldChange,
        'revenueChange': revenueChange,
        'invoicesChange': invoicesChange,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error fetching dashboard metrics: $e');
      rethrow;
    }
  }

  /// Validates connection to Google Sheets
  Future<bool> validateConnection() async {
    try {
      final response = await _dio.get(_buildCsvUrl());
      return response.statusCode == 200;
    } catch (e) {
      print('Connection validation failed: $e');
      return false;
    }
  }
}
