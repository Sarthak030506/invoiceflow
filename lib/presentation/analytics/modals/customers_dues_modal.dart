import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_modal.dart';
import '../../../services/customer_service.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../core/app_export.dart';

class CustomersDuesModal extends StatefulWidget {
  const CustomersDuesModal({Key? key}) : super(key: key);

  @override
  State<CustomersDuesModal> createState() => _CustomersDuesModalState();
}

class _CustomersDuesModalState extends State<CustomersDuesModal> {
  final CustomerService _customerService = CustomerService.instance;

  List<CustomerModel> _customersWithDues = [];
  Map<String, double> _outstandingBalances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomersWithDues();
  }

  Future<void> _loadCustomersWithDues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allCustomers = await _customerService.getAllCustomers();
      final balances = await _customerService.getCustomerOutstandingBalances();

      // Filter customers who have outstanding balance
      final customersWithDues = allCustomers.where((customer) {
        final balance = balances[customer.id] ?? 0.0;
        return balance > 0;
      }).toList();

      // Sort by balance (highest first)
      customersWithDues.sort((a, b) {
        final balanceA = balances[a.id] ?? 0.0;
        final balanceB = balances[b.id] ?? 0.0;
        return balanceB.compareTo(balanceA);
      });

      setState(() {
        _customersWithDues = customersWithDues;
        _outstandingBalances = balances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassModal(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Customers With Dues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingIndicator.centered(message: 'Loading customers...')
                : _customersWithDues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No Outstanding Dues!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All customers have paid in full',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _customersWithDues.length,
                        itemBuilder: (context, index) {
                          final customer = _customersWithDues[index];
                          final balance = _outstandingBalances[customer.id] ?? 0.0;
                          return _buildCustomerCard(customer, balance);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer, double balance) {
    // Color coding based on amount
    Color color;
    if (balance > 10000) {
      color = Colors.red;
    } else if (balance > 5000) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phoneNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getSubtitleColor(color),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(color),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showEditDueDialog(customer, balance),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDueDialog(CustomerModel customer, double currentDue) {
    final TextEditingController controller = TextEditingController(
      text: currentDue.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    BlurredModal.show(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Due Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${customer.name}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'New Due Amount',
                prefixText: '₹',
                hintText: '0.00',
                helperText: 'Current due: ₹${currentDue.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount < 0) {
                  return 'Amount cannot be negative';
                }
                if (amount > currentDue) {
                  return 'New amount cannot be greater than current due';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Update',
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final newAmount = double.parse(controller.text);
                        Navigator.pop(context);
                        await _updateDueAmount(customer, newAmount, currentDue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDueAmount(CustomerModel customer, double newDue, double oldDue) async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _customerService.adjustOutstandingBalance(customer.id, newDue);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success feedback
      FeedbackAnimations.showSuccess(
        context,
        message: 'Due updated: ₹${newDue.toStringAsFixed(2)}',
      );
      HapticFeedbackUtil.success();

      // Reload data in background
      _loadCustomersWithDues();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      FeedbackAnimations.showError(
        context,
        message: 'Update failed: ${e.toString()}',
      );
      HapticFeedbackUtil.error();
    }
  }

  Color _getTextColor(Color color) {
    if (color == Colors.red) return Colors.red.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.green) return Colors.green.shade800;
    return Colors.grey.shade800;
  }

  Color _getSubtitleColor(Color color) {
    if (color == Colors.red) return Colors.red.shade600;
    if (color == Colors.orange) return Colors.orange.shade600;
    if (color == Colors.green) return Colors.green.shade600;
    return Colors.grey.shade600;
  }

  Color _getIconColor(Color color) {
    if (color == Colors.red) return Colors.red.shade400;
    if (color == Colors.orange) return Colors.orange.shade400;
    if (color == Colors.green) return Colors.green.shade400;
    return Colors.grey.shade400;
  }
}