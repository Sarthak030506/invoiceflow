import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/invoice_file_provider.dart' as file_provider;

/// Gets the appropriate CSV path for the current platform
Future<String> getCsvPath() async {
  // Handle web platform separately
  if (kIsWeb) {
    return 'assets/images/data/invoices.csv';
  }
  
  // For non-web platforms, use the existing file provider
  try {
    return await file_provider.getInvoicesCsvPath();
  } catch (e) {
    print('Error getting CSV path: $e');
    // Fall back to assets path
    return 'assets/images/data/invoices.csv';
  }
}
