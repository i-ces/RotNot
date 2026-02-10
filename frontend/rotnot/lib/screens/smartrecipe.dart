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

  final Map<int, bool> _selectedItems = {};
  bool _isExpanded = false;

  final List<Map<String, String>> expiringItems = [
    {"name": "Spinach", "days": "1 day left"},
    {"name": "Greek Yogurt", "days": "2 days left"},
    {"name": "Tomatoes", "days": "3 days left"},
    {"name": "Chicken Breast", "days": "4 days left"},
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < expiringItems.length; i++) {
      _selectedItems[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _selectedItems.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Smart Recipes"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Use resizeToAvoidBottomInset to prevent the keyboard from breaking the UI
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            // Extra bottom padding (140) so content doesn't get hidden behind the chatbox
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: THE GIANT RECIPE HUB CONTAINER ---
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: accentGreen.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Expandable Dropbox
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          unselectedWidgetColor: Colors.white60,
                        ),
                        child: ExpansionTile(
                          onExpansionChanged: (val) => setState(() => _isExpanded = val),
                          title: const Text(
                            "Select Ingredients",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                          subtitle: Text(
                            "$selectedCount items selected for rescue",
                            style: TextStyle(
                              color: selectedCount > 0 ? accentGreen : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          leading: Icon(
                            Icons.inventory_2_rounded,
                            color: _isExpanded ? accentGreen : Colors.white60,
                          ),
                          trailing: Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white38,
                          ),
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: expiringItems.length,
                              itemBuilder: (context, index) {
                                final item = expiringItems[index];
                                final isSelected = _selectedItems[index] ?? false;
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (val) => setState(() => _selectedItems[index] = val!),
                                  activeColor: accentGreen,
                                  checkColor: Colors.black,
                                  title: Text(
                                    item['name']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? accentGreen : Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['days']!,
                                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      
                      // Action Button within the same frame
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: selectedCount > 0 
                                ? () => _showAILoader(context, "Mixing $selectedCount ingredients...") 
                                : null,
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: const Text("GENERATE FROM SELECTION", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.white10,
                              disabledForegroundColor: Colors.white24,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- SECTION 2: SURPRISE ME BUTTON ---
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text("Feeling Indecisive?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                _buildSurpriseMeButton(),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "AI Kitchen Assistant Active",
                    style: TextStyle(color: Colors.white10, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // --- SECTION 3: REPOSITIONED AI CHATBOX ---
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildSurpriseMeButton() {
    return InkWell(
      onTap: () => _showAILoader(context, "Scanning your whole shelf..."),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: accentOrange, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Surprise Me", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text("Generate a random recipe from everything you have", 
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // Added bottom padding to handle system navigation bars
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 25), 
        decoration: BoxDecoration(
          color: surfaceColor,
          // Added a slight blur effect to the background of the chatbox
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          // SafeArea nested here further ensures it avoids "The Notch" or "The Bar"
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
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask AI for recipe tips...",
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: accentGreen,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () {},
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const LinearProgressIndicator(
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
            ),
            const SizedBox(height: 32),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 12),
            const Text("Finding the best recipe for your ingredients...", 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}