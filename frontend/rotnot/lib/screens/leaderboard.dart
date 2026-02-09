import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Pokhara Eco-Leaderboard"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: 30,
        itemBuilder: (context, index) {
          int rank = index + 1;
          bool isMe = rank == 24;
          bool isTopThree = rank <= 3;
          
          final entity = _getLeaderboardData(rank, isMe);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? accentGreen.withOpacity(0.15) : surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: isMe ? Border.all(color: accentGreen.withOpacity(0.5), width: 2) : null,
              boxShadow: isMe ? [
                BoxShadow(color: accentGreen.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
              ] : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: isTopThree 
                    ? Icon(_getTrophyIcon(rank), color: _getTrophyColor(rank), size: 24)
                    : Text("#$rank", style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: entity['type'] == 'Individual' ? Colors.white10 : accentGreen.withOpacity(0.2),
                  child: Icon(
                    _getEntityIcon(entity['type']), 
                    size: 20, 
                    color: entity['type'] == 'Individual' ? Colors.white30 : accentGreen
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entity['name'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                          color: isMe ? accentGreen : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entity['type'].toUpperCase(),
                          style: TextStyle(
                            fontSize: 9, 
                            color: isMe ? accentGreen : Colors.white38, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${entity['weight']} kg",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: isMe ? accentGreen : Colors.white
                      ),
                    ),
                    const Text(
                      "DONATED", 
                      style: TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- POKHARA-SPECIFIC HARDCODED DATA ---

  Map<String, dynamic> _getLeaderboardData(int rank, bool isMe) {
    if (isMe) {
      return {'name': 'Alex (You)', 'type': 'Individual', 'weight': '14.2'};
    }

    // Top 10 Pokhara Institutions (Hotels, Catering, Restaurants)
    final institutions = [
      {'name': 'The Pavilions Himalayas', 'type': 'Hotel', 'weight': '1,210'},
      {'name': 'Fishtail Lodge', 'type': 'Hotel', 'weight': '1,050'},
      {'name': 'Temple Tree Resort', 'type': 'Hotel', 'weight': '920'},
      {'name': 'Busy Bee Café Lakeside', 'type': 'Restaurant', 'weight': '840'},
      {'name': 'Pokhara Grande', 'type': 'Hotel', 'weight': '780'},
      {'name': 'Fresh Elements Restaurant', 'type': 'Restaurant', 'weight': '690'},
      {'name': 'Saravana Catering Pokhara', 'type': 'Catering', 'weight': '580'},
      {'name': 'Moondance Village', 'type': 'Restaurant', 'weight': '510'},
      {'name': 'Lakeside Catering Services', 'type': 'Catering', 'weight': '465'},
      {'name': 'Godfather\'s Pizzeria', 'type': 'Restaurant', 'weight': '420'},
    ];

    // Local Individual Eco-Warriors (Pokhara Based Names)
    final individuals = [
      'Sushant Gurung', 'Pema Lama', 'Binod Pokharel', 'Srijana Thapa', 
      'Ramesh Baral', 'Deepak Gc', 'Anju Adhikari', 'Prabhat Ranabhat',
      'Kushum Tulachan', 'Rajesh Pariyar', 'Anita Karki', 'Sagar Neupane', 
      'Rupa Bhandari', 'Nirmal Chhetri', 'Sandesh Dhakal', 'Bina Shrestha',
      'Sudip Gautam', 'Manisha Pun', 'Arjun Sigdel', 'Laxmi Bastola'
    ];

    if (rank <= 10) {
      return institutions[rank - 1];
    } else {
      int individualIndex = (rank - 11) % individuals.length;
      
      // Pokhara-specific mid-tier businesses
      if (rank == 15) return {'name': 'Byanjan Restaurant', 'type': 'Restaurant', 'weight': '280'};
      if (rank == 20) return {'name': 'Krazy Gecko Lakeside', 'type': 'Restaurant', 'weight': '195'};
      
      double baseWeight = 390.0 - (rank * 11.5);
      return {
        'name': individuals[individualIndex],
        'type': 'Individual',
        'weight': baseWeight.toStringAsFixed(1)
      };
    }
  }

  IconData _getEntityIcon(String type) {
    switch (type) {
      case 'Hotel': return Icons.corporate_fare_rounded;
      case 'Catering': return Icons.outdoor_grill_rounded;
      case 'Restaurant': return Icons.restaurant_rounded;
      default: return Icons.person_rounded;
    }
  }

  IconData _getTrophyIcon(int rank) {
    if (rank == 1) return Icons.workspace_premium_rounded;
    return Icons.emoji_events_rounded;
  }

  Color _getTrophyColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC2C2C2);
    return const Color(0xFFCD7F32);
  }
}