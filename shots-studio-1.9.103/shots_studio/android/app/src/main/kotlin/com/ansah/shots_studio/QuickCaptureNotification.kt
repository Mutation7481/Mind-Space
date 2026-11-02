package com.ansah.shots_studio

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object QuickCaptureNotification {

    const val CHANNEL_ID = "mind_space_quick_tile_channel"
    const val NOTIFICATION_ID = 3003

    fun show(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mind Space Quick Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Quick screenshot capture to Mind Space without saving to gallery"
                setShowBadge(false)
            }
            manager.createNotificationChannel(channel)
        }

        val captureIntent = Intent(context, CaptureActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            102,
            captureIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_capture)
            .setContentTitle("Mind Space Capture")
            .setContentText("Tap to capture screen directly to Mind Space")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .addAction(
                R.drawable.ic_tile_capture,
                "Capture Memory",
                pendingIntent
            )
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }

    fun dismiss(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }
}
