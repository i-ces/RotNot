import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        // Removed the spaces and settings icon for a cleaner look
        title: const Text("My Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          children: [
            const Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: accentGreen,
                    child: CircleAvatar(
                      radius: 51,
                      backgroundColor: Color(0xFF121212),
                      child: Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
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
            const SizedBox(height: 8),
            const Text(
              "Eco-Warrior Level 4",
              style: TextStyle(color: accentGreen, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Impact Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("14kg", "Food Saved"),
                  _buildDivider(),
                  _buildStatColumn("12", "Donations"),
                  _buildDivider(),
                  _buildStatColumn("85%", "Shelf Score"),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildOptionTile(Icons.history_rounded, "Shelf History"),
            _buildOptionTile(Icons.favorite_rounded, "Saved Recipes"),
            _buildOptionTile(Icons.card_giftcard_rounded, "My Contributions"),
            _buildOptionTile(Icons.info_outline_rounded, "Impact Report"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white10);
  }

  Widget _buildOptionTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentGreen, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
        ),
        onTap: () {
          // Add navigation logic for these sub-sections later
        },
      ),
    );
  }
}
