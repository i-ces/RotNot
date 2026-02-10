# Expiry Reminder Notification System

## 📖 Overview

This is a **100% offline, local notification system** for food expiry reminders. It uses `flutter_local_notifications` with `timezone` support to schedule precise notifications that persist even after app closure or device reboot.

## 🎯 Key Features

- ✅ **Local-only**: No Firebase, no backend required
- ✅ **Timezone-aware**: Uses `TZDateTime` for accurate scheduling
- ✅ **Persistent**: Survives app kills and device reboots
- ✅ **Exact scheduling**: Uses `AndroidScheduleMode.exactAllowWhileIdle` 
- ✅ **Wake from sleep**: Fires even when device is in deep sleep
- ✅ **Auto-reschedule**: Restores notifications after reboot

## 🏗️ Architecture

### NotificationService (Singleton)

Located at `lib/services/notification_service.dart`

**Core Methods:**
```dart
// Initialize service (call once in main())
await NotificationService.instance.initialize();

// Request permissions
await NotificationService.instance.requestPermissions();

// Schedule notification for an item
await NotificationService.instance.scheduleExpiryNotification(
  id: item.id.hashCode,
  itemName: 'Milk',
  expiryDate: DateTime(2026, 2, 15),
  category: 'Dairy',
);

// Cancel when item is deleted/consumed
await NotificationService.instance.cancelNotification(id);

// Reschedule after device reboot
await NotificationService.instance.rescheduleAllNotifications();
```

## 📅 Scheduling Logic

**Default behavior:** Notifies **1 day before expiry at 9:00 AM**

```dart
// Example: Item expires on Feb 15, 2026
// Notification will fire on Feb 14, 2026 at 9:00 AM

final notificationTime = DateTime(
  expiryDate.year,
  expiryDate.month,
  expiryDate.day - 1,  // 1 day before
  9,  // 9:00 AM
  0,
);
```

### Timezone Handling

```dart
// Initialize timezone database
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));

// Convert to TZDateTime for accurate scheduling
final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

// Schedule with exact mode
await _notifications.zonedSchedule(
  id,
  title,
  body,
  scheduledDate,
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  // ... other params
);
```

## 🔐 Android Permissions

Located at `android/app/src/main/AndroidManifest.xml`

### Required Permissions:

```xml
<!-- Notification permissions for Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Exact alarm scheduling for precise notification delivery -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Boot receiver to reschedule notifications after device restart -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Wake lock to ensure notifications fire even when device is sleeping -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Permission Explanations:

**POST_NOTIFICATIONS** (Android 13+)
- Required to display notifications on Android 13 and above
- Runtime permission - user must explicitly grant

**SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM**
- Allows scheduling notifications at exact times (not approximate)
- Critical for "fire at 9:00 AM" precision
- Without this, Android may delay notifications by 10-15 minutes

**RECEIVE_BOOT_COMPLETED**
- Listens for device reboot events  
- **Why it's critical:** Android clears ALL scheduled alarms/notifications after reboot
- When device boots, `rescheduleAllNotifications()` is called
- Reads saved notification data from `SharedPreferences`
- Re-schedules all valid (non-expired) notifications
- **Without this:** Users won't get notifications after restarting their phone

**WAKE_LOCK**
- Allows the notification to wake the device from deep sleep
- Ensures timely delivery even if phone is in Doze mode
- Uses `exactAllowWhileIdle` mode for reliability

## 💾 Persistence Strategy

### SharedPreferences Storage

When a notification is scheduled, metadata is saved:

```json
{
  "id": 12345,
  "itemName": "Milk",
  "expiryDate": "2026-02-15T00:00:00.000",
  "category": "Dairy",
  "scheduledAt": "2026-02-10T14:30:00.000"
}
```

### Reschedule Flow (After Reboot)

1. **Device boots** → Android clears all scheduled notifications
2. **App launches** → `main()` calls `rescheduleAllNotifications()`
3. **Service reads** saved notifications from `SharedPreferences`
4. **Service filters** out expired items
5. **Service re-schedules** each valid notification using `zonedSchedule`
6. **Result:** User's reminders are restored automatically

## 🔧 Android Schedule Modes

```dart
androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
```

**Why this mode?**

| Mode | Use Case | Doze Mode | Battery Drain |
|------|----------|-----------|---------------|
| `exact` | Precise timing, device awake | ❌ Won't fire | Low |
| `exactAllowWhileIdle` | **Expiry reminders** | ✅ Fires even in deep sleep | Medium |
| `inexactAllowWhileIdle` | Non-critical reminders | ✅ Fires (delayed) | Low |

For food expiry, we **must** use `exactAllowWhileIdle` because:
- Users need timely alerts (not 2 hours late)
- Food safety is critical
- Acceptable battery trade-off

## 📱 Usage Examples

### When Adding Food Item

```dart
// After saving item to database
final foodItem = FoodItem(
  id: '123',
  name: 'Strawberries',
  expiryDate: DateTime.now().add(Duration(days: 3)),
  category: 'Fruits',
);

