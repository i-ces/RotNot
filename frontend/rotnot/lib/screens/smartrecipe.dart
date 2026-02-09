import 'package:flutter/material.dart';

class SmartRecipesScreen extends StatelessWidget {
  const SmartRecipesScreen({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22); // For "Expiring Soon"
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    // Mock data: In a real app, this comes from your Shelf database
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

            // Phase 1: The "Expiring Soon" List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expiringItems.length,
              itemBuilder: (context, index) {
                final item = expiringItems[index];
                return _buildExpiringCard(item['name']!, item['days']!, context);
              },
            ),
            
            const SizedBox(height: 30),
            // Placeholder for Phase 2 (Coming next)
            _buildPhase2Placeholder(),
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
          const Icon(Icons.warning_amber_rounded, color: accentOrange),
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
          ElevatedButton(
            onPressed: () {
              // This is where your AI logic will trigger
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("AI is finding recipes for $name...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Find Recipes"),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase2Placeholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text(
          "All Shelf Items functionality coming soon...",
          style: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
}