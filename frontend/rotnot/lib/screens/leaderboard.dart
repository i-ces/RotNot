import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Leaderboard"),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 30,
        itemBuilder: (context, index) {
          int rank = index + 1;
          bool isMe = rank == 24;
          bool isTopThree = rank <= 3;
          
          // Data Logic for Institutions vs Individuals
          final entity = _getLeaderboardData(rank, isMe);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? accentGreen.withOpacity(0.1) : surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: isMe ? Border.all(color: accentGreen.withOpacity(0.5)) : null,
            ),
            child: Row(
              children: [
                // Rank Number/Icon
                SizedBox(
                  width: 35,
                  child: isTopThree 
                    ? Icon(_getTrophyIcon(rank), color: _getTrophyColor(rank), size: 22)
                    : Text("#$rank", style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                
                // Entity Icon (Business vs Person)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: entity['type'] == 'Individual' ? Colors.white10 : accentGreen.withOpacity(0.2),
                  child: Icon(
                    _getEntityIcon(entity['type']), 
                    size: 20, 
                    color: entity['type'] == 'Individual' ? Colors.white30 : accentGreen
                  ),
                ),
                const SizedBox(width: 15),
                
                // Name and Category Tag
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entity['name'],
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                          color: isMe ? accentGreen : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entity['type'].toUpperCase(),
                          style: TextStyle(fontSize: 8, color: isMe ? accentGreen : Colors.white38, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Impact Data
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${entity['weight']} kg",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text("DONATED", style: TextStyle(fontSize: 8, color: Colors.white24)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- LOGIC HELPERS ---

  Map<String, dynamic> _getLeaderboardData(int rank, bool isMe) {
    if (isMe) {
      return {'name': 'Alex (You)', 'type': 'Individual', 'weight': '14'};
    }

    // Hardcoded high-performers for top ranks
    switch (rank) {
      case 1: return {'name': 'Hyatt Regency Kathmandu', 'type': 'Hotel', 'weight': '1,240'};
      case 2: return {'name': 'The Everest Hotel', 'type': 'Hotel', 'weight': '980'};
      case 3: return {'name': 'Bawarchi Catering', 'type': 'Catering', 'weight': '850'};
      case 4: return {'name': 'Roadhouse Café', 'type': 'Restaurant', 'weight': '620'};
      case 5: return {'name': 'Anish Prajapati', 'type': 'Individual', 'weight': '410'};
      default:
        return {
          'name': 'User $rank', 
          'type': rank % 3 == 0 ? 'Restaurant' : 'Individual', 
          'weight': '${400 - (rank * 10)}'
        };
    }
  }

  IconData _getEntityIcon(String type) {
    switch (type) {
      case 'Hotel': return Icons.hotel_rounded;
      case 'Catering': return Icons.outdoor_grill_rounded;
      case 'Restaurant': return Icons.restaurant_rounded;
      default: return Icons.person_rounded;
    }
  }

  IconData _getTrophyIcon(int rank) {
    return rank == 1 ? Icons.workspace_premium : Icons.emoji_events;
  }

  Color _getTrophyColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }
}