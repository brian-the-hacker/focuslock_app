import 'package:flutter/services.dart';

class VpnKillService {
  static const _channel = MethodChannel('focuslock/vpn');
  static const _accessibilityChannel = MethodChannel('focuslock/accessibility');

  static Future<bool> requestPermissionAndStart({int endTimeMs = 0}) async {
    try {
      final result = await _channel.invokeMethod('startVpn', {
        'end_time': endTimeMs,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopVpn');
    } catch (e) {}
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod('isVpnRunning');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // New accessibility methods
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _accessibilityChannel.invokeMethod('checkAccessibility');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _accessibilityChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {}
  }
}