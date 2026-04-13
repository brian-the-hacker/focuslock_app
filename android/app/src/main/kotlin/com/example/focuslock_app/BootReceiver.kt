package com.example.focuslock_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            // Check if a session was active before reboot
            val prefs: SharedPreferences = context.getSharedPreferences(
                "focuslock_prefs", Context.MODE_PRIVATE)

            val sessionActive  = prefs.getBoolean("session_active", false)
            val sessionEndTime = prefs.getLong("session_end_time", 0L)

            if (sessionActive && sessionEndTime > System.currentTimeMillis()) {
                // Session still has time remaining — restart the VPN
                val vpnIntent = Intent(context, VpnKillService::class.java)
                vpnIntent.putExtra("end_time", sessionEndTime)
                context.startForegroundService(vpnIntent)
            } else if (sessionActive) {
                // Session expired during reboot — clear it
                prefs.edit()
                    .putBoolean("session_active", false)
                    .apply()
            }
        }
    }
}