import 'package:flutter/material.dart';

/// Unified design-token color palette for the Islamic Super App.
/// All colors are defined here; no magic hex values in widget files.
abstract final class AppColors {
  // ─── Brand Palette ───────────────────────────────────────────────────────
  static const Color emeraldDeep   = Color(0xFF0D4F3C); // primary dark
  static const Color emeraldMid    = Color(0xFF1A7A5E); // primary normal
  static const Color emeraldLight  = Color(0xFF2ECC9A); // primary accent
  static const Color goldDeep      = Color(0xFFB8860B); // gold deep
  static const Color goldMid       = Color(0xFFD4A017); // gold normal
  static const Color goldLight     = Color(0xFFFFD966); // gold accent / highlight

  // ─── Surface & Background ────────────────────────────────────────────────
  static const Color surfaceDark   = Color(0xFF0A0F14); // main bg dark mode
  static const Color surfaceCard   = Color(0xFF111B26); // card bg dark mode
  static const Color surfaceElevated = Color(0xFF1A2535); // elevated card
  static const Color surfaceLight  = Color(0xFFF4F7F2); // main bg light mode
  static const Color surfaceCardLight = Color(0xFFFFFFFF); // card bg light mode

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4F0);
  static const Color textSecondary = Color(0xFF9BAAAA);
  static const Color textMuted     = Color(0xFF5E7070);
  static const Color textOnGold    = Color(0xFF1A1200);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color prayerFajr    = Color(0xFF4A90D9); // predawn blue
  static const Color prayerSunrise = Color(0xFFFF8C42); // sunrise orange
  static const Color prayerDhuhr   = Color(0xFFFFD166); // midday gold
  static const Color prayerAsr     = Color(0xFF06D6A0); // afternoon teal
  static const Color prayerMaghrib = Color(0xFFEF476F); // sunset rose
  static const Color prayerIsha    = Color(0xFF8B5CF6); // night violet
  static const Color prayerTahajjud = Color(0xFF1E293B); // last third deep navy

  static const Color streakFlame   = Color(0xFFFF6B35); // active streak
  static const Color streakGrey    = Color(0xFF4B5563); // inactive streak

  static const Color audioActive   = Color(0xFF2ECC9A);
  static const Color audioPaused   = Color(0xFF9BAAAA);
  static const Color audioLive     = Color(0xFFEF4444); // red dot

  static const Color communityBadgeGold    = Color(0xFFFFD966);
  static const Color communityBadgeSilver  = Color(0xFFC0C0C0);
  static const Color communityBadgeBronze  = Color(0xFFCD7F32);

  static const Color divider       = Color(0xFF1E2D3D);
  static const Color shimmerBase   = Color(0xFF1A2535);
  static const Color shimmerHighlight = Color(0xFF2A3A50);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient miqatNight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF1A2A4A)],
  );
  static const LinearGradient miqatDay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D4F3C), Color(0xFF1A7A5E)],
  );
  static const LinearGradient miqatSunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B2D00), Color(0xFFFF8C42)],
  );
  static const LinearGradient goldAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8860B), Color(0xFFFFD966)],
  );
}
