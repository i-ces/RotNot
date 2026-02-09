import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'Alex'; // Default for preview
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
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 55,
                    backgroundColor: accentGreen,
                    child: CircleAvatar(
                      radius: 51,
                      backgroundColor: Color(0xFF121212),
                      child: Icon(Icons.person_rounded, size: 60, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: accentGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_rounded, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Badge / Level indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withOpacity(0.3)),
              ),
              child: const Text(
                "Eco-Warrior Level 4",
                style: TextStyle(color: accentGreen, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 32),

            // --- 2. CORE STATS CARD ---
            Container(
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
            ),
            
            const SizedBox(height: 32),

            // --- 3. OPTIONS & ACTIONS ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Collections", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(Icons.favorite_rounded, "Saved Recipes", "Access your favorite AI suggestions"),
            _buildOptionTile(Icons.card_giftcard_rounded, "My Contributions", "Track your local food bank donations"),
            _buildOptionTile(Icons.analytics_rounded, "Impact Report", "Detailed CO2 and savings analytics"),
            
            const SizedBox(height: 24),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("App Settings", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(Icons.notifications_active_rounded, "Expiry Alerts", "Manage how you get notified"),
            _buildOptionTile(Icons.language_rounded, "Region: Nepal", "Currency and unit preferences"),
            
            const SizedBox(height: 32),
            
            // Logout Button
            TextButton.icon(
              onPressed: () {
                // AuthService().signOut();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white38),
              label: const Text("Log Out", style: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accentGreen, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: () {},
      ),
    );
  }
}