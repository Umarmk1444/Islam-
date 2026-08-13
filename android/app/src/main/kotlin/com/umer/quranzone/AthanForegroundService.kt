package com.umer.quranzone

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.database.ContentObserver
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.Timer
import java.util.TimerTask

class AthanForegroundService : Service() {

    companion object {
        const val TAG = "AthanForegroundService"
        const val CHANNEL_ID = "athan_fg_service_channel"
        const val NOTIF_ID = 9001
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_AUDIO_PATH = "audio_path"
        const val EXTRA_DURATION_SECONDS = "duration_seconds"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val DEFAULT_MAX_DURATION_SECONDS = 120 // 2-minute hard cap

        // Intent action for the Stop button and swipe-to-dismiss
        const val ACTION_STOP_ATHAN = "com.umer.quranzone.ACTION_STOP_ATHAN"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var durationTimer: Timer? = null
    private var volumeObserver: ContentObserver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ── Handle Stop action (from notification button or swipe-to-dismiss) ──
        if (intent?.action == ACTION_STOP_ATHAN) {
            Log.d(TAG, "Stop action received — cleaning up.")
            cleanupAndStop()
            return START_NOT_STICKY
        }

        Log.d(TAG, "onStartCommand: starting Athan playback")

        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "Prayer"
        val audioPath = intent?.getStringExtra(EXTRA_AUDIO_PATH)
        val durationSeconds = intent?.getIntExtra(EXTRA_DURATION_SECONDS, 0) ?: 0

        // ── 1. Post foreground notification (MUST be within 5 seconds on API 26+) ──
        val notification = buildNotification(prayerName)
        startForeground(NOTIF_ID, notification)
        Log.d(TAG, "Foreground notification posted for: $prayerName")

        // ── 2. Acquire WakeLock to keep the CPU alive during playback ──
        acquireWakeLock(durationSeconds)

        // ── 3. Play audio ──
        playAudio(audioPath, durationSeconds, prayerName)

        return START_NOT_STICKY
    }

    // ─────────────────────────────────────────────────────────────────────────
    // WakeLock
    // ─────────────────────────────────────────────────────────────────────────

