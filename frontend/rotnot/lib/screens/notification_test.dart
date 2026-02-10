import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rotnot/services/notification_service.dart';

/// 🧪 TEST SCREEN: Use this to test notifications in real-time
/// Add this to your navigation to test notification functionality
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen>
    with WidgetsBindingObserver {
  List<PendingNotificationRequest> _pending = [];
  bool _loading = false;
  bool? _permissionsGranted;
  bool? _exactAlarmGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPending();
    _checkPermissions();
    _checkExactAlarmPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns from background, recheck permissions
    if (state == AppLifecycleState.resumed) {
      _checkExactAlarmPermission();
      _loadPending();
    }
  }

  Future<void> _checkPermissions() async {
    // Try to get pending notifications - if this works, permissions are likely granted
    try {
      await NotificationService.instance.getPendingNotifications();
      setState(() => _permissionsGranted = true);
    } catch (e) {
      setState(() => _permissionsGranted = false);
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.canScheduleExactNotifications();
      setState(() => _exactAlarmGranted = granted);
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
      // Wait a bit for user to come back from settings
      await Future.delayed(Duration(milliseconds: 500));
      await _checkExactAlarmPermission();

      if (mounted && _exactAlarmGranted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Exact alarm permission granted! You can now schedule notifications.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _loading = true);
    final granted = await NotificationService.instance.requestPermissions();
    setState(() {
      _permissionsGranted = granted;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? '✅ Permissions granted!'
                : '❌ Permissions denied. Enable in Settings.',
          ),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPending() async {
    final pending = await NotificationService.instance
        .getPendingNotifications();
    setState(() {
      _pending = pending;
    });
  }

  Future<void> _showImmediateNotification() async {
    setState(() => _loading = true);

    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

    // Show notification IMMEDIATELY (no scheduling)
    await NotificationService.instance.showImmediateNotification(
      id: id,
      title: '🔔 Test Notification',
      body: 'If you see this, notification channel works!',
    );

    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Immediate notification sent!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _scheduleTest({int seconds = 30}) async {
    // Check exact alarm permission first
    if (_exactAlarmGranted != true) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF1A1A1A),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Permission Required',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(
              'To schedule notifications that fire when the app is closed, you need to grant "Exact Alarm" permission.\n\n'
              'Tap the orange "Grant Exact Alarm Permission" button below, then enable "Alarms & reminders" in Settings.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Show battery optimization warning
    if (mounted && seconds <= 10) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          title: Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.yellow),
              SizedBox(width: 8),
              Flexible(
                child: Text('Important', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'For notifications to fire when app is closed:\n\n'
              '1. Schedule the notification (tap OK)\n'
              '2. SWIPE AWAY the app from recent apps\n'
              '3. WAIT the full $seconds seconds\n'
              '4. Notification should appear!\n\n'
              'If it still doesn\'t work, disable Battery Optimization:\n'
              'Settings → Apps → RotNot → Battery → Unrestricted',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() => _loading = true);

    // Generate a valid notification ID (32-bit integer)
    // Use last 9 digits of timestamp to keep it under 2^31
    final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

    try {
      await NotificationService.instance.scheduleTestNotification(
        id: id,
        itemName: 'Test Food Item',
        secondsFromNow: seconds,
      );

      await _loadPending();

      if (mounted) {
        final fireTime = DateTime.now().add(Duration(seconds: seconds));
        final timeStr =
            '${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}:${fireTime.second.toString().padLeft(2, '0')}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Scheduled! Will fire at $timeStr\n'
              'SWIPE AWAY app from recent apps, then wait.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelAll() async {
    await NotificationService.instance.cancelAllNotifications();
    await _loadPending();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ All notifications cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('🧪 Notification Test Mode'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'How to Test',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '1. Tap a button below to schedule a test notification\n'
                          '2. Close the app completely (swipe away from recent apps)\n'
                          '3. Wait for the notification to appear\n'
                          '4. Even with app closed, notification will fire!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Permission Status
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _permissionsGranted == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _permissionsGranted == true
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _permissionsGranted == true
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              color: _permissionsGranted == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _permissionsGranted == null
                                    ? 'Checking permissions...'
                                    : _permissionsGranted == true
                                    ? 'Notification permissions granted ✓'
                                    : 'Notification permissions required!',
                                style: TextStyle(
                                  color: _permissionsGranted == true
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_permissionsGranted == false) ...[
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _requestPermissions,
                            icon: Icon(Icons.notifications_active),
                            label: Text('Grant Permissions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Exact Alarm Permission Status (Critical for Android 12+)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _exactAlarmGranted == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _exactAlarmGranted == true
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _exactAlarmGranted == true
                                  ? Icons.check_circle_outline
                                  : Icons.alarm_off,
                              color: _exactAlarmGranted == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _exactAlarmGranted == null
                                    ? 'Checking exact alarm permission...'
                                    : _exactAlarmGranted == true
                                    ? 'Exact alarm permission granted ✓'
                                    : 'Exact alarm permission needed!',
                                style: TextStyle(
                                  color: _exactAlarmGranted == true
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_exactAlarmGranted == false) ...[
                          SizedBox(height: 8),
                          Text(
                            'Without this, scheduled notifications won\'t fire. Android 12+ requires this for exact timing.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _requestExactAlarmPermission,
                            icon: Icon(Icons.alarm),
                            label: Text('Grant Exact Alarm Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Test immediate notification first
                  Text(
                    'Quick Test (No Scheduling)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Test if notification channel works - shows immediately!',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _showImmediateNotification,
                    icon: Icon(Icons.notifications_active, size: 28),
                    label: Text(
                      'Show Notification NOW',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.all(18),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Pending notifications count banner
                  if (_pending.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_pending.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notification${_pending.length == 1 ? '' : 's'} scheduled and waiting!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_pending.isNotEmpty) SizedBox(height: 20),

                  // Battery optimization warning
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.2),
                          Colors.orange.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.battery_alert,
                              color: Colors.red,
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '⚠️ IMPORTANT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Notifications are scheduled but Android Battery Optimization may prevent them from firing.\\n\\n'
                          'To fix: Disable ALL battery restrictions.\\n\\n'
                          'SAMSUNG USERS: Also remove from "Sleeping apps"!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Open app settings
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Color(0xFF1A1A1A),
                                title: Text(
                                  'How to Fix Battery Restrictions',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '✅ STEP 1: Battery Setting',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Settings → Apps → RotNot → Battery → Unrestricted',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '🔴 STEP 2: SAMSUNG ONLY!',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '1. Settings → Battery → Background usage limits\\n'
                                        '2. Remove RotNot from "Sleeping apps" list\\n'
                                        '3. Remove from "Deep sleeping apps" list\\n'
                                        '4. Turn OFF "Put unused apps to sleep"',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '🧪 STEP 3: Test It!',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '1. Close this dialog\\n'
                                        '2. Tap "ULTRA FAST: Fire in 5 seconds"\\n'
                                        '3. SWIPE AWAY app from recent apps\\n'
                                        '4. Wait 5 seconds → notification!',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Got it!',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.settings),
                          label: Text('How to Fix'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              // Try to open app-specific settings
                              const platform = MethodChannel(
                                'com.example.rotnot/settings',
                              );
                              await platform.invokeMethod('openSettings');
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please open Settings manually',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.open_in_new, color: Colors.white),
                          label: Text(
                            'Open App Settings',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 2),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Quick test buttons
                  Text(
                    'Schedule Test Notification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Schedule, then SWIPE AWAY app from recent apps. Wait for notification.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  SizedBox(height: 12),

                  // ULTRA FAST TEST - 5 seconds
                  ElevatedButton.icon(
                    onPressed: () => _scheduleTest(seconds: 5),
                    icon: Icon(Icons.bolt, size: 28),
                    label: Text(
                      'ULTRA FAST: Fire in 5 seconds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.all(18),
                    ),
                  ),
                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: () => _scheduleTest(seconds: 10),
                    icon: Icon(Icons.timer_10_outlined),
                    label: Text('Fire in 10 seconds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: () => _scheduleTest(seconds: 30),
                    icon: Icon(Icons.timer),
                    label: Text('Fire in 30 seconds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                  SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: () => _scheduleTest(seconds: 60),
                    icon: Icon(Icons.access_time),
                    label: Text('Fire in 1 minute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.all(16),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Pending notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Notifications (${_pending.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadPending,
                        icon: Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  if (_pending.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No pending notifications',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    ...(_pending.map(
                      (PendingNotificationRequest notif) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title ?? 'No title',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (notif.body != null)
                                    Text(
                                      notif.body!,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'ID: ${notif.id}',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                  SizedBox(height: 24),

                  // Cancel all button
                  OutlinedButton.icon(
                    onPressed: _pending.isEmpty ? null : _cancelAll,
                    icon: Icon(Icons.delete_outline),
                    label: Text('Cancel All Notifications'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      padding: EdgeInsets.all(16),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Current behavior explanation
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Production Behavior',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'In the real app, notifications fire 1 day BEFORE expiry at 9:00 AM.\n\n'
                          'Example: Item expires Feb 15 → Notification on Feb 14 at 9:00 AM\n\n'
                          'If you add an item expiring tomorrow, the notification time is TODAY at 9 AM (already passed), so it won\'t fire.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
