import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider {
  static const String _localeKey = 'app_locale';
  
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeStr = prefs.getString(_localeKey);
    if (localeStr != null && localeStr.isNotEmpty) {
      final parts = localeStr.split('_');
      if (parts.isNotEmpty) {
        return Locale(parts[0]);
      }
    }
    return null;
  }
  
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.toString());
  }
  
  static Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
  }
  
  static List<Map<String, dynamic>> getSupportedLanguages() {
    return [
      {
        'code': 'system',
        'name': 'systemLanguage',
        'locale': null,
      },
      {
        'code': 'en',
        'name': 'english',
        'locale': const Locale('en'),
      },
      {
        'code': 'zh',
        'name': 'chinese',
        'locale': const Locale('zh'),
      },
    ];
  }
}
