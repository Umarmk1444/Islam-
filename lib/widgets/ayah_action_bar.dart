import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';
import '../controllers/quran_audio_controller.dart';
import '../l10n/app_localizations.dart';
import 'verse_content_sheet.dart';
import 'verse_meanings_and_irab_sheet.dart';
import '../core/database/database_helper.dart';

/// Ultra-compact, icon-only floating action bar that appears when a user
/// taps an Ayah. Contains only icons with tooltips — no text labels.
class AyahActionBar extends StatefulWidget {
  final Map<String, dynamic> verseData;
  final VoidCallback onListen;
  final VoidCallback onClose;
  final Future<void> Function(int pageNumber, QuranReciter reciter)? onDownloadPage;
  final Future<bool> Function(int pageNumber)? onIsPageDownloaded;
  final bool isBookmarked;
  final VoidCallback? onBookmarkChanged;
  final VoidCallback onGoToBookmark;
  final VoidCallback onChangeTheme;
  final VoidCallback onOpenIndex;
  final VoidCallback onOpenSearch;

  const AyahActionBar({
    Key? key,
    required this.verseData,
    required this.onListen,
    required this.onClose,
    required this.isBookmarked,
    required this.onGoToBookmark,
    required this.onChangeTheme,
    required this.onOpenIndex,
    required this.onOpenSearch,
    this.onDownloadPage,
    this.onIsPageDownloaded,
    this.onBookmarkChanged,
  }) : super(key: key);

  @override
  State<AyahActionBar> createState() => _AyahActionBarState();
}

