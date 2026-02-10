import 'package:flutter/material.dart';
import 'package:rotnot/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpiringItemsScreen extends StatefulWidget {
  const ExpiringItemsScreen({super.key});

  @override
  State<ExpiringItemsScreen> createState() => _ExpiringItemsScreenState();
}

class _ExpiringItemsScreenState extends State<ExpiringItemsScreen> {
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentRed = Color(0xFFE74C3C);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Set<String> _clearedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadClearedNotifications();
  }

  Future<void> _loadClearedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final cleared = prefs.getStringList('cleared_notifications') ?? [];
    setState(() {
      _clearedNotifications = cleared.toSet();
    });
    _loadNotifications();
  }

  Future<void> _saveClearedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'cleared_notifications',
      _clearedNotifications.toList(),
    );
  }

  String _generateNotificationId(Map<String, dynamic> notification) {
    final type = notification['type'];
    if (type == 'expiring') {
      return 'expiring_${notification['title']}_${notification['time']}';
    } else {
      return 'donation_${notification['title']}_${notification['time']}';
    }
  }

  void _clearNotification(int index) {
    final notificationId = _generateNotificationId(_notifications[index]);
    setState(() {
      _clearedNotifications.add(notificationId);
      _notifications.removeAt(index);
    });
    _saveClearedNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getFoodItems();
      final donations = await ApiService.getDonations();
      final now = DateTime.now();

      final notifications = <Map<String, dynamic>>[];

      // Add expiring food notifications
      for (var item in items) {
        if (item['expiryDate'] != null) {
          final expiryDate = DateTime.parse(item['expiryDate']);
          final daysLeft = expiryDate.difference(now).inDays;

          if (daysLeft <= 3) {
            final notification = {
              'type': 'expiring',
              'title': item['name'] ?? 'Unknown Item',
              'message': daysLeft < 0
                  ? 'Expired ${daysLeft.abs()} day${daysLeft.abs() == 1 ? '' : 's'} ago'
                  : daysLeft == 0
                  ? 'Expires today!'
                  : daysLeft == 1
                  ? 'Expires tomorrow'
                  : 'Expires in $daysLeft days',
              'category': item['category'] ?? 'Other',
              'daysLeft': daysLeft,
              'icon': Icons.warning_amber_rounded,
              'color': daysLeft < 0
                  ? accentRed
                  : daysLeft == 0
                  ? accentRed
                  : daysLeft == 1
                  ? accentOrange
                  : accentOrange.withOpacity(0.7),
              'time': expiryDate,
            };

            // Only add if not cleared
            final notificationId = _generateNotificationId(notification);
            if (!_clearedNotifications.contains(notificationId)) {
              notifications.add(notification);
            }
          }
        }
      }

      // Add donation notifications (recent ones)
      for (var donation in donations) {
        final createdAt = donation['createdAt'] != null
            ? DateTime.parse(donation['createdAt'])
            : null;

        if (createdAt != null) {
          final daysSince = now.difference(createdAt).inDays;

          // Only show notifications from last 7 days
          if (daysSince <= 7) {
            final status =
                donation['status']?.toString().toLowerCase() ?? 'pending';
            final foodItemsCount =
                (donation['foodItems'] as List?)?.length ?? 0;

            String message = '';
            Color color = accentGreen;
            IconData icon = Icons.info_outline;

            if (status == 'accepted' || status == 'completed') {
              message =
                  'Your donation of $foodItemsCount item${foodItemsCount == 1 ? '' : 's'} was accepted';
              color = accentGreen;
              icon = Icons.check_circle_outline;
            } else if (status == 'picked_up') {
              message =
                  'Your donation of $foodItemsCount item${foodItemsCount == 1 ? '' : 's'} was picked up';
              color = accentGreen;
              icon = Icons.local_shipping_outlined;
            } else if (status == 'pending') {
              message =
                  'Donation of $foodItemsCount item${foodItemsCount == 1 ? '' : 's'} is pending';
              color = accentOrange;
              icon = Icons.pending_outlined;
            } else if (status == 'rejected') {
              message = 'Your donation request was declined';
              color = accentRed;
              icon = Icons.cancel_outlined;
            }

            final notification = {
              'type': 'donation',
              'title':
                  '${status[0].toUpperCase()}${status.substring(1)} Donation',
              'message': message,
              'category': 'Donation',
              'icon': icon,
              'color': color,
              'time': createdAt,
            };

            // Only add if not cleared
            final notificationId = _generateNotificationId(notification);
            if (!_clearedNotifications.contains(notificationId)) {
              notifications.add(notification);
            }
          }
        }
      }

      // Sort by time (most recent first)
      notifications.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeB.compareTo(timeA);
      });

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(
                Icons.check_circle_outline,
                color: accentGreen,
                size: 20,
              ),
              label: const Text(
                'Mark as read',
                style: TextStyle(
                  color: accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : RefreshIndicator(
              color: accentGreen,
              backgroundColor: surfaceColor,
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          _notifications[index],
                          index,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: accentGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Good! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final type = notification['type'] as String;
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final category = notification['category']?.toString() ?? '';
    final color = notification['color'] as Color;
    final icon = notification['icon'] as IconData;
    final time = notification['time'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(time);

    String timeAgo;
    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type == 'expiring' ? _getCategoryIcon(category) : icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.white.withOpacity(0.4),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _clearNotification(index),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple_rounded;
      case 'vegetables':
        return Icons.eco_rounded;
      case 'dairy':
        return Icons.water_drop_rounded;
      case 'meat':
        return Icons.food_bank_rounded;
      case 'beverages':
        return Icons.local_drink_rounded;
      case 'snacks':
        return Icons.cookie_rounded;
      case 'grains':
        return Icons.grain_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
