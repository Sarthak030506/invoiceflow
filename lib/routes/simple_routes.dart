import 'package:flutter/material.dart';
import '../presentation/auth/simple_login_screen.dart';
import '../presentation/auth/simple_signup_screen.dart';
import '../presentation/auth/simple_splash_screen.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/invoices_list/invoices_list_screen.dart'; // Import the InvoicesListScreen

class SimpleRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String invoicesList = '/invoices-list-screen'; // Add this line
  
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => SimpleSplashScreen(),
    login: (context) => SimpleLoginScreen(),
    signup: (context) => SimpleSignupScreen(),
    home: (context) => HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
    invoicesList: (context) => InvoicesListScreen(), // Add this line
  };
}