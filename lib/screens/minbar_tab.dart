import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';
import 'audio_categories_screen.dart';
import 'minbar_downloads_screen.dart';
import 'live_radio_screen.dart';
import 'live_tv_screen.dart';
import '../l10n/app_localizations.dart';

class MinbarTab extends StatelessWidget {
  const MinbarTab({super.key});

  static const Map<String, Map<String, String>> _l10n = {
    'en': {
      'header_subtitle': 'Holy Quran recitations, Islamic lessons & live streaming',
      'live_section': 'Live Broadcasts',
      'live_radio_title': 'Live Radios',
      'live_radio_sub': '175+ Stations',
      'live_tv_title': 'Haramain TV',
      'live_tv_sub': 'Makkah & Madinah HD',
      'sections_title': 'Audio Library Sections',
      'quran_title': 'Holy Quran',
      'quran_sub': 'Recitations by 100+ renowned reciters',
      'quran_badge': '100+ Reciters',
      'dawah_title': 'Arabic Dawah',
      'dawah_sub': 'Lectures, Ruqyah & Dua',
      'downloads_title': 'My Downloads',
      'downloads_sub': 'Offline audio files',
      'regional_title': 'Amharic & Oromo Dawah',
      'regional_sub': 'Lectures & audio translations',
      'coming_soon': 'Coming Soon',
    },
    'ar': {
      'header_subtitle': 'تلاوات القرآن الكريم والدروس الإسلامية والبث المباشر',
      'live_section': 'البث المباشر الحي',
      'live_radio_title': 'الإذاعات الإسلامية',
      'live_radio_sub': '١٧٥+ محطة وقارئ',
      'live_tv_title': 'تلفزيون الحرمين',
      'live_tv_sub': 'مكة والمدينة مباشر HD',
      'sections_title': 'أقسام المكتبة الصوتية',
      'quran_title': 'القرآن الكريم',
      'quran_sub': 'تلاوات ومصاحف كبار القراء',
      'quran_badge': '١٠٠+ قارئ',
      'dawah_title': 'الدروس والخطب',
      'dawah_sub': 'محاضرات ورقيا وأدعية',
      'downloads_title': 'المحفوظات',
      'downloads_sub': 'الاستماع بدون إنترنت',
      'regional_title': 'الدروس (አማርኛ & Oromoo)',
      'regional_sub': 'محاضرات وترجمات صوتية ميسرة',
      'coming_soon': 'قريباً',
    },
    'am': {
      'header_subtitle': 'የቅዱስ ቁርኣን ንባቦች፣ ኢስላማዊ ትምህርቶች እና የቀጥታ ስርጭቶች',
      'live_section': 'የቀጥታ ስርጭቶች',
      'live_radio_title': 'የቀጥታ ሬዲዮ',
      'live_radio_sub': '175+ ጣቢያዎች',
      'live_tv_title': 'የሐረመይን ቴሌቪዥን',
      'live_tv_sub': 'መካ እና መዲና በቀጥታ',
      'sections_title': 'የድምጽ ላይብረሪ ክፍሎች',
      'quran_title': 'ቅዱስ ቁርኣን',
      'quran_sub': 'በ100+ ታዋቂ ቃሪኦች የተደረጉ ንባቦች',
      'quran_badge': '100+ ቃሪኦች',
      'dawah_title': 'አረብኛ ዳዕዋ',
      'dawah_sub': 'ትምህርቶች፣ ሩቅያህ እና ዱዓ',
      'downloads_title': 'የወረዱ ፋይሎች',
      'downloads_sub': 'ከኢንተርኔት ውጭ ማዳመጥ',
      'regional_title': 'የአማርኛ እና ኦሮምኛ ዳዕዋ',
      'regional_sub': 'ትምህርቶች እና የድምጽ ትርጉሞች',
      'coming_soon': 'በቅርቡ',
    },
    'om': {
      'header_subtitle': 'Qiraatii Qur\'aanaa, barnoota Islaamaa fi tamsaasa kallattii',
      'live_section': 'Tamsaasa Kallattii',
      'live_radio_title': 'Raadiyoo Kallattii',
      'live_radio_sub': 'Buufataalee 175+',
      'live_tv_title': 'Tv Haramayn',
      'live_tv_sub': 'Makkaa fi Madiinaa HD',
      'sections_title': 'Kutaalee Kuusaa Sagalee',
      'quran_title': 'Qur\'aana Kabajamaa',
      'quran_sub': 'Qiraatii qari\'oota 100+ ol',
      'quran_badge': 'Qari\'oota 100+',
      'dawah_title': 'Da\'waa Arabaa',
      'dawah_sub': 'Gorsawwan, Ruqiyaa fi Du\'aa',
      'downloads_title': 'Kuusaa Buufataa',
      'downloads_sub': 'Tajaajila toora malee',
      'regional_title': 'Da\'waa Afaan Oromoo fi Amaaraa',
      'regional_sub': 'Gorsawwan fi hiika sagalee',
      'coming_soon': 'Dhiyootti',
    },
  };

