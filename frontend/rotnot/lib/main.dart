import 'package:flutter/material.dart';

import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/food_detection.dart';
import 'screens/recipe.dart';
import 'screens/donation.dart';
import 'screens/shelf.dart';
import 'screens/settings.dart';
import 'screens/signup.dart';
import 'screens/forgotpw.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color scaffoldBg = Color(0xFF121212);    
  static const Color surfaceColor = Color(0xFF1E1E1E); 
  static const Color accentGreen = Color(0xFF2ECC71);  
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
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarColor,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: accentGreen),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/forgotpw': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomeScreen(),
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
  Widget _activeBody = const Home(); 
  String _activeTitle = 'Home';
  IconData _activeIcon = Icons.home_rounded;

  void _changeScreen(Widget newScreen, String newTitle, IconData newIcon) {
    setState(() {
      _activeBody = newScreen;
      _activeTitle = newTitle;
      _activeIcon = newIcon;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_activeIcon, color: MyApp.accentGreen, size: 22),
            const SizedBox(width: 12),
            Text(_activeTitle == 'Home' ? 'RotNot' : _activeTitle),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: MyApp.surfaceColor,
        child: SafeArea( // <--- THIS PREVENTS BLEEDING TO THE TOP
          child: Column(
            children: [
              // This pushes the content down further if SafeArea isn't enough
              const SizedBox(height: 20), 

              // --- LOGO IN DRAWER HEADER ---
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: MyApp.appBarColor,
                  border: Border(
                    top: BorderSide(color: Colors.white10, width: 1), // Optional: adds a top line
                    bottom: BorderSide(color: Colors.white10, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.eco_rounded, color: MyApp.accentGreen, size: 50);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "ROTNOT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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

              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pushReplacementNamed(context, '/'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: _activeBody,
      ),
    );
  }

  Widget _buildDrawerTile(String title, IconData icon, Widget screen) {
    bool isSelected = (_activeTitle == title);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? MyApp.accentGreen.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? MyApp.accentGreen : Colors.white60,
          size: 22,
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )
        ),
        onTap: () => _changeScreen(screen, title, icon),
      ),
    );
  }
}