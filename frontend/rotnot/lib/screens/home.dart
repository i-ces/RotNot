import 'package:flutter/material.dart';
import 'dart:math' as math;

class Home extends StatelessWidget {
  const Home({super.key});

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
            // --- PERSONALIZED GREETING HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hey, $username",
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                // Notification Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Badge(
                    label: Text("3"), // Mock notification count
                    backgroundColor: accentRed,
                    child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                  ),
                )
              ],
            ),

            const SizedBox(height: 35),

            // --- STATUS RINGS ROW ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusRing("Total Items", "8", accentGreen, Icons.inventory_2_outlined),
                _buildStatusRing("Expiring Soon", "6", accentOrange, Icons.warning_amber_rounded),
                _buildStatusRing("Expired", "1", accentRed, Icons.timer_off_outlined),
              ],
            ),
          ],
        ),
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
                  Text(
                    value, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            style: TextStyle(
              color: color, 
              fontSize: 10, 
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            )
          ),
        ],
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