  String _tr(BuildContext context, String key) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    return _l10n[lang]?[key] ?? _l10n['ar']?[key] ?? _l10n['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;

        final textColor = AppTheme.getMainTextColor(theme);
        final l10n = AppLocalizations.of(context)!;
        final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

        final Color primaryAccent = isDark
            ? const Color(0xFF2ECC9A)
            : (isCream ? const Color(0xFF8B5319) : const Color(0xFF1B8A6B));

        final Color cardBg = AppTheme.getCardBgColor(theme);

        final Color borderColor = isCream
            ? const Color(0xFFC9A84C).withValues(alpha: 0.35)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06));

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.navMinbar,
              style: AppTextStyles.headlineMedium.copyWith(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isCream ? AppColors.emeraldDeep : textColor,
              ),
            ),
          ),
          body: ValueListenableBuilder<bool>(
            valueListenable: kAdVisibleNotifier,
            builder: (context, isAdVisible, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, isAdVisible ? 94 : 84),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Clean Subtitle ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              _tr(context, 'header_subtitle'),
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.65),
                                fontFamily: isArabic ? 'Amiri' : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // ── LIVE BROADCAST SHOWCASE (Dual Hero Grid) ──
                          _buildSectionHeader(
                            context: context,
                            title: _tr(context, 'live_section'),
                            isArabic: isArabic,
                            textColor: textColor,
                            accentColor: primaryAccent,
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // Live Islamic Radios Hero Card
                              Expanded(
                                child: _buildLiveHubCard(
                                  context: context,
                                  title: _tr(context, 'live_radio_title'),
                                  subtitle: _tr(context, 'live_radio_sub'),
                                  icon: Icons.radio_rounded,
                                  isLive: true,
                                  gradient: isDark
                                      ? const [Color(0xFF0F3D2C), Color(0xFF1B6B4E)]
                                      : [const Color(0xFF0E5B3E), const Color(0xFF1B8A6B)],
                                  accentGlow: const Color(0xFF2ECC9A),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LiveRadioScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Live Makkah & Madinah TV Hero Card
                              Expanded(
                                child: _buildLiveHubCard(
                                  context: context,
                                  title: _tr(context, 'live_tv_title'),
                                  subtitle: _tr(context, 'live_tv_sub'),
                                  icon: Icons.mosque_rounded,
                                  isLive: true,
                                  gradient: isDark
                                      ? const [Color(0xFF121B3B), Color(0xFF1E2F68)]
                                      : [const Color(0xFF1A2A6C), const Color(0xFF274496)],
                                  accentGlow: const Color(0xFF3B82F6),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LiveTvScreen()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── MAIN AUDIO PILLARS (Bento Islamic Showcase) ──
                          _buildSectionHeader(
                            context: context,
                            title: _tr(context, 'sections_title'),
                            isArabic: isArabic,
                            textColor: textColor,
                            accentColor: primaryAccent,
                          ),
                          const SizedBox(height: 8),

                          // 1. Holy Quran Recitations (Prominent Wide Card)
                          _buildQuranHeroCard(
                            context: context,
                            theme: theme,
                            isDark: isDark,
                            isCream: isCream,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            isArabic: isArabic,
                            title: _tr(context, 'quran_title'),
                            subtitle: _tr(context, 'quran_sub'),
                            badge: _tr(context, 'quran_badge'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AudioCategoriesScreen(onlyQuran: true),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // 2. Bento 2-Column (Arabic Dawah & My Downloads)
                          Row(
                            children: [
                              // Arabic Dawah Card
                              Expanded(
                                child: _buildBentoPillarCard(
                                  context: context,
                                  theme: theme,
                                  isDark: isDark,
                                  isCream: isCream,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  isArabic: isArabic,
                                  title: _tr(context, 'dawah_title'),
                                  subtitle: _tr(context, 'dawah_sub'),
                                  icon: Icons.record_voice_over_rounded,
                                  iconGradient: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AudioCategoriesScreen(excludeQuran: true),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // My Downloads Card
                              Expanded(
                                child: _buildBentoPillarCard(
                                  context: context,
                                  theme: theme,
                                  isDark: isDark,
                                  isCream: isCream,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  isArabic: isArabic,
                                  title: _tr(context, 'downloads_title'),
                                  subtitle: _tr(context, 'downloads_sub'),
                                  icon: Icons.download_done_rounded,
                                  iconGradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MinbarDownloadsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // 3. African / Regional Languages Card (Amharic & Oromo)
                          _buildRegionalLanguagesCard(
                            context: context,
                            theme: theme,
                            isDark: isDark,
                            isCream: isCream,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            isArabic: isArabic,
                            title: _tr(context, 'regional_title'),
                            subtitle: _tr(context, 'regional_sub'),
                            comingSoonText: _tr(context, 'coming_soon'),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Persistent Floating Audio Bar
                  const PersistentAudioBar(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── Section Header with Dot Accent ──
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required bool isArabic,
    required Color textColor,
    required Color accentColor,
  }) {
    return Row(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
            fontFamily: isArabic ? 'Amiri' : null,
          ),
        ),
      ],
    );
  }

  // ── Live Hub Hero Card (Dual Column for Radio & TV) ──
  Widget _buildLiveHubCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isLive,
    required List<Color> gradient,
    required Color accentGlow,
    required VoidCallback onTap,
  }) {
    return LiquidPressable(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Quran Hero Card (Wide Bento Pillar) ──
  Widget _buildQuranHeroCard({
    required BuildContext context,
    required QuranTheme theme,
    required bool isDark,
    required bool isCream,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required bool isArabic,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    final gradient = isDark
        ? const [Color(0xFF0D281E), Color(0xFF133F30)]
        : (isCream
            ? [const Color(0xFFF9F5EC), const Color(0xFFF0E8D7)]
            : [Colors.white, const Color(0xFFF0FDF4)]);

    final Color emeraldHighlight = isDark
        ? const Color(0xFF2ECC9A)
        : (isCream ? const Color(0xFF8B5319) : const Color(0xFF0F766E));

    return LiquidPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCream ? const Color(0xFFD4AF37).withValues(alpha: 0.4) : borderColor,
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Glowing Quran Medallion
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1B8A6B), const Color(0xFF0D5A42)]
                      : [const Color(0xFF0F766E), const Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: isArabic ? 'Amiri' : null,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isCream ? AppColors.emeraldDeep : textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: emeraldHighlight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: emeraldHighlight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: textColor.withValues(alpha: 0.3),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  // ── Bento Pillar Card (Arabic Dawah & My Downloads) ──
  Widget _buildBentoPillarCard({
    required BuildContext context,
    required QuranTheme theme,
    required bool isDark,
    required bool isCream,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required bool isArabic,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required VoidCallback onTap,
  }) {
    return LiquidPressable(
      onTap: onTap,
      child: Container(
        height: 122,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textColor.withValues(alpha: 0.25),
                  size: 13,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: isArabic ? 'Amiri' : null,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCream ? AppColors.emeraldDeep : textColor,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Regional African Languages Card (Amharic & Afaan Oromo) ──
  Widget _buildRegionalLanguagesCard({
    required BuildContext context,
    required QuranTheme theme,
    required bool isDark,
    required bool isCream,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required bool isArabic,
    required String title,
    required String subtitle,
    required String comingSoonText,
  }) {
    return LiquidPressable(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'الدروس باللغات الإفريقية (أمهري وأورومي) - قريباً بإذن الله'
                  : 'Amharic & Oromo Islamic Dawah - Coming Soon InshaAllah',
              textAlign: TextAlign.center,
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.language_rounded, color: Colors.white, size: 19),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCream ? AppColors.emeraldDeep : textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), width: 0.8),
              ),
              child: Text(
                comingSoonText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
