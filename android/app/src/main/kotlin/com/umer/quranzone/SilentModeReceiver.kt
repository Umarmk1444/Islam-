package com.umer.quranzone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.util.Log

class SilentModeReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "SilentModeReceiver"
        const val ACTION_SET_SILENT_MODE = "com.umer.quranzone.ACTION_SET_SILENT_MODE"
        const val EXTRA_IS_SILENT = "is_silent"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "SilentMode alarm received: action=${intent.action}")

        if (intent.action != ACTION_SET_SILENT_MODE) {
            Log.w(TAG, "Unexpected action: ${intent.action}")
            return
        }

        val isSilent = intent.getBooleanExtra(EXTRA_IS_SILENT, false)
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

        try {
            if (isSilent) {
                // True DND mode (API 23+)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALARMS)
                        Log.d(TAG, "DND Filter set to ALARMS")
                    } else {
                        Log.w(TAG, "DND permission missing. Cannot set Interruption Filter.")
                    }
                }
                // Fallback / standard ringer mode
                audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                Log.d(TAG, "Ringer mode set to SILENT")
            } else {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    if (notificationManager.isNotificationPolicyAccessGranted) {
                        notificationManager.setInterruptionFilter(android.app.NotificationManager.INTERRUPTION_FILTER_ALL)
                        Log.d(TAG, "DND Filter set to ALL")
                    }
                }
                audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                Log.d(TAG, "Ringer mode set to NORMAL")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set ringer mode: ${e.message}")
        }
    }
}
