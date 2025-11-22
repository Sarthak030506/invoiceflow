import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/skeleton_loader.dart';
import '../../../services/customer_service.dart';

class DueRemindersSection extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic> outstandingPayments;