// Schedule notification
await NotificationService.instance.scheduleExpiryNotification(
  id: foodItem.id.hashCode,
  itemName: foodItem.name,
  expiryDate: foodItem.expiryDate,
  category: foodItem.category,
);
```

### When Deleting Food Item

```dart
// When user consumes or deletes item
await NotificationService.instance.cancelNotification(
  foodItem.id.hashCode,
);
```

### When Updating Expiry Date

```dart
// Cancel old notification
await NotificationService.instance.cancelNotification(oldId);

// Schedule new notification with updated date
await NotificationService.instance.scheduleExpiryNotification(
  id: newId,
  itemName: updatedItem.name,
  expiryDate: updatedItem.expiryDate,
);
```

## 🧪 Testing

### Test Immediate Notification (Debug)

Modify `scheduleExpiryNotification` temporarily:

```dart
// Change notification time to 10 seconds from now
final notificationTime = DateTime.now().add(Duration(seconds: 10));
```

### Test After Reboot

1. Schedule notifications for 2-3 items
2. Check pending notifications: 
   ```dart
   final pending = await NotificationService.instance.getPendingNotifications();
   print('Pending: ${pending.length}');
   ```
3. Restart device
4. Open app → notifications should auto-reschedule
5. Verify count matches original

### Check SharedPreferences

```dart
// Debug: View saved notifications
final prefs = await SharedPreferences.getInstance();
final saved = prefs.getString('scheduled_notifications');
print('Saved notifications: $saved');
```

## 🐛 Troubleshooting

**Notification not firing?**
- Check if past notification time (can't schedule in the past)
- Verify exact alarm permission granted
- Check battery optimization settings (disable for your app)

**Lost after reboot?**
- Verify `RECEIVE_BOOT_COMPLETED` permission in manifest
- Check if `rescheduleAllNotifications()` is called in `main()`
- Inspect SharedPreferences data

**Wrong time?**
- Confirm timezone: `tz.setLocalLocation(tz.getLocation('Your/Timezone'))`
- Verify device time/timezone settings

## 📚 Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.4
  shared_preferences: ^2.2.2
```

## 🎓 Educational Notes

### Why Not WorkManager?

WorkManager is for **periodic background tasks**, not scheduled notifications:
- Runs every X hours (minimum 15 minutes)
- Imprecise timing (can delay task by hours)
- Requires persistent worker logic
- Overkill for simple "fire once" notifications

### Why Not Firebase Cloud Messaging?

FCM requires:
- Backend server to send notifications
- Internet connection
- Google Play Services
- More complex setup

**Our solution:** 100% offline, works in airplane mode!

## 🚀 Quick Start

1. **Install dependencies:** `flutter pub get`
2. **Initialize in main.dart** (already done)
3. **Schedule notifications when adding items:**
   ```dart
   await NotificationService.instance.scheduleExpiryNotification(
     id: item.id.hashCode,
     itemName: item.name,
     expiryDate: item.expiryDate,
   );
   ```
4. **Cancel when deleting:**
   ```dart
   await NotificationService.instance.cancelNotification(id);
   ```

Done! Your notifications will persist across app kills and reboots. 🎉
