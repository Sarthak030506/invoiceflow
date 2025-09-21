import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';
import '../models/invoice_model.dart';

Future<void> runOneTimeDataImportIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final fs = FirestoreService.instance;
  
  // Check if the initial data has already been imported
  final bool isImported = prefs.getBool('initial_data_imported') ?? false;

  // If it's already imported, do nothing and exit
  if (isImported) {
    print('Initial data already imported. Skipping.');
    return;
  }

  // This block now only runs ONCE, ever - on the very first app launch
  print('Performing one-time initial data import...');

  // Only clear invoices on the very first run to remove any hardcoded test data
  await fs.deleteAllInvoices();
  print('Hardcoded test invoices cleared from database (first run only).');

  // No hardcoded invoices are inserted here anymore.

  // IMPORTANT: Set the flag to true so this never runs again
  await prefs.setBool('initial_data_imported', true);
  print('One-time data import complete. Invoices will now be saved permanently.');
}

/// Clears all invoices from the database immediately (use with caution)
Future<void> clearAllInvoices() async {
  final fs = FirestoreService.instance;
  await fs.deleteAllInvoices();
  print('All invoices cleared from database.');
}

/// Resets the import flag and clears all invoices (use with caution)
Future<void> resetAndClearDatabase() async {
  final prefs = await SharedPreferences.getInstance();
  final fs = FirestoreService.instance;
  
  // Clear all invoices
  await fs.deleteAllInvoices();
  
  // Reset the import flag so the import can run again if needed
  await prefs.setBool('initial_data_imported', false);
  
  print('Database cleared and import flag reset.');
}