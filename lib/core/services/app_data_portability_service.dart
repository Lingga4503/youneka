import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDataPortabilityService {
  AppDataPortabilityService._();

  static Future<String> exportToJsonFile() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final payload = <String, dynamic>{};
    for (final key in keys) {
      payload[key] = prefs.get(key);
    }
    final data = jsonEncode({
      'app': 'youneka',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'prefs': payload,
    });
    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}\\youneka_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(data);
    return file.path;
  }

  static Future<bool> importFromJsonFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['prefs'] is! Map) return false;

    final prefs = await SharedPreferences.getInstance();
    final map = Map<String, dynamic>.from(decoded['prefs'] as Map);
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(entry.key, value.cast<String>());
      }
    }
    return true;
  }
}

