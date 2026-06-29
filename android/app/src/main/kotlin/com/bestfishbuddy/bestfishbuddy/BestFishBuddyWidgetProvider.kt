package com.bestfishbuddy.bestfishbuddy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home screen widget for Best Fish Buddy.
 * Displays catch count, best fishing times, weather, and biggest catch.
 * Data is pushed from Flutter via HomeWidget.saveWidgetData() into SharedPreferences.
 */
class BestFishBuddyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.bestfishbuddy_widget)

        // Read data pushed from Flutter via home_widget
        val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)

        val catchCount = prefs.getString("catch_count", "0") ?: "0"
        val solunarTime = prefs.getString("solunar_time", "--:--") ?: "--:--"
        val weather = prefs.getString("weather", "--°C") ?: "--°C"
        val biggestCatch = prefs.getString("biggest_catch", "-- kg") ?: "-- kg"
        val subtitle = prefs.getString("subtitle", "Tap to open") ?: "Tap to open"

        views.setTextViewText(R.id.widget_catch_count, catchCount)
        views.setTextViewText(R.id.widget_solunar_time, solunarTime)
        views.setTextViewText(R.id.widget_weather, weather)
        views.setTextViewText(R.id.widget_biggest, biggestCatch)
        views.setTextViewText(R.id.widget_subtitle, subtitle)

        // Open app on tap
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
