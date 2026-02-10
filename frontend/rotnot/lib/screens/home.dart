import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:rotnot/services/auth_service.dart';
import 'package:rotnot/services/api_service.dart';
import 'package:rotnot/screens/leaderboard.dart';
import 'package:rotnot/screens/smartrecipe.dart';

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

  // Donation contributions
  List<dynamic> _donations = [];
  int _totalDonations = 0;
  int _acceptedDonations = 0;
  int _pendingDonations = 0;
  int _totalItemsDonated = 0;

  // Community champion
  Map<String, dynamic>? _champion;

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

    const double avgItemCost = 150.0;
    final itemsConsumed = _totalItems - _expired;
    _moneySaved = itemsConsumed * avgItemCost;
    _co2Avoided = itemsConsumed * 0.5;
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

    for (var donation in _donations) {
      final status = donation['status']?.toString().toLowerCase();
      if (status == 'accepted') {
        _acceptedDonations++;
      } else if (status == 'pending') {
        _pendingDonations++;
      }

      final foodItems = donation['foodItems'] as List?;
      if (foodItems != null) {
        _totalItemsDonated += foodItems.length;
      }
    }
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
                        _buildMenuButton(context),
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

                    const SizedBox(height: 30),

                    // --- 5. MY CONTRIBUTIONS ---
                    if (_totalDonations > 0) ...[
                      const Text(
                        "My Contributions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildContributionsCard(),
                      const SizedBox(height: 30),
                    ],

                    // --- 6. AI RECIPE SUGGESTION ---
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
                    "COMMUNITY CHAMPION",
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _champion?['userName'] ?? 'No champion yet',
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

  Widget _buildContributionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3498DB).withOpacity(0.15),
            const Color(0xFF3498DB).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF3498DB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Food Donations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Your impact in the community",
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildContributionStat(
                  "Total Donations",
                  "$_totalDonations",
                  Icons.card_giftcard_rounded,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContributionStat(
                  "Items Shared",
                  "$_totalItemsDonated",
                  Icons.inventory_2_rounded,
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContributionStat(
                  "Accepted",
                  "$_acceptedDonations",
                  Icons.check_circle_rounded,
                  accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContributionStat(
                  "Pending",
                  "$_pendingDonations",
                  Icons.pending_rounded,
                  accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributionStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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
