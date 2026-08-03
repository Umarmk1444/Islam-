package com.sadaga.quran_dawah

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
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
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
        const val DEFAULT_MAX_DURATION_SECONDS = 120 // 2 minutes hard cap
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var durationTimer: Timer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand received")

        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "Prayer"
        val audioPath = intent?.getStringExtra(EXTRA_AUDIO_PATH)
        val durationSeconds = intent?.getIntExtra(EXTRA_DURATION_SECONDS, 0) ?: 0
        val alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, NOTIF_ID) ?: NOTIF_ID

        // ── 1. Post foreground notification immediately (MUST be within 5 seconds on Android 8+) ──
        val notification = buildNotification(prayerName)
        startForeground(NOTIF_ID, notification)
        Log.d(TAG, "Foreground notification posted for: $prayerName")

        // ── 2. Acquire partial WakeLock to keep CPU alive during playback ──
        acquireWakeLock(durationSeconds)

        // ── 3. Play audio ──
        playAudio(audioPath, durationSeconds, prayerName)

        // Return START_NOT_STICKY so the service is NOT restarted if killed mid-play.
        // The alarm will fire again tomorrow anyway.
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

            // Configure audio attributes for alarm/athan use
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()
            player.setAudioAttributes(audioAttributes)

            // Use max alarm stream volume
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            am.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)

            // Set audio source
            val sourceSet = trySetAudioSource(player, audioPath, prayerName)
            if (!sourceSet) {
                Log.e(TAG, "All audio sources failed. Stopping service.")
                stopSelf()
                return
            }

            player.prepare()

            // ── Completion listener: clean up when audio finishes naturally ──
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
            Log.d(TAG, "Athan MediaPlayer started for $prayerName")

            // ── Safety timer: enforce max duration ──
            val maxSecs = if (durationSeconds > 0) durationSeconds else DEFAULT_MAX_DURATION_SECONDS
            durationTimer = Timer()
            durationTimer?.schedule(object : TimerTask() {
                override fun run() {
                    Log.d(TAG, "Max duration ($maxSecs s) reached. Stopping athan.")
                    cleanupAndStop()
                }
            }, maxSecs * 1000L)

        } catch (e: Exception) {
            Log.e(TAG, "Error starting audio playback: ${e.message}", e)
            cleanupAndStop()
        }
    }

    /**
     * Attempts to set the audio source in priority order:
     * 1. Provided file path (downloaded muezzin)
     * 2. Matching bundled raw resource (by muezzin ID extracted from path)
     * 3. Default fallback: adhan_abdulbasit raw resource
     *
     * Returns true if any source was successfully set.
     */
    private fun trySetAudioSource(player: MediaPlayer, audioPath: String?, prayerName: String): Boolean {
        // 1. Try the provided file path first (downloaded or absolute path)
        if (!audioPath.isNullOrBlank()) {
            // If it's a full file path (downloaded muezzin)
            if (!audioPath.startsWith("assets/") && File(audioPath).exists()) {
                return try {
                    player.setDataSource(audioPath)
                    Log.d(TAG, "Audio source set from file: $audioPath")
                    true
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set file source $audioPath: ${e.message}")
                    false
                }.also { success ->
                    if (!success) return tryBundledFallback(player, audioPath)
                }
            }

            // 2. If it's an asset path like "assets/audio/adhan_abdulbasit.mp3",
            // extract the filename and map it to a raw resource
            if (audioPath.startsWith("assets/")) {
                return tryBundledFallback(player, audioPath)
            }
        }

        // 3. Ultimate fallback: adhan_abdulbasit
        return tryRawResource(player, "adhan_abdulbasit")
    }

    private fun tryBundledFallback(player: MediaPlayer, audioPath: String): Boolean {
        // Extract filename without extension from path like "assets/audio/adhan_abdulbasit.mp3"
        val fileName = audioPath.substringAfterLast("/").substringBeforeLast(".")
        // Try the exact name, then default
        return if (tryRawResource(player, fileName)) true
        else tryRawResource(player, "adhan_abdulbasit")
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
            Log.d(TAG, "Audio source set from raw resource: $rawName")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set raw resource $rawName: ${e.message}")
            false
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Cleanup
    // ─────────────────────────────────────────────────────────────────────────

    private fun cleanupAndStop() {
        durationTimer?.cancel()
        durationTimer = null

        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer: ${e.message}")
        }
        mediaPlayer = null

        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.d(TAG, "AthanForegroundService stopped and cleaned up.")
    }

    override fun onDestroy() {
        super.onDestroy()
        cleanupAndStop()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Notification
    // ─────────────────────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Athan Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Foreground service for Athan audio playback"
                setSound(null, null) // Audio is handled by MediaPlayer, not notification sound
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(prayerName: String): Notification {
        val displayName = when (prayerName.lowercase()) {
            "fajr" -> "Fajr"
            "sunrise" -> "Sunrise"
            "dhuhr" -> "Dhuhr"
            "asr" -> "Asr"
            "maghrib" -> "Maghrib"
            "isha" -> "Isha"
            else -> prayerName
        }

        // Tap notification to open app
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🕌 $displayName Prayer")
            .setContentText("حان الآن موعد أذان $displayName")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
