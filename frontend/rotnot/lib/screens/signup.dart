import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const Color scaffoldBg = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color accentGreen = Color(0xFF2ECC71);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'user'; // Default role

  final List<Map<String, dynamic>> _roles = [
    {'value': 'user', 'label': 'Individual User', 'icon': Icons.person},
    {'value': 'organization', 'label': 'Organization', 'icon': Icons.business},
    {'value': 'foodbank', 'label': 'Food Bank', 'icon': Icons.restaurant_menu},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Start reducing waste with RotNot",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            _buildField(Icons.person, "Full Name", controller: _nameController),
            const SizedBox(height: 16),
            _buildRoleSelector(),
            const SizedBox(height: 16),
            _buildField(Icons.email, "Email", controller: _emailController),
            const SizedBox(height: 16),
            _buildField(
              Icons.lock,
              "Password",
              isPass: true,
              controller: _passwordController,
            ),
            const SizedBox(height: 16),
            _buildField(
              Icons.lock_outline,
              "Confirm Password",
              isPass: true,
              controller: _confirmPasswordController,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "REGISTER",
                        style: TextStyle(
                          color: Colors.white,
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

  Widget _buildField(
    IconData icon,
    String hint, {
    bool isPass = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: surfaceColor,
        prefixIcon: Icon(icon, color: accentGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              'Select Your Role',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _roles.map((role) {
              final isSelected = _selectedRole == role['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRole = role['value'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentGreen.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? accentGreen
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        role['icon'] as IconData,
                        color: isSelected ? accentGreen : Colors.white60,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role['label'] as String,
                        style: TextStyle(
                          color: isSelected ? accentGreen : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create Firebase account
      final credential = await AuthService.signUp(email, password);

      // 2. Set display name
      await credential.user?.updateDisplayName(name);

      // 3. Create user profile in backend with role
      try {
        await ApiService.createOrUpdateUserProfile(
          role: _selectedRole,
          name: name,
          email: email,
        );
      } catch (profileError) {
        print('Failed to create profile: $profileError');
        // Continue anyway - profile can be created later
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showError(_mapFirebaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  String _mapFirebaseError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('email-already-in-use'))
      return 'This email is already registered.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    return 'Sign up failed. Please try again.';
  }
}
