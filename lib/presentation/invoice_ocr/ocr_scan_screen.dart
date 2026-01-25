import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:invoiceflow/providers/subscription_provider.dart';
import 'package:invoiceflow/services/ai/ocr_service.dart';
import 'package:invoiceflow/models/ocr_scan_model.dart';
import 'package:invoiceflow/presentation/invoice_ocr/widgets/ocr_results_sheet.dart';
import 'package:invoiceflow/widgets/feature_gate_overlay.dart';
import 'package:invoiceflow/services/catalog_service.dart';

class OCRScanScreen extends StatefulWidget {
  const OCRScanScreen({super.key});

  @override
  State<OCRScanScreen> createState() => _OCRScanScreenState();
}

class _OCRScanScreenState extends State<OCRScanScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final OCRService _ocrService = OCRService.instance;

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : _buildScanOptionsView(),
    );
  }

  Widget _buildScanOptionsView() {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        final scansRemaining = provider.ocrScansRemaining;
        final isPremium = provider.isPremium;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Illustration/Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.document_scanner,
                  size: 80,
                  color: Colors.blue[700],
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Scan Your Receipt',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Take a photo of your invoice or receipt and let AI auto-fill the details with smart item matching.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Usage info
              if (!isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scansRemaining > 0 ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scansRemaining > 0
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        scansRemaining > 0 ? Icons.check_circle : Icons.warning,
                        color: scansRemaining > 0 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          scansRemaining > 0
                              ? '$scansRemaining free scans remaining this month'
                              : 'Free scans limit reached. Upgrade to Premium!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scansRemaining > 0
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Scan buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _takePicture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _takePicture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Features list
              _buildFeaturesList(),

              if (!isPremium) ...[
                const SizedBox(height: 24),
                _buildUpgradePrompt(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          Icons.camera,
          'Take a clear photo',
          'Capture the full receipt with good lighting',
        ),
        _buildFeatureItem(
          Icons.auto_fix_high,
          'AI extracts data',
          'Gemini Vision reads items, prices, and totals',
        ),
        _buildFeatureItem(
          Icons.compare_arrows,
          'Smart matching',
          'Fuzzy algorithm matches items to your catalog',
        ),
        _buildFeatureItem(
          Icons.check_circle,
          'Review & create',
          'Verify matches and create invoice in seconds',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get unlimited OCR scans + all AI features',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('See Plans'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture(ImageSource source) async {
    // Check subscription access first
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);
    final canUse = await provider.checkFeatureAccess(
      'ocr',
      context: context,
      showDialog: false,
    );

    if (!canUse) {
      if (mounted) {
        FeatureGateOverlay.showOCRGate(
          context,
          () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/subscription');
          },
          limitReached: provider.ocrScansRemaining == 0,
        );
      }
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );

      if (photo == null) return;

      if (mounted) {
        await _processImage(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to capture image: $e');
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _progress = 0.1;
      _statusMessage = 'Uploading image...';
    });

    try {
      // Get catalog items for fuzzy matching
      setState(() {
        _progress = 0.2;
        _statusMessage = 'Loading catalog...';
      });

      final catalogItems = await CatalogService.instance.getAllItems();

      // Process OCR
      setState(() {
        _progress = 0.4;
        _statusMessage = 'Processing with AI...';
      });

      final scan = await _ocrService.scanReceipt(
        imageFile,
        catalogItems: catalogItems
            .map((item) => {
                  'id': item.id,
                  'name': item.name,
                })
            .toList(),
      );

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Complete!';
      });

      // Show results
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isProcessing = false);

        _showResultsSheet(scan);
      }
    } on OCRException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog('OCR processing failed: $e');
      }
    }
  }

  void _showResultsSheet(OCRScanModel scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OCRResultsSheet(scan: scan),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
