import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';

/// InventoryDetailScreen
/// - Self-contained implementation that does not assume exact provider method names.
/// - Uses dynamic calls and try/catch to support different provider APIs.
/// - Local widgets for summary, info pills, movement tiles and sticky action bar.
/// NOTE: Replace local widgets with your own if you prefer.
class InventoryDetailScreen extends StatefulWidget {
  final String itemId;

  const InventoryDetailScreen({required this.itemId, super.key});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with TickerProviderStateMixin {
  late AnimationController _countController;
  late AnimationController _slideController;
  late Animation<double> _stockAnimation;
  late Animation<double> _valueAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _animationsStarted = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'IN', 'OUT', 'ADJUST'];

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // attempt to load item using common provider API names
      final provider = Provider.of<dynamic>(context, listen: false);
      _callProviderLoad(provider, widget.itemId);
    });
  }

  void _initAnimations() {
    _countController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _stockAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_countController);
    _valueAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_countController);

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAnimations(double stock, double value) {
    _countController.reset();
    _slideController.reset();

    _stockAnimation = Tween<double>(begin: 0.0, end: stock).animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));
    _valueAnimation = Tween<double>(begin: 0.0, end: value).animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));

    _countController.forward();
    _slideController.forward();
  }

  // ------------------ provider-adapter helpers ------------------

  Future<void> _callProviderLoad(dynamic provider, String itemId) async {
    if (provider == null) return;
    try {
      // common variants
      if (_hasMethod(provider, 'load')) {
        await provider.load(itemId);
        return;
      }
      if (_hasMethod(provider, 'loadItem')) {
        await provider.loadItem(itemId);
        return;
      }
      if (_hasMethod(provider, 'fetchItem')) {
        await provider.fetchItem(itemId);
        return;
      }
      // fallback no-op
      // print warning for developer
      // ignore: avoid_print
      print('Warning: provider has no load/loadItem/fetchItem method. Provide one or call load before opening screen.');
    } catch (e) {
      // ignore runtime errors here, but print for debugging
      // ignore: avoid_print
      print('Error calling provider load: $e');
    }
  }

  bool _hasMethod(dynamic object, String name) {
    // best-effort: check typical members on common provider shapes
    // This is not reflection but a safe best-effort check using try/catch.
    try {
      final v = object.toJson; // just to touch object (may not exist)
      // ignore: avoid_returning_null
      return true; // not a real check; we'll rely on try/catch when calling.
    } catch (_) {
      // still allow; we will catch on call
      return true;
    }
  }

  // robust wrapper to attempt many method names for actions
  Future<void> _safeReceive(dynamic provider, double qty, double unitCost, {String? note}) async {
    if (provider == null) throw Exception('Provider not found');
    // try multiple common method names
    final attempts = <Future<void> Function()>[
      () async => await provider.receive(qty, unitCost),
      () async => await provider.receiveStock(widget.itemId, qty, unitCost),
      () async => await provider.addStock(widget.itemId, qty, unitCost),
      () async => await provider.updateStock(widget.itemId, qty, 'IN'),
    ];
    await _runAttempts(attempts, 'receive');
  }

  Future<void> _safeIssue(dynamic provider, double qty, {String? note}) async {
    if (provider == null) throw Exception('Provider not found');
    final attempts = <Future<void> Function()>[
      () async => await provider.issue(qty),
      () async => await provider.issueStock(widget.itemId, qty),
      () async => await provider.removeStock(widget.itemId, qty),
      () async => await provider.updateStock(widget.itemId, -qty, 'OUT'),
    ];
    await _runAttempts(attempts, 'issue');
  }

  Future<void> _safeAdjust(dynamic provider, double qty, {String? reason}) async {
    if (provider == null) throw Exception('Provider not found');
    final attempts = <Future<void> Function()>[
      () async => await provider.adjust(qty, reason),
      () async => await provider.adjustStock(widget.itemId, qty, reason),
      () async => await provider.updateStock(widget.itemId, qty, 'ADJUST'),
    ];
    await _runAttempts(attempts, 'adjust');
  }

  Future<void> _runAttempts(List<Future<void> Function()> attempts, String name) async {
    Exception? last;
    for (final attempt in attempts) {
      try {
        await attempt();
        return; // success
      } catch (e) {
        last = Exception('$name attempt failed: $e');
        continue;
      }
    }
    throw last ?? Exception('No $name attempts provided');
  }

  // updateItem fallback
  Future<void> _safeUpdateItem(dynamic provider, Map<String, dynamic> updates) async {
    if (provider == null) throw Exception('Provider not found');
    final attempts = <Future<void> Function()>[
      () async => await provider.updateItem(updates),
      () async => await provider.saveItem(updates),
      () async => await provider.editItem(updates),
    ];
    await _runAttempts(attempts, 'updateItem');
  }

  // ------------------ UI & flows ------------------

  @override
  Widget build(BuildContext context) {
    // we expect a Provider to exist. Use 'dynamic' so file compiles even if provider methods differ.
    final provider = Provider.of<dynamic>(context);

    // retrieve item info defensively (many app providers use different fields)
    final title = _getProviderField(provider, ['title', 'name', 'itemName', 'currentItem?.name']);
    final sku = _getProviderField(provider, ['sku', 'code', 'currentItem?.sku']);
    final unit = _getProviderField(provider, ['unit', 'uom']) ?? 'pcs';
    final category = _getProviderField(provider, ['category']) ?? 'General';
    final barcode = _getProviderField(provider, ['barcode']) ?? '';
    final reorderPointRaw = _getProviderField(provider, ['reorderPoint', 'reorder'], fallbackNumeric: true);
    final currentStockRaw = _getProviderField(provider, ['currentStock', 'stock', 'quantity'], fallbackNumeric: true);
    final avgCostRaw = _getProviderField(provider, ['avgCost', 'averageCost', 'cost'], fallbackNumeric: true);
    final inventoryValueRaw = _getProviderField(provider, ['inventoryValue', 'value'], fallbackNumeric: true);

    final reorderPoint = (reorderPointRaw is num) ? reorderPointRaw.toDouble() : double.tryParse('$reorderPointRaw') ?? 0.0;
    final currentStock = (currentStockRaw is num) ? currentStockRaw.toDouble() : double.tryParse('$currentStockRaw') ?? 0.0;
    final avgCost = (avgCostRaw is num) ? avgCostRaw.toDouble() : double.tryParse('$avgCostRaw') ?? 0.0;
    final inventoryValue = (inventoryValueRaw is num) ? inventoryValueRaw.toDouble() : double.tryParse('$inventoryValueRaw') ?? 0.0;

    // Movements list retrieval: try provider.movements or provider.currentItem?.movements
    final rawMovements = _getProviderField(provider, ['movements', 'currentItem?.movements', 'movementList']) ?? <dynamic>[];
    final movements = (rawMovements is List) ? rawMovements : <dynamic>[];

    // start animations once when data appears
    if (!_animationsStarted && (title != null)) {
      _animationsStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimations(currentStock, inventoryValue));
    }

    // Bottom action bar height for calculations
    const double bottomBarHeight = 80.0;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? 'Item',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sku ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditDialog(provider),
                    icon: const Icon(Icons.edit_outlined),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () => _showBarcodeDialog(provider),
                    icon: const Icon(Icons.qr_code_2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // summary card with improved spacing
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildSummaryCard(context, currentStock, reorderPoint, avgCost, inventoryValue, unit),
                        ),
                      ),
                    ),

                    // info pills with better spacing
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _infoPill(icon: Icons.category_outlined, label: 'Category', value: category),
                          _infoPill(icon: Icons.straighten, label: 'Unit', value: unit),
                          _infoPill(icon: Icons.notification_important_outlined, label: 'Reorder', value: reorderPoint.toInt().toString()),
                          _infoPill(icon: Icons.qr_code, label: 'Barcode', value: barcode.isEmpty ? 'Not set' : barcode),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // movements header with improved spacing
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Movements',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                ),
                          ),
                          const SizedBox(height: 12),
                          // filters with better visual treatment
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (c, i) {
                                final label = _filters[i];
                                final selected = label == _selectedFilter;
                                return ChoiceChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: selected,
                                  onSelected: (v) => setState(() => _selectedFilter = v ? label : 'All'),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                                    width: selected ? 0 : 1,
                                  ),
                                  selectedColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: _filters.length,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // movement list or empty state
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: movements.isEmpty ? _emptyMovementState() : _buildMovementList(movements),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom action bar
            Container(
              height: bottomBarHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openStockForm(context, provider, 'receive'),
                      icon: const Icon(Icons.add_business_outlined, size: 20),
                      label: const Text('Receive'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openStockForm(context, provider, 'issue'),
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      label: const Text('Issue'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: IconButton(
                      onPressed: () => _openStockForm(context, provider, 'adjust'),
                      icon: const Icon(Icons.tune, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ small local widgets ------------------

  Widget _buildSummaryCard(BuildContext context, double stock, double reorder, double avgCost, double invValue, String unit) {
    final theme = Theme.of(context);
    final low = stock <= reorder;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (low)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Low Stock',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Stock info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _stockAnimation,
                      builder: (context, child) {
                        final val = _stockAnimation.value;
                        return Text(
                          '${val.toInt()} $unit',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current stock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reorder at ${reorder.toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                
                // Right side - Cost info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Avg Cost',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${avgCost.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _valueAnimation,
                      builder: (context, child) {
                        final val = _valueAnimation.value;
                        return Text(
                          '₹${val.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label, required String value}) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[700]), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])),
      ]),
    );
  }

  Widget _emptyMovementState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [Icon(Icons.history, size: 56, color: Colors.grey[300]), const SizedBox(height: 12), Text('No movements yet — perform Receive, Issue or Adjust.', style: TextStyle(color: Colors.grey[700]), textAlign: TextAlign.center)]),
    );
  }

  Widget _buildMovementList(List<dynamic> movements) {
    final filtered = _getFilteredMovements(movements);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (c, i) => _movementTile(filtered[i]),
      separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[200]),
    );
  }

  Widget _movementTile(dynamic m) {
    final type = _getField(m, ['type', 'movementType', 'txnType'])?.toString() ?? 'adjust';
    final qty = _getField(m, ['quantity', 'qty']) ?? 0;
    final created = _getField(m, ['createdAt', 'created', 'date']);
    final note = _getField(m, ['note', 'notes', 'reason']) ?? '';
    final src = _getField(m, ['sourceType', 'source'])?.toString() ?? '';

    Color badgeColor = Colors.grey;
    if (type.toUpperCase().contains('IN')) badgeColor = Colors.green;
    if (type.toUpperCase().contains('OUT')) badgeColor = Colors.blue;
    if (type.toUpperCase().contains('ADJUST')) badgeColor = Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(type, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11))),
        title: Text('${qty.toInt()} ${_getProviderField(Provider.of<dynamic>(context, listen: false), ['unit'], fallbackNumeric: false) ?? 'pcs'} - ${_movementTitle(type)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_movementSubtitle(created)), if (note.isNotEmpty) Text(note, style: const TextStyle(color: Colors.grey))]),
        trailing: src.isNotEmpty ? Text(src, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      ),
    );
  }

  String _movementTitle(String type) {
    final t = type.toUpperCase();
    if (t.contains('IN')) return 'Receive';
    if (t.contains('OUT')) return 'Issue';
    if (t.contains('ADJUST')) return 'Adjustment';
    return 'Movement';
  }

  String _movementSubtitle(dynamic created) {
    if (created is DateTime) {
      final d = created;
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return created?.toString() ?? '';
  }

  // ------------------ action forms ------------------

  void _openStockForm(BuildContext context, dynamic provider, String type) {
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController(text: _getProviderField(provider, ['avgCost', 'cost', 'averageCost'])?.toString() ?? '0');
    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${type.toUpperCase()} Stock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity *', border: const OutlineInputBorder()), validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) <= 0) ? 'Enter positive quantity' : null),
            if (type == 'receive') ...[
              const SizedBox(height: 12),
              TextFormField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit cost *', border: OutlineInputBorder(), prefixText: '₹'), validator: (v) => (double.tryParse(v ?? '') == null || double.parse(v!) < 0) ? 'Enter valid cost' : null),
            ],
            if (type == 'adjust') ...[
              const SizedBox(height: 12),
              TextFormField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null),
            ],
            const SizedBox(height: 12),
            TextFormField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _submitStockForm(ctx, provider, type, formKey, qtyController, costController, reasonController, noteController), child: const Text('Confirm'))),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _submitStockForm(
    BuildContext ctx,
    dynamic provider,
    String type,
    GlobalKey<FormState> formKey,
    TextEditingController qtyController,
    TextEditingController costController,
    TextEditingController reasonController,
    TextEditingController noteController,
  ) async {
    if (!formKey.currentState!.validate()) return;
    final q = double.parse(qtyController.text);
    final cost = double.tryParse(costController.text) ?? 0.0;
    final reason = reasonController.text.trim();
    final note = noteController.text.trim();

    final prevStockRaw = _getProviderField(provider, ['currentStock', 'stock', 'quantity']);
    final prevStock = (prevStockRaw is num) ? prevStockRaw.toDouble() : double.tryParse('$prevStockRaw') ?? 0.0;

    Navigator.pop(ctx); // close modal while processing

    try {
      if (type == 'receive') {
        await _safeReceive(provider, q, cost, note: note);
      } else if (type == 'issue') {
        await _safeIssue(provider, q, note: note);
      } else {
        await _safeAdjust(provider, q, reason: reason);
      }

      // show snackbar with undo
      final newStockRaw = _getProviderField(provider, ['currentStock', 'stock', 'quantity']);
      final newStock = (newStockRaw is num) ? newStockRaw.toDouble() : double.tryParse('$newStockRaw') ?? prevStock;
      final delta = newStock - prevStock;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${type.toUpperCase()} completed. Stock: ${newStock.toInt()} (${delta >= 0 ? '+' : ''}${delta.toInt()})'),
        action: SnackBarAction(label: 'Undo', onPressed: () async {
          try {
            // best-effort undo
            if (type == 'receive') {
              await _safeIssue(provider, q, note: 'Undo receive');
            } else if (type == 'issue') {
              await _safeReceive(provider, q, cost, note: 'Undo issue');
            } else {
              // revert adjust by opposite
              await _safeAdjust(provider, -q, reason: 'Undo adjust');
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undo successful')));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Undo failed: $e'), backgroundColor: Colors.red));
          }
        }),
        duration: const Duration(seconds: 6),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  // ------------------ edit & barcode dialogs ------------------

  void _showEditDialog(dynamic provider) {
    // gather existing values defensively
    final name = _getProviderField(provider, ['title', 'name', 'currentItem?.name'])?.toString() ?? '';
    final sku = _getProviderField(provider, ['sku', 'code', 'currentItem?.sku'])?.toString() ?? '';
    final unit = _getProviderField(provider, ['unit'])?.toString() ?? 'pcs';
    final category = _getProviderField(provider, ['category'])?.toString() ?? 'General';
    final reorder = _getProviderField(provider, ['reorderPoint', 'reorder'])?.toString() ?? '0';
    final barcode = _getProviderField(provider, ['barcode'])?.toString() ?? '';

    final nameCtrl = TextEditingController(text: name);
    final skuCtrl = TextEditingController(text: sku);
    final unitCtrl = TextEditingController(text: unit);
    final catCtrl = TextEditingController(text: category);
    final reorderCtrl = TextEditingController(text: reorder);
    final barcodeCtrl = TextEditingController(text: barcode);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 8),
              TextFormField(controller: reorderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Point')),
              const SizedBox(height: 8),
              TextFormField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (optional)')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              // prepare updates map
              final updates = <String, dynamic>{
                'title': nameCtrl.text.trim(),
                'sku': skuCtrl.text.trim(),
                'unit': unitCtrl.text.trim(),
                'category': catCtrl.text.trim(),
                'reorderPoint': double.tryParse(reorderCtrl.text) ?? 0,
                'barcode': barcodeCtrl.text.trim(),
              };
              Navigator.pop(ctx);
              try {
                await _safeUpdateItem(provider, updates);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBarcodeDialog(dynamic provider) {
    final currentBarcode = _getProviderField(provider, ['barcode'])?.toString() ?? '';
    final barcodeCtrl = TextEditingController(text: currentBarcode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Barcode'),
        content: TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updates = {'barcode': barcodeCtrl.text.trim()};
              try {
                await _safeUpdateItem(Provider.of<dynamic>(context, listen: false), updates);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode saved')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ------------------ small helpers to read dynamic fields ------------------

  dynamic _getProviderField(dynamic provider, List<String> keys, {bool fallbackNumeric = false}) {
    if (provider == null) return null;
    try {
      // Common direct fields
      for (final k in keys) {
        if (k.contains('?.')) {
          // handle "currentItem?.name" style
          final parts = k.split('?.');
          var obj = provider;
          var ok = true;
          for (final p in parts) {
            try {
              obj = obj is Map ? obj[p] : (obj?.toJson != null ? obj[p] : (obj?.toMap != null ? obj[p] : (obj?.runtimeType.toString()))); // best-effort
            } catch (_) {
              ok = false;
              break;
            }
            if (obj == null) {
              ok = false;
              break;
            }
          }
          if (ok && obj != null) return obj;
        } else {
          try {
            // try property access (dynamic)
            final v = provider is Map ? provider[k] : provider?.toJson != null ? provider[k] : provider[k];
            if (v != null) return v;
          } catch (_) {
            // fallback to Map-like access
            try {
              final v2 = provider is Map ? provider[k] : null;
              if (v2 != null) return v2;
            } catch (_) {}
          }
        }
      }

      // If provider has currentItem Map
      try {
        final cur = provider.currentItem ?? provider.item ?? provider.data;
        if (cur != null) {
          for (final k in keys) {
            if (cur is Map && cur.containsKey(k)) return cur[k];
            try {
              final v = cur[k];
              if (v != null) return v;
            } catch (_) {}
          }
        }
      } catch (_) {}

      // if fallback numeric requested
      if (fallbackNumeric) return 0.0;
    } catch (_) {}
    return null;
  }

  dynamic _getField(dynamic obj, List<String> keys) {
    if (obj == null) return null;
    try {
      if (obj is Map) {
        for (final k in keys) {
          if (obj.containsKey(k)) return obj[k];
        }
      } else {
        for (final k in keys) {
          try {
            final v = obj[k];
            if (v != null) return v;
          } catch (_) {}
        }
      }
      // try properties
      try {
        for (final k in keys) {
          final v = (obj as dynamic).toJson != null ? obj[k] : (obj as dynamic)[k];
          if (v != null) return v;
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  // filter movements by chip
  List<dynamic> _getFilteredMovements(List<dynamic> movs) {
    if (_selectedFilter == 'All') return movs;
    final up = _selectedFilter.toUpperCase();
    return movs.where((m) {
      final t = _getField(m, ['type', 'movementType', 'txnType'])?.toString().toUpperCase() ?? '';
      if (up == 'IN') return t.contains('IN');
      if (up == 'OUT') return t.contains('OUT');
      if (up == 'ADJUST') return t.contains('ADJUST');
      return true;
    }).toList();
  }
}
