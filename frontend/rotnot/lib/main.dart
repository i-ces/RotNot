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
      // Pointing to our renamed class
      home: HomeScreen(), 
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Now Flutter knows this is the built-in AppBar widget
      appBar: AppBar(
        title: const Text('RotNot'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text('Welcome to RotNot!'),
      ),
    );
  }
}