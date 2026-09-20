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
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.model.AssetPackStatus

class MainActivity : AudioServiceActivity() {

    private val DEVICE_CHANNEL = "com.umer.quranzone/device"
    private val ATHAN_ALARM_CHANNEL = "com.umer.quranzone/athan_alarm"
    private val SYSTEM_ACTIONS_CHANNEL = "com.umer.quranzone/system_actions"
    private val PLAY_ASSET_DELIVERY_CHANNEL = "com.umer.quranzone/play_asset_delivery"

    private var deviceChannel: MethodChannel? = null
    private var athanAlarmChannel: MethodChannel? = null
    private var systemActionsChannel: MethodChannel? = null
    private var playAssetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── System Actions Channel (ACTION_PROCESS_TEXT for AI & Translate popup) ──
        systemActionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_ACTIONS_CHANNEL)
        systemActionsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getProcessTextApps" -> {
                    try {
                        val intent = Intent(Intent.ACTION_PROCESS_TEXT).setType("text/plain")
                        val resolveInfos = packageManager.queryIntentActivities(intent, 0)
                        val apps = mutableListOf<Map<String, String>>()
                        for (ri in resolveInfos) {
                            try {
                                val actInfo = ri.activityInfo ?: continue
                                val pkg = actInfo.packageName ?: continue
                                val name = actInfo.name ?: ""
                                var labelStr = pkg
                                try {
                                    val charSeq = ri.loadLabel(packageManager)
                                    if (charSeq != null && charSeq.isNotEmpty()) {
                                        labelStr = charSeq.toString()
                                    }
                                } catch (_: Throwable) {
                                    labelStr = pkg
                                }
                                apps.add(mapOf(
                                    "packageName" to pkg,
                                    "activityName" to name,
                                    "label" to labelStr
                                ))
                            } catch (_: Throwable) {}
                        }
                        result.success(apps)
                    } catch (e: Throwable) {
                        Log.e("MainActivity", "getProcessTextApps error: ${e.message}", e)
                        result.success(emptyList<Map<String, String>>())
                    }
                }
                "launchProcessText" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        val activityName = call.argument<String>("activityName")
                        val text = call.argument<String>("text") ?: ""

                        val intent = Intent(Intent.ACTION_PROCESS_TEXT).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
                            putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, true)
                            if (!activityName.isNullOrEmpty() && !packageName.isNullOrEmpty()) {
                                setClassName(packageName, activityName)
                            } else if (!packageName.isNullOrEmpty()) {
                                setPackage(packageName)
                            }
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Throwable) {
                        Log.e("MainActivity", "launchProcessText error: ${e.message}", e)
                        result.error("LAUNCH_ERROR", e.message ?: "Failed to launch", null)
                    }
                }
                "isPackageInstalled" -> {
                    try {
                        val packageName = call.argument<String>("packageName") ?: ""
                        packageManager.getPackageInfo(packageName, 0)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

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
                "scheduleSilentAlarm" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        val epochMillis = call.argument<Long>("epochMillis") ?: 0L
                        val isSilent = call.argument<Boolean>("isSilent") ?: false
                        
                        scheduleSilentAlarm(id, epochMillis, isSilent)
                        Log.d("MainActivity", "scheduleSilentAlarm: id=$id, time=$epochMillis, isSilent=$isSilent")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "scheduleSilentAlarm error: ${e.message}", e)
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelSilentAlarm" -> {
                    try {
                        val id = call.argument<Int>("id") ?: 0
                        cancelSilentAlarm(id)
                        Log.d("MainActivity", "cancelSilentAlarm: id=$id")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "cancelSilentAlarm error: ${e.message}", e)
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

        // ── Google Play Asset Delivery Channel ──
        try {
            val assetPackManager = AssetPackManagerFactory.getInstance(this)
            playAssetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLAY_ASSET_DELIVERY_CHANNEL)
            playAssetChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAssetPackPath" -> {
                        val packName = call.argument<String>("packName") ?: "quran_fonts"
                        try {
                            val location = assetPackManager.getPackLocation(packName)
                            if (location != null) {
                                result.success(location.assetsPath())
                            } else {
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "getAssetPackPath error: ${e.message}", e)
                            result.success(null)
                        }
                    }
                    "getAssetPackStatus" -> {
                        val packName = call.argument<String>("packName") ?: "quran_fonts"
                        try {
                            val location = assetPackManager.getPackLocation(packName)
                            if (location != null) {
                                result.success(mapOf(
                                    "status" to "COMPLETED",
                                    "bytesDownloaded" to 100L,
                                    "totalBytes" to 100L,
                                    "path" to location.assetsPath()
                                ))
                            } else {
                                assetPackManager.getPackStates(listOf(packName))
                                    .addOnSuccessListener { packStates ->
                                        val state = packStates.packStates()[packName]
                                        val statusStr = when (state?.status()) {
                                            AssetPackStatus.COMPLETED -> "COMPLETED"
                                            AssetPackStatus.DOWNLOADING -> "DOWNLOADING"
                                            AssetPackStatus.PENDING -> "PENDING"
                                            AssetPackStatus.TRANSFERRING -> "TRANSFERRING"
                                            AssetPackStatus.FAILED -> "FAILED"
                                            AssetPackStatus.CANCELED -> "CANCELED"
                                            AssetPackStatus.NOT_INSTALLED -> "NOT_INSTALLED"
                                            AssetPackStatus.WAITING_FOR_WIFI -> "WAITING_FOR_WIFI"
                                            else -> "UNKNOWN"
                                        }
                                        result.success(mapOf(
                                            "status" to statusStr,
                                            "bytesDownloaded" to (state?.bytesDownloaded() ?: 0L),
                                            "totalBytes" to (state?.totalBytesToDownload() ?: 0L),
                                            "path" to null
                                        ))
                                    }
                                    .addOnFailureListener { e ->
                                        result.success(mapOf(
                                            "status" to "UNKNOWN",
                                            "bytesDownloaded" to 0L,
                                            "totalBytes" to 0L,
                                            "error" to e.message
                                        ))
                                    }
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "getAssetPackStatus error: ${e.message}", e)
                            result.success(mapOf("status" to "UNKNOWN", "error" to e.message))
                        }
                    }
                    "fetchAssetPack" -> {
                        val packName = call.argument<String>("packName") ?: "quran_fonts"
                        try {
                            assetPackManager.fetch(listOf(packName))
                                .addOnSuccessListener {
                                    result.success(true)
                                }
                                .addOnFailureListener { e ->
                                    Log.e("MainActivity", "fetchAssetPack error: ${e.message}", e)
                                    result.success(false)
                                }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "fetchAssetPack error: ${e.message}", e)
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

            assetPackManager.registerListener { state ->
                val statusStr = when (state.status()) {
                    AssetPackStatus.COMPLETED -> "COMPLETED"
                    AssetPackStatus.DOWNLOADING -> "DOWNLOADING"
                    AssetPackStatus.PENDING -> "PENDING"
                    AssetPackStatus.TRANSFERRING -> "TRANSFERRING"
                    AssetPackStatus.FAILED -> "FAILED"
                    else -> "UNKNOWN"
                }
                val payload = mapOf(
                    "packName" to state.name(),
                    "status" to statusStr,
                    "bytesDownloaded" to state.bytesDownloaded(),
                    "totalBytes" to state.totalBytesToDownload()
                )
                runOnUiThread {
                    playAssetChannel?.invokeMethod("onAssetPackStateUpdate", payload)
                }
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "AssetPackManager warning: ${e.message}")
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
        val showIntent = PendingIntent.getActivity(
            this, id, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val alarmClockInfo = AlarmManager.AlarmClockInfo(epochMillis, showIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                Log.w("MainActivity", "Exact alarm permission not granted. Using inexact alarm for id=$id")
            }
        } else {
            // Android 11 and below (including API 33/Android 13 Xiaomi if not SDK_INT check)
            // Wait, Android 12 is Build.VERSION_CODES.S
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        }
        Log.d("MainActivity", "Native alarm scheduled (AlarmClock): id=$id at $epochMillis for $prayerName")
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

    private fun buildSilentPendingIntent(id: Int, isSilent: Boolean): PendingIntent {
        val intent = Intent(this, SilentModeReceiver::class.java).apply {
            action = SilentModeReceiver.ACTION_SET_SILENT_MODE
            putExtra(SilentModeReceiver.EXTRA_IS_SILENT, isSilent)
        }
        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleSilentAlarm(id: Int, epochMillis: Long, isSilent: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = buildSilentPendingIntent(id, isSilent)
        val showIntent = PendingIntent.getActivity(
            this, id, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val alarmClockInfo = AlarmManager.AlarmClockInfo(epochMillis, showIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMillis, pendingIntent)
                Log.w("MainActivity", "Exact alarm permission not granted. Using inexact alarm for SilentMode id=$id")
            }
        } else {
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        }
        Log.d("MainActivity", "SilentMode alarm scheduled (AlarmClock): id=$id at $epochMillis, isSilent=$isSilent")
    }

    private fun cancelSilentAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SilentModeReceiver::class.java).apply {
            action = SilentModeReceiver.ACTION_SET_SILENT_MODE
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
            Log.d("MainActivity", "SilentMode alarm cancelled: id=$id")
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

        // Edge-to-edge support for Android 15 (SDK 35+) and backward compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }

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
