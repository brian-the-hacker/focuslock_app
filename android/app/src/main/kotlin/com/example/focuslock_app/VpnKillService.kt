package com.example.focuslock_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.PowerManager

class VpnKillService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "focuslock_vpn"
    private var endTime: Long = 0L

    companion object {
        var isRunning = false
        const val PREFS_NAME = "focuslock_prefs"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "STOP") {
            stopVpn()
            return START_NOT_STICKY
        }

        // Get end time from intent or prefs
        endTime = intent?.getLongExtra("end_time", 0L) ?: 0L
        if (endTime == 0L) {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            endTime = prefs.getLong("session_end_time", 0L)
        }

        acquireWakeLock()
        startForegroundNotification()
        startVpn()
        startEnforcer()

        return START_STICKY  // Android restarts this if killed
    }

    private fun startVpn() {
        try {
            vpnInterface?.close()
            vpnInterface = Builder()
                .addAddress("10.0.0.1", 32)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0)
                .setSession("FocusLock")
                .setBlocking(false)
                // Exclude our own app from VPN so it can still reach Railway
                // This allows: session complete, emergency requests, coin awards
                // Everything else (Instagram, Chrome, TikTok) still blocked
                .addDisallowedApplication("com.example.focuslock_app")
                .establish()
            isRunning = true
        } catch (e: Exception) {
            handler.postDelayed({ startVpn() }, 500)
        }
    }

    // ── Enforcer — runs every 500ms ───────────────────────────
    private val enforcerRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return

            // Check if session expired
            if (endTime > 0 && System.currentTimeMillis() > endTime) {
                stopVpn()
                return
            }

            // Aggressive VPN check — if interface is null or fd invalid, restart
            val needsRestart = try {
                when {
                    vpnInterface == null -> true
                    vpnInterface?.fileDescriptor == null -> true
                    !vpnInterface!!.fileDescriptor.valid() -> true
                    else -> {
                        // Try writing a byte to detect silent revocation
                        val os = java.io.FileOutputStream(vpnInterface!!.fileDescriptor)
                        os.flush()
                        false
                    }
                }
            } catch (e: Exception) {
                true  // Any exception = VPN is dead, restart it
            }

            if (needsRestart) {
                isRunning = false
                startVpn()
            }

            updateNotification()
            handler.postDelayed(this, 500)
        }
    }

    private fun startEnforcer() {
        handler.post(enforcerRunnable)
    }

    private fun stopVpn() {
        isRunning = false
        handler.removeCallbacks(enforcerRunnable)
        wakeLock?.release()
        wakeLock = null

        try {
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Clear session from prefs
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean("session_active", false)
            .apply()

        stopForeground(true)
        stopSelf()
    }

    // ── Wake lock — prevents CPU sleep ───────────────────────
    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "FocusLock::VpnWakeLock"
        ).apply { acquire(12 * 60 * 60 * 1000L) } // max 12 hours
    }

    // ── Notification ──────────────────────────────────────────
    private fun startForegroundNotification() {
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Session active"))
    }

    private fun updateNotification() {
        if (endTime > 0) {
            val remaining = endTime - System.currentTimeMillis()
            if (remaining > 0) {
                val mins = (remaining / 60000).toInt()
                val secs = ((remaining % 60000) / 1000).toInt()
                val text = "%02d:%02d remaining".format(mins, secs)
                val manager = getSystemService(NotificationManager::class.java)
                manager.notify(NOTIFICATION_ID, buildNotification(text))
            }
        }
    }

    private fun buildNotification(text: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("🔒 Focus Lock Active")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)       // can't be swiped away
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("🔒 Focus Lock Active")
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Lock Active",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows remaining focus time"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}