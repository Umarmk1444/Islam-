import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static final ValueNotifier<Locale> notifier = ValueNotifier(const Locale('en'));

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language') ?? 'English';
    notifier.value = _getLocaleFromLangString(lang);
  }

  static Future<void> changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    notifier.value = _getLocaleFromLangString(lang);
  }

  static Locale _getLocaleFromLangString(String lang) {
    switch (lang) {
      case 'Amharic':
        return const Locale('am');
      case 'Oromo':
        return const Locale('om');
      case 'Arabic':
        return const Locale('ar');
      case 'English':
      default:
        return const Locale('en');
    }
  }
}
