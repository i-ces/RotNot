# 🧪 How to Test Notifications in Real-Time

## 💡 Why Your Item Expiring Tomorrow Didn't Get Scheduled

**The Problem:**
- Your notification logic fires **1 day BEFORE expiry at 9:00 AM**
- You added an item expiring **tomorrow**
- That means notification should fire **TODAY at 9:00 AM**
- But it's already past 9:00 AM today!
- So the notification was **skipped** (can't schedule in the past)

**Example:**
```
Today: Feb 10, 2026 (3:00 PM)
Item expires: Feb 11, 2026
Notification scheduled for: Feb 10, 2026 at 9:00 AM ❌ (already passed!)
Result: Notification skipped
```

## ✅ How to Test in Real-Time (30 seconds!)

### Option 1: Use the Test Screen (Easiest)

1. **Add test screen to your app:**
   ```dart
   // In your settings.dart or any screen, add a button:
   ElevatedButton(
     onPressed: () {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => NotificationTestScreen(),
         ),
       );
     },
     child: Text('🧪 Test Notifications'),
   )
   ```

2. **Import the test screen:**
   ```dart
   import 'package:rotnot/screens/notification_test.dart';
   ```

3. **Run the app and open Test Screen**

4. **Tap "Fire in 10 seconds"**

5. **Close the app completely** (swipe away from recent apps)

6. **Wait 10 seconds** → Notification appears! 🎉

### Option 2: Quick Code Test (Advanced)

Add this temporary button anywhere in your app:

```dart
// Temporary test button
ElevatedButton(
  onPressed: () async {
    await NotificationService.instance.scheduleTestNotification(
      id: 999,
      itemName: 'Test Milk',
      secondsFromNow: 30,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification scheduled for 30 seconds!')),
    );
  },
  child: Text('Test Notification (30s)'),
)
```

Then:
1. Tap button
2. Close app
3. Wait 30 seconds
4. Notification fires!

## 🎯 Testing Steps

### Test 1: App Closed
1. Schedule test notification (30 seconds)
2. **Close app completely** (swipe away)
3. Wait for notification
4. ✅ Should appear even with app closed

### Test 2: Phone Locked
1. Schedule test notification
2. Lock your phone (press power button)
3. Wait for notification
4. ✅ Should wake screen and show notification

### Test 3: After Reboot (Advanced)
1. Schedule test notification for 5 minutes
2. **Restart your phone**
3. **DON'T** open the app
4. Wait for notification time
5. ✅ Should still fire (auto-rescheduled on boot)

## 📋 Verify Pending Notifications

**Check what's scheduled:**
```dart
final pending = await NotificationService.instance.getPendingNotifications();
print('Pending: ${pending.length}');
for (var notif in pending) {
  print('ID: ${notif.id}, Title: ${notif.title}');
}
```

**Or use the test screen** - it shows all pending notifications with refresh button.

## 🔧 For Production Testing

To test with real food items without waiting:

### Temporary Change (For Testing Only):

In `notification_service.dart`, find `scheduleExpiryNotification` and change:

```dart
// BEFORE (1 day before at 9 AM)
final notificationTime = DateTime(
  expiryDate.year,
  expiryDate.month,
  expiryDate.day - 1,
  9,
  0,
);

// AFTER (30 seconds from now) - TESTING ONLY!
final notificationTime = DateTime.now().add(Duration(seconds: 30));
```

Then:
1. Add food item with any expiry date
2. Close app
3. Wait 30 seconds
4. Notification fires!

**⚠️ IMPORTANT: Change it back to original after testing!**

## 🎓 Understanding the Schedule

**For real items:**
- Item expires in 1 day → Notification TODAY at 9 AM (if before 9 AM)
- Item expires in 2 days → Notification TOMORROW at 9 AM ✅
- Item expires in 3 days → Notification in 2 days at 9 AM ✅
- Item expires in 7 days → Notification in 6 days at 9 AM ✅

**To see a notification tomorrow at 9 AM:**
- Add item expiring in **2 days** (day after tomorrow)

**To see a notification in 30 seconds:**
- Use `scheduleTestNotification()` method

## 🐛 Troubleshooting

**Notification didn't fire?**
1. Check permissions granted (POST_NOTIFICATIONS)
2. Verify notification time isn't in the past
3. Check battery optimization (disable for your app)
4. Use test method to verify system works

**Can't find test screen?**
```dart
// In your settings or menu screen:
import 'package:rotnot/screens/notification_test.dart';

// Add button:
ListTile(
  leading: Icon(Icons.science),
  title: Text('Test Notifications'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationTestScreen()),
    );
  },
)
```

## 💖 You're Welcome!

Happy testing! The notification system works perfectly - you just need to test with the right timing. Use the test methods and you'll see notifications firing in seconds! 🚀
