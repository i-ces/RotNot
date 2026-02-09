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
      // SafeArea ensures content doesn't go behind the status bar/notch
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      // We removed the separate FloatingActionButton to put it inside the BottomAppBar
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isSearchActive ? 0 : null, // Hide when searching
        child: Wrap(
          children: [
            // SafeArea handles the bottom system navigation bar (Home/Back/Recent buttons)
            SafeArea(
              child: BottomAppBar(
                color: MyApp.surfaceColor,
                elevation: 0,
                padding: EdgeInsets.zero, // Clean padding for custom row
                height: 80, // Slightly taller to accommodate the camera button
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center, // Aligns all items in the same horizontal row
                  children: [
                    _buildNavItem(0, Icons.home_rounded, "Home"),
                    _buildNavItem(1, Icons.inventory_2_rounded, "Shelf"),
                    
                    // --- INTEGRATED CAMERA BUTTON ---
                    _buildCameraButton(),
                    
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
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
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
            )
          ],
        ),
      ),
    );
  }
}