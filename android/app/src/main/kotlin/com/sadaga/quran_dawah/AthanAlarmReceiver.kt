package com.sadaga.quran_dawah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * AthanAlarmReceiver — BroadcastReceiver that receives the Athan alarm PendingIntent
 * from the native AlarmManager (scheduled via MethodChannel in MainActivity).
 *
 * It immediately starts [AthanForegroundService] so the OS cannot kill the process
 * before the Athan audio finishes playing.
 *
 * Intent extras expected:
 *   - EXTRA_PRAYER_NAME  (String): e.g. "fajr", "dhuhr"
 *   - EXTRA_AUDIO_PATH   (String): absolute file path OR "assets/audio/xxx.mp3"
 *   - EXTRA_DURATION_SECONDS (Int): max playback seconds (0 = use default 120s)
 *   - EXTRA_ALARM_ID     (Int)  : the alarm ID (100–105)
 */
class AthanAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "AthanAlarmReceiver"
        const val ACTION_PLAY_ATHAN = "com.sadaga.quran_dawah.ACTION_PLAY_ATHAN"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Alarm received: action=${intent.action}")

        if (intent.action != ACTION_PLAY_ATHAN) {
            Log.w(TAG, "Unexpected action: ${intent.action}")
            return
        }

        val prayerName = intent.getStringExtra(AthanForegroundService.EXTRA_PRAYER_NAME) ?: "Prayer"
        val audioPath = intent.getStringExtra(AthanForegroundService.EXTRA_AUDIO_PATH)
        val durationSeconds = intent.getIntExtra(AthanForegroundService.EXTRA_DURATION_SECONDS, 0)
        val alarmId = intent.getIntExtra(AthanForegroundService.EXTRA_ALARM_ID, 9001)

        Log.d(TAG, "Starting AthanForegroundService for $prayerName (id=$alarmId, path=$audioPath)")

        val serviceIntent = Intent(context, AthanForegroundService::class.java).apply {
            putExtra(AthanForegroundService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AthanForegroundService.EXTRA_AUDIO_PATH, audioPath)
            putExtra(AthanForegroundService.EXTRA_DURATION_SECONDS, durationSeconds)
            putExtra(AthanForegroundService.EXTRA_ALARM_ID, alarmId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
