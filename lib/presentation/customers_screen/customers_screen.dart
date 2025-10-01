import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import './widgets/customer_card_widget.dart';
import './widgets/enhanced_customer_card.dart';
import '../../widgets/enhanced_bottom_nav.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filteredCustomers = [];
  Map<String, double> _outstandingBalances = {};
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Sorting options
  String _sortBy = 'name'; // 'name' or 'balance'
  bool _sortAscending = true;
  
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customers = await _customerService.getAllCustomers();
      final balances = await _customerService.getCustomerOutstandingBalances();
      
      setState(() {
        _allCustomers = customers;
        _filteredCustomers = List.from(customers);
        _outstandingBalances = balances;
        _isLoading = false;
      });
      
      // Apply sorting after loading
      _sortCustomers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        _filteredCustomers = List.from(_allCustomers);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCustomers = _allCustomers.where((customer) {
          return customer.name.toLowerCase().contains(lowerQuery) ||
                 customer.phoneNumber.contains(query);
        }).toList();
      }
      
      // Apply sorting after filtering
      _sortCustomers();
    });
  }
  
  void _sortCustomers() {
    _filteredCustomers.sort((a, b) {
      if (_sortBy == 'name') {
        return _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name);
      } else { // 'balance'
        final balanceA = _outstandingBalances[a.id] ?? 0.0;
        final balanceB = _outstandingBalances[b.id] ?? 0.0;
        return _sortAscending
            ? balanceA.compareTo(balanceB)
            : balanceB.compareTo(balanceA);
      }
    });
  }
  
  void _viewCustomerDetails(CustomerModel customer) {
    Navigator.pushNamed(
      context,
      '/customer-detail-screen',
      arguments: customer.id,
    );
  }
  
  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    BlurredModal.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Customer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    final phoneRegex = RegExp(r'^[0-9]{10}$');
                    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (!phoneRegex.hasMatch(cleanPhone)) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Go Back',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: PrimaryButton(
                  text: 'Add Customer',
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final customer = await _customerService.addCustomer(
                          nameController.text.trim(),
                          phoneController.text.trim(),
                        );
                        
                        Navigator.pop(context);
                        _loadCustomers(); // Refresh the list
                        
                        // Show success feedback animation
                        FeedbackAnimations.showSuccess(
                          context,
                          message: 'Customer added successfully',
                        );
                        HapticFeedbackUtil.success();
                      } catch (e) {
                        // Show error feedback animation
                        FeedbackAnimations.showError(
                          context,
                          message: 'Error adding customer: ${e.toString()}',
                        );
                        HapticFeedbackUtil.error();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSortChip(String label, String sortValue) {
    final bool isSelected = _sortBy == sortValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_sortBy == sortValue) {
            // If already selected, toggle sort direction
            _sortAscending = !_sortAscending;
          } else {
            // If not selected, change sort field and set default direction
            _sortBy = sortValue;
            _sortAscending = sortValue == 'name'; // A-Z for name, High-Low for balance
          }
          _sortCustomers();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.lightTheme.colorScheme.primary 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        title: Text(
          'Customers',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
      ),
      body: Column(
        children: [
          // Enhanced Search Bar
          Container(
            margin: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).cardTheme.shadowColor ?? Colors.black.withOpacity(0.05),
                  blurRadius: Theme.of(context).cardTheme.elevation ?? 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by name or phone...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          _filterCustomers('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              ),
              onChanged: _filterCustomers,
            ),
          ),
          
          // Sort Options
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2.w),
                _buildSortChip('Name', 'name'),
                SizedBox(width: 2.w),
                _buildSortChip('Balance', 'balance'),
                Spacer(),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortCustomers();
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final outstandingBalance = _outstandingBalances[customer.id] ?? 0.0;
                            
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(30 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: EnhancedCustomerCard(
                                      customer: customer,
                                      outstandingBalance: outstandingBalance,
                                      onTap: () => _viewCustomerDetails(customer),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: EnhancedBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/invoices-list-screen');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/analytics-screen');
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile-screen');
              break;
          }
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 20.w,
            color: Colors.grey,
          ),
          SizedBox(height: 2.h),
          Text(
            'No customers found',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Add customers when creating sales invoices',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue.shade800,
      unselectedItemColor: Colors.grey.shade600,
      currentIndex: 3,
      onTap: (index) {
        if (index == 3) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/invoices-list-screen');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/analytics-screen');
            break;
          case 3:
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Invoices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Customers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}