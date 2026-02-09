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
            const SizedBox(height: 16),

            // NEW: KITCHEN RESCUE BUTTON (Mix all expiring items)
            _buildRescueButton(context, expiringItems),

            const SizedBox(height: 16),

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

            // --- SECTION 2: PANTRY MIX ---
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
                      onPressed: () => _showAILoader(context, "Scanning whole shelf..."),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget for the new "Mix Expiring Items" button
  Widget _buildRescueButton(BuildContext context, List expiringItems) {
    return InkWell(
      onTap: () => _showAILoader(context, "Combining ${expiringItems.length} urgent items..."),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentOrange.withOpacity(0.2), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentOrange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: accentOrange, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Kitchen Rescue: Mix all expiring items",
                style: TextStyle(color: accentOrange, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: accentOrange),
          ],
        ),
      ),
    );
  }

  void _showAILoader(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const CircularProgressIndicator(color: accentGreen),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: accentOrange, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(timeLeft, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showAILoader(context, "Finding recipes for $name..."),
            child: const Text("Use This", style: TextStyle(color: accentGreen)),
          ),
        ],
      ),
    );
  }
}