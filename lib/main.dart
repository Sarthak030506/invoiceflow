import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:invoiceflow/providers/auth_provider.dart';
import 'package:invoiceflow/providers/inventory_provider.dart';

import 'package:invoiceflow/presentation/auth/auth_gate.dart';
import 'package:invoiceflow/presentation/home_dashboard/home_dashboard.dart';
import 'package:invoiceflow/theme/app_theme.dart';

import 'firebase_options.dart';

import 'package:invoiceflow/services/invoice_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:invoiceflow/constants/app_scaling.dart';
import 'package:invoiceflow/utils/app_logger.dart';

import 'package:invoiceflow/routes/app_routes.dart';
import 'package:invoiceflow/presentation/inventory_screen/inventory_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Google Sign In
    await GoogleSignIn().signInSilently();

    await InvoiceService.initialize(csvPath: 'assets/images/data/invoices.csv');
    AppLogger.info('Firebase and Google Services initialized successfully', 'App');
  } catch (e) {
    AppLogger.error('Initialization error', 'App', e);
  }

  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return const MyApp();
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'InvoiceFlow',
        builder: (context, child) {
          // Force textScaleFactor to 1.0
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
        // Apply the modern blue/green application theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/home': (context) => const HomeDashboard(
                csvPath: 'assets/images/data/invoices.csv',
              ),
          // Include all routes from AppRoutes
          ...AppRoutes.routes,
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/inventory/item/') == true) {
            final itemId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => InventoryProvider(),
                child: InventoryDetailScreen(itemId: itemId),
              ),
            );
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}