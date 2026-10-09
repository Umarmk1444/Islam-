import 'package:flutter/material.dart';
import '../core/database/hadith_database_helper.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import 'hadith_books_screen.dart';
import 'hadith_search_screen.dart';

class HadithCollectionsScreen extends StatefulWidget {
  const HadithCollectionsScreen({super.key});

  @override
  State<HadithCollectionsScreen> createState() => _HadithCollectionsScreenState();
}

class _HadithCollectionsScreenState extends State<HadithCollectionsScreen> {
  final HadithService _hadithService = HadithService();
  List<HadithCollection> _collections = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _hadithService.getCollections();
      if (mounted) {
        setState(() {
          _collections = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HadithCollectionsScreen] Error loading collections: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final screenBg = AppTheme.getScreenBgColor(theme);
        final cardBg = AppTheme.getPageBgColor(theme);
        final textColor = theme == QuranTheme.dark ? Colors.white : const Color(0xFF2C2416);
        final isDark = theme == QuranTheme.dark;

        final kutubSittah = _collections.where((c) => c.sortOrder <= 6).toList();
        final secondaryCollections = _collections.where((c) => c.sortOrder > 6).toList();

        Widget bodyContent;
        if (_isLoading) {
          bodyContent = _buildLoadingView(textColor, isDark);
        } else if (_errorMessage != null) {
          bodyContent = _buildErrorView(textColor, cardBg, isDark);
        } else {
          bodyContent = ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // Grand Header Banner
              _buildGrandBanner(isDark),
              const SizedBox(height: 18),

              // Section 1: الكتب الستة (The Six Canonical Books)
              _buildSectionHeader('الكتب الستة المعتمدة', Icons.stars_rounded, textColor),
              const SizedBox(height: 10),
              ...kutubSittah.map((col) => _buildCollectionCard(col, cardBg, textColor, isDark)),

              const SizedBox(height: 18),

              // Section 2: الجوامع والمصنفات الأخرى
              _buildSectionHeader('الجوامع والمصنفات المعتمدة', Icons.auto_stories_rounded, textColor),
              const SizedBox(height: 10),
              ...secondaryCollections.map((col) => _buildCollectionCard(col, cardBg, textColor, isDark)),
              const SizedBox(height: 16),
            ],
          );
        }

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0.5,
            centerTitle: true,
            iconTheme: IconThemeData(color: textColor),
            title: Text(
              'موسوعة الحديث الشريف',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'البحث في الحديث الشريف',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
                  );
                },
              ),
            ],
          ),
          body: bodyContent,
        );
      },
    );
  }

  Widget _buildLoadingView(Color textColor, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: HadithDatabaseHelper.instance.isExtractingNotifier,
      builder: (context, isExtracting, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1B8A6B),
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isExtracting
                      ? 'جاري تهيئة موسوعة الحديث الشريف للمرة الأولى...'
                      : 'جاري تحميل الأحاديث الشريفة...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isExtracting
                      ? 'يتم فك ضغط 10 دواوين معتمدة (40,937 حديثاً شريفاً)\nيستغرق هذا الإجراء بضع ثوانٍ فقط...'
                      : 'يرجى الانتظار لحظات...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.7),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(Color textColor, Color cardBg, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 14),
              Text(
                'تعذر تحميل موسوعة الحديث الشريف',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'حدث خطأ أثناء فتح قاعدة البيانات. يمكنك إعادة المحاولة الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13.5,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadCollections,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrandBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F382A), const Color(0xFF1B5E46)]
              : [const Color(0xFF104A3A), const Color(0xFF1B8A6B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8A6B).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFFF3D27C), size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مكتبة السنة النبوية الشريفة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '10 دواوين معتمدة • 40,937 حديثاً شريفاً بالسند والترتيب الأصلي بدون إنترنت',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC68A2E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(
    HadithCollection col,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    final isSahihayn = col.slug == 'bukhari' || col.slug == 'muslim';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSahihayn
              ? const Color(0xFFC9A84C).withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          width: isSahihayn ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HadithBooksScreen(collection: col)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Rank / Order Avatar
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSahihayn
                          ? const [Color(0xFF8D5B18), Color(0xFFC68A2E)]
                          : const [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${col.sortOrder}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.nameAr,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isSahihayn) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC68A2E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'صحيح',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC68A2E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        col.authorAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatPill('${col.totalBooks} كتاباً', textColor),
                          if (col.hasChapters && col.totalChapters > 0)
                            _buildStatPill('${col.totalChapters} باباً', textColor),
                          _buildStatPill('${col.totalHadiths} حديثاً', const Color(0xFF1B8A6B)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: textColor.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
