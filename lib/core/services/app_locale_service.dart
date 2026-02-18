import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleService {
  AppLocaleService._();

  static const _localeKey = 'youneka_locale';
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('id'));

  static Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return;
    localeNotifier.value = Locale(code);
  }

  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    localeNotifier.value = Locale(languageCode);
  }
}

