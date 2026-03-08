import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/home_models.dart';

class HomeStateStorage {
  HomeStateStorage._();

  static const String _stateKey = 'youneka_home_state_v1';

  static Future<HomeStateSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return HomeStateSnapshot.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(HomeStateSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(snapshot.toMap());
    await prefs.setString(_stateKey, raw);
  }
}
