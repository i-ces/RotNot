import 'package:flutter/material.dart';

class MyContributionsPage extends StatelessWidget {
  const MyContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Contributions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _contributionTile("Lalitpur Food Bank", "5kg Rice, 2kg Lentils", "2 days ago"),
            _contributionTile("Community Kitchen", "Assorted Vegetables", "1 week ago"),
          ],
        ),
      ),
    );
  }

  Widget _contributionTile(String place, String items, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism, color: Color(0xFF2ECC71)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(items, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}