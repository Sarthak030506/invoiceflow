import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:invoiceflow/services/items_service.dart';
import 'package:invoiceflow/providers/auth_provider.dart';
import '../../home_dashboard/home_dashboard.dart';

class CsvUploadScreen extends StatefulWidget {
  const CsvUploadScreen({Key? key}) : super(key: key);

  @override
  State<CsvUploadScreen> createState() => _CsvUploadScreenState();
}

class _CsvUploadScreenState extends State<CsvUploadScreen> {
  final ItemsService _itemsService = ItemsService();
  bool _isLoading = false;
  String _fileName = '';
  String _status = '';
  bool _hasValidFile = false;
  List<Map<String, dynamic>> _previewData = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Items'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 4.w),
            _buildUploadArea(),
            if (_hasValidFile) ...[
              SizedBox(height: 4.w),
              _buildPreviewSection(),
            ],
            SizedBox(height: 4.w),
            _buildImportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Items from CSV/Excel',
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a CSV file to add items to your product catalog',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _hasValidFile ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasValidFile ? Colors.green[300]! : Colors.grey[300]!,
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _hasValidFile ? Icons.check_circle : Icons.cloud_upload,
            size: 48,
            color: _hasValidFile ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(height: 16),
          if (_fileName.isNotEmpty) ...[
            Text(
              _fileName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
          ],
          Text(
            _hasValidFile 
              ? 'File uploaded successfully!'
              : 'Tap to select CSV file',
            style: TextStyle(
              fontSize: 11.sp,
              color: _hasValidFile ? Colors.green[700] : Colors.grey[600],
              fontWeight: _hasValidFile ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (_status.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              _status,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                ? SizedBox(
                    height: 4.w,
                    width: 4.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _hasValidFile ? 'Choose Different File' : 'Choose File',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.grey[700], size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Preview (First 5 rows)',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                Text(
                  '${_previewData.length} items',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _previewData.isEmpty 
                  ? []
                  : _previewData.first.keys.map((key) => 
                      DataColumn(
                        label: Text(
                          key,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).toList(),
                rows: _previewData.take(5).map((row) =>
                  DataRow(
                    cells: row.values.map((value) =>
                      DataCell(
                        Text(
                          value.toString(),
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      ),
                    ).toList(),
                  ),
                ).toList(),
                headingRowHeight: 6.w,
                dataRowHeight: 5.w,
                columnSpacing: 4.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _importItems,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2.5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 4.w,
                  width: 4.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 3.w),
                Text('Importing items...'),
              ],
            )
          : Text(
              'Import ${_previewData.length} Items to Catalog',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _status = 'Selecting file...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _fileName = result.files.single.name;
          _status = 'Processing file...';
        });
        await _processFile(file);
      } else {
        setState(() {
          _status = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error selecting file: $e';
        _hasValidFile = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processFile(File file) async {
    try {
      final input = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);
      
      if (rows.isNotEmpty) {
        final headers = rows.first.map((e) => e.toString()).toList();
        final List<Map<String, dynamic>> data = [];
        
        for (var i = 1; i < rows.length; i++) {
          final Map<String, dynamic> rowData = {};
          for (var j = 0; j < headers.length; j++) {
            rowData[headers[j]] = rows[i][j];
          }
          data.add(rowData);
        }
        
        setState(() {
          _previewData = data;
          _hasValidFile = true;
          _status = 'File processed successfully';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error processing file: $e';
        _hasValidFile = false;
      });
    }
  }

  Future<void> _importItems() async {
    setState(() {
      _isLoading = true;
      _status = 'Importing items...';
    });

    try {
      List<ProductCatalogItem> catalogItems = [];
      List<String> errors = [];

      for (int i = 0; i < _previewData.length; i++) {
        try {
          final item = _createItemFromRow(_previewData[i], i);
          if (item != null) {
            catalogItems.add(item);
          }
        } catch (e) {
          errors.add('Row ${i + 1} error: $e');
        }
      }

      // Import all items to catalog in batch
      if (catalogItems.isNotEmpty) {
        await _itemsService.addMultipleItems(catalogItems);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported ${catalogItems.length} items to your catalog!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (errors.isNotEmpty) {
        // Show error details if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${errors.length} items had errors'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Mark onboarding as complete and navigate to home
      if (mounted) {
        context.read<AuthProvider>().completeOnboarding();
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
          ),
          (route) => false,
        );
      }

    } catch (e) {
      setState(() {
        _status = 'Import failed: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ProductCatalogItem? _createItemFromRow(Map<String, dynamic> row, int index) {
    String? name;
    double? price;
    String? sku;
    String category = 'General';
    String unit = 'pcs';
    String? description;
    String? barcode;

    // Extract data from row
    for (final entry in row.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value?.toString().trim();

      if (value == null || value.isEmpty) continue;

      if (key.contains('name') || key.contains('item')) {
        name = value;
      } else if (key.contains('price') || key.contains('rate') || key.contains('cost')) {
        price = double.tryParse(value);
      } else if (key.contains('sku') || key.contains('code')) {
        sku = value;
      } else if (key.contains('category') || key.contains('type')) {
        category = value;
      } else if (key.contains('unit') || key.contains('uom')) {
        unit = value;
      } else if (key.contains('description') || key.contains('desc')) {
        description = value;
      } else if (key.contains('barcode') || key.contains('bar_code')) {
        barcode = value;
      }
    }

    // Validate required fields
    if (name == null || name.isEmpty || price == null || price <= 0) {
      return null;
    }

    // Generate SKU if not provided
    sku = sku?.isNotEmpty == true ? sku : 'CSV${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}_$index';

    return ProductCatalogItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_csv_$index',
      name: name,
      sku: sku!,
      category: category,
      unit: unit,
      rate: price,
      barcode: barcode,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}