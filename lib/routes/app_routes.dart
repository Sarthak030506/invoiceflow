import 'package:flutter/material.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/invoice_detail_screen/invoice_detail_screen.dart';
import '../presentation/invoices_list_screen/invoices_list_screen.dart';
import '../presentation/analytics_screen/analytics_screen.dart';
import '../presentation/analytics_redesign/analytics_redesign_screen.dart';
import '../presentation/analytics_redesign/analytics_main_screen.dart';
import '../presentation/invoice_type_selection_screen.dart';
import '../presentation/customers_screen/customers_screen.dart';
import '../presentation/customers_screen/customer_detail_screen.dart';
import '../presentation/inventory_screen/inventory_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String homeDashboard = '/home-dashboard';
  static const String profileScreen = '/profile-screen';
  static const String invoiceDetailScreen = '/invoice-detail-screen';
  static const String invoicesListScreen = '/invoices-list-screen';
  static const String analyticsScreen = '/analytics-screen';
  static const String invoiceTypeSelectionScreen = '/invoice-type-selection-screen';
  static const String customersScreen = '/customers-screen';
  static const String customerDetailScreen = '/customer-detail-screen';
  static const String inventoryScreen = '/inventory-screen';
  static const String inventoryDetailScreen = '/inventory/item';
  static const String loginScreen = '/login';
  static const String forgotPasswordScreen = '/forgot-password';

  static final String csvPath = 'assets/images/data/invoices.csv';
  
  static Map<String, WidgetBuilder> routes = {
    homeDashboard: (context) => HomeDashboard(csvPath: csvPath),
    profileScreen: (context) => const ProfileScreen(),
    invoiceDetailScreen: (context) => const InvoiceDetailScreen(),
    invoicesListScreen: (context) => InvoicesListScreen(csvPath: csvPath),
    analyticsScreen: (context) => const AnalyticsMainScreen(),
    invoiceTypeSelectionScreen: (context) => const InvoiceTypeSelectionScreen(),
    customersScreen: (context) => const CustomersScreen(),
    customerDetailScreen: (context) {
      final customerId = ModalRoute.of(context)!.settings.arguments as String;
      return CustomerDetailScreen(customerId: customerId);
    },
    inventoryScreen: (context) => InventoryScreen(),
    loginScreen: (context) => const LoginScreen(),
    forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
  };
}
