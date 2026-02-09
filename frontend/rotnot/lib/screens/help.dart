import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "How can we help you?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Contact Cards
          Row(
            children: [
              _buildContactCard(Icons.email_rounded, "Email Support"),
              const SizedBox(width: 15),
              _buildContactCard(Icons.chat_bubble_rounded, "Live Chat"),
            ],
          ),
          
          const SizedBox(height: 35),
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          // FAQ Section
          _buildFAQ("How does food detection work?", 
            "RotNot uses AI to analyze photos of your food. Simply point the camera, and it will identify the item and estimate its shelf life."),
          _buildFAQ("Can I sync data across devices?", 
            "Yes! Once you've created an account, your 'Shelf' and impact stats are synced to the cloud automatically."),
          _buildFAQ("How do I donate food?", 
            "Go to the 'Donate' tab, select the items from your shelf you wish to give away, and choose a local food bank from the map."),
          _buildFAQ("Is my data private?", 
            "Absolutely. We only use your data to improve detection accuracy and provide waste analytics. We never sell your info."),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              "App Version 1.0.4",
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentGreen, size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: accentGreen,
        collapsedIconColor: Colors.white38,
        title: Text(
          question,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.white60, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}