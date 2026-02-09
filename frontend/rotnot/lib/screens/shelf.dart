import 'package:flutter/material.dart';
import '../main.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum FoodStatus { fresh, expiring, expired }

class FoodItem {
  final String id;
  final String name;
  final DateTime addedDate;
  final DateTime expiryDate;
  final int quantity;
  final String unit;
  final String? notes;

  FoodItem({
    required this.id,
    required this.name,
    required this.addedDate,
    required this.expiryDate,
    required this.quantity,
    this.unit = 'pcs',
    this.notes,
  });

  FoodStatus get status {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) return FoodStatus.expired;
    if (expiryDate.difference(now).inDays <= 3) return FoodStatus.expiring;
    return FoodStatus.fresh;
  }

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;

  String get daysLeftLabel {
    final d = daysLeft;
    if (d < 0) return '${d.abs()}d overdue';
    if (d == 0) return 'Expires today';
    if (d == 1) return '1 day left';
    return '$d days left';
  }

  Color get statusColor {
    switch (status) {
      case FoodStatus.fresh:
        return const Color(0xFF2ECC71);
      case FoodStatus.expiring:
        return const Color(0xFFF39C12);
      case FoodStatus.expired:
        return const Color(0xFFE74C3C);
    }
  }

  String get statusLabel {
    switch (status) {
      case FoodStatus.fresh:
        return 'Fresh';
      case FoodStatus.expiring:
        return 'Expiring Soon';
      case FoodStatus.expired:
        return 'Expired';
    }
  }
}

// ─── Sample data ──────────────────────────────────────────────────────────────

List<FoodItem> _sampleItems() {
  final now = DateTime.now();
  return [
    FoodItem(
      id: '1',
      name: 'Milk',
      addedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 1)),
      quantity: 1,
      unit: 'litre',
      notes: 'Full cream milk',
    ),
    FoodItem(
      id: '2',
      name: 'Apples',
      addedDate: now.subtract(const Duration(days: 5)),
      expiryDate: now.add(const Duration(days: 10)),
      quantity: 6,
      unit: 'pcs',
    ),
    FoodItem(
      id: '3',
      name: 'Chicken Breast',
      addedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.subtract(const Duration(days: 1)),
      quantity: 500,
      unit: 'grams',
      notes: 'Needs to be cooked or discarded',
    ),
    FoodItem(
      id: '4',
      name: 'Bread',
      addedDate: now.subtract(const Duration(days: 4)),
      expiryDate: now.add(const Duration(days: 2)),
      quantity: 1,
      unit: 'loaf',
    ),
    FoodItem(
      id: '5',
      name: 'Spinach',
      addedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 7)),
      quantity: 250,
      unit: 'grams',
    ),
    FoodItem(
      id: '6',
      name: 'Yogurt',
      addedDate: now.subtract(const Duration(days: 6)),
      expiryDate: now.subtract(const Duration(days: 2)),
      quantity: 2,
      unit: 'cups',
      notes: 'Greek yogurt — expired',
    ),
    FoodItem(
      id: '7',
      name: 'Eggs',
      addedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 14)),
      quantity: 12,
      unit: 'pcs',
    ),
    FoodItem(
      id: '8',
      name: 'Rice',
      addedDate: now.subtract(const Duration(days: 10)),
      expiryDate: now.add(const Duration(days: 180)),
      quantity: 5,
      unit: 'kg',
    ),
    FoodItem(
      id: '9',
      name: 'Tomatoes',
      addedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 3)),
      quantity: 4,
      unit: 'pcs',
      notes: 'Use soon for pasta sauce',
    ),
    FoodItem(
      id: '10',
      name: 'Cheddar Cheese',
      addedDate: now.subtract(const Duration(days: 7)),
      expiryDate: now.subtract(const Duration(days: 0)),
      quantity: 200,
      unit: 'grams',
    ),
  ];
}

