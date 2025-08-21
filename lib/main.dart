import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

// Screens
import 'presentation/auth/auth_wrapper.dart';
import 'presentation/inventory_screen/inventory_screen.dart';
import 'presentation/inventory_screen/new_inventory_detail_screen.dart' as NewInventoryDetail;

// Providers
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';

// Services
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/invoice_file_provider.dart';
import 'services/bulk_invoice_import.dart';
import 'services/invoice_service.dart';

// Core
import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'animations/fluid_animations.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/rounded_theme_extensions.dart';

// Models
import 'models/invoice_model.dart';

Future<String> getInvoicesCsvPath() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'invoices.csv');
  }
  return 'assets/images/data/invoices.csv';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // You might want to show a user-friendly error message here
    // or fallback to a different configuration
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize InvoiceService early so any consumers (e.g., NotificationService)
  // can safely access InvoiceService.instance during startup
  try {
    final csvPath = await getInvoicesCsvPath();
    await InvoiceService.initialize(csvPath: csvPath);
    print('InvoiceService initialized with csvPath: ' + csvPath);
  } catch (e, st) {
    print('Error initializing InvoiceService: ' + e.toString());
    print(st);
  }

  // Initialize notification service
  try {
    await NotificationService().init();
    print('NotificationService initialized');
  } catch (e, st) {
    print('Error in NotificationService.init: $e');
    print(st);
  }
  
  // Initialize background service for daily reminders
  try {
    await BackgroundService.initialize();
    print('BackgroundService initialized');
  } catch (e, st) {
    print('Error in BackgroundService.initialize: $e');
    print(st);
  }

  // Insert hardcoded data into DB (one-time only)
  try {
    await runOneTimeDataImportIfNeeded();
    print('One-time data import complete');
  } catch (e, st) {
    print('Error in runOneTimeDataImportIfNeeded: $e');
    print(st);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return MaterialApp(
              title: 'InvoiceFlow',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              // Use AuthWrapper to handle authentication state
              home: const AuthWrapper(),
              // Define all routes using AppRoutes
              onGenerateRoute: (settings) {
                // Try to find the route in AppRoutes.routes first
                final routeBuilder = AppRoutes.routes[settings.name];
                if (routeBuilder != null) {
                  return MaterialPageRoute(
                    builder: routeBuilder,
                    settings: settings,
                  );
                }

                // Handle dynamic routes
                if (settings.name?.startsWith(AppRoutes.inventoryDetailScreen) == true) {
                  final itemId = settings.name!.split('/').last;
                  return FluidAnimations.createSlideUpRoute(
                    child: NewInventoryDetail.InventoryDetailScreen(itemId: itemId),
                    settings: settings,
                  );
                }

                // Default route when no named route matches
                return MaterialPageRoute(
                  builder: (context) => const AuthWrapper(),
                  settings: settings,
                );
              },
            );
          },
        );
      },
    );
  }
}
