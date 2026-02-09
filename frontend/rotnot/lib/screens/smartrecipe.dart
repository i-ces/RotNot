import 'package:flutter/material.dart';

class SmartRecipesPage extends StatefulWidget {
  const SmartRecipesPage({super.key});

  @override
  State<SmartRecipesPage> createState() => _SmartRecipesPageState();
}

class _SmartRecipesPageState extends State<SmartRecipesPage> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  // Track which items are selected
  final Map<int, bool> _selectedItems = {};

  final List<Map<String, String>> expiringItems = [
    {"name": "Spinach", "days": "1 day left"},
    {"name": "Greek Yogurt", "days": "2 days left"},
    {"name": "Tomatoes", "days": "3 days left"},
    {"name": "Chicken Breast", "days": "4 days left"},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize all as unselected
    for (int i = 0; i < expiringItems.length; i++) {
      _selectedItems[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Recipes"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Extra bottom padding for chatbox
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: INGREDIENT SELECTION ---
                const Text(
                  "Select Ingredients",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tick the items you want the AI to include in your recipe.",
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // THE INGREDIENT CHECKLIST
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expiringItems.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = expiringItems[index];
                      final isSelected = _selectedItems[index] ?? false;

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedItems[index] = value ?? false;
                          });
                        },
                        title: Text(
                          item['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? accentGreen : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          item['days']!,
                          style: TextStyle(
                            color: isSelected ? accentOrange : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        secondary: Icon(
                          Icons.timer_rounded,
                          color: isSelected ? accentOrange : Colors.white24,
                        ),
                        activeColor: accentGreen,
                        checkColor: Colors.black,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // --- SECTION 2: SURPRISE ME (Now the primary action) ---
                _buildActionCard(context),

                const SizedBox(height: 40),

                // --- SECTION 3: PANTRY INFO ---
                const Text(
                  "Need Inspiration?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Type a question in the chat below, like 'What can I make with these for a quick lunch?'",
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          // --- SECTION 4: AI CHATBOX ---
          _buildChatInput(),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildActionCard(BuildContext context) {
    int selectedCount = _selectedItems.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentGreen.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: accentGreen, size: 24),
              const SizedBox(width: 10),
              Text(
                selectedCount > 0 ? "$selectedCount items selected" : "No items selected",
                style: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => _showAILoader(context, "Crafting recipe from your selection..."),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text(
                "GENERATE SMART RECIPE",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Ask AI for recipe tips...",
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: accentGreen,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () {}, // Future AI logic
                ),
              ),
            ],
          ),
        ),
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
              "Our AI is analyzing your selected ingredients to suggest the best Pokhara-style meal.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}