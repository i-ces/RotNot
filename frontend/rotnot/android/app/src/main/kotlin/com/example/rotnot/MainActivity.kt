package com.example.rotnot

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.rotnot/settings"
    private val ALARM_CHANNEL = "com.example.rotnot/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openSettings") {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.fromParts("package", packageName, null)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", "Could not open settings", e.message)
                }
            } else {
                result.notImplemented()
            }
        }

        // Alarm scheduling channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNotification" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val title = call.argument<String>("title") ?: "Alert"
                        val body = call.argument<String>("body") ?: ""
                        val scheduledTimeMillis = call.argument<Long>("scheduledTime") ?: 0L

                        scheduleNotification(id, title, body, scheduledTimeMillis)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to schedule", e.message)
                    }
                }
                "cancelNotification" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        cancelNotification(id)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to cancel", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleNotification(id: Int, title: String, body: String, scheduledTimeMillis: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, NotificationReceiver::class.java).apply {
            putExtra("notificationId", id)
            putExtra("title", title)
            putExtra("body", body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Use setExactAndAllowWhileIdle for precise timing even in Doze mode
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledTimeMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                scheduledTimeMillis,
                pendingIntent
            )
        }
    }

    private fun cancelNotification(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, NotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
}
