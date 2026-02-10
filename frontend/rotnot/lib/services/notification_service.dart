import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _alarmChannel = MethodChannel('com.example.rotnot/alarm');

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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
    }

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {}

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted == null || !granted) return false;

      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  Future<void> scheduleExpiryNotification({
    required int id,
    required String itemName,
    required DateTime expiryDate,
    String? category,
  }) async {
    if (!_isInitialized) await initialize();

    final notificationTime = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day - 1,
      9,
      0,
    );

    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    try {
      await _alarmChannel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': 'Food Expiring Soon!',
        'body': '$itemName expires tomorrow. Use it before it goes bad!',
        'scheduledTime': notificationTime.millisecondsSinceEpoch,
      });

      await _saveScheduledNotification(id, itemName, expiryDate, category);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    try {
      await _alarmChannel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {}
    await _removeScheduledNotification(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _clearAllScheduledNotifications();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> scheduleTestNotification({
    required int id,
    required String itemName,
    int secondsFromNow = 30,
  }) async {
    if (!_isInitialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final notificationTime = DateTime.now().add(
      Duration(seconds: secondsFromNow),
    );

    try {
      await _alarmChannel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': 'TEST: Food Expiring Soon!',
        'body': '$itemName expires tomorrow. This is a test notification.',
        'scheduledTime': notificationTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      rethrow;
    }
  }

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
  }

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

      if (expiryDate.isAfter(DateTime.now())) {
        await scheduleExpiryNotification(
          id: id,
          itemName: itemName,
          expiryDate: expiryDate,
          category: category,
        );
      } else {
        await _removeScheduledNotification(id);
      }
    }
  }

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

    notifications.removeWhere((n) => n['id'] == id);

    notifications.add({
      'id': id,
      'itemName': itemName,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'scheduledAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString('scheduled_notifications', jsonEncode(notifications));
  }

  Future<void> _removeScheduledNotification(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson =
        prefs.getString('scheduled_notifications') ?? '[]';
    final List<dynamic> notifications = jsonDecode(notificationsJson);

    notifications.removeWhere((n) => n['id'] == id);

    await prefs.setString('scheduled_notifications', jsonEncode(notifications));
  }

  Future<void> _clearAllScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_notifications');
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }
}