    private fun acquireWakeLock(durationSeconds: Int) {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val timeoutMs = ((if (durationSeconds > 0) durationSeconds else DEFAULT_MAX_DURATION_SECONDS) + 10) * 1000L
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "QuranZone::AthanWakeLock"
            ).apply {
                acquire(timeoutMs)
            }
            Log.d(TAG, "WakeLock acquired for ${timeoutMs / 1000}s")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "WakeLock released")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
        wakeLock = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Audio Playback
    // ─────────────────────────────────────────────────────────────────────────

    private fun playAudio(audioPath: String?, durationSeconds: Int, prayerName: String) {
        try {
            val player = MediaPlayer()
            mediaPlayer = player

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()
            player.setAudioAttributes(audioAttributes)

            // Max alarm volume
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            am.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)

            val sourceSet = trySetAudioSource(player, audioPath)
            if (!sourceSet) {
                Log.e(TAG, "All audio sources failed. Stopping service.")
                cleanupAndStop()
                return
            }

            player.prepare()

            player.setOnCompletionListener {
                Log.d(TAG, "Athan playback completed naturally.")
                cleanupAndStop()
            }

            player.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer error: what=$what extra=$extra")
                cleanupAndStop()
                true
            }

            player.start()
            Log.d(TAG, "MediaPlayer started for: $prayerName")

            // Register Volume Observer to act as a Kill Switch
            registerVolumeObserver()

            // Safety timer: enforce max duration
            val maxSecs = if (durationSeconds > 0) durationSeconds else DEFAULT_MAX_DURATION_SECONDS
            durationTimer = Timer()
            durationTimer?.schedule(object : TimerTask() {
                override fun run() {
                    Log.d(TAG, "Max duration (${maxSecs}s) reached — stopping.")
                    cleanupAndStop()
                }
            }, maxSecs * 1000L)

        } catch (e: Exception) {
            Log.e(TAG, "Error starting playback: ${e.message}", e)
            cleanupAndStop()
        }
    }

    private fun trySetAudioSource(player: MediaPlayer, audioPath: String?): Boolean {
        if (!audioPath.isNullOrBlank()) {
            if (!audioPath.startsWith("assets/") && File(audioPath).exists()) {
                try {
                    player.setDataSource(audioPath)
                    Log.d(TAG, "Audio source: file path — $audioPath")
                    return true
                } catch (e: Exception) {
                    Log.w(TAG, "File source failed ($audioPath): ${e.message}")
                    return tryBundledFallback(player, audioPath)
                }
            }
            if (audioPath.startsWith("assets/")) {
                return tryBundledFallback(player, audioPath)
            }
        }
        return tryRawResource(player, "takbir_mishary_alafasy")
    }

    private fun tryBundledFallback(player: MediaPlayer, audioPath: String): Boolean {
        val fileName = audioPath.substringAfterLast("/").substringBeforeLast(".")
        return if (tryRawResource(player, fileName)) true
        else tryRawResource(player, "takbir_mishary_alafasy")
    }

    private fun tryRawResource(player: MediaPlayer, rawName: String): Boolean {
        return try {
            val resId = resources.getIdentifier(rawName, "raw", packageName)
            if (resId == 0) {
                Log.w(TAG, "Raw resource not found: $rawName")
                return false
            }
            val afd = resources.openRawResourceFd(resId)
            player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            Log.d(TAG, "Audio source: raw resource — $rawName")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Raw resource failed ($rawName): ${e.message}")
            false
        }
    }

    private var initialVolumeSum: Int = -1

    private fun registerVolumeObserver() {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val alarmVol = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            val musicVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val ringVol = audioManager.getStreamVolume(AudioManager.STREAM_RING)
            initialVolumeSum = alarmVol + musicVol + ringVol

            volumeObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    super.onChange(selfChange)
                    
                    val newAlarm = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
                    val newMusic = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val newRing = audioManager.getStreamVolume(AudioManager.STREAM_RING)
                    val newSum = newAlarm + newMusic + newRing
                    
                    if (newSum != initialVolumeSum) {
                        Log.d(TAG, "Volume change detected ($initialVolumeSum -> $newSum). Silencing Adhan.")
                        cleanupAndStop()
                    }
                }
            }
            contentResolver.registerContentObserver(
                Settings.System.CONTENT_URI,
                true,
                volumeObserver!!
            )
            Log.d(TAG, "Volume observer registered with initialSum=$initialVolumeSum")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register volume observer: ${e.message}")
        }
    }

    private fun unregisterVolumeObserver() {
        try {
            volumeObserver?.let {
                contentResolver.unregisterContentObserver(it)
                volumeObserver = null
                Log.d(TAG, "Volume observer unregistered.")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister volume observer: ${e.message}")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Cleanup
    // ─────────────────────────────────────────────────────────────────────────

    private fun cleanupAndStop() {
        durationTimer?.cancel()
        durationTimer = null

        unregisterVolumeObserver()

        try {
            if (mediaPlayer?.isPlaying == true) mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer: ${e.message}")
        }
        mediaPlayer = null

        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "AthanForegroundService cleaned up and stopped.")
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupAndStop()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Notification — with Stop action button and delete intent
    // ─────────────────────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Athan Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Foreground service for Athan audio playback"
                setSound(null, null) // Audio is managed by MediaPlayer, not the notification
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    /**
     * Builds a PendingIntent that sends ACTION_STOP_ATHAN back to this service.
     * Used for both the Stop action button and the swipe-to-dismiss (deleteIntent).
     */
    private fun buildStopPendingIntent(): PendingIntent {
        val stopIntent = Intent(this, AthanForegroundService::class.java).apply {
            action = ACTION_STOP_ATHAN
        }
        return PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildNotification(prayerName: String): Notification {
        val displayName = when (prayerName.lowercase()) {
            "fajr"    -> "Fajr"
            "sunrise" -> "Sunrise"
            "dhuhr"   -> "Dhuhr"
            "asr"     -> "Asr"
            "maghrib" -> "Maghrib"
            "isha"    -> "Isha"
            else      -> prayerName
        }

        // Tap notification body → open app
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = PendingIntent.getActivity(
            this, 1, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopPendingIntent = buildStopPendingIntent()

        // BigTextStyle auto-expands the notification so the Stop action button
        // is always visible without requiring the user to manually expand it.
        val bigTextStyle = NotificationCompat.BigTextStyle()
            .bigText("حان الآن موعد أذان $displayName\nPress \"■ Stop Athan\" to silence the audio.")
            .setBigContentTitle("🕌 $displayName Prayer")

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🕌 $displayName Prayer")
            .setContentText("Tap ■ Stop Athan to silence")   // collapsed-state hint
            .setStyle(bigTextStyle)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)               // sticky — cannot swipe on Android ≤ 12
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(openPendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            // ── Stop action button — THE only stop mechanism on Android ≤ 12 ──
            .addAction(
                android.R.drawable.ic_delete,   // ■ stop icon (more intuitive than pause)
                "■ Stop Athan",
                stopPendingIntent
            )
            // ── Delete intent — fires on Android 13+ if user dismisses ──────
            .setDeleteIntent(stopPendingIntent)
            .build()
    }
}
