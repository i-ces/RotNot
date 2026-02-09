import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

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

// ─── Shelf Screen ─────────────────────────────────────────────────────────────

class ShelfScreen extends StatefulWidget {
  // Callback to notify main.dart about search status
  final Function(bool) onSearchToggle;

  const ShelfScreen({super.key, required this.onSearchToggle});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FoodItem> _items = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFoodItems();

    // Listen to focus changes to hide/show FAB in main.dart
    _searchFocusNode.addListener(() {
      widget.onSearchToggle(_searchFocusNode.hasFocus);
    });
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ApiService.getFoodItems();
      setState(() {
        _items = items.map((item) {
          return FoodItem(
            id: item['_id'] ?? '',
            name: item['name'] ?? '',
            addedDate: item['addedAt'] != null
                ? DateTime.parse(item['addedAt'])
                : DateTime.now(),
            expiryDate: item['expiryDate'] != null
                ? DateTime.parse(item['expiryDate'])
                : DateTime.now(),
            quantity: item['quantity'] ?? 1,
            unit: item['unit'] ?? 'pcs',
            notes: item['notes'],
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading food items: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Filtered lists ────────────────────────────────────────────────────────────

  List<FoodItem> _applySearch(List<FoodItem> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  List<FoodItem> get _allItems => _applySearch(_items);
  List<FoodItem> get _freshItems =>
      _applySearch(_items.where((i) => i.status == FoodStatus.fresh).toList());
  List<FoodItem> get _expiringItems => _applySearch(
    _items.where((i) => i.status == FoodStatus.expiring).toList(),
  );
  List<FoodItem> get _expiredItems => _applySearch(
    _items.where((i) => i.status == FoodStatus.expired).toList(),
  );

  // Summary counts ────────────────────────────────────────────────────────────

  int get _freshCount =>
      _items.where((i) => i.status == FoodStatus.fresh).length;
  int get _expiringCount =>
      _items.where((i) => i.status == FoodStatus.expiring).length;
  int get _expiredCount =>
      _items.where((i) => i.status == FoodStatus.expired).length;

  // ──────────────────────────────────────────────────────────────────────────

  void _deleteItem(String id) async {
    try {
      await ApiService.deleteFoodItem(id);
      setState(() => _items.removeWhere((i) => i.id == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item removed'),
            backgroundColor: MyApp.surfaceColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item: $e'),
            backgroundColor: MyApp.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addItem(FoodItem item) async {
    try {
      final foodData = {
        'name': item.name,
        'category': 'General', // Default category
        'quantity': item.quantity,
        'unit': item.unit,
        'expiryDate': item.expiryDate.toIso8601String(),
        if (item.notes != null) 'notes': item.notes,
      };

      await ApiService.createFoodItem(foodData);
      await _loadFoodItems(); // Reload to get the server-generated ID

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added successfully'),
            backgroundColor: MyApp.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Add item error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add item: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: MyApp.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: MyApp.accentGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: MyApp.accentRed),
            const SizedBox(height: 16),
            Text(
              'Failed to load items',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFoodItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.accentGreen,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Search bar (With SafeArea and increased padding) ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 4),
            child: TextField(
              focusNode: _searchFocusNode,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search items…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.4),
                ),
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
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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

        // ── Add button (Hide if searching to keep UI clean) ──
        if (!_searchFocusNode.hasFocus)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showAddItemSheet(context),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Add Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.accentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
      ],
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
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Item list ────────────────────────────────────────────────────────────

  Widget _buildItemList(List<FoodItem> items) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFoodItems,
        color: MyApp.accentGreen,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items found',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFoodItems,
      color: MyApp.accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: items.length,
        itemBuilder: (context, index) => _FoodItemCard(
          item: items[index],
          onDelete: () => _deleteItem(items[index].id),
          onTap: () => _showItemDetail(items[index]),
        ),
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
                    const Text(
                      'Add Food Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sheetTextField(nameCtrl, 'Item name', Icons.label_rounded),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _sheetTextField(
                            qtyCtrl,
                            'Qty',
                            Icons.numbers_rounded,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _sheetTextField(
                            unitCtrl,
                            'Unit',
                            Icons.straighten_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 730),
                          ),
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
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: MyApp.scaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Expires: ${_formatDate(expiryDate)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white24,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(
                      notesCtrl,
                      'Notes (optional)',
                      Icons.notes_rounded,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final newItem = FoodItem(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: nameCtrl.text.trim(),
                            addedDate: DateTime.now(),
                            expiryDate: expiryDate,
                            quantity: int.tryParse(qtyCtrl.text.trim()) ?? 1,
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
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
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
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fastfood_rounded,
                color: item.statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _statusChip(item),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: item.statusColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.daysLeftLabel,
                        style: TextStyle(
                          color: item.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.white.withOpacity(0.25),
                size: 20,
              ),
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
          color: item.statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.fastfood_rounded,
              color: item.statusColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.statusLabel,
              style: TextStyle(
                color: item.statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _detailRow(
            Icons.inventory_2_outlined,
            'Quantity',
            '${item.quantity} ${item.unit}',
          ),
          _detailRow(
            Icons.calendar_today_rounded,
            'Added on',
            _formatDate(item.addedDate),
          ),
          _detailRow(
            Icons.event_rounded,
            'Expires on',
            _formatDate(item.expiryDate),
          ),
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
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
