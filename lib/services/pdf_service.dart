import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../utils/app_logger.dart';

/// Service to handle PDF generation, download, and sharing for invoices
class PdfService {
  static PdfService? _instance;
  PdfService._internal();

  static PdfService get instance {
    _instance ??= PdfService._internal();
    return _instance!;
  }

  /// Generate PDF document for an invoice (optimized with isolate)
  Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    // Use compute to run PDF generation in a separate isolate
    // This prevents UI freezing during PDF creation
    return await compute(_generatePdfInIsolate, invoice);
  }

  /// Static method to generate PDF in an isolate
  /// This is called by compute() and runs in a background thread
  static Future<Uint8List> _generatePdfInIsolate(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with branding
              _buildHeader(invoice),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2, color: PdfColors.blue800),
              pw.SizedBox(height: 20),

              // Invoice & Customer Details in a Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildInvoiceDetails(invoice),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _buildCustomerDetails(invoice),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),

              // Totals
              _buildTotals(invoice),

              pw.Spacer(),

              // Footer
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
                _buildNotes(invoice),
              ],

              pw.SizedBox(height: 15),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build header section
  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICEFLOW',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Professional Invoice Management',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: invoice.status.toLowerCase() == 'paid'
                    ? PdfColors.green100
                    : invoice.remainingAmount > 0
                        ? PdfColors.orange100
                        : PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: invoice.status.toLowerCase() == 'paid'
                      ? PdfColors.green600
                      : invoice.remainingAmount > 0
                          ? PdfColors.orange600
                          : PdfColors.blue600,
                  width: 1.5,
                ),
              ),
              child: pw.Text(
                invoice.status.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: invoice.status.toLowerCase() == 'paid'
                      ? PdfColors.green900
                      : invoice.remainingAmount > 0
                          ? PdfColors.orange900
                          : PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoice.invoiceType.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build invoice details section
  static pw.Widget _buildInvoiceDetails(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildDetailRow('Invoice #:', invoice.invoiceNumber),
          pw.SizedBox(height: 6),
          _buildDetailRow('Date:', _formatDate(invoice.date)),
          pw.SizedBox(height: 6),
          _buildDetailRow('Payment:', invoice.paymentMethod),
          if (invoice.modifiedFlag) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.yellow200,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.orange600, width: 1),
              ),
              child: pw.Text(
                'MODIFIED',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build customer details section
  static pw.Widget _buildCustomerDetails(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey800,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Icon(
                  pw.IconData(0xe7fd), // person icon
                  size: 14,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Bill To',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            invoice.clientName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (invoice.customerPhone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.customerPhone!,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.symmetric(
        outside: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
        inside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            _buildTableCell('Item Description', isHeader: true, color: PdfColors.white),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center, color: PdfColors.white),
            _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right, color: PdfColors.white),
            _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right, color: PdfColors.white),
          ],
        ),
        // Items
        ...invoice.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _buildTableCell(item.name, fontSize: 11),
              _buildTableCell('${item.quantity}', align: pw.TextAlign.center, fontSize: 11),
              _buildTableCell('₹${item.price.toStringAsFixed(2)}', align: pw.TextAlign.right, fontSize: 11),
              _buildTableCell(
                '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                align: pw.TextAlign.right,
                fontSize: 11,
                isBold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 280,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(7),
                    topRight: pw.Radius.circular(7),
                  ),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow('Subtotal:', '₹${invoice.total.toStringAsFixed(2)}'),
                    if (invoice.refundAdjustment != 0) ...[
                      pw.SizedBox(height: 6),
                      _buildTotalRow(
                        'Refund Adjustment:',
                        '-₹${invoice.refundAdjustment.abs().toStringAsFixed(2)}',
                        color: PdfColors.red700,
                      ),
                    ],
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                child: _buildTotalRow(
                  'TOTAL:',
                  '₹${invoice.adjustedTotal.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 15,
                  color: PdfColors.white,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  children: [
                    _buildTotalRow(
                      'Amount Paid:',
                      '₹${invoice.amountPaid.toStringAsFixed(2)}',
                      color: PdfColors.green700,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: invoice.remainingAmount > 0 ? PdfColors.orange50 : PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: _buildTotalRow(
                        'Balance Due:',
                        '₹${invoice.remainingAmount.toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 14,
                        color: invoice.remainingAmount > 0 ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build notes section
  static pw.Widget _buildNotes(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.yellow200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe873), // note icon
                size: 12,
                color: PdfColors.orange800,
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            invoice.notes!,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer section
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated by InvoiceFlow - Professional Invoice Management',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Document generated on ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build detail row
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  /// Helper: Build table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    double? fontSize,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize ?? (isHeader ? 11 : 10),
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }

  /// Helper: Build total row
  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Helper: Format date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Generate outstanding invoices summary PDF
  Future<Uint8List> generateOutstandingInvoicesSummaryPdf({
    required String customerName,
    required String? customerPhone,
    required List<InvoiceModel> unpaidInvoices,
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalAmount = unpaidInvoices.fold<double>(0, (sum, inv) => sum + inv.adjustedTotal);
    final totalPaid = unpaidInvoices.fold<double>(0, (sum, inv) => sum + inv.amountPaid);
    final totalDue = totalAmount - totalPaid;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICEFLOW',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Outstanding Invoices Statement',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.red600, width: 1.5),
                    ),
                    child: pw.Text(
                      'PAYMENT DUE',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(thickness: 2, color: PdfColors.red800),
              pw.SizedBox(height: 20),

              // Customer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red800,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Icon(
                            pw.IconData(0xe7fd),
                            size: 14,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'Customer',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      customerName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (customerPhone != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        customerPhone,
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Statement Date: ${_formatDate(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // Outstanding Invoices Table
              pw.Text(
                'Outstanding Invoices (${unpaidInvoices.length})',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.symmetric(
                  outside: pw.BorderSide(color: PdfColors.grey400, width: 1.5),
                  inside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red800),
                    children: [
                      _buildTableCell('Invoice #', isHeader: true, color: PdfColors.white),
                      _buildTableCell('Date', isHeader: true, color: PdfColors.white),
                      _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right, color: PdfColors.white),
                      _buildTableCell('Paid', isHeader: true, align: pw.TextAlign.right, color: PdfColors.white),
                      _buildTableCell('Due', isHeader: true, align: pw.TextAlign.right, color: PdfColors.white),
                    ],
                  ),
                  // Invoice rows
                  ...unpaidInvoices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final invoice = entry.value;
                    final isEven = index % 2 == 0;
                    final due = invoice.adjustedTotal - invoice.amountPaid;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell(invoice.invoiceNumber, fontSize: 10),
                        _buildTableCell(_formatDate(invoice.date), fontSize: 10),
                        _buildTableCell('₹${invoice.adjustedTotal.toStringAsFixed(2)}', align: pw.TextAlign.right, fontSize: 10),
                        _buildTableCell('₹${invoice.amountPaid.toStringAsFixed(2)}', align: pw.TextAlign.right, fontSize: 10),
                        _buildTableCell(
                          '₹${due.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          fontSize: 10,
                          isBold: true,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 25),

              // Summary Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 280,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.red300, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(7),
                              topRight: pw.Radius.circular(7),
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              _buildTotalRow('Total Amount:', '₹${totalAmount.toStringAsFixed(2)}'),
                              pw.SizedBox(height: 6),
                              _buildTotalRow('Amount Paid:', '₹${totalPaid.toStringAsFixed(2)}', color: PdfColors.green700),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(14),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.red800,
                            borderRadius: pw.BorderRadius.only(
                              bottomLeft: pw.Radius.circular(7),
                              bottomRight: pw.Radius.circular(7),
                            ),
                          ),
                          child: _buildTotalRow(
                            'TOTAL DUE:',
                            '₹${totalDue.toStringAsFixed(2)}',
                            isBold: true,
                            fontSize: 16,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Payment Request Message
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.yellow50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.orange400, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Request',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'This statement shows your outstanding invoices. Please arrange for payment of ₹${totalDue.toStringAsFixed(2)} at your earliest convenience.',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Get temporary file path for invoice PDF (for WhatsApp sharing)
  Future<String> getInvoicePdfPath(InvoiceModel invoice) async {
    try {
      AppLogger.info('Generating PDF file: ${invoice.invoiceNumber}', 'PdfService');

      // Generate PDF
      final pdfBytes = await generateInvoicePdf(invoice);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      // Save PDF to temporary file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      AppLogger.info('PDF saved to: $filePath', 'PdfService');

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate PDF file', 'PdfService', e, stackTrace);
      rethrow;
    }
  }

  /// Get temporary file path for outstanding invoices summary PDF
  Future<String> getOutstandingInvoicesSummaryPdfPath({
    required String customerName,
    required String? customerPhone,
    required List<InvoiceModel> unpaidInvoices,
  }) async {
    try {
      AppLogger.info('Generating outstanding invoices summary for: $customerName', 'PdfService');

      // Generate PDF
      final pdfBytes = await generateOutstandingInvoicesSummaryPdf(
        customerName: customerName,
        customerPhone: customerPhone,
        unpaidInvoices: unpaidInvoices,
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Outstanding_Statement_${customerName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      // Save PDF to temporary file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      AppLogger.info('Summary PDF saved to: $filePath', 'PdfService');

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate summary PDF', 'PdfService', e, stackTrace);
      rethrow;
    }
  }

  /// Share invoice PDF via platform share sheet
  Future<void> shareInvoicePdf(InvoiceModel invoice) async {
    try {
      AppLogger.info('Generating PDF for sharing: ${invoice.invoiceNumber}', 'PdfService');

      // Generate PDF
      final pdfBytes = await generateInvoicePdf(invoice);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      // Save PDF to temporary file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      AppLogger.info('PDF saved to: $filePath', 'PdfService');

      // Share file using share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Invoice ${invoice.invoiceNumber}',
        text: 'Invoice for ${invoice.clientName} - Total: ₹${invoice.adjustedTotal.toStringAsFixed(2)}',
      );

      AppLogger.info('PDF shared successfully', 'PdfService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to share PDF', 'PdfService', e, stackTrace);
      rethrow;
    }
  }

  /// Download invoice PDF to device storage
  Future<String> downloadInvoicePdf(InvoiceModel invoice) async {
    try {
      AppLogger.info('Generating PDF for download: ${invoice.invoiceNumber}', 'PdfService');

      // Generate PDF
      final pdfBytes = await generateInvoicePdf(invoice);

      // Get downloads directory (or documents for iOS)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create filename with timestamp
      final fileName = 'Invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Save PDF to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      AppLogger.info('PDF downloaded to: $filePath', 'PdfService');

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to download PDF', 'PdfService', e, stackTrace);
      rethrow;
    }
  }

  /// Print invoice PDF (for future use)
  Future<void> printInvoicePdf(InvoiceModel invoice) async {
    try {
      AppLogger.info('Preparing invoice for printing: ${invoice.invoiceNumber}', 'PdfService');

      // Generate PDF
      final pdfBytes = await generateInvoicePdf(invoice);

      // Open print dialog
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'Invoice_${invoice.invoiceNumber}.pdf',
      );

      AppLogger.info('Print dialog opened', 'PdfService');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to print PDF', 'PdfService', e, stackTrace);
      rethrow;
    }
  }
}
