package com.umer.quranzone

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    private val DEVICE_CHANNEL = "com.umer.quranzone/device"
    private val ATHAN_ALARM_CHANNEL = "com.umer.quranzone/athan_alarm"

    private var deviceChannel: MethodChannel? = null
    private var athanAlarmChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Device info channel (existing) ──────────────────────────────────
        deviceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
        deviceChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getDeviceInfo") {
                val manufacturer = Build.MANUFACTURER ?: "Unknown"
                val sdkInt = Build.VERSION.SDK_INT
                result.success(mapOf("manufacturer" to manufacturer, "sdkInt" to sdkInt))
            } else {
                result.notImplemented()
            }
        }

        // ── Native Athan alarm scheduling channel ───────────────────────────
        athanAlarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ATHAN_ALARM_CHANNEL)
        athanAlarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAthanAlarm" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val epochMillis = call.argument<Long>("epochMillis") ?: 0L
                        val prayerName = call.argument<String>("prayerName") ?: "Prayer"
                        val audioPath = call.argument<String>("audioPath") ?: ""
                        val durationSeconds = call.argument<Int>("durationSeconds") ?: 0

                        scheduleAthanAlarm(id, epochMillis, prayerName, audioPath, durationSeconds)
                        Log.d("MainActivity", "scheduleAthanAlarm: id=$id, prayer=$prayerName, time=$epochMillis")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "scheduleAthanAlarm error: ${e.message}", e)
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelAthanAlarm" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        cancelAthanAlarm(id)
                        Log.d("MainActivity", "cancelAthanAlarm: id=$id")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "cancelAthanAlarm error: ${e.message}", e)
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "stopAthanService" -> {
                    try {
                        stopAthanService()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Native AlarmManager scheduling
    // ─────────────────────────────────────────────────────────────────────────

    private fun buildAthanPendingIntent(id: Int, prayerName: String, audioPath: String, durationSeconds: Int): PendingIntent {
        val intent = Intent(this, AthanAlarmReceiver::class.java).apply {
            action = AthanAlarmReceiver.ACTION_PLAY_ATHAN
            putExtra(AthanForegroundService.EXTRA_ALARM_ID, id)
            putExtra(AthanForegroundService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AthanForegroundService.EXTRA_AUDIO_PATH, audioPath)
            putExtra(AthanForegroundService.EXTRA_DURATION_SECONDS, durationSeconds)
        }
        // Each alarm ID gets a unique request code so PendingIntents don't collide
        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleAthanAlarm(
        id: Int,
        epochMillis: Long,
        prayerName: String,
        audioPath: String,
        durationSeconds: Int
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = buildAthanPendingIntent(id, prayerName, audioPath, durationSeconds)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+: must check permission before using setExactAndAllowWhileIdle
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
            } else {
                // Fallback to inexact if exact alarm permission not granted
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                Log.w("MainActivity", "Exact alarm permission not granted. Using inexact alarm for id=$id")
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6-11: use setExactAndAllowWhileIdle to bypass Doze
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
        } else {
            // Android 5 and below: setExact
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
        }
        Log.d("MainActivity", "Native alarm scheduled: id=$id at $epochMillis for $prayerName")
    }

    private fun cancelAthanAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Rebuild PendingIntent with same parameters to cancel. Extras don't matter for cancellation.
        val intent = Intent(this, AthanAlarmReceiver::class.java).apply {
            action = AthanAlarmReceiver.ACTION_PLAY_ATHAN
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            Log.d("MainActivity", "Native alarm cancelled: id=$id")
        }
    }

    private fun stopAthanService() {
        stopService(Intent(this, AthanForegroundService::class.java))
        Log.d("MainActivity", "AthanForegroundService stop requested from Flutter.")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Activity lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        volumeControlStream = android.media.AudioManager.STREAM_ALARM

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }
}
