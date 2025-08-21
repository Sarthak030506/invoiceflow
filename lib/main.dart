import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'animations/fluid_animations.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/rounded_theme_extensions.dart';

import 'services/invoice_file_provider.dart';
import 'services/invoice_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'presentation/home_dashboard/home_dashboard.dart';
import 'presentation/invoices_list_screen/invoices_list_screen.dart';
import 'presentation/invoice_detail_screen/invoice_detail_screen.dart';
import 'presentation/analytics_screen/analytics_screen.dart';
import 'presentation/analytics_redesign/analytics_redesign_screen.dart';
import 'presentation/analytics_redesign/analytics_main_screen.dart';
import 'presentation/profile_screen/profile_screen.dart';
import 'presentation/customers_screen/customers_screen.dart';
import 'presentation/customers_screen/customer_detail_screen.dart';
import 'presentation/inventory_screen/inventory_screen.dart';
import 'presentation/inventory_screen/inventory_detail_screen.dart';
import 'screens/inventory_detail_screen.dart' as NewInventoryDetail;
import 'providers/inventory_provider.dart';
import 'package:provider/provider.dart';
import 'models/invoice_model.dart';
import 'services/bulk_invoice_import.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final csvPath = await getInvoicesCsvPath();

  // Initialize InvoiceService singleton and run migration ONCE
  await InvoiceService.initialize(csvPath: csvPath);

  // Initialize notification service
  await NotificationService().init();
  
  // Initialize background service for daily reminders
  await BackgroundService.initialize();

  // Insert hardcoded data into DB (one-time only)
  await runOneTimeDataImportIfNeeded();

  runApp(MyApp(csvPath: csvPath));
}

class MyApp extends StatelessWidget {
  final String csvPath;
  const MyApp({required this.csvPath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return ChangeNotifierProvider(
        create: (_) => InventoryProvider(),
        child: MaterialApp(
        title: 'invoiceflow',
        theme: RoundedThemeExtensions.enhanceLightTheme(AppTheme.lightTheme),
        darkTheme: RoundedThemeExtensions.enhanceDarkTheme(AppTheme.darkTheme),
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.homeDashboard,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.homeDashboard:
              return FluidAnimations.createFadeRoute(
                child: HomeDashboard(csvPath: csvPath),
                settings: settings,
              );
            case AppRoutes.invoicesListScreen:
              return FluidAnimations.createCupertinoSlideRoute(
                child: InvoicesListScreen(csvPath: csvPath),
                settings: settings,
              );
            case AppRoutes.invoiceDetailScreen:
              final invoice = settings.arguments as InvoiceModel?;
              if (invoice != null) {
                return FluidAnimations.createSlideUpRoute(
                  child: const InvoiceDetailScreen(),
                  settings: RouteSettings(
                    name: settings.name,
                    arguments: invoice,
                  ),
                );
              }
              return FluidAnimations.createFadeRoute(
                child: HomeDashboard(csvPath: csvPath),
                settings: settings,
              );
            case AppRoutes.analyticsScreen:
              return FluidAnimations.createScaleRoute(
                child: AnalyticsMainScreen(),
                settings: settings,
              );
            case '/analytics-old':
              return FluidAnimations.createScaleRoute(
                child: AnalyticsScreen(),
                settings: settings,
              );
            case '/analytics-full':
              return FluidAnimations.createScaleRoute(
                child: AnalyticsRedesignScreen(),
                settings: settings,
              );
            case AppRoutes.profileScreen:
              return FluidAnimations.createSlideUpRoute(
                child: ProfileScreen(),
                settings: settings,
              );
            case AppRoutes.customersScreen:
              return FluidAnimations.createCupertinoSlideRoute(
                child: CustomersScreen(),
                settings: settings,
              );
            case AppRoutes.customerDetailScreen:
              final customerId = settings.arguments as String;
              return FluidAnimations.createSlideUpRoute(
                child: CustomerDetailScreen(customerId: customerId),
                settings: settings,
              );
            case '/pending-invoices':
              return FluidAnimations.createCupertinoSlideRoute(
                child: InvoicesListScreen(csvPath: csvPath),
                settings: settings,
              );
            case AppRoutes.inventoryScreen:
              return FluidAnimations.createSlideUpRoute(
                child: InventoryScreen(),
                settings: settings,
              );
            default:
              if (settings.name?.startsWith('/inventory/item/') == true) {
                final itemId = settings.name!.split('/').last;
                return FluidAnimations.createSlideUpRoute(
                  child: NewInventoryDetail.InventoryDetailScreen(itemId: itemId),
                  settings: settings,
                );
              }
              if (settings.name?.startsWith('/inventory/') == true) {
                final parts = settings.name!.split('/');
                if (parts.length >= 3) {
                  final itemId = parts[2];
                  return FluidAnimations.createSlideUpRoute(
                    child: NewInventoryDetail.InventoryDetailScreen(itemId: itemId),
                    settings: settings,
                  );
                }
              }
              return FluidAnimations.createFadeRoute(
                child: HomeDashboard(csvPath: csvPath),
                settings: settings,
              );
          }
        },
        ),
      );
    });
  }
}
