import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import 'audio_categories_screen.dart';
import 'minbar_downloads_screen.dart';
import 'live_radio_screen.dart';
import 'live_tv_screen.dart';
import '../l10n/app_localizations.dart';

bool _globalHasAnimatedMinbar = false;

Widget _wrapAnim(Widget child, bool animate, int delayMs, {bool slideY = false}) {
  if (!animate) return child;
  if (slideY) return child.animate().fade(delay: delayMs.ms).slideY(begin: 0.2);
  return child.animate().fade(delay: delayMs.ms).slideX(begin: 0.1);
}

class MinbarTab extends StatelessWidget {
  const MinbarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool animate = !_globalHasAnimatedMinbar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _globalHasAnimatedMinbar = true;
    });

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.navMinbar,
              style: AppTextStyles.headlineMedium.copyWith(
                fontFamily: 'Amiri',
                fontSize: 22,
                color: theme == QuranTheme.cream
                    ? AppColors.emeraldDeep
                    : textColor,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _wrapAnim(
                        Text(
                          l10n.minbarHeaderSubtitle,
                          style: AppTextStyles.audioSubtitle.copyWith(
                            fontSize: 16,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        animate, 0, slideY: true,
                      ),

                      const SizedBox(height: 8),

                      _wrapAnim(
                        _buildUniformCard(
                          context: context,
                          theme: theme,
                          title: l10n.minbarQuranTitle,
                          subtitle: l10n.minbarQuranSubtitle,
                          icon: Icons.menu_book_rounded,
                          primaryGradient: [
                            AppColors.emeraldDeep,
                            AppColors.emeraldMid
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AudioCategoriesScreen(onlyQuran: true),
                              ),
                            );
                          },
                        ),
                        animate, 100,
                      ),

                      const SizedBox(height: 6),

                      _wrapAnim(
                        _buildUniformCard(
                          context: context,
                          theme: theme,
                          title: l10n.minbarDawahTitle,
                          subtitle: l10n.minbarDawahSubtitle,
                          icon: Icons.record_voice_over_rounded,
                          primaryGradient: [
                            isDark
                                ? Colors.indigo.shade400
                                : Colors.indigo.shade300,
                            isDark
                                ? Colors.indigo.shade600
                                : Colors.indigo.shade500,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AudioCategoriesScreen(
                                    excludeQuran: true),
                              ),
                            );
                          },
                        ),
                        animate, 200,
                      ),

                      const SizedBox(height: 6),

                      _wrapAnim(
                        _buildUniformCard(
                          context: context,
                          theme: theme,
                          title: l10n.minbarAmharicLessons,
                          subtitle: l10n.minbarComingSoon,
                          icon: Icons.language_rounded,
                          isPlaceholder: true,
                          primaryGradient: [
                            isDark ? Colors.teal.shade400 : Colors.teal.shade300,
                            isDark ? Colors.teal.shade600 : Colors.teal.shade500,
                          ],
                          onTap: () {},
                        ),
                        animate, 300,
                      ),

                      const SizedBox(height: 6),

                      _wrapAnim(
                        _buildUniformCard(
                          context: context,
                          theme: theme,
                          title: l10n.minbarOromoLessons,
                          subtitle: l10n.minbarComingSoon,
                          icon: Icons.language_rounded,
                          isPlaceholder: true,
                          primaryGradient: [
                            isDark ? Colors.cyan.shade400 : Colors.cyan.shade300,
                            isDark ? Colors.cyan.shade600 : Colors.cyan.shade500,
                          ],
                          onTap: () {},
                        ),
                        animate, 400,
                      ),

                      const SizedBox(height: 6),

                      _wrapAnim(
                        _buildUniformCard(
                          context: context,
                          theme: theme,
                          title: l10n.minbarDownloadsTitle,
                          subtitle: l10n.minbarDownloadsSubtitle,
                          icon: Icons.download_done_rounded,
                          primaryGradient: [
                            isDark
                                ? Colors.blueGrey.shade800
                                : Colors.blueGrey.shade600,
                            isDark
                                ? Colors.blueGrey.shade700
                                : Colors.blueGrey.shade400,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MinbarDownloadsScreen(),
                              ),
                            );
                          },
                        ),
                        animate, 500,
                      ),

                      const SizedBox(height: 12),

                      // ── LIVE BROADCASTS SECTION ──────────────────────────
                      _buildSectionTitle(
                          theme, textColor, 'البث المباشر · Live'),

                      const SizedBox(height: 8),

                      // Premium full-width Live Radio banner
                      _buildLiveRadioBanner(context, theme, textColor, isDark),

                      const SizedBox(height: 8),

                      // ── Live Makkah & Madinah TV Card ─────────────────────
                      _buildLiveTvBanner(context, theme, textColor, isDark),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const PersistentAudioBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUniformCard({
    required BuildContext context,
    required QuranTheme theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> primaryGradient,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    final isDark = theme == QuranTheme.dark;
    final cardBg = AppTheme.getCardBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);

    // Smooth Glassmorphism feel
    final borderColor = theme == QuranTheme.cream
        ? const Color(0xFFC9A84C).withValues(alpha: 0.3)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1));

    return GestureDetector(
      onTap: () {
        if (isPlaceholder) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title - ${l10n.minbarComingSoon}',
                  textAlign: TextAlign.center),
              backgroundColor: isDark ? cardBg : AppColors.emeraldDeep,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          onTap();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cardBg.withValues(alpha: 0.8) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color:
                  primaryGradient.last.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Icon Container (Proportional, glowing)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: primaryGradient.last.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.audioSubtitle.copyWith(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isPlaceholder)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: textColor.withValues(alpha: 0.4), size: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(QuranTheme theme, Color textColor, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme == QuranTheme.cream
                ? AppColors.emeraldDeep
                : const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                theme == QuranTheme.cream ? AppColors.emeraldDeep : textColor,
          ),
        ),
      ],
    );
  }

  // ── Full-width premium radio banner ─────────────────────────────────────
  Widget _buildLiveRadioBanner(
    BuildContext context,
    QuranTheme theme,
    Color textColor,
    bool isDark,
  ) {
    final borderColor = theme == QuranTheme.cream
        ? const Color(0xFFC9A84C).withValues(alpha: 0.4)
        : (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.withValues(alpha: 0.12));

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveRadioScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D2B1F), const Color(0xFF134E30)]
                : [
                    AppColors.emeraldDeep.withValues(alpha: 0.08),
                    AppColors.emeraldMid.withValues(alpha: 0.14),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emeraldDeep.withValues(alpha: isDark ? 0.25 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Glowing radio icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emeraldDeep, AppColors.emeraldMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldDeep.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.radio_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإذاعات الإسلامية',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '١٧٠+ إذاعة · قرآن · تفسير · أذكار · رقية',
                    style: AppTextStyles.audioSubtitle.copyWith(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Live badge + arrow
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: AppTextStyles.audioSubtitle.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textColor.withValues(alpha: 0.30),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Live TV banner (Makkah & Madinah in-app player) ──────────────────────
  Widget _buildLiveTvBanner(
    BuildContext context,
    QuranTheme theme,
    Color textColor,
    bool isDark,
  ) {
    const gradient = [Color(0xFF1A1A4E), Color(0xFF2D3A8C)];
    final borderColor = isDark
        ? const Color(0xFF2D3A8C).withValues(alpha: 0.50)
        : const Color(0xFF2563EB).withValues(alpha: 0.18);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveTvScreen()),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D1233), const Color(0xFF162055)]
                : [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.07),
                    const Color(0xFF2563EB).withValues(alpha: 0.13),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A)
                  .withValues(alpha: isDark ? 0.28 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with two mosque symbols stacked
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.mosque_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مكة المكرمة والمدينة المنورة',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Makkah & Madinah · Live 24/7 TV',
                    style: AppTextStyles.audioSubtitle.copyWith(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.38), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: AppTextStyles.audioSubtitle.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded,
                    color: textColor.withValues(alpha: 0.28), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
