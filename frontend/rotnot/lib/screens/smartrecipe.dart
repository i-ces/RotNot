import 'package:flutter/material.dart';

class SmartRecipesPage extends StatelessWidget {
  const SmartRecipesPage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    // Hardcoded list of expiring items for Pokhara users
    final List<Map<String, String>> expiringItems = [
      {"name": "Spinach", "days": "1 day left"},
      {"name": "Greek Yogurt", "days": "2 days left"},
      {"name": "Tomatoes", "days": "3 days left"},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Recipes"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: EXPIRING SOON ---
            const Text(
              "Expiring Soon",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Don't let these go to waste! AI can find recipes to use them up right now.",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // KITCHEN RESCUE BUTTON
            _buildRescueButton(context, expiringItems),

            const SizedBox(height: 16),

            // List of Individual items
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Feeling adventurous? Let AI combine everything on your shelf into a custom meal plan.",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            _buildPantryMixCard(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildRescueButton(BuildContext context, List expiringItems) {
    return InkWell(
      onTap: () => _showAILoader(context, "Combining ${expiringItems.length} urgent items..."),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentOrange.withOpacity(0.2), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentOrange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: accentOrange, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Kitchen Rescue: Mix all expiring items",
                style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: accentOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildPantryMixCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: accentGreen, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Ready to cook with everything?",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
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
    );
  }

  Widget _buildExpiringCard(String name, String timeLeft, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: accentOrange, size: 22),
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
          ElevatedButton(
            onPressed: () => _showAILoader(context, "Finding recipes for $name..."),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen.withOpacity(0.1),
              foregroundColor: accentGreen,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Use This", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAILoader(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(color: accentGreen),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            const Text(
              "Our AI is mixing ingredients to find the perfect recipe for you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}