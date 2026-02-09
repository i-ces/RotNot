import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';
// 1. Integrated Imports
import 'package:rotnot/screens/savedrecipes.dart';
import 'package:rotnot/screens/impactreport.dart';
import 'package:rotnot/screens/mycontributions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'Alex'; 
    final email = user?.email ?? 'alex.warrior@eco.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Impact"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: accentGreen,
                child: CircleAvatar(
                  radius: 51,
                  backgroundColor: const Color(0xFF121212),
                  child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 12),
            _buildLevelBadge(),
            
            const SizedBox(height: 32),

            // --- CORE STATS CARD ---
            _buildStatsCard(),
            
            const SizedBox(height: 32),

            // --- NAVIGATION TILES ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("COLLECTIONS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            
            _buildOptionTile(
              context, 
              Icons.favorite_rounded, 
              "Saved Recipes", 
              "Access your favorite AI suggestions",
              const SavedRecipesPage(),
            ),
            _buildOptionTile(
              context, 
              Icons.card_giftcard_rounded, 
              "My Contributions", 
              "Track your local food bank donations",
              const MyContributionsPage(),
            ),
            _buildOptionTile(
              context, 
              Icons.analytics_rounded, 
              "Impact Report", 
              "Detailed CO2 and savings analytics",
              const ImpactReportPage(),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withOpacity(0.3)),
      ),
      child: const Text("Eco-Warrior Level 4", style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn("14kg", "Waste Saved"),
          _buildDivider(),
          _buildStatColumn("12", "Donations"),
          _buildDivider(),
          _buildStatColumn("85%", "Shelf Score"),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.white10);

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, String subtitle, Widget targetPage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)),
      ),
    );
  }
}