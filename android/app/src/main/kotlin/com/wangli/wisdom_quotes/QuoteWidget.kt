package com.wangli.wisdom_quotes

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class QuoteWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "quote_widget_prefs"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            val quote = prefs.getString("quote_$appWidgetId", "点击设置今日名言") ?: "点击设置今日名言"
            val author = prefs.getString("author_$appWidgetId", "") ?: ""
            val category = prefs.getString("category_$appWidgetId", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.quote_widget)
            views.setTextViewText(R.id.widget_quote, "\"$quote\"")
            views.setTextViewText(R.id.widget_author, if (author.isNotEmpty()) "— $author" else "")
            views.setTextViewText(R.id.widget_category, category)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
