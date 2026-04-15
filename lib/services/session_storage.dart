import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _keyActive      = 'session_active';
  static const _keySessionId   = 'session_id';
  static const _keyEndTime     = 'session_end_time';
  static const _keyMode        = 'session_mode';
  static const _keyDuration    = 'session_duration';
  static const _keyPreviewCoins = 'session_preview_coins';
  static const _keySetupDone   = 'setup_complete';

  // ── Session persistence ───────────────────────────────────

  static Future<void> saveSession({
    required int sessionId,
    required int durationMins,
    required String mode,
    required double previewCoins,
    required int endTimeMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActive, true);
    await prefs.setInt(_keySessionId, sessionId);
    await prefs.setInt(_keyEndTime, endTimeMs);
    await prefs.setString(_keyMode, mode);
    await prefs.setInt(_keyDuration, durationMins);
    await prefs.setDouble(_keyPreviewCoins, previewCoins);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActive, false);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyEndTime);
    await prefs.remove(_keyMode);
    await prefs.remove(_keyDuration);
    await prefs.remove(_keyPreviewCoins);
  }

  static Future<Map<String, dynamic>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final active  = prefs.getBool(_keyActive) ?? false;
    final endTime = prefs.getInt(_keyEndTime) ?? 0;

    if (!active || endTime < DateTime.now().millisecondsSinceEpoch) {
      await clearSession();
      return null;
    }

    return {
      'session_id':    prefs.getInt(_keySessionId) ?? 0,
      'end_time_ms':   endTime,
      'mode':          prefs.getString(_keyMode) ?? 'hybrid',
      'duration_mins': prefs.getInt(_keyDuration) ?? 0,
      'preview_coins': prefs.getDouble(_keyPreviewCoins) ?? 0.0,
    };
  }

  // ── Setup state ───────────────────────────────────────────

  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySetupDone) ?? false;
  }

  static Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupDone, true);
  }
}