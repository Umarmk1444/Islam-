import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum QuranTheme { cream, dark, white }

/// Single source of truth for the entire app's color system.
/// Option A — "الأصالة الإسلامية" : Emerald & Gold palette.
class AppTheme {
  static final ValueNotifier<QuranTheme> notifier =
      ValueNotifier<QuranTheme>(QuranTheme.cream);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    int themeIdx = prefs.getInt('quran_theme_index') ?? 0;
    if (themeIdx < 0 || themeIdx >= QuranTheme.values.length) themeIdx = 0;
    notifier.value = QuranTheme.values[themeIdx];
  }

  static void changeTheme(QuranTheme theme) async {
    notifier.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_theme_index', theme.index);
  }

  // ── Option A: Emerald & Gold Color Palette ────────────────────────────────
  //
  // Cream  → Warm Parchment / Sand Dune / Antique Gold / Deep Ink / Forest Green
  // Dark   → Midnight Mosque Green / Warm Gold / Cream Text
  // White  → Crisp White / Sage Green / Antique Gold

  /// Outer scaffold / screen background
  static Color getScreenBgColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFE8E2CC); // Sand Dune
      case QuranTheme.dark:
        return const Color(0xFF06100A); // Almost Black Moss
      case QuranTheme.white:
        return const Color(0xFFEFF4EF); // Mint-tinged White
    }
  }

  /// Mushaf page background
  static Color getPageBgColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFFDFBF0); // Warm Parchment
      case QuranTheme.dark:
        return const Color(0xFF0D1F17); // Midnight Mosque Green
      case QuranTheme.white:
        return Colors.white;
    }
  }

  /// Gold border / accent colour (for page borders, dividers, surah frames)
  static Color getBorderColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFC9A84C); // Antique Gold
      case QuranTheme.dark:
        return const Color(0xFFE8C77A); // Warm Bright Gold
      case QuranTheme.white:
        return const Color(0xFFC9A84C); // Same antique gold
    }
  }

  /// Smaller gold text (page numbers, juz labels, surah names)
  static Color getGoldTextColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFF7A5900); // Deep Antique Gold
      case QuranTheme.dark:
        return const Color(0xFFE8C77A); // Bright Warm Gold
      case QuranTheme.white:
        return const Color(0xFF7A5900); // Deep Antique Gold
    }
  }

  /// Primary Quranic Arabic text colour
  static Color getMainTextColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFF1A120B); // Warm Manuscript Ink
      case QuranTheme.dark:
        return const Color(0xFFE8DCC8); // Warm Cream
      case QuranTheme.white:
        return const Color(0xFF111827); // Near Black
    }
  }

  // ── Global App UI (AppBar, BottomNav, Dawah, Settings) ────────────────────

  static Color getAppBarBgColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFF1B4332); // Deep Forest Green
      case QuranTheme.dark:
        return const Color(0xFF0A180F); // Deeper than page, subtle separation
      case QuranTheme.white:
        return const Color(0xFF1B4332); // Same Forest Green for consistency
    }
  }

  static Color getAppBarTextColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFF0E6C8); // Warm Gold-White
      case QuranTheme.dark:
        return const Color(0xFFE8C77A); // Bright Gold
      case QuranTheme.white:
        return const Color(0xFFF0E6C8); // Warm Gold-White
    }
  }

  static Color getBottomBarBgColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFFDFBF0); // Matches page bg
      case QuranTheme.dark:
        return const Color(0xFF0D1F17); // Matches page bg
      case QuranTheme.white:
        return Colors.white;
    }
  }

  static Color getPrimaryColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFF1B4332); // Forest Green
      case QuranTheme.dark:
        return const Color(0xFFE8C77A); // Bright Gold
      case QuranTheme.white:
        return const Color(0xFF1B4332); // Forest Green
    }
  }

  /// Used for card/dialog backgrounds in Dawah + Settings
  static Color getCardBgColor(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.cream:
        return const Color(0xFFF5F0DC); // Slightly darker parchment
      case QuranTheme.dark:
        return const Color(0xFF142912); // Dark Moss
      case QuranTheme.white:
        return const Color(0xFFF8FAF8); // Off-white
    }
  }
}
