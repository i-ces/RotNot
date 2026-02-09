import 'package:flutter/material.dart';

// Your screen imports
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/food_detection.dart';
import 'screens/recipe.dart';
import 'screens/donation.dart';
import 'screens/shelf.dart';
import 'screens/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RotNot',
      // The theme is set to dark globally here
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0000),
      ),
      // --- ROUTE NAVIGATION SETUP ---
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),    // Starting screen
        '/home': (context) => const HomeScreen(), // Main app shell
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
  // Navigation State
  Widget _activeBody = const Home();
  String _activeTitle = 'RotNot';

  // Helper to swap screens and close drawer
  void _changeScreen(Widget newScreen, String newTitle) {
    setState(() {
      _activeBody = newScreen;
      _activeTitle = newTitle;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeTitle),
        backgroundColor: Colors.teal,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(
                  'RotNot',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Navigation List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile('Home', Icons.home_rounded, const Home()),
                  _buildDrawerTile('Food Detection', Icons.camera_rounded, const FoodDetectionScreen()),
                  _buildDrawerTile('Recipe', Icons.restaurant_menu_rounded, const RecipeScreen()),
                  _buildDrawerTile('Donation', Icons.volunteer_activism_rounded, const DonationScreen()),
                  _buildDrawerTile('Shelf', Icons.inventory_2_rounded, const ShelfScreen()),
                  _buildDrawerTile('Settings', Icons.settings_rounded, const SettingsScreen()),
                ],
              ),
            ),
            // Logout Footer
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                // Returns to login and clears the screen stack
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // SAFE AREA: Keeps UI above system navigation buttons (back, home, apps)
      body: SafeArea(
        bottom: true,
        child: _activeBody,
      ),
    );
  }

  // Custom tile builder to keep code clean
  Widget _buildDrawerTile(String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      onTap: () => _changeScreen(screen, title == 'Home' ? 'RotNot' : title),
    );
  }
}