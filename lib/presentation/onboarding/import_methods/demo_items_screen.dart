import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../../services/demo_items_service.dart';
import '../../../services/items_service.dart';
import '../../../providers/auth_provider.dart';
import '../../home_dashboard/home_dashboard.dart';

class DemoItemsScreen extends StatefulWidget {
  const DemoItemsScreen({Key? key}) : super(key: key);

  @override
  State<DemoItemsScreen> createState() => _DemoItemsScreenState();
}

class _DemoItemsScreenState extends State<DemoItemsScreen> {
  bool _isLoading = false;
  final ItemsService _itemsService = ItemsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Catalog Items'),
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildDemoItemsList(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'These are your existing catalog items. Select "Use Items" to add them to your inventory and start using the app.',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoItemsList() {
    return ListView.builder(
      itemCount: DemoItemsService.demoItems.length,
      padding: EdgeInsets.all(2.w),
      itemBuilder: (context, index) {
        final item = DemoItemsService.demoItems[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                item.name[0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
            title: Text(item.name),
            subtitle: Text('${item.category} • ₹${item.rate.toStringAsFixed(0)}'),
            trailing: Text(
              item.sku,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10.sp,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _importDemoItems,
              child: Text(_isLoading ? 'Setting up...' : 'Use Items'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importDemoItems() async {
    setState(() => _isLoading = true);
    try {
      await DemoItemsService.importDemoItems(_itemsService);
      
      // Mark onboarding as complete
      if (mounted) {
        context.read<AuthProvider>().completeOnboarding();
        
        // Navigate directly to home dashboard, replacing all previous screens
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeDashboard(csvPath: 'assets/images/data/invoices.csv'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up items: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
                    
