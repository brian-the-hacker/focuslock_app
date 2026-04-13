import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/stats.dart';
import '../models/session.dart';

class ApiService {
  static const String baseUrl = 'https://web-production-1e4ea.up.railway.app';
  static const _storage = FlutterSecureStorage();

  // ── Token management ──────────────────────────────────────

  static Future<String?> getToken() => _storage.read(key: 'token');

  static Future<void> saveToken(String token, String username, int userId) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'user_id', value: userId.toString());
  }

  static Future<void> clearToken() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<String?> getUsername() => _storage.read(key: 'username');

  // ── HTTP helpers ──────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> _get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  // ── Auth ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final result = await _post('/auth/register', {
      'username': username,
      'email':    email,
      'password': password,
    });
    if (result['access_token'] != null) {
      await saveToken(
          result['access_token'], result['username'], result['user_id']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final result = await _post('/auth/login', {
      'username': username,
      'password': password,
    });
    if (result['access_token'] != null) {
      await saveToken(
          result['access_token'], result['username'], result['user_id']);
    }
    return result;
  }

  static Future<void> logout() => clearToken();

  // ── Sessions ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> startSession(
      int durationMins, String mode) async {
    return await _post('/sessions/start', {
      'duration_mins': durationMins,
      'mode':          mode,
    });
  }

  static Future<Map<String, dynamic>> completeSession(
      int sessionId, bool completed,
      {int minutesCompleted = 0}) async {
    return await _post('/sessions/complete', {
      'session_id':        sessionId,
      'completed':         completed,
      'minutes_completed': minutesCompleted,
    });
  }

  // ── Stats ─────────────────────────────────────────────────

  static Future<Stats> getStats() async {
    final data = await _get('/stats');
    return Stats.fromJson(data);
  }

  static Future<List<Session>> getHistory() async {
    final data = await _get('/sessions/history?limit=20');
    return (data as List).map((s) => Session.fromJson(s)).toList();
  }

  // ── Leaderboard ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final data = await _get('/leaderboard');
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Emergency exit ────────────────────────────────────────

  static Future<Map<String, dynamic>> requestEmergencyExit(
      int sessionId, String reason) async {
    return await _post('/emergency/request?session_id=$sessionId&reason=${Uri.encodeComponent(reason)}', {});
  }

  static Future<Map<String, dynamic>> checkEmergencyStatus(
      int sessionId) async {
    final data = await _get('/emergency/status/$sessionId');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> redeemEmergencyCode(
      int sessionId, String code) async {
    return await _post('/emergency/redeem?session_id=$sessionId&code=$code', {});
  }
}