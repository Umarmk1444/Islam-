package com.umer.quranzone

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_times).apply {
                // Get data from SharedPreferences
                val hijriDate = widgetData.getString("hijri_date", "")
                val gregorianDate = widgetData.getString("gregorian_date", "")
                val location = widgetData.getString("location_label", "")
                val prayerName = widgetData.getString("next_prayer_name", "")
                val prayerTime = widgetData.getString("next_prayer_time", "")
                val prayerTimestamp = widgetData.getLong("next_prayer_timestamp", 0L)
                val daySegment = widgetData.getString("day_segment", "afternoon")
                
                val bgRes = when (daySegment) {
                    "lastThirdNight", "lateNight" -> R.drawable.widget_bg_night
                    "fajr" -> R.drawable.widget_bg_fajr
                    "morning" -> R.drawable.widget_bg_morning
                    "afternoon" -> R.drawable.widget_bg_afternoon
                    "evening" -> R.drawable.widget_bg_evening
                    "night" -> R.drawable.widget_bg_isha
                    else -> R.drawable.widget_bg_afternoon
                }
                setInt(R.id.widget_root, "setBackgroundResource", bgRes)

                setTextViewText(R.id.tv_hijri_date, hijriDate)
                setTextViewText(R.id.tv_gregorian_date, gregorianDate)
                setTextViewText(R.id.tv_location, location)
                setTextViewText(R.id.tv_prayer_name, prayerName)
                setTextViewText(R.id.tv_prayer_time, prayerTime)

                if (prayerTimestamp > 0) {
                    // Set up Chronometer countdown
                    val now = System.currentTimeMillis()
                    val diff = prayerTimestamp - now
                    val base = SystemClock.elapsedRealtime() + diff
                    
                    setChronometer(R.id.chronometer_countdown, base, "-%s", true)
                    
                    // CountDown true requires API 24+, since our minSdk is 24, this is safe.
                    setChronometerCountDown(R.id.chronometer_countdown, true)
                }

                // Intent to launch the app directly
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                    data = Uri.parse("app://launch")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // Intent for Quran Button
                val quranIntent = Intent(context, MainActivity::class.java).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                    data = Uri.parse("app://quran_action")
                }
                val quranPendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    quranIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_quran, quranPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
