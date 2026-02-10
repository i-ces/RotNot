import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Singleton service for managing local expiry notifications
/// Uses flutter_local_notifications with timezone support for reliable scheduling
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Native Android AlarmManager channel for Samsung compatibility
  static const _alarmChannel = MethodChannel('com.example.rotnot/alarm');

  bool _isInitialized = false;

  /// Initialize the notification service
  /// Call this once in main() before runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    // Set local timezone (adjust as needed, or detect from device)
    tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 🔔 CRITICAL: Create Android notification channel explicitly
    // Required for Android 8.0 (API 26)+ to show notifications
    const androidChannel = AndroidNotificationChannel(
      'expiry_reminders',
      'Expiry Reminders',
      description: 'Notifications for items about to expire',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      print('✅ Notification channel created: expiry_reminders');
    }

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to shelf page, etc.
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (Android 13+, iOS)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    // Request Android 13+ permissions
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == null || !granted) return false;

      // Request exact alarm permission for precise scheduling
      await androidPlugin.requestExactAlarmsPermission();
    }

    // Request iOS permissions
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  /// Schedule a notification for an expiring item
  /// Notifies 1 day before expiry at 9:00 AM
  Future<void> scheduleExpiryNotification({
    required int id,
    required String itemName,
    required DateTime expiryDate,
    String? category,
  }) async {
    if (!_isInitialized) await initialize();

    // Calculate notification time: 1 day before expiry at 9:00 AM
    final notificationTime = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 1,
      9, // 9:00 AM
      0,
    );

    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      print('Notification time is in the past, skipping: $itemName');
      return;
    }

    // 🚀 USE NATIVE ANDROID ALARMMANAGER (Samsung compatible)
    try {
      await _alarmChannel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': '⚠️ Food Expiring Soon!',
        'body': '$itemName expires tomorrow. Use it before it goes bad!',
        'scheduledTime': notificationTime.millisecondsSinceEpoch,
      });

      // Save scheduled notification info for recovery after reboot
      await _saveScheduledNotification(id, itemName, expiryDate, category);

      print(
        '✅ Scheduled notification for $itemName at $notificationTime via NATIVE AlarmManager',
      );
    } catch (e) {
      print('❌ ERROR scheduling native notification: $e');
      rethrow;
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    // Cancel both flutter plugin and native notifications
    await _notifications.cancel(id);
    try {
      await _alarmChannel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {
      print('⚠️ Error canceling native notification: $e');
    }
    await _removeScheduledNotification(id);
    print('❌ Cancelled notification $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _clearAllScheduledNotifications();
    print('❌ Cancelled all notifications');
  }

  /// Get list of pending scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 🧪 TEST MODE: Schedule a notification for 30 seconds from now
  /// Use this to test notifications in real-time without waiting
  Future<void> scheduleTestNotification({
    required int id,
    required String itemName,
    int secondsFromNow = 30,
  }) async {
    if (!_isInitialized) await initialize();

    // Check if we can schedule exact notifications (Android 12+)
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      if (canScheduleExact != true) {
        print('⚠️ WARNING: Exact alarm permission NOT granted!');
        print('⚠️ Notification will be scheduled but may not fire.');
        print('⚠️ Please grant "Alarms & reminders" permission in Settings.');
      }
    }

    // Schedule notification for X seconds from now
    final notificationTime = DateTime.now().add(
      Duration(seconds: secondsFromNow),
    );

    // 🚀 USE NATIVE ANDROID ALARMMANAGER (Samsung compatible)
    try {
      await _alarmChannel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': '🧪 TEST: Food Expiring Soon!',
        'body': '$itemName expires tomorrow. This is a test notification.',
        'scheduledTime': notificationTime.millisecondsSinceEpoch,
      });

      print(
        '🧪 TEST notification scheduled via NATIVE AlarmManager for $itemName in $secondsFromNow seconds',
      );
      print('⏰ Current time: ${DateTime.now()}');
      print('⏰ Will fire at: $notificationTime');
      print(
        '✅ Notification scheduled using native Android AlarmManager (Samsung compatible)!',
      );
    } catch (e) {
      print('❌ ERROR scheduling native notification: $e');
      rethrow;
    }
  }

  /// 🔔 Show an immediate notification (no scheduling)
  /// Use this to test if notification channel works
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'expiry_reminders',
      'Expiry Reminders',
      channelDescription: 'Notifications for items about to expire',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Food Expiry Alert',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: jsonEncode({'test': true, 'immediate': true}),
    );

    print('🔔 Immediate notification shown: $title');
  }

  /// Reschedule all notifications (call after device reboot)
  /// This should be called from main() if notifications are enabled
  Future<void> rescheduleAllNotifications() async {
    if (!_isInitialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString('scheduled_notifications');

    if (notificationsJson == null) return;

    final List<dynamic> notifications = jsonDecode(notificationsJson);

    for (var notification in notifications) {
      final id = notification['id'] as int;
      final itemName = notification['itemName'] as String;
      final expiryDate = DateTime.parse(notification['expiryDate'] as String);
      final category = notification['category'] as String?;

      // Reschedule if still valid
      if (expiryDate.isAfter(DateTime.now())) {
        await scheduleExpiryNotification(
          id: id,
          itemName: itemName,
          expiryDate: expiryDate,
          category: category,
        );
      } else {
        // Remove expired notifications
        await _removeScheduledNotification(id);
      }
    }

    print('✅ Rescheduled ${notifications.length} notifications');
  }

  /// Save scheduled notification info for recovery
  Future<void> _saveScheduledNotification(
    int id,
    String itemName,
    DateTime expiryDate,
    String? category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson =
        prefs.getString('scheduled_notifications') ?? '[]';
    final List<dynamic> notifications = jsonDecode(notificationsJson);

    // Remove existing entry for this ID
    notifications.removeWhere((n) => n['id'] == id);

    // Add new entry
    notifications.add({
      'id': id,
      'itemName': itemName,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'scheduledAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString('scheduled_notifications', jsonEncode(notifications));
  }

  /// Remove scheduled notification info
  Future<void> _removeScheduledNotification(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson =
        prefs.getString('scheduled_notifications') ?? '[]';
    final List<dynamic> notifications = jsonDecode(notificationsJson);

    notifications.removeWhere((n) => n['id'] == id);

    await prefs.setString('scheduled_notifications', jsonEncode(notifications));
  }

  /// Clear all scheduled notification info
  Future<void> _clearAllScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_notifications');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }
}
