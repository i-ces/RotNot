import 'package:flutter/material.dart';

class SavedRecipesPage extends StatelessWidget {
  const SavedRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Recipes")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) {
          final recipes = ["Spicy Tomato Pasta", "Veggie Stir Fry", "Banana Pancakes"];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Color(0xFF2ECC71)),
              title: Text(recipes[index]),
              subtitle: const Text("AI Suggested • 15 mins"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
            ),
          );
        },
      ),
    );
  }
}