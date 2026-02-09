import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:rotnot/services/auth_service.dart';
import 'package:rotnot/services/api_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Theme Colors
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  List<dynamic> _foodItems = [];
  bool _isLoading = true;
  String? _error;

  int _totalItems = 0;
  int _expiringSoon = 0;
  int _expired = 0;

  // Savings impact calculations
  double _moneySaved = 0.0;
  double _co2Avoided = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await ApiService.getFoodItems();
      setState(() {
        _foodItems = items;
        _calculateStats();
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

  void _calculateStats() {
    _totalItems = _foodItems.length;
    _expiringSoon = 0;
    _expired = 0;

    final now = DateTime.now();

    for (var item in _foodItems) {
      if (item['expiryDate'] != null) {
        final expiryDate = DateTime.parse(item['expiryDate']);
        final daysUntilExpiry = expiryDate.difference(now).inDays;

        if (daysUntilExpiry < 0) {
          _expired++;
        } else if (daysUntilExpiry <= 3) {
          _expiringSoon++;
        }
      }
    }

    // Calculate savings impact
    // Average food item cost in NPR (Nepali Rupees)
    const double avgItemCost = 150.0;

    // Money saved by not wasting expired items (consumed before expiry)
    // Formula: (total items - expired items) × average cost
    final itemsConsumed = _totalItems - _expired;
    _moneySaved = itemsConsumed * avgItemCost;

    // CO2 avoided by reducing food waste
    // Formula: items consumed × 0.5 kg CO2 per item (average food waste carbon footprint)
    _co2Avoided = itemsConsumed * 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final username = user?.displayName?.split(' ').first ?? 'User';

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: accentRed),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load food items',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFoodItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFoodItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 0. TOP NAVIGATION ROW ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMenuButton(context),
                        _buildNotificationBell(),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 1. PERSONALIZED GREETING HEADER ---
                    Text(
                      "Hey, $username",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Track your food, reduce waste,\nsave the planet.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // --- 2. STATUS RINGS ROW (REAL DATA) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusRing(
                          "Total Items",
                          "$_totalItems",
                          accentGreen,
                          Icons.inventory_2_outlined,
                        ),
                        _buildStatusRing(
                          "Expiring Soon",
                          "$_expiringSoon",
                          accentOrange,
                          Icons.warning_amber_rounded,
                        ),
                        _buildStatusRing(
                          "Expired",
                          "$_expired",
                          accentRed,
                          Icons.timer_off_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- 3. SAVINGS IMPACT CARD ---
                    _buildSavingsImpactCard(),

                    const SizedBox(height: 30),

                    // --- 4. AI RECIPE SUGGESTION ---
                    const Text(
                      "AI Recipe Suggestion",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildRecipeSuggestionCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSavingsImpactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentGreen.withOpacity(0.15),
            accentGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Savings Impact",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _buildImpactStat(
                "MONEY SAVED",
                "रू ${_moneySaved.toStringAsFixed(0)}",
                "By reducing waste",
                accentGreen,
              ),
              const SizedBox(width: 15),
              _buildImpactStat(
                "CO2 AVOIDED",
                "${_co2Avoided.toStringAsFixed(1)} kg",
                "Carbon footprint",
                const Color(0xFF64FFDA),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Recipe Image Placeholder
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                // Replace with actual NetworkImage later
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1473093226795-af9932fe5856?auto=format&fit=crop&w=200&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Roasted Tomato Pasta",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Use your expiring tomatoes!",
                  style: TextStyle(
                    color: accentOrange.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to Smart Recipes
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "View Recipe",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Badge(
        label: Text("3"),
        backgroundColor: accentRed,
        child: Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildStatusRing(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: CustomPaint(
                  painter: RingPainter(progress: 0.75, color: color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: Colors.white38),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(
    String label,
    String value,
    String subValue,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subValue,
              style: TextStyle(color: color.withOpacity(0.5), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  RingPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
