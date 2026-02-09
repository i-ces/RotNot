import 'package:flutter/material.dart';

class SmartRecipesScreen extends StatelessWidget {
  const SmartRecipesScreen({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> expiringItems = [
      {"name": "Spinach", "days": "1 day left"},
      {"name": "Greek Yogurt", "days": "2 days left"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Recipes"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: EXPIRING SOON ---
            const Text(
              "Expiring Soon",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Don't let these go to waste! AI can find recipes to use them up right now.",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expiringItems.length,
              itemBuilder: (context, index) {
                final item = expiringItems[index];
                return _buildExpiringCard(item['name']!, item['days']!, context);
              },
            ),

            const SizedBox(height: 40),

            // --- SECTION 2: PANTRY MIX (Button Included Here Now) ---
            const Text(
              "Pantry Mix",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Feeling adventurous? Let AI combine everything on your shelf into a custom meal plan.",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: accentGreen, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    "Ready to cook with everything?",
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _showAILoader(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "SURPRISE ME (ALL ITEMS)",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Space for future "Further things" you mentioned
            const SizedBox(height: 40),
            _buildFutureFeaturePlaceholder("Recipe History"),
            const SizedBox(height: 12),
            _buildFutureFeaturePlaceholder("Cuisine Preferences"),
          ],
        ),
      ),
    );
  }

  void _showAILoader(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(30),
        child: const Column(
          children: [
            CircularProgressIndicator(color: accentGreen),
            const SizedBox(height: 20),
            const Text("Analyzing Shelf Contents...",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text(
              "Our AI is mixing ingredients to find the perfect recipe for you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringCard(String name, String timeLeft, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: accentOrange),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(timeLeft, style: const TextStyle(color: accentOrange, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Use This", style: TextStyle(color: accentGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureFeaturePlaceholder(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white24)),
          const Spacer(),
          const Icon(Icons.lock_outline, color: Colors.white10, size: 18),
        ],
      ),
    );
  }
}