// ─── Shelf Screen ─────────────────────────────────────────────────────────────

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<FoodItem> _items;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _items = _sampleItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filtered lists ────────────────────────────────────────────────────────────

  List<FoodItem> _applySearch(List<FoodItem> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((i) => i.name.toLowerCase().contains(q))
        .toList();
  }

  List<FoodItem> get _allItems => _applySearch(_items);
  List<FoodItem> get _freshItems =>
      _applySearch(_items.where((i) => i.status == FoodStatus.fresh).toList());
  List<FoodItem> get _expiringItems => _applySearch(
      _items.where((i) => i.status == FoodStatus.expiring).toList());
  List<FoodItem> get _expiredItems => _applySearch(
      _items.where((i) => i.status == FoodStatus.expired).toList());

  // Summary counts ────────────────────────────────────────────────────────────

  int get _freshCount =>
      _items.where((i) => i.status == FoodStatus.fresh).length;
  int get _expiringCount =>
      _items.where((i) => i.status == FoodStatus.expiring).length;
  int get _expiredCount =>
      _items.where((i) => i.status == FoodStatus.expired).length;

  // ──────────────────────────────────────────────────────────────────────────

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed'),
        backgroundColor: MyApp.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addItem(FoodItem item) {
    setState(() => _items.add(item));
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search items…',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon:
                  Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: MyApp.surfaceColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ── Tab bar ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: MyApp.surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            indicator: BoxDecoration(
              color: MyApp.accentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: MyApp.accentGreen,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              _buildTab('All', _items.length),
              _buildTab('Fresh', _freshCount),
              _buildTab('Expiring', _expiringCount),
              _buildTab('Expired', _expiredCount),
            ],
          ),
        ),

        // ── Item lists ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildItemList(_allItems),
              _buildItemList(_freshItems),
              _buildItemList(_expiringItems),
              _buildItemList(_expiredItems),
            ],
          ),
        ),

        // ── Add button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddItemSheet(context),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('Add Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Summary row ──────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _summaryCard('Fresh', _freshCount, const Color(0xFF2ECC71),
              Icons.check_circle_outline_rounded),
          const SizedBox(width: 10),
          _summaryCard('Expiring', _expiringCount, const Color(0xFFF39C12),
              Icons.warning_amber_rounded),
          const SizedBox(width: 10),
          _summaryCard('Expired', _expiredCount, const Color(0xFFE74C3C),
              Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── Tab helper ───────────────────────────────────────────────────────────

  Widget _buildTab(String label, int count) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Item list ────────────────────────────────────────────────────────────

  Widget _buildItemList(List<FoodItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            Text('No items found',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      itemCount: items.length,
      itemBuilder: (context, index) => _FoodItemCard(
        item: items[index],
        onDelete: () => _deleteItem(items[index].id),
        onTap: () => _showItemDetail(items[index]),
      ),
    );
  }

  // ─── Item detail bottom sheet ─────────────────────────────────────────────

  void _showItemDetail(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  // ─── Add item bottom sheet ────────────────────────────────────────────────

  void _showAddItemSheet(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'pcs');
    final notesCtrl = TextEditingController();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: MyApp.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const Text('Add Food Item',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Name
                    _sheetTextField(nameCtrl, 'Item name', Icons.label_rounded),
                    const SizedBox(height: 14),

                    // Quantity + Unit
                    Row(
                      children: [
                        Expanded(
                            child: _sheetTextField(
                                qtyCtrl, 'Qty', Icons.numbers_rounded,
                                isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _sheetTextField(
                                unitCtrl, 'Unit', Icons.straighten_rounded)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Expiry date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 730)),
                          builder: (ctx, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: MyApp.accentGreen,
                                  surface: MyApp.surfaceColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => expiryDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: MyApp.scaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white54, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Expires: ${_formatDate(expiryDate)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_rounded,
                                color: Colors.white24, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    _sheetTextField(
                        notesCtrl, 'Notes (optional)', Icons.notes_rounded),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final newItem = FoodItem(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            name: nameCtrl.text.trim(),
                            addedDate: DateTime.now(),
                            expiryDate: expiryDate,
                            quantity:
                                int.tryParse(qtyCtrl.text.trim()) ?? 1,
                            unit: unitCtrl.text.trim().isEmpty
                                ? 'pcs'
                                : unitCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          );
                          _addItem(newItem);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.accentGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Save Item',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetTextField(
      TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: MyApp.scaffoldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─── Food item card widget ──────────────────────────────────────────────────

class _FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _FoodItemCard({
    required this.item,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyApp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.statusColor.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.fastfood_rounded, color: item.statusColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      _statusChip(item),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 13, color: Colors.white.withOpacity(0.35)),
                      const SizedBox(width: 4),
                      Text('${item.quantity} ${item.unit}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: item.statusColor.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(item.daysLeftLabel,
                          style: TextStyle(
                              color: item.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            // Delete
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.white.withOpacity(0.25), size: 20),
              onPressed: onDelete,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(FoodItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: item.statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.statusLabel,
        style: TextStyle(
            color: item.statusColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Item detail sheet ──────────────────────────────────────────────────────

class _ItemDetailSheet extends StatelessWidget {
  final FoodItem item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MyApp.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Icon + name
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.fastfood_rounded, color: item.statusColor, size: 32),
          ),
          const SizedBox(height: 14),
          Text(item.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(item.statusLabel,
                style: TextStyle(
                    color: item.statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),

          // Info rows
          _detailRow(Icons.inventory_2_outlined, 'Quantity',
              '${item.quantity} ${item.unit}'),
          _detailRow(Icons.calendar_today_rounded, 'Added on',
              _formatDate(item.addedDate)),
          _detailRow(Icons.event_rounded, 'Expires on',
              _formatDate(item.expiryDate)),
          _detailRow(Icons.schedule_rounded, 'Time left', item.daysLeftLabel),
          if (item.notes != null)
            _detailRow(Icons.notes_rounded, 'Notes', item.notes!),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Text('$label:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}