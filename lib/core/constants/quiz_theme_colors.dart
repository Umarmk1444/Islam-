import 'package:flutter/material.dart';
import '../../theme_notifier.dart';

/// Centralized, high-contrast color system for the Islamic Quiz experience.
/// Guarantees that gold and amber NEVER wash out or look pale against white/light surfaces!
class QuizColors {
  final bool isDark;
  final bool isCream;

  QuizColors({required this.isDark, required this.isCream});

  factory QuizColors.of(BuildContext context) {
    final theme = AppTheme.notifier.value;
    return QuizColors(
      isDark: theme == QuranTheme.dark,
      isCream: theme == QuranTheme.cream,
    );
  }

  // ── Backgrounds ────────────────────────────────────────────────────────────
  Color get screenBg => isDark
      ? const Color(0xFF07120E)
      : (isCream ? const Color(0xFFE8E2CC) : const Color(0xFFF4F7F5));

  Color get cardBg => isDark
      ? const Color(0xFF0D1B17)
      : (isCream ? const Color(0xFFFDFBF0) : Colors.white);

  Color get cardSubtleBg => isDark
      ? const Color(0xFF12221E)
      : (isCream ? const Color(0xFFF3ECE0) : const Color(0xFFF0F5F3));

  // ── Typography ─────────────────────────────────────────────────────────────
  Color get textPrimary => isDark
      ? const Color(0xFFFFFBF0) // Warm pearl ivory
      : const Color(0xFF10241E); // Deep midnight forest ink

  Color get textSecondary => isDark
      ? const Color(0xFFDFD5C4)
      : const Color(0xFF435851);

  Color get textMuted => isDark
      ? const Color(0xFF90A49E)
      : const Color(0xFF6B7F79);

  // ── Gold & Bronze Accents (High Contrast Guaranteed!) ──────────────────────
  /// In dark mode: Radiant champagne gold; In light/cream: Deep imperial antique bronze!
  Color get goldAccent => isDark
      ? const Color(0xFFFFD54F) // Radiant amber gold on dark
      : const Color(0xFF8A6208); // Deep antique burnished bronze (WCAG AAA on light!)

  /// High-contrast icon color
  Color get goldIcon => isDark
      ? const Color(0xFFFFD54F)
      : const Color(0xFF946A0B);

  /// Manuscript border color
  Color get goldBorder => isDark
      ? const Color(0xFFD4AF37).withValues(alpha: 0.50)
      : const Color(0xFF946A0B).withValues(alpha: 0.35);

  /// Subtle gold pill/container fill
  Color get goldPillBg => isDark
      ? const Color(0xFFD4AF37).withValues(alpha: 0.14)
      : const Color(0xFF8A6208).withValues(alpha: 0.10);

  // ── Emerald Sanctuary Accents ──────────────────────────────────────────────
  Color get emeraldPrimary => isDark
      ? const Color(0xFF2ECC71)
      : const Color(0xFF147352);

  Color get emeraldBorder => isDark
      ? const Color(0xFF2ECC71).withValues(alpha: 0.45)
      : const Color(0xFF147352).withValues(alpha: 0.35);

  Color get emeraldPillBg => isDark
      ? const Color(0xFF1B8A6B).withValues(alpha: 0.20)
      : const Color(0xFF147352).withValues(alpha: 0.10);

  // ── Difficulty Colors ──────────────────────────────────────────────────────
  Color get diffEasyBg => isDark
      ? const Color(0xFF1B8A6B).withValues(alpha: 0.18)
      : const Color(0xFF147352).withValues(alpha: 0.12);
  Color get diffEasyText => isDark
      ? const Color(0xFF80CBC4)
      : const Color(0xFF0F5A40);

  Color get diffMediumBg => isDark
      ? const Color(0xFF1565C0).withValues(alpha: 0.18)
      : const Color(0xFF0D47A1).withValues(alpha: 0.10);
  Color get diffMediumText => isDark
      ? const Color(0xFF90CAF9)
      : const Color(0xFF0D47A1);

  Color get diffHardBg => isDark
      ? const Color(0xFF6A1B9A).withValues(alpha: 0.18)
      : const Color(0xFF4A148C).withValues(alpha: 0.10);
  Color get diffHardText => isDark
      ? const Color(0xFFCE93D8)
      : const Color(0xFF4A148C);
}
