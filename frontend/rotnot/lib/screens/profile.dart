import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';
import 'package:rotnot/screens/savedrecipes.dart';
import 'package:rotnot/screens/impactreport.dart';
import 'package:rotnot/screens/mycontributions.dart';
import 'package:rotnot/screens/leaderboard.dart'; // Ensure this import exists

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
            // --- 1. PROFILE HEADER ---
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: accentGreen,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFF121212),
                  child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 24),

            // --- 2. YOUR RANKING CARD (Gateway to Leaderboard) ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("COMMUNITY STANDING", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentGreen.withOpacity(0.2), surfaceColor]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: accentGreen, size: 30),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Current Rank", style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text("#24 in Nepal", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    const Text("View All", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                    const Icon(Icons.chevron_right_rounded, color: accentGreen),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- 3. COLLECTIONS TILES ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("COLLECTIONS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(context, Icons.favorite_rounded, "Saved Recipes", const SavedRecipesPage()),
            _buildOptionTile(context, Icons.card_giftcard_rounded, "My Contributions", const MyContributionsPage()),
            _buildOptionTile(context, Icons.analytics_rounded, "Impact Report", const ImpactReportPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, Widget targetPage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: accentGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)),
      ),
    );
  }
}