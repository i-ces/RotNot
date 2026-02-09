import 'package:flutter/material.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RotNot'),
        backgroundColor: Colors.teal,
      ),
      // Adding the Drawer here
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // A simple header for the drawer
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Drawer items with just names
            ListTile(
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Food Detection'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Recipe'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Donation'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Shelf'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Welcome to RotNot!'),
      ),
    );
  }
}