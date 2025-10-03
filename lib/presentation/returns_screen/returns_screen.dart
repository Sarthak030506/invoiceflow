import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../models/return_model.dart';
import '../../services/return_service.dart';
import '../../widgets/app_loading_indicator.dart';
import 'return_detail_screen.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({Key? key}) : super(key: key);

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReturnService _returnService = ReturnService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Sales Returns'),
            Tab(text: 'Purchase Returns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReturnsList(returnType: 'sales'),
          _ReturnsList(returnType: 'purchase'),
        ],
      ),
    );
  }
}

class _ReturnsList extends StatelessWidget {
  final String returnType;

  const _ReturnsList({required this.returnType});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReturnModel>>(
      future: ReturnService.instance.getReturnsByType(returnType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingIndicator.centered(message: 'Loading returns...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 2.h),
                Text(
                  'Error loading returns',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 1.h),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final returns = snapshot.data ?? [];

        if (returns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_return,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No ${returnType == 'sales' ? 'sales' : 'purchase'} returns',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Returns will appear here when you process them',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger rebuild to refresh data
            (context as Element).markNeedsBuild();
          },
          child: ListView.builder(
            padding: EdgeInsets.all(4.w),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final returnModel = returns[index];
              return _ReturnCard(returnModel: returnModel);
            },
          ),
        );
      },
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnModel returnModel;

  const _ReturnCard({required this.returnModel});

  @override
  Widget build(BuildContext context) {
    final isSalesReturn = returnModel.returnType == 'sales';
    final color = isSalesReturn ? Colors.orange : Colors.blue;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 3.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: returnModel.isApplied ? Colors.grey.shade300 : color.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnDetailScreen(returnModel: returnModel),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: color.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_return,
                          color: color.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            returnModel.returnNumber,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Invoice: ${returnModel.invoiceNumber}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (returnModel.isApplied)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Applied',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 2.h),

              // Customer info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      returnModel.customerName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 2.w),
                  Text(
                    'Return Date: ${_formatDate(returnModel.returnDate)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Invoice date
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 2.w),
                  Text(
                    'Invoice Date: ${_formatDate(returnModel.invoiceDate)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Items breakdown
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items Returned:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...returnModel.items.map((item) => Padding(
                          padding: EdgeInsets.only(bottom: 0.5.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.name} (×${item.quantity})',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                              Text(
                                '₹${item.totalValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Total and refund amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Return Value',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${returnModel.totalReturnValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: color.shade700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isSalesReturn ? 'Refund Amount' : 'Expected Amount',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${returnModel.refundAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
