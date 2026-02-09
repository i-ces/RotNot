import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  // This makes the system bar transparent and allows our app to handle the padding
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
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
  bool _isSearchActive = false; 

  List<Widget> get _pages => [
    const Home(),
    ShelfScreen(onSearchToggle: (isActive) => setState(() => _isSearchActive = isActive)),
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
      // 1. Body uses SafeArea to avoid the top "notch"/status bar
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      // 2. Adjusting the Floating Action Button Location
      // We use a custom location or standard docked to keep it above the bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedScale(
        scale: _isSearchActive ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(top: 10), // Prevents it from sitting too low
          child: FloatingActionButton(
            onPressed: _isSearchActive ? null : () => _onItemTapped(2), 
            backgroundColor: MyApp.accentGreen,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),

      // 3. The Bottom Navigation Bar Fix
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // We use zero height when searching, otherwise let it fit naturally
        height: _isSearchActive ? 0 : null, 
        child: Wrap(
          children: [
            // SafeArea here is the MAGIC. It automatically adds padding 
            // specifically for the system navigation bar (back/home buttons).
            SafeArea(
              child: BottomAppBar(
                color: MyApp.surfaceColor,
                elevation: 0,
                height: 70, // Standard height
                notchMargin: 10,
                shape: const CircularNotchedRectangle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Home"),
                    _buildNavItem(1, Icons.inventory_2_rounded, "Shelf"),
                    const SizedBox(width: 50), // Gap for the Camera FAB
                    _buildNavItem(3, Icons.volunteer_activism_rounded, "Donate"),
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? MyApp.accentGreen : Colors.white38, size: 24),
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