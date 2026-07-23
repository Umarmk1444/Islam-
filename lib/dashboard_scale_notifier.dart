import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScale {
  static final ValueNotifier<double> notifier = ValueNotifier<double>(1.0);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    double scale = prefs.getDouble('dashboard_scale_factor') ?? 1.0;
    notifier.value = scale;
  }

  static Future<void> setScale(double scale) async {
    notifier.value = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dashboard_scale_factor', scale);
  }
}
