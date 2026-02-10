import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';
import 'package:rotnot/services/api_service.dart';
import 'package:rotnot/screens/mycontributions.dart';
import 'package:rotnot/screens/leaderboard.dart';
import 'package:rotnot/screens/settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  String? _userRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await ApiService.getUserProfile();
      setState(() {
        _userRole = profile['role'] as String?;
        _loadingRole = false;
      });
    } catch (e) {
      print('Failed to fetch user profile: $e');
      setState(() {
        _loadingRole = false;
      });
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'user':
        return 'Individual User';
      case 'organization':
        return 'Organization';
      case 'foodbank':
        return 'Food Bank';
      default:
        return 'User';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'user':
        return Icons.person;
      case 'organization':
        return Icons.business;
      case 'foodbank':
        return Icons.restaurant_menu;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'user':
        return const Color(0xFF3498DB);
      case 'organization':
        return const Color(0xFFF39C12);
      case 'foodbank':
        return accentGreen;
      default:
        return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'Alex';
    final email = user?.email ?? 'alex.warrior@eco.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
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
                  child: const Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildRoleBadge(),
            const SizedBox(height: 24),

            // --- 2. YOUR RANKING CARD (Gateway to Leaderboard) ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "COMMUNITY STANDING",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardPage(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentGreen.withOpacity(0.2), surfaceColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: accentGreen,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Current Rank",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          "#24 in Nepal",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      "View All",
                      style: TextStyle(
                        color: accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: accentGreen),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- 3. COLLECTIONS TILES ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "COLLECTIONS",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context,
              Icons.card_giftcard_rounded,
              "My Contributions",
              const MyContributionsPage(),
            ),

            const SizedBox(height: 32),

            // --- 4. HELP & SUPPORT ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SUPPORT",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpTile(
              context,
              Icons.help_outline_rounded,
              "Help & Support",
              "Get assistance and FAQs",
            ),

            const SizedBox(height: 32),

            // --- 5. LOGOUT BUTTON ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ACCOUNT",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLogoutButton(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    IconData icon,
    String title,
    Widget targetPage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        ),
      ),
    );
  }

  Widget _buildHelpTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: accentGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
        ),
        onTap: () {
          // TODO: Navigate to help page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Help & Support feature coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        title: const Text(
          "Logout",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.redAccent,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white24,
        ),
        onTap: () => _handleLogout(context),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: accentGreen),
          ),
        );

        // Call logout from AuthService
        await AuthService.logout();

        // The AuthGate will automatically redirect to login screen
        // due to authStateChanges stream, so we just pop the loading dialog
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Logout failed: ${e.toString()}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildRoleBadge() {
    if (_loadingRole) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: accentGreen),
        ),
      );
    }

    if (_userRole == null) {
      return const SizedBox.shrink();
    }

    final roleColor = _getRoleColor(_userRole!);
    final roleIcon = _getRoleIcon(_userRole!);
    final roleLabel = _getRoleLabel(_userRole!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [roleColor.withOpacity(0.2), roleColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, color: roleColor, size: 18),
          const SizedBox(width: 8),
          Text(
            roleLabel,
            style: TextStyle(
              color: roleColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
