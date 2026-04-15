import 'package:flutter/services.dart';

class VpnKillService {
  static const _channel = MethodChannel('focuslock/vpn');
  static bool isRunningSync = false; // local cache

  static Future<bool> requestPermissionAndStart({int endTimeMs = 0}) async {
    try {
      final result = await _channel.invokeMethod('startVpn', {
        'end_time': endTimeMs,
      });
      isRunningSync = result == true;
      return isRunningSync;
    } catch (e) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopVpn');
      isRunningSync = false;
    } catch (e) {}
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod('isVpnRunning');
      isRunningSync = result == true;
      return isRunningSync;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _channel.invokeMethod('checkAccessibility');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {}
  }
}