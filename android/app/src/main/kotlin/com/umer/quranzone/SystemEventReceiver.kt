package com.umer.quranzone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker

class SystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("SystemEventReceiver", "Received intent action: $action")
        if (action == Intent.ACTION_TIME_CHANGED || 
            action == Intent.ACTION_TIMEZONE_CHANGED || 
            action == Intent.ACTION_DATE_CHANGED || 
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_BOOT_COMPLETED) {
            
            try {
                // Ensure alarms are synced immediately upon critical system events
                val data = Data.Builder()
                    .putString("be.tramckrijte.workmanager.DART_TASK", "sync_alarms")
                    .putBoolean("be.tramckrijte.workmanager.IS_IN_DEBUG_MODE", false)
                    .build()

                val request = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
                    .setInputData(data)
                    .build()

                WorkManager.getInstance(context).enqueue(request)
                Log.d("SystemEventReceiver", "Successfully enqueued sync_alarms task via WorkManager")
            } catch (e: Exception) {
                Log.e("SystemEventReceiver", "Failed to enqueue workmanager task: ${e.message}")
            }
        }
    }
}
