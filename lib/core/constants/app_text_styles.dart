import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unified typography system for the Islamic Super App.
/// Uses Google-font-compatible fallback stack.
/// Arabic text uses the Amiri family already declared in pubspec.yaml.
abstract final class AppTextStyles {
  // ─── Font Family Names ────────────────────────────────────────────────────
  static const String _latin   = 'Roboto';  // system default on Android / SF on iOS
  static const String _arabic  = 'Amiri';   // declared in pubspec.yaml

  // ─── Display ──────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _latin,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _latin,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  // ─── Headline ─────────────────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _latin,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _latin,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _latin,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _latin,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _latin,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ─── Label / Caption ──────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _latin,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _latin,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  // ─── Prayer Time Display ──────────────────────────────────────────────────
  static const TextStyle prayerTimeLarge = TextStyle(
    fontFamily: _latin,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle prayerTimeCountdown = TextStyle(
    fontFamily: _latin,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.goldLight,
    letterSpacing: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle prayerName = TextStyle(
    fontFamily: _latin,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );

  // ─── Arabic / Quran ───────────────────────────────────────────────────────
  static const TextStyle arabicAyah = TextStyle(
    fontFamily: _arabic,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 2.0,
  );

  static const TextStyle arabicSmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.8,
  );

  static const TextStyle arabicLabel = TextStyle(
    fontFamily: _arabic,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // ─── Streak / Stat Numbers ────────────────────────────────────────────────
  static const TextStyle statNumber = TextStyle(
    fontFamily: _latin,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.streakFlame,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle statLabel = TextStyle(
    fontFamily: _latin,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.6,
  );

  // ─── Tool Grid Labels ─────────────────────────────────────────────────────
  static const TextStyle toolGridLabel = TextStyle(
    fontFamily: _latin,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ─── Audio / Media ────────────────────────────────────────────────────────
  static const TextStyle audioTitle = TextStyle(
    fontFamily: _latin,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle audioSubtitle = TextStyle(
    fontFamily: _latin,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle liveTag = TextStyle(
    fontFamily: _latin,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 1.5,
  );
}
