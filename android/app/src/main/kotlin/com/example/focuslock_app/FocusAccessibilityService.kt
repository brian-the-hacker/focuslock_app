package com.example.focuslock_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class FocusAccessibilityService : AccessibilityService() {

    companion object {
        var isEnabled = false

        // Screens to block during a session
        private val BLOCKED_PACKAGES = setOf(
            "com.android.settings",
            "com.android.vpndialogs",
            "com.transsion.settings",    // itel/Transsion settings
            "com.mediatek.settings",
        )

        private val BLOCKED_CLASSES = setOf(
            "com.android.settings.vpn2.VpnSettings",
            "com.android.settings.Settings\$VpnSettingsActivity",
            "com.android.settings.network.NetworkDashboardFragment",
        )
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isEnabled = true
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Only enforce if a session is active
        val prefs = getSharedPreferences(
            VpnKillService.PREFS_NAME, Context.MODE_PRIVATE)
        val sessionActive  = prefs.getBoolean("session_active", false)
        val sessionEndTime = prefs.getLong("session_end_time", 0L)

        if (!sessionActive || System.currentTimeMillis() > sessionEndTime) return

        val packageName = event.packageName?.toString() ?: return
        val className   = event.className?.toString() ?: ""

        // Check if user opened a blocked screen
        val isBlockedPackage = packageName in BLOCKED_PACKAGES
        val isBlockedClass   = BLOCKED_CLASSES.any { className.contains(it) }
        val isVpnRelated     = className.contains("vpn", ignoreCase = true) ||
                               className.contains("Vpn", ignoreCase = false)

        if (isBlockedPackage || isBlockedClass || isVpnRelated) {
            // Go back immediately
            performGlobalAction(GLOBAL_ACTION_BACK)

            // Show toast-like notification
            android.widget.Toast.makeText(
                this,
                "🔒 Settings blocked during Focus Lock session",
                android.widget.Toast.LENGTH_SHORT
            ).show()
        }
    }

    override fun onInterrupt() {
        isEnabled = false
    }

    override fun onDestroy() {
        super.onDestroy()
        isEnabled = false
    }
}