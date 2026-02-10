import 'package:flutter/material.dart';
import 'package:rotnot/services/api_service.dart';

class ExpiringItemsScreen extends StatefulWidget {
  const ExpiringItemsScreen({super.key});

  @override
  State<ExpiringItemsScreen> createState() => _ExpiringItemsScreenState();
}

class _ExpiringItemsScreenState extends State<ExpiringItemsScreen> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  List<Map<String, dynamic>> _expiringItems = [];
  List<Map<String, dynamic>> _expiredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getFoodItems();
      final now = DateTime.now();

      final expiring = <Map<String, dynamic>>[];
      final expired = <Map<String, dynamic>>[];

      for (var item in items) {
        if (item['expiryDate'] != null) {
          final expiryDate = DateTime.parse(item['expiryDate']);
          final daysLeft = expiryDate.difference(now).inDays;

          if (daysLeft < 0) {
            expired.add({...item, 'daysLeft': daysLeft});
          } else if (daysLeft <= 3) {
            expiring.add({...item, 'daysLeft': daysLeft});
          }
        }
      }

      // Sort by days left (most urgent first)
      expiring.sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));
      expired.sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));

      setState(() {
        _expiringItems = expiring;
        _expiredItems = expired;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Expiring Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : RefreshIndicator(
              color: accentGreen,
              backgroundColor: surfaceColor,
              onRefresh: _loadItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_expiringItems.isEmpty && _expiredItems.isEmpty)
                      _buildEmptyState(),
                    if (_expiringItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        '⚠️ Expiring Soon',
                        _expiringItems.length,
                        accentOrange,
                      ),
                      const SizedBox(height: 12),
                      ..._expiringItems.map(_buildItemCard),
                      const SizedBox(height: 24),
                    ],
                    if (_expiredItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        '❌ Expired',
                        _expiredItems.length,
                        accentRed,
                      ),
                      const SizedBox(height: 12),
                      ..._expiredItems.map(_buildItemCard),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: accentGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Good! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No items expiring soon',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Unknown Item';
    final category = item['category']?.toString() ?? 'Other';
    final daysLeft = item['daysLeft'] as int;
    final isExpired = daysLeft < 0;

    final color = isExpired
        ? accentRed
        : daysLeft == 0
        ? accentRed
        : daysLeft <= 1
        ? accentOrange
        : accentOrange.withOpacity(0.7);

    final urgencyText = isExpired
        ? 'Expired ${daysLeft.abs()} day${daysLeft.abs() == 1 ? '' : 's'} ago'
        : daysLeft == 0
        ? 'Expires today!'
        : daysLeft == 1
        ? 'Expires tomorrow'
        : 'Expires in $daysLeft days';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getCategoryIcon(category), color: color, size: 28),
          ),
          const SizedBox(width: 16),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Urgency Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              urgencyText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple_rounded;
      case 'vegetables':
        return Icons.eco_rounded;
      case 'dairy':
        return Icons.water_drop_rounded;
      case 'meat':
        return Icons.food_bank_rounded;
      case 'beverages':
        return Icons.local_drink_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'grains':
        return Icons.grain_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
