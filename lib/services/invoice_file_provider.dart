import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String> getInvoicesCsvPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/invoices.csv';
}
