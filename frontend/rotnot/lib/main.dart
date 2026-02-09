import 'package:flutter/material.dart';

// Import all your screen files
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/food_detection.dart';
import 'screens/shelf.dart';      
import 'screens/donation.dart';
import 'screens/profile.dart'; 
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
  int _selectedIndex = 0;
  bool _isSearchActive = false; // Tracks if the shelf search bar is open

  // We use a getter for pages so it can react to the _isSearchActive state
  List<Widget> get _pages => [
    const Home(),
    ShelfScreen(
      onSearchToggle: (bool isActive) {
        setState(() {
          _isSearchActive = isActive;
        });
      },
    ),
    const FoodDetectionScreen(),
    const DonationScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // If we navigate away from Shelf, ensure search mode is reset
      if (index != 1) {
        _isSearchActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- DYNAMIC CAMERA BUTTON ---
      // We use AnimatedScale so it disappears gracefully
      floatingActionButton: AnimatedScale(
        scale: _isSearchActive ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.only(top: 30), 
          child: FloatingActionButton(
            onPressed: _isSearchActive ? null : () => _onItemTapped(2), 
            backgroundColor: MyApp.accentGreen,
            elevation: 2,
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- DYNAMIC BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isSearchActive ? 0 : 70, // Shrinks the bar to 0 when searching
        child: Wrap( // Wrap prevents overflow errors when height is 0
          children: [
            BottomAppBar(
              color: MyApp.surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 70, 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, "Home"),
                  _buildNavItem(1, Icons.inventory_2_rounded, "Shelf"),
                  const SizedBox(width: 48), 
                  _buildNavItem(3, Icons.volunteer_activism_rounded, "Donate"),
                  _buildNavItem(4, Icons.person_rounded, "Profile"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? MyApp.accentGreen : Colors.white38,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? MyApp.accentGreen : Colors.white38,
            ),
          )
        ],
      ),
    );
  }
}