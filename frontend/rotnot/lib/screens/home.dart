import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:RotNot/services/auth_service.dart';
import 'package:RotNot/services/api_service.dart';
import 'package:RotNot/screens/leaderboard.dart';
import 'package:RotNot/screens/smartrecipe.dart';
import 'package:RotNot/screens/expiring_items.dart';
import 'package:RotNot/utils/impact_calculator.dart';

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

  // Savings impact calculations (Nepal-specific metrics)
  double _moneySaved = 0.0;
  double _co2Avoided = 0.0;
  double _totalDonatedWeightKg = 0.0;

  // Donation contributions
  List<dynamic> _donations = [];
  int _totalDonations = 0;
  int _acceptedDonations = 0;
  int _pendingDonations = 0;
  int _totalItemsDonated = 0;

  // Community champion
  Map<String, dynamic>? _champion;

  // Notifications read state
  bool _notificationsRead = false;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
    _loadDonations();
    _loadChampion();
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
    // Savings impact is computed from donations in _calculateDonationStats()
  }

  Future<void> _loadDonations() async {
    try {
      final donations = await ApiService.getDonations();
      setState(() {
        _donations = donations;
        _calculateDonationStats();
      });
    } catch (e) {
      print('Error loading donations: $e');
    }
  }

  void _calculateDonationStats() {
    _totalDonations = _donations.length;
    _acceptedDonations = 0;
    _pendingDonations = 0;
    _totalItemsDonated = 0;

    final List<Map<String, dynamic>> donatedItems = [];

    for (var donation in _donations) {
      final status = donation['status']?.toString().toLowerCase();
      if (status == 'accepted' || status == 'completed' || status == 'Re') {
        _acceptedDonations++;
      } else if (status == 'pending') {
        _pendingDonations++;
      }

      final foodItems = donation['foodItems'] as List?;
      if (foodItems != null) {
        _totalItemsDonated += foodItems.length;

        if (status == 'accepted' ||
            status == 'completed' ||
            status == 'picked_up') {
          for (var fi in foodItems) {
            donatedItems.add({
              'quantity': fi['quantity'] ?? 1,
              'unit': fi['unit'] ?? 'pcs',
              'category': fi['category'],
            });
          }
        }
      }
    }

    final impact = ImpactCalculator.calculateFromDonations(donatedItems);
    _moneySaved = impact.moneySavedNPR;
    _co2Avoided = impact.co2AvoidedKg;
    _totalDonatedWeightKg = impact.totalWeightKg;
  }

  Future<void> _loadChampion() async {
    try {
      final leaderboard = await ApiService.getLeaderboard();
      if (leaderboard.isNotEmpty) {
        setState(() {
          _champion = leaderboard[0];
        });
      }
    } catch (e) {
      print('Error loading champion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final username = user?.displayName?.split(' ').first ?? 'User';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SmartRecipesPage()),
        ),
        backgroundColor: accentGreen,
        child: const Icon(Icons.restaurant_menu, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
              color: accentGreen,
              onRefresh: () async {
                await _loadFoodItems();
                await _loadDonations();
                await _loadChampion();
              },
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
                        Image.asset('assets/images/logo.png', height: 60),
                        _buildNotificationBell(),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 1. PERSONALIZED GREETING ---
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

                    const SizedBox(height: 25),

                    // --- 2. COMMUNITY CHAMPION SPOTLIGHT (Pokhara) ---
                    _buildChampionCard(context),

                    const SizedBox(height: 35),

                    // --- 3. STATUS RINGS ROW ---
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

                    // --- 4. SAVINGS IMPACT CARD ---
                    _buildSavingsImpactCard(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // --- HELPERS ---

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    final intVal = value.round();
    final str = intVal.toString();
    if (str.length <= 3) return str;
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    return '$buffer,$last3';
  }

  // --- WIDGET BUILDERS ---

  Widget _buildChampionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TOP CONTRIBUTOR",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _champion?['name'] ?? 'No champion yet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _champion != null
                        ? '${_champion!['totalItems']} items donated'
                        : 'Be the first to donate!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
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
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1473093226795-af9932fe5856?auto=format&fit=crop&w=200&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "Roasted Tomato Pasta",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.auto_awesome, color: accentGreen, size: 14),
                  ],
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
                  // UPDATED: Points to SmartRecipesPage in smartrecipes.dart
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartRecipesPage(),
                    ),
                  ),
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
                    "Open Smart Recipes",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SHARED UI COMPONENTS ---

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

  Widget _buildSavingsImpactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentGreen.withOpacity(0.08),
            accentGreen.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentGreen.withOpacity(0.1)),
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
                "रू ${_formatNumber(_moneySaved)}",
                "From ${_totalDonatedWeightKg.toStringAsFixed(1)} kg donated",
                accentGreen,
              ),
              const SizedBox(width: 15),
              _buildImpactStat(
                "CO₂ AVOIDED",
                "${_co2Avoided.toStringAsFixed(1)} kg",
                "2.5 kg CO₂e per kg saved",
                const Color(0xFF64FFDA),
              ),
            ],
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

  Widget _buildNotificationBell() {
    final totalAlerts = _notificationsRead ? 0 : (_expiringSoon + _expired);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpiringItemsScreen()),
        );

        // If user marked as read in expiring items screen
        if (result == true) {
          setState(() {
            _notificationsRead = true;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Badge(
          label: Text('$totalAlerts'),
          backgroundColor: totalAlerts > 0 ? accentRed : Colors.grey,
          isLabelVisible: totalAlerts > 0,
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: accentRed),
          const SizedBox(height: 16),
          const Text(
            'Failed to load food items',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFoodItems,
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// --- PAINTERS ---

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
      ..strokeWidth = 5;
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