class _AyahActionBarState extends State<AyahActionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────

  QuranTheme get _theme => AppTheme.notifier.value;
  bool get _isDark => _theme == QuranTheme.dark;
  Color get _bg => _isDark
      ? const Color(0xFF0D1F17).withValues(alpha: 0.95)
      : AppTheme.getPageBgColor(_theme).withValues(alpha: 0.95);
  Color get _border => AppTheme.getBorderColor(_theme);
  Color get _gold => AppTheme.getGoldTextColor(_theme);
  Color get _text => AppTheme.getMainTextColor(_theme);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _copyAyah() async {
    final surahNum = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNum = widget.verseData['ayahNumber'] as int? ?? 1;
    final surahName = widget.verseData['surahName'] as String? ?? '';
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      'SELECT aya FROM quran WHERE sura_num = ? AND aya_num = ?',
      [surahNum, ayahNum],
    );
    final ayahText = res.isNotEmpty ? (res.first['aya'] as String? ?? '') : '';
    final formatted = '$ayahText\n\n﴿ سورة $surahName - الآية $ayahNum ﴾';
    await Clipboard.setData(ClipboardData(text: formatted));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ الآية',
              style: TextStyle(fontFamily: 'Amiri')),
          backgroundColor: _border,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareAyah() async {
    final surahNum = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNum = widget.verseData['ayahNumber'] as int? ?? 1;
    final surahName = widget.verseData['surahName'] as String? ?? '';
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      'SELECT aya FROM quran WHERE sura_num = ? AND aya_num = ?',
      [surahNum, ayahNum],
    );
    final ayahText = res.isNotEmpty ? (res.first['aya'] as String? ?? '') : '';
    final formatted = '$ayahText\n\n﴿ سورة $surahName - الآية $ayahNum ﴾';
    Share.share(formatted);
  }

  void _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final pageNumber = widget.verseData['page'] ?? 1;
    final surahNumber = widget.verseData['surahNumber'] ?? 1;
    final ayahNumber = widget.verseData['ayahNumber'] ?? 1;

    if (widget.isBookmarked) {
      await prefs.remove('bookmark_page');
      await prefs.remove('bookmark_surah');
      await prefs.remove('bookmark_ayah');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إزالة العلامة',
                style: TextStyle(fontFamily: 'Amiri')),
            backgroundColor: _border,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      await prefs.setInt('bookmark_page', pageNumber);
      await prefs.setInt('bookmark_surah', surahNumber);
      await prefs.setInt('bookmark_ayah', ayahNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ العلامة',
                style: TextStyle(fontFamily: 'Amiri')),
            backgroundColor: _border,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    if (widget.onBookmarkChanged != null) {
      widget.onBookmarkChanged!();
    }
  }

  void _showTafsir() {
    _showContentSheet(isTafsir: true);
  }

  void _showTranslation() {
    _showContentSheet(isTafsir: false);
  }

  void _showMeaningsAndIrab() {
    final surahNumber = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNumber = widget.verseData['ayahNumber'] as int? ?? 1;
    final verseText = widget.verseData['text'] as String? ?? '';
    final rawSurahName = widget.verseData['surahName'] as String? ?? '';
    final surahName = rawSurahName.isNotEmpty
        ? rawSurahName
        : (surahNumber >= 1 && surahNumber <= DatabaseHelper.surahNamesArabicList.length
            ? DatabaseHelper.surahNamesArabicList[surahNumber - 1]
            : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VerseMeaningsAndIrabSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        verseText: verseText,
        surahName: surahName,
      ),
    );
  }

  void _showContentSheet({required bool isTafsir}) {
    final surahNumber = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNumber = widget.verseData['ayahNumber'] as int? ?? 1;
    final verseText = widget.verseData['text'] as String? ?? '';
    final rawSurahName = widget.verseData['surahName'] as String? ?? '';
    final surahName = rawSurahName.isNotEmpty
        ? rawSurahName
        : (surahNumber >= 1 && surahNumber <= DatabaseHelper.surahNamesArabicList.length
            ? DatabaseHelper.surahNamesArabicList[surahNumber - 1]
            : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VerseContentSheet(
        initialIsTafsir: isTafsir,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        verseText: verseText,
        surahName: surahName,
      ),
    );
  }

  void _onListenTapped() async {
    final surahNum = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNum = widget.verseData['ayahNumber'] as int? ?? 1;
    final pageNum = widget.verseData['page'] as int? ?? 1;

    if (kIsWeb) {
      widget.onListen();
      return;
    }

    final hasAudio = await QuranAudioController.instance.hasOfflineAudio(surahNum, ayahNum);
    _showListenOptions(surahNum, ayahNum, pageNum, hasOffline: hasAudio, playAfterDownload: true);
  }

  void _showListenOptions(int surahNum, int ayahNum, int pageNum, {required bool hasOffline, required bool playAfterDownload}) {
    String searchQuery = '';
    QuranReciter selectedReciter = QuranAudioController.instance.selectedReciter;
    


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredReciters = [...kAllReciters]..sort((a, b) => a.englishName.toLowerCase().compareTo(b.englishName.toLowerCase()));
            final lowerQuery = searchQuery.trim().toLowerCase();
            final visibleReciters = lowerQuery.isEmpty
                ? filteredReciters
                : filteredReciters.where((reciter) => reciter.searchText.contains(lowerQuery)).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: _border.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'اختر القارئ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold, color: _gold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن القارئ بالعربية أو الإنجليزية',
                      hintStyle: TextStyle(color: _text.withValues(alpha: 0.55), fontFamily: 'Amiri'),
                      filled: true,
                      fillColor: _bg.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.search, color: _gold.withValues(alpha: 0.7)),
                    ),
                    style: TextStyle(color: _text, fontFamily: 'Amiri', fontSize: 16),
                    onChanged: (query) => setModalState(() => searchQuery = query),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visibleReciters.isEmpty
                        ? Center(
                            child: Text('لا يوجد نتائج', style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: _text.withValues(alpha: 0.7))),
                          )
                        : ListView.builder(
                            itemCount: visibleReciters.length,
                            itemBuilder: (context, index) {
                              final reciter = visibleReciters[index];
                              final isSelected = selectedReciter.identifier == reciter.identifier;
                              final supportsGapless = reciter.quranComId != null;
                              
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? _gold.withValues(alpha: 0.18) : _border.withValues(alpha: 0.1),
                                    border: Border.all(color: isSelected ? _gold : _border.withValues(alpha: 0.3), width: isSelected ? 1.5 : 1),
                                  ),
                                  child: Icon(Icons.person, size: 18, color: isSelected ? _gold : _text.withValues(alpha: 0.6)),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reciter.name, 
                                        style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: isSelected ? _gold : _text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
                                      )
                                    ),
                                    if (supportsGapless)
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  ],
                                ),
                                subtitle: Text(
                                  reciter.englishName, 
                                  style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: _text.withValues(alpha: 0.65))
                                ),
                                trailing: isSelected ? Icon(Icons.check_circle, color: _gold, size: 22) : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                onTap: () {
                                  setModalState(() {
                                    selectedReciter = reciter;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      QuranAudioController.instance.selectedReciter = selectedReciter;
                      QuranAudioController.instance.hasUserSelectedReciter = true;
                      widget.onListen();
                    },
                    child: const Text(
                      'تشغيل الآن', 
                      style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _border.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDark ? 0.5 : 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Line 1: Navigation & Global Utilities + Content Views (6 items) ──
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Listen — primary action
                        _ActionIcon(
                          icon: Icons.headphones_rounded,
                          label: l10n.actionListen,
                          color: _gold,
                          isPrimary: true,
                          borderColor: _gold,
                          onTap: _onListenTapped,
                        ),
                        _sep(),
                        // Search
                        _ActionIcon(
                          icon: Icons.search_rounded,
                          label: l10n.actionSearch,
                          color: _text,
                          onTap: widget.onOpenSearch,
                        ),
                        _sep(),
                        // Go to Bookmark
                        _ActionIcon(
                          icon: Icons.bookmark_added_rounded,
                          label: l10n.actionGoToBookmark,
                          color: _text,
                          onTap: widget.onGoToBookmark,
                        ),
                        _sep(),
                        // Tafsir
                        _ActionIcon(
                          icon: Icons.auto_stories_rounded,
                          label: l10n.actionTafsir,
                          color: _text,
                          onTap: _showTafsir,
                        ),
                        _sep(),
                        // Translation
                        _ActionIcon(
                          icon: Icons.translate_rounded,
                          label: l10n.actionTranslation,
                          color: _text,
                          onTap: _showTranslation,
                        ),
                        _sep(),
                        // Meanings & I'rab
                        _ActionIcon(
                          icon: Icons.menu_book_rounded,
                          label: 'المعاني والإعراب',
                          color: _text,
                          onTap: _showMeaningsAndIrab,
                        ),
                      ],
                    ),
                    // ── Divider ──
                    Container(
                      height: 1.0,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _border.withValues(alpha: 0.25),
                            _border.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // ── Line 2: Verse Actions (5 items) ──
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy
                        _ActionIcon(
                          icon: Icons.copy_rounded,
                          label: l10n.actionCopyAyah,
                          color: _text,
                          onTap: _copyAyah,
                        ),
                        _sep(),
                        // Share
                        _ActionIcon(
                          icon: Icons.share_rounded,
                          label: l10n.actionShareText,
                          color: _text,
                          onTap: _shareAyah,
                        ),
                        _sep(),
                        // Bookmark toggle
                        _ActionIcon(
                          icon: widget.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_rounded,
                          label: l10n.actionSaveBookmark,
                          color: widget.isBookmarked ? _gold : _text,
                          onTap: _toggleBookmark,
                        ),
                        _sep(),
                        // Theme
                        _ActionIcon(
                          icon: Icons.palette_outlined,
                          label: l10n.actionTheme,
                          color: _text,
                          onTap: widget.onChangeTheme,
                        ),
                        _sep(),
                        // Close
                        _ActionIcon(
                          icon: Icons.close_rounded,
                          label: l10n.actionClose,
                          color: _text.withValues(alpha: 0.6),
                          onTap: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sep() {
    return const SizedBox(width: 4);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single action icon button with a tiny label underneath
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary ? color.withValues(alpha: 0.14) : Colors.transparent,
                border: isPrimary && borderColor != null
                    ? Border.all(color: borderColor!.withValues(alpha: 0.5), width: 1.5)
                    : null,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.85),
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


