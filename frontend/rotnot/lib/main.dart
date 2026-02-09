import 'package:flutter/material.dart';

// Importing your future files
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _activeBody = const Home();
  String _activeTitle = 'RotNot';

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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            // ... inside the Drawer ListView ...
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.teal),
              title: const Text('Home'), 
              onTap: () => _changeScreen(const Home(), 'Home')
            ),
            ListTile(
              leading: const Icon(Icons.camera_rounded, color: Colors.teal),
              title: const Text('Food Detection'), 
              onTap: () => _changeScreen(const FoodDetectionScreen(), 'Food Detection')
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_rounded, color: Colors.teal),
              title: const Text('Recipe'), 
              onTap: () => _changeScreen(const RecipeScreen(), 'Recipes')
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_rounded, color: Colors.teal),
              title: const Text('Donation'), 
              onTap: () => _changeScreen(const DonationScreen(), 'Donations')
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded, color: Colors.teal),
              title: const Text('Shelf'), 
              onTap: () => _changeScreen(const ShelfScreen(), 'My Shelf')
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.teal),
              title: const Text('Settings'), 
              onTap: () => _changeScreen(const SettingsScreen(), 'Settings')
            ),
// ...
          ],
        ),
      ),
      body: _activeBody,
    );
  }
}