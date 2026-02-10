import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final user = AuthService.currentUser;
      _currentUserId = user?.uid;

      // Fetch leaderboard
      final leaderboard = await ApiService.getLeaderboard();

      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Our Contributors"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : _leaderboard.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: accentGreen,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = _leaderboard[index];
                  final rank = entry['rank'] as int;
                  final donorId = entry['donorId']?.toString();
                  final isMe = donorId == _currentUserId;
                  final isTopThree = rank <= 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isMe
                          ? accentGreen.withOpacity(0.15)
                          : surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isMe
                          ? Border.all(
                              color: accentGreen.withOpacity(0.5),
                              width: 2,
                            )
                          : null,
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: accentGreen.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 35,
                          child: isTopThree
                              ? Icon(
                                  _getTrophyIcon(rank),
                                  color: _getTrophyColor(rank),
                                  size: 24,
                                )
                              : Text(
                                  "#$rank",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: _getRoleColor(
                            entry['role']?.toString() ?? 'user',
                          ),
                          child: Icon(
                            _getRoleIcon(entry['role']?.toString() ?? 'user'),
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe
                                    ? '${entry['name']} (You)'
                                    : entry['name']?.toString() ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isMe ? accentGreen : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getRoleLabel(
                                    entry['role']?.toString() ?? 'user',
                                  ),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isMe ? accentGreen : Colors.white38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
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
                              "${entry['totalItems'] ?? 0}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isMe ? accentGreen : Colors.white,
                              ),
                            ),
                            const Text(
                              "ITEMS",
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No Leaderboard Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to donate and appear\non the leaderboard!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'organization':
        return 'ORGANIZATION';
      case 'foodbank':
        return 'FOOD BANK';
      default:
        return 'INDIVIDUAL';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'organization':
        return Icons.business_rounded;
      case 'foodbank':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'organization':
        return const Color(0xFF3498DB).withOpacity(0.3);
      case 'foodbank':
        return accentGreen.withOpacity(0.3);
      default:
        return Colors.white10;
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
