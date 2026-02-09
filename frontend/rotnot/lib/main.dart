import 'package:flutter/material.dart';

// Importing the screens from your separate files
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
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomeScreen(),
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

  // Function to switch screens
  void _changeScreen(Widget newScreen, String newTitle) {
    setState(() {
      _activeBody = newScreen;
      _activeTitle = newTitle;
    });
    Navigator.pop(context); // Closes the drawer
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
            // Header with Icon and App Name
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                    SizedBox(height: 10),
                    Text(
                      'RotNot',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scrollable Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(
                    title: 'Home', 
                    icon: Icons.home_rounded, 
                    screen: const Home()
                  ),
                  _buildDrawerTile(
                    title: 'Food Detection', 
                    icon: Icons.camera_rounded, 
                    screen: const FoodDetectionScreen()
                  ),
                  _buildDrawerTile(
                    title: 'Recipe', 
                    icon: Icons.restaurant_menu_rounded, 
                    screen: const RecipeScreen()
                  ),
                  _buildDrawerTile(
                    title: 'Donation', 
                    icon: Icons.volunteer_activism_rounded, 
                    screen: const DonationScreen()
                  ),
                  _buildDrawerTile(
                    title: 'Shelf', 
                    icon: Icons.inventory_2_rounded, 
                    screen: const ShelfScreen()
                  ),
                  _buildDrawerTile(
                    title: 'Settings', 
                    icon: Icons.settings_rounded, 
                    screen: const SettingsScreen()
                  ),
                ],
              ),
            ),

            // Footer Section
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                // Add logout logic here later
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _activeBody,
    );
  }

  // Helper widget to keep the drawer code clean
  Widget _buildDrawerTile({required String title, required IconData icon, required Widget screen}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      onTap: () => _changeScreen(screen, title == 'Home' ? 'RotNot' : title),
    );
  }
}