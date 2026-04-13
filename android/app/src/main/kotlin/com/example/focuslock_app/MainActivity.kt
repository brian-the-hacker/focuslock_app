package com.example.focuslock_app

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "focuslock/vpn"
    private val ACCESSIBILITY_CHANNEL = "focuslock/accessibility"  // New channel for accessibility
    private val VPN_REQUEST_CODE = 100
    private var pendingResult: MethodChannel.Result? = null
    private var pendingEndTime: Long = 0L  // ← store endTime for onActivityResult

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // VPN Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startVpn" -> {
                        pendingResult  = result
                        pendingEndTime = call.argument<Long>("end_time") ?: 0L

                        // Save to prefs for boot recovery
                        if (pendingEndTime > 0) {
                            getSharedPreferences("focuslock_prefs", MODE_PRIVATE)
                                .edit()
                                .putBoolean("session_active", true)
                                .putLong("session_end_time", pendingEndTime)
                                .apply()
                        }

                        val intent = VpnService.prepare(this)
                        if (intent != null) {
                            // Need user permission — show dialog
                            startActivityForResult(intent, VPN_REQUEST_CODE)
                        } else {
                            // Already have permission — start immediately
                            startVpnService(pendingEndTime)
                            result.success(true)
                            pendingResult = null
                        }
                    }

                    "stopVpn" -> {
                        getSharedPreferences("focuslock_prefs", MODE_PRIVATE)
                            .edit()
                            .putBoolean("session_active", false)
                            .remove("session_end_time")
                            .apply()

                        val stopIntent = Intent(this, VpnKillService::class.java)
                        stopIntent.action = "STOP"
                        startService(stopIntent)
                        result.success(true)
                    }

                    "isVpnRunning" -> {
                        result.success(VpnKillService.isRunning)
                    }

                    else -> result.notImplemented()
                }
            }
        
        // Accessibility Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibility" -> {
                        val enabled = isAccessibilityEnabled()
                        result.success(enabled)
                    }
                    "openAccessibilitySettings" -> {
                        val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startVpnService(endTime: Long = 0L) {
        val intent = Intent(this, VpnKillService::class.java)
        if (endTime > 0) intent.putExtra("end_time", endTime)
        startForegroundService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                // Permission granted — start with stored endTime
                startVpnService(pendingEndTime)
                pendingResult?.success(true)
            } else {
                // Permission denied — clear prefs
                getSharedPreferences("focuslock_prefs", MODE_PRIVATE)
                    .edit()
                    .putBoolean("session_active", false)
                    .remove("session_end_time")
                    .apply()
                pendingResult?.success(false)
            }
            pendingResult  = null
            pendingEndTime = 0L
        }
    }
    
    // Helper function to check if accessibility service is enabled
    private fun isAccessibilityEnabled(): Boolean {
        val service = "${packageName}/${FocusAccessibilityService::class.java.canonicalName}"
        val enabled = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.contains(service)
    }
}