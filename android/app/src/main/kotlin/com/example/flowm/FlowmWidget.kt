package com.example.flowm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.*

class FlowmWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.flowm_widget).apply {
                // 从 SharedPreferences 读取数据，更稳健地处理数字类型
                val expense = (widgetData.all["expense"]?.toString())?.toDoubleOrNull() ?: 0.0
                val income = (widgetData.all["income"]?.toString())?.toDoubleOrNull() ?: 0.0
                val balance = (widgetData.all["balance"]?.toString())?.toDoubleOrNull() ?: 0.0

                // 格式化金额
                val formatter = NumberFormat.getCurrencyInstance(Locale.CHINA)
                
                // 设置文本
                setTextViewText(R.id.widget_expense_amount, formatter.format(expense))
                setTextViewText(R.id.widget_income_amount, formatter.format(income))
                setTextViewText(R.id.widget_balance_amount, formatter.format(balance))

                // 设置点击事件，打开应用
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
} 