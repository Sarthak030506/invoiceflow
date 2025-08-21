import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';

import 'dart:io';

class CsvInvoiceService {
  final String assetPath;
  CsvInvoiceService({required this.assetPath});

  Future<List<InvoiceModel>> loadInvoicesFromCsv() async {
    String csvString;
final file = File(assetPath);
if (await file.exists()) {
  csvString = await file.readAsString();
} else {
  // Try to copy from asset, or create a file with just the header
  try {
    final assetCsv = await rootBundle.loadString(assetPath);
    await file.writeAsString(assetCsv);
    csvString = assetCsv;
  } catch (e) {
    // Asset not found, create file with just the header
    const header = 'Sr. No.,Item Particulars,Quantity,Rate (Rs.),Amount,Invoice Number\n';
    await file.writeAsString(header);
    csvString = header;
  }
}
    final lines = const LineSplitter().convert(csvString);

    List<InvoiceModel> invoices = [];
    List<InvoiceItem> currentItems = [];
    String invoiceNumber = '';
    int invoiceCounter = 1;
    double invoiceTotal = 0.0;

    String pendingInvoiceNumber = '';
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Detect new invoice table by header
      if (line.startsWith('Sr. No.') || line.startsWith('Sr No.')) {
        // Save previous invoice if exists
        if (currentItems.isNotEmpty) {
          invoices.add(
            InvoiceModel(
              id: pendingInvoiceNumber.isNotEmpty ? pendingInvoiceNumber : 'INV$invoiceCounter',
              invoiceNumber: pendingInvoiceNumber.isNotEmpty ? pendingInvoiceNumber : 'Invoice $invoiceCounter',
              clientName: '',
              date: DateTime.now(), // No date in CSV
              revenue: invoiceTotal,
              status: 'paid',
              items: List.from(currentItems),
              notes: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              amountPaid: invoiceTotal, // Set amount paid to match total for paid invoices
              paymentMethod: 'Cash',
            ),
          );
          invoiceCounter++;
          currentItems.clear();
          invoiceTotal = 0.0;
          pendingInvoiceNumber = '';
        }
        continue;
      }

      // Detect subtotal row
      final parts = line.split(',');
      if (parts.length >= 5 && parts[0].isEmpty && parts[4].isNotEmpty) {
        invoiceTotal = double.tryParse(parts[4].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        continue;
      }

      // Parse item row
      if (parts.length >= 6 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        final name = parts[1];
        // Try to extract quantity as int from e.g. "45 nos"
        final qtyMatch = RegExp(r'(\d+)').firstMatch(parts[2]);
        int quantity = qtyMatch != null ? int.parse(qtyMatch.group(1)!) : 1;
        double rate = double.tryParse(parts[3].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        double amount = double.tryParse(parts[4].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        // Get invoice number from column 5 if present
        if (parts.length > 5 && parts[5].trim().isNotEmpty) {
          pendingInvoiceNumber = parts[5].trim();
        }
        currentItems.add(InvoiceItem(
          name: name,
          quantity: quantity,
          price: rate,
        ));
        continue;
      }
    }
    // Add last invoice if any
    if (currentItems.isNotEmpty) {
      invoices.add(
        InvoiceModel(
          id: pendingInvoiceNumber.isNotEmpty ? pendingInvoiceNumber : 'INV$invoiceCounter',
          invoiceNumber: pendingInvoiceNumber.isNotEmpty ? pendingInvoiceNumber : 'Invoice $invoiceCounter',
          clientName: '',
          date: DateTime.now(),
          revenue: invoiceTotal,
          status: 'paid',
          items: List.from(currentItems),
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          amountPaid: invoiceTotal, // Set amount paid to match total for paid invoices
          paymentMethod: 'Cash',
        ),
      );
    }
    return invoices;
  }

  /// Appends a new invoice to the CSV file
  Future<void> addInvoice(InvoiceModel invoice) async {
    final file = File(assetPath);
    final exists = await file.exists();
    final sink = file.openWrite(mode: FileMode.append);
    // Write header if file is empty
    // Always write the header before each invoice block
    sink.writeln('Sr. No.,Item Particulars,Quantity,Rate (Rs.),Amount,Invoice Number');
    int srNo = 1;
    for (final item in invoice.items) {
      sink.writeln([
        srNo,
        item.name,
        item.quantity,
        item.price,
        (item.quantity * item.price).toStringAsFixed(2),
        invoice.invoiceNumber
      ].join(','));
      srNo++;
    }
    // Optionally, add a subtotal row
    sink.writeln(["", "", "", "", invoice.revenue.toStringAsFixed(2), invoice.invoiceNumber].join(","));
    await sink.flush();
    await sink.close();
  }
}

