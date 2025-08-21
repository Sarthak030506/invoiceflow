import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/customer_model.dart';
import '../../../core/app_export.dart';

class EnhancedCustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final double outstandingBalance;
  final VoidCallback onTap;

  const EnhancedCustomerCard({
    Key? key,
    required this.customer,
    required this.outstandingBalance,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasOutstanding = outstandingBalance > 0;
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return FluidAnimations.createTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
          border: hasOutstanding 
              ? Border.all(color: Colors.orange.shade600, width: 2.0)
              : Border.all(color: Colors.grey.shade200, width: 1.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Avatar
              FluidAnimations.createHero(
                tag: 'customer-avatar-${customer.id}',
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getAvatarColors(customer.name),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(customer.name),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 4.w),
              
              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 4.w,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            customer.phoneNumber,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Outstanding Balance
              Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasOutstanding) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          '₹${_formatCurrency(outstandingBalance)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Outstanding',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Paid Up',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 1.h),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 4.w,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'C';
  }

  List<Color> _getAvatarColors(String name) {
    final colors = [
      [Colors.blue.shade400, Colors.blue.shade600],
      [Colors.green.shade400, Colors.green.shade600],
      [Colors.purple.shade400, Colors.purple.shade600],
      [Colors.orange.shade400, Colors.orange.shade600],
      [Colors.teal.shade400, Colors.teal.shade600],
      [Colors.indigo.shade400, Colors.indigo.shade600],
      [Colors.pink.shade400, Colors.pink.shade600],
    ];
    
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}