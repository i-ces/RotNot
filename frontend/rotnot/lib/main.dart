import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

// Import all your screen files
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/food_detection.dart';
import 'screens/shelf.dart';
import 'screens/donation.dart';
import 'screens/profile.dart';
import 'screens/signup.dart';
import 'screens/forgotpw.dart';
import 'screens/settings.dart';
import 'screens/help.dart';
import 'screens/smartrecipe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is not supported on Linux/Windows/macOS desktop
  if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
    await Firebase.initializeApp();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color scaffoldBg = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color appBarColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RotNot',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: scaffoldBg,
        primaryColor: accentGreen,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/signup': (context) => const SignUpPage(),
        '/forgotpw': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase not available on desktop — skip auth
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return const HomeScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginPage();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearchActive = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    const Home(),
    ShelfScreen(
      onSearchToggle: (isActive) => setState(() => _isSearchActive = isActive),
    ),
    const FoodDetectionScreen(),
    const DonationScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) _isSearchActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebar(context),
      // FIX: Removed the Stack and Positioned IconButton that was overlapping content.
      // The body now only contains the IndexedStack.
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isSearchActive ? 0 : null,
        child: Wrap(
          children: [
            SafeArea(
              child: BottomAppBar(
                color: MyApp.surfaceColor,
                elevation: 0,
                padding: EdgeInsets.zero,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Home"),
                    _buildNavItem(1, Icons.inventory_2_rounded, "Shelf"),
                    _buildCameraButton(),
                    _buildNavItem(
                      3,
                      Icons.volunteer_activism_rounded,
                      "Donate",
                    ),
                    _buildNavItem(4, Icons.person_rounded, "Profile"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';

    return Drawer(
      backgroundColor: MyApp.scaffoldBg,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: MyApp.surfaceColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: MyApp.accentGreen,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              email,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.analytics_rounded, "Waste Analytics", () {}),
                _drawerItem(Icons.restaurant_menu_rounded, "Smart Recipes", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartRecipesScreen(),
                    ),
                  );
                }),
                _drawerItem(
                  Icons.notifications_active_rounded,
                  "Expiry Alerts",
                  () {},
                ),
                _drawerItem(Icons.history_rounded, "Donation History", () {}),
                const Divider(color: Colors.white12, indent: 20, endIndent: 20),
                _drawerItem(Icons.settings_rounded, "Settings", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }),
                _drawerItem(Icons.help_outline_rounded, "Help & Support", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _drawerItem(Icons.logout_rounded, "Logout", () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 24),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 15),
      ),
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: MyApp.accentGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MyApp.accentGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? MyApp.accentGreen : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? MyApp.accentGreen : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
