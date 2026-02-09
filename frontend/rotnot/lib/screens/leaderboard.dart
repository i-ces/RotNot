import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Eco-Warriors"),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 30,
        itemBuilder: (context, index) {
          int rank = index + 1;
          bool isMe = rank == 24;
          bool isTopThree = rank <= 3;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? accentGreen.withOpacity(0.1) : surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: isMe ? Border.all(color: accentGreen.withOpacity(0.5)) : null,
            ),
            child: Row(
              children: [
                // Rank Number/Icon
                SizedBox(
                  width: 35,
                  child: isTopThree 
                    ? Icon(_getTrophyIcon(rank), color: _getTrophyColor(rank), size: 20)
                    : Text("#$rank", style: const TextStyle(color: Colors.white38)),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, size: 20, color: Colors.white30),
                ),
                const SizedBox(width: 15),
                // Name
                Text(
                  isMe ? "Alex (You)" : _getRandomName(rank),
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    color: isMe ? accentGreen : Colors.white,
                  ),
                ),
                const Spacer(),
                // Points/Impact
                Text(
                  "${(400 - (index * 12))} kg",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getTrophyIcon(int rank) {
    return rank == 1 ? Icons.workspace_premium : Icons.emoji_events;
  }

  Color _getTrophyColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }

  String _getRandomName(int rank) {
    const names = ["Anish", "Suman", "Priya", "Nisha", "Bibek", "Rohan", "Aayush", "Sita"];
    return names[rank % names.length];
  }
}