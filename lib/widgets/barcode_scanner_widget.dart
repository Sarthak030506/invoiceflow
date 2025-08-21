import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final Function(String) onBarcodeScanned;
  final VoidCallback? onManualEntry;

  const BarcodeScannerWidget({
    required this.onBarcodeScanned,
    this.onManualEntry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.blue.shade600, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Scan Barcode',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _simulateBarcodeScan(context),
                  icon: Icon(Icons.camera_alt, size: 5.w),
                  label: Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              if (onManualEntry != null) ...[
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualEntry,
                    icon: Icon(Icons.keyboard, size: 5.w),
                    label: Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _simulateBarcodeScan(BuildContext context) {
    // Simulate barcode scanning - in real implementation, this would use camera
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Barcode Scanner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Camera scanner would open here.'),
            SizedBox(height: 2.h),
            Text('For demo, enter barcode manually:'),
            SizedBox(height: 1.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'Barcode',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.pop(context);
                if (value.isNotEmpty) {
                  onBarcodeScanned(value);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}