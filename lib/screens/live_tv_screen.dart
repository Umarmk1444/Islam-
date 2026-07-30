import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import 'youtube_player_screen.dart';

class _LiveChannel {
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final List<Color> gradient;
  final IconData icon;
  final String videoId;

  const _LiveChannel({
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.gradient,
    required this.icon,
    required this.videoId,
  });
}

const List<_LiveChannel> _channels = [
  _LiveChannel(
    titleAr: 'المسجد الحرام – مكة المكرمة',
    titleEn: 'Masjid al-Haram – Makkah',
    subtitleAr: 'بث مباشر على مدار الساعة',
    gradient: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    icon: Icons.mosque_rounded,
    videoId: 'wawzF8i5yAo',
  ),
  _LiveChannel(
    titleAr: 'المسجد النبوي – المدينة المنورة',
    titleEn: 'Al-Masjid an-Nabawi – Madinah',
    subtitleAr: 'بث مباشر على مدار الساعة',
    gradient: [Color(0xFF065F46), Color(0xFF059669)],
    icon: Icons.location_city_rounded,
    videoId: 'rHWSRMcGGBQ',
  ),
];

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'البث المباشر',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  color: theme == QuranTheme.cream ? AppColors.emeraldDeep : textColor,
                ),
              ),
              actions: [
                const _PulsingLiveBadge(large: false).animate(onPlay: (c) => c.repeat()),
                const SizedBox(width: 12),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'استمع وشاهد بثاً مباشراً من أقدس البقاع',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.audioSubtitle.copyWith(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ).animate().fade(delay: 50.ms),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _channels.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          return _ChannelCard(
                            channel: _channels[i],
                            theme: theme,
                            textColor: textColor,
                            isDark: isDark,
                            delay: Duration(milliseconds: 100 + i * 130),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 13, color: textColor.withValues(alpha: 0.30)),
                        const SizedBox(width: 6),
                        Text(
                          'Powered by YouTube Official Live Streams',
                          style: AppTextStyles.audioSubtitle.copyWith(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.theme,
    required this.textColor,
    required this.isDark,
    required this.delay,
  });

  final _LiveChannel channel;
  final QuranTheme theme;
  final Color textColor;
  final bool isDark;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.getCardBgColor(theme);
    final borderColor = theme == QuranTheme.cream
        ? const Color(0xFFC9A84C).withValues(alpha: 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.12));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YouTubePlayerScreen(
              videoId: channel.videoId,
              titleAr: channel.titleAr,
              titleEn: channel.titleEn,
              gradient: channel.gradient,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? cardBg.withValues(alpha: 0.85) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: channel.gradient.last.withValues(alpha: isDark ? 0.20 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.10 : 0.06,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: channel.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: channel.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: channel.gradient.last.withValues(alpha: 0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(channel.icon, color: Colors.white, size: 28),
                        ),
                        const _PulsingLiveBadge(large: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      channel.titleAr,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme == QuranTheme.cream
                            ? AppColors.emeraldDeep
                            : textColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channel.titleEn,
                      style: AppTextStyles.audioSubtitle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: channel.gradient.last.withValues(alpha: isDark ? 0.90 : 0.80),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      channel.subtitleAr,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.audioSubtitle.copyWith(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: channel.gradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: channel.gradient.last.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'شاهد الآن  ·  Watch Now',
                            style: AppTextStyles.audioSubtitle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: delay).slideY(begin: 0.08, delay: delay);
  }
}

// ── Pulsing LIVE badge ────────────────────────────────────────────────────────
class _PulsingLiveBadge extends StatelessWidget {
  const _PulsingLiveBadge({required this.large});
  final bool large;

  @override
  Widget build(BuildContext context) {
    final dot = large ? 8.0 : 6.0;
    final font = large ? 12.0 : 10.0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 8, vertical: large ? 5 : 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dot,
            height: dot,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .fade(begin: 1.0, end: 0.2, duration: 900.ms, curve: Curves.easeInOut)
              .then()
              .fade(begin: 0.2, end: 1.0, duration: 900.ms),
          SizedBox(width: large ? 6 : 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: font,
              fontWeight: FontWeight.w800,
              color: Colors.red,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
