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
      body: Column( // Changed to Column + Expanded for fixed bottom button
        children: [
          Expanded(
            child: SingleChildScrollView(
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

                  // Phase 1: Expiring List
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

                  // Phase 2: Information Section
                  const Text(
                    "Pantry Mix",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Feeling adventurous? Let AI combine everything on your shelf into a custom meal plan.",
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // --- PHASE 2: MASTER COMBINE BUTTON ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ready to cook with everything?",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // AI Logic for combining all items
                        _showAILoader(context);
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text("SURPRISE ME (ALL ITEMS)", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        child: Column(
          children: [
            const CircularProgressIndicator(color: accentGreen),
            const SizedBox(height: 20),
            const Text("Analyzing Shelf Contents...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
}