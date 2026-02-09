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

  final List<Widget> _pages = [
    const Home(),
    const ShelfScreen(),        
    const FoodDetectionScreen(), 
    const DonationScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- ADJUSTED CAMERA BUTTON ---
      // Removed centerDocked location to allow it to sit naturally
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30), // Minimal padding to nudge it into the bar
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2), 
          backgroundColor: MyApp.accentGreen,
          elevation: 2, // Lower elevation makes it look more "part of the bar"
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomAppBar(
        color: MyApp.surfaceColor,
        // Removed CircularNotchedRectangle to flatten the bar
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 70, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Home"),
            _buildNavItem(1, Icons.inventory_2_rounded, "Shelf"),
            
            // This is the gap where the FAB sits
            const SizedBox(width: 48), 
            
            _buildNavItem(3, Icons.volunteer_activism_rounded, "Donate"),
            _buildNavItem(4, Icons.person_rounded, "Profile"),
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