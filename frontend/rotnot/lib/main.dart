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
            ListTile(title: const Text('Home'), onTap: () => _changeScreen(const Home(), 'Home')),
            ListTile(title: const Text('Food Detection'), onTap: () => _changeScreen(const FoodDetectionScreen(), 'Food Detection')),
            ListTile(title: const Text('Recipe'), onTap: () => _changeScreen(const RecipeScreen(), 'Recipes')),
            ListTile(title: const Text('Donation'), onTap: () => _changeScreen(const DonationScreen(), 'Donations')),
            ListTile(title: const Text('Shelf'), onTap: () => _changeScreen(const ShelfScreen(), 'My Shelf')),
            ListTile(title: const Text('Settings'), onTap: () => _changeScreen(const SettingsScreen(), 'Settings')),
          ],
        ),
      ),
      body: _activeBody,
    );
  }
}