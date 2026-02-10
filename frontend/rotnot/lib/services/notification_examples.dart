/// Example: How to use NotificationService in your app
///
/// This demonstrates how to schedule and cancel expiry notifications
/// for food items in your shelf/inventory.

import 'package:RotNot/services/notification_service.dart';

// Example food item model (adjust based on your actual model)
class FoodItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String? category;

  FoodItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    this.category,
  });
}

class NotificationExamples {
  /// Schedule notification when adding a new food item
  Future<void> onItemAdded(FoodItem item) async {
    // Generate numeric ID from string ID (hash code)
    final notificationId = item.id.hashCode;

    await NotificationService.instance.scheduleExpiryNotification(
      id: notificationId,
      itemName: item.name,
      expiryDate: item.expiryDate,
      category: item.category,
    );

    print('✅ Notification scheduled for ${item.name}');
  }

  /// Cancel notification when item is deleted or consumed
  Future<void> onItemDeleted(FoodItem item) async {
    final notificationId = item.id.hashCode;

    await NotificationService.instance.cancelNotification(notificationId);

    print('❌ Notification cancelled for ${item.name}');
  }

  /// Cancel notification when item expiry date is updated
  /// Then reschedule with new date
  Future<void> onItemUpdated(FoodItem oldItem, FoodItem newItem) async {
    final notificationId = oldItem.id.hashCode;

    // Cancel old notification
    await NotificationService.instance.cancelNotification(notificationId);

    // Schedule new notification with updated date
    await NotificationService.instance.scheduleExpiryNotification(
      id: notificationId,
      itemName: newItem.name,
      expiryDate: newItem.expiryDate,
      category: newItem.category,
    );

    print('🔄 Notification updated for ${newItem.name}');
  }

  /// Check pending notifications (useful for debugging)
  Future<void> listPendingNotifications() async {
    final pending = await NotificationService.instance
        .getPendingNotifications();

    print('📋 Pending notifications: ${pending.length}');
    for (var notification in pending) {
      print('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  /// Cancel all notifications (e.g., when user logs out)
  Future<void> clearAllNotifications() async {
    await NotificationService.instance.cancelAllNotifications();
    print('🗑️ All notifications cleared');
  }
}

// Usage in your shelf/add item screen:
/*
  // After successfully adding item to database
  final item = FoodItem(
    id: 'unique-id-123',
    name: 'Milk',
    expiryDate: DateTime.now().add(Duration(days: 3)),
    category: 'Dairy',
  );
  
  await NotificationService.instance.scheduleExpiryNotification(
    id: item.id.hashCode,
    itemName: item.name,
    expiryDate: item.expiryDate,
    category: item.category,
  );
  
  // When deleting item
  await NotificationService.instance.cancelNotification(item.id.hashCode);
*/
