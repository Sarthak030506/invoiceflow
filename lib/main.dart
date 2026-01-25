import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:invoiceflow/providers/auth_provider.dart';
import 'package:invoiceflow/providers/inventory_provider.dart';
import 'package:invoiceflow/providers/subscription_provider.dart';

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
    debugPrint('InvoiceFlow Web Version: 1.0.2 (Mobile Frame Fix Setup)');
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

  Widget app = Sizer(
    builder: (context, orientation, deviceType) {
      return const MyApp();
    },
  );

  // WEB-ONLY: Center the app and limit width to simulate mobile device
  if (kIsWeb) {
    debugPrint('Applying Web Mobile Frame Constraints');
    app = Container(
      color: Colors.grey.shade400, // Darker gray to be more visible
      alignment: Alignment.center,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRect( // Ensure content doesn't bleed out
            child: app,
          ),
        ),
      ),
    );
  }

  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: MaterialApp(
        title: 'InvoiceFlow',
        builder: (context, child) {
          // Wrap with ResponsiveFramework for desktop support
          child = ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 599, name: MOBILE),
              const Breakpoint(start: 600, end: 1023, name: TABLET),
              const Breakpoint(start: 1024, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          );

          // Force textScaleFactor to 1.0 for consistent sizing
          final mediaQuery = MediaQuery.of(context);

          // WEB-ONLY: Override MediaQuery size to match our fake mobile frame (500px)
          // This forces ResponsiveHelper.isMobile() to return true, showing Bottom Nav instead of Drawer.
          if (kIsWeb) {
            return MediaQuery(
              data: mediaQuery.copyWith(
                size: Size(500, mediaQuery.size.height),
                textScaleFactor: 1.0,
              ),
              child: child!,
            );
          }

          return MediaQuery(
            data: mediaQuery.copyWith(textScaleFactor: 1.0),
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