import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/plan_template_bridge.dart';

class TemplateLibraryStorage {
  TemplateLibraryStorage._();

  static const String _customTemplatesKey = 'youneka_custom_templates_v1';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<PlanTemplatePreset>> loadCustomTemplates() async {
    final prefs = await _instance();
    final raw = prefs.getString(_customTemplatesKey);
    if (raw == null || raw.isEmpty) return const <PlanTemplatePreset>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PlanTemplatePreset>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => PlanTemplatePreset(
              id: '${item['id'] ?? ''}',
              title: '${item['title'] ?? ''}',
              durationMinutes:
                  (item['duration_minutes'] as num?)?.toInt() ?? 25,
              note: '${item['note'] ?? ''}',
            ),
          )
          .where((item) => item.id.isNotEmpty && item.title.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const <PlanTemplatePreset>[];
    }
  }

  static Future<void> saveCustomTemplates(
    List<PlanTemplatePreset> templates,
  ) async {
    final prefs = await _instance();
    final raw = jsonEncode(
      templates
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'title': item.title,
              'duration_minutes': item.durationMinutes,
              'note': item.note,
            },
          )
          .toList(),
    );
    await prefs.setString(_customTemplatesKey, raw);
  }
}
