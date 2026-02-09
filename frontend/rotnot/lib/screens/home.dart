import 'package:flutter/material.dart';
import 'dart:math' as math;

class Home extends StatelessWidget {
  const Home({super.key});

  // Theme Colors
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    // This would eventually come from your Auth provider
    const String username = "Alex"; 

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PERSONALIZED GREETING HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hey, $username",
                      style: TextStyle(
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
                  ],
                ),
                _buildNotificationBell(),
              ],
            ),

            const SizedBox(height: 35),

            // --- 2. STATUS RINGS ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusRing("Total Items", "8", accentGreen, Icons.inventory_2_outlined),
                _buildStatusRing("Expiring Soon", "6", accentOrange, Icons.warning_amber_rounded),
                _buildStatusRing("Expired", "1", accentRed, Icons.timer_off_outlined),
              ],
            ),

            const SizedBox(height: 30),

            // --- 3. SAVINGS IMPACT CARD (LOCALIZED NEPAL) ---
            const Text(
              "Savings Impact",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Container(
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
                        child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Local Impact (Nepal)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      // Localized Money Saved (NPR 210/kg average)
                      _buildImpactStat(
                        "MONEY SAVED", 
                        "रू 1,420", 
                        "+12% this week", 
                        accentGreen
                      ),
                      const SizedBox(width: 15),
                      // CO2 Avoided (2.5 kg CO2e factor)
                      _buildImpactStat(
                        "CO2 AVOIDED", 
                        "18.4 kg", 
                        "CO₂e saved", 
                        const Color(0xFF64FFDA)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

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
        child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildStatusRing(String label, String value, Color color, IconData icon) {
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
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String label, String value, String subValue, Color color) {
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
                letterSpacing: 0.5
              )
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subValue, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10)),
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