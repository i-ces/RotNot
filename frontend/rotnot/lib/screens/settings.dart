import 'package:flutter/material.dart';
import 'package:rotnot/services/auth_service.dart';
import 'package:rotnot/screens/help.dart';
import 'package:rotnot/screens/notification_test.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;

  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color accentGreen = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Account"),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              subtitle: AuthService.currentUser?.email ?? '',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Preferences"),
            _buildSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: "Push Notifications",
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Support"),
            _buildSettingsTile(
              icon: Icons.help_outline_rounded,
              title: "Help Center",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.info_outline_rounded,
              title: "About RotNot",
              subtitle: "v1.0.0",
              onTap: () {},
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Developer"),
            _buildSettingsTile(
              icon: Icons.science_outlined,
              title: "🧪 Test Notifications",
              subtitle: "Test expiry alerts in real-time",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: accentGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: accentGreen,
        onChanged: onChanged,
      ),
    );
  }
}
