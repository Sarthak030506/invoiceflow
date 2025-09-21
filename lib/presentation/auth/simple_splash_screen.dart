import 'package:flutter/material.dart';
import '../../services/simple_auth_service.dart';
import '../../services/invoice_service.dart';
import '../../utils/csv_path_utils.dart';
import 'simple_login_screen.dart';
import '../home_dashboard/home_dashboard.dart';

class SimpleSplashScreen extends StatefulWidget {
  @override
  _SimpleSplashScreenState createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Initialize InvoiceService
      final csvPath = await getCsvPath();
      await InvoiceService.initialize(csvPath: csvPath);
      
      await Future.delayed(Duration(seconds: 1)); // Splash delay
      
      final isLoggedIn = await SimpleAuthService.isLoggedIn();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isLoggedIn 
                ? HomeDashboard(csvPath: csvPath)
                : SimpleLoginScreen(),
          ),
        );
      }
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SimpleLoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'InvoiceFlow',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}