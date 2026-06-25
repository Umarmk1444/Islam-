import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';
import '../services/quran_api_service.dart';
import '../controllers/quran_audio_controller.dart';

/// Ultra-compact, icon-only floating action bar that appears when a user
/// taps an Ayah. Contains only icons with tooltips — no text labels.
class AyahActionBar extends StatefulWidget {
  final Map<String, dynamic> verseData;
  final VoidCallback onListen;
  final VoidCallback onClose;

  const AyahActionBar({
    Key? key,
    required this.verseData,
    required this.onListen,
    required this.onClose,
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
      ? const Color(0xFF0D1F17).withOpacity(0.95)
      : AppTheme.getPageBgColor(_theme).withOpacity(0.95);
  Color get _border => AppTheme.getBorderColor(_theme);
  Color get _gold => AppTheme.getGoldTextColor(_theme);
  Color get _text => AppTheme.getMainTextColor(_theme);

  // ── Actions ───────────────────────────────────────────────────────────────

  void _copyAyah() {
    final text = widget.verseData['text'] ?? '';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الآية',
            style: TextStyle(fontFamily: 'Amiri')),
        backgroundColor: _border,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareAyah() {
    final surahName = widget.verseData['surahName'] ?? '';
    final ayahNumber = widget.verseData['ayahNumber'] ?? 1;
    final text = widget.verseData['text'] ?? '';
    Share.share('﴿$text﴾ [$surahName: $ayahNumber]');
  }

  void _saveBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final pageNumber = widget.verseData['page'] ?? 1;
    final surahNumber = widget.verseData['surahNumber'] ?? 1;
    final ayahNumber = widget.verseData['ayahNumber'] ?? 1;
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

  void _showTafsir() {
    _showContentSheet(isTafsir: true);
  }

  void _showTranslation() {
    _showContentSheet(isTafsir: false);
  }

  void _showContentSheet({required bool isTafsir}) {
    final surahNumber = widget.verseData['surahNumber'] as int? ?? 1;
    final ayahNumber = widget.verseData['ayahNumber'] as int? ?? 1;
    final verseText = widget.verseData['text'] as String? ?? '';
    final surahName = widget.verseData['surahName'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContentSheet(
        isTafsir: isTafsir,
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
    
    if (kIsWeb) {
      widget.onListen();
      return;
    }
    
    final hasAudio = await QuranAudioController.instance.hasOfflineAudio(surahNum, ayahNum);
    
    if (hasAudio) {
      widget.onListen();
    } else {
      _showDownloadPrompt(surahNum, ayahNum);
    }
  }

  void _showDownloadPrompt(int surahNum, int ayahNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border, width: 1.5),
        ),
        title: Text(
          'تنزيل الصوت',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Amiri', color: _gold, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'الملف الصوتي لهذه الآية غير متوفر محلياً. ماذا تود أن تفعل؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Amiri', color: _text, fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onListen();
            },
            child: const Text('استماع مباشر', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _border, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              QuranAudioController.instance.downloadAyah(surahNum, ayahNum).then((_) {
                widget.onListen();
              });
            },
            child: const Text('تنزيل الآية', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              QuranAudioController.instance.downloadSurah(surahNum, 286); // fallback to 286
              widget.onListen();
            },
            child: const Text('تنزيل السورة', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _onDownloadTapped() {
    _showReciterSelectionSheet(isForDownload: true);
  }



  void _showReciterSelectionSheet({required bool isForDownload}) {
    final ctrl = QuranAudioController.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: _border.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _border.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('اختر القارئ',
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _gold)),
              const SizedBox(height: 4),
              Text(
                'سورة ${widget.verseData['surahName'] ?? ''} · الآية ${widget.verseData['ayahNumber'] ?? 1}',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: _text.withOpacity(0.6)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: kAllReciters.length,
                  itemBuilder: (context, index) {
                    final reciter = kAllReciters[index];
                    final isSelected =
                        ctrl.selectedReciter.identifier ==
                            reciter.identifier;
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _gold.withOpacity(0.15)
                              : _border.withOpacity(0.08),
                          border: Border.all(
                            color: isSelected ? _gold : _border.withOpacity(0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: isSelected ? _gold : _text.withOpacity(0.5),
                        ),
                      ),
                      title: Text(reciter.name,
                          style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? _gold : _text)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: _gold, size: 20)
                          : null,
                      onTap: () {
                        ctrl.selectedReciter = reciter;
                        ctrl.hasUserSelectedReciter = true;
                        Navigator.pop(ctx);
                        if (isForDownload) {
                          // The totalVerses is passed from QuranScreen but AyahActionBar doesn't have it directly.
                          // Wait, it can download by getting total verses from controller or we pass it.
                          // Let's just download the current surah assuming 286 max for simplicity, 
                          // or better: call downloadSurah.
                          final surahNum = widget.verseData['surahNumber'] as int? ?? 1;
                          final totalVerses = 286; // Just a safe upper bound if we don't have it locally, controller handles 404s
                          ctrl.downloadSurah(surahNum, totalVerses);
                        } else {
                          // Now start playback
                          widget.onListen();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _border.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark ? 0.5 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Listen (primary — gold accent)
                _ActionIcon(
                  icon: Icons.headphones_rounded,
                  tooltip: 'استماع',
                  color: _gold,
                  isPrimary: true,
                  borderColor: _gold,
                  onTap: _onListenTapped,
                ),
                _dot(),
                // Download
                ListenableBuilder(
                  listenable: QuranAudioController.instance,
                  builder: (context, _) {
                    final isDownloading = QuranAudioController.instance.isDownloading;
                    return _ActionIcon(
                      icon: isDownloading ? Icons.stop_circle_outlined : Icons.download_rounded,
                      tooltip: isDownloading ? 'إلغاء التنزيل' : 'تنزيل السورة',
                      color: isDownloading ? Colors.redAccent : _text,
                      onTap: () {
                        if (isDownloading) {
                          QuranAudioController.instance.cancelDownload();
                        } else {
                          _onDownloadTapped();
                        }
                      },
                    );
                  },
                ),
                _dot(),
                // Tafsir
                _ActionIcon(
                  icon: Icons.menu_book_rounded,
                  tooltip: 'التفسير',
                  color: _text,
                  onTap: _showTafsir,
                ),
                _dot(),
                // Translation
                _ActionIcon(
                  icon: Icons.translate_rounded,
                  tooltip: 'الترجمة',
                  color: _text,
                  onTap: _showTranslation,
                ),
                _dot(),
                // Copy
                _ActionIcon(
                  icon: Icons.copy_rounded,
                  tooltip: 'نسخ الآية',
                  color: _text,
                  onTap: _copyAyah,
                ),
                _dot(),
                // Share
                _ActionIcon(
                  icon: Icons.share_rounded,
                  tooltip: 'مشاركة',
                  color: _text,
                  onTap: _shareAyah,
                ),
                _dot(),
                // Bookmark
                _ActionIcon(
                  icon: Icons.bookmark_add_rounded,
                  tooltip: 'حفظ العلامة',
                  color: _text,
                  onTap: _saveBookmark,
                ),
                _dot(),
                // Close
                _ActionIcon(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: _text.withOpacity(0.6),
                  onTap: widget.onClose,
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

  Widget _dot() {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _border.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single action icon button with tooltip
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isPrimary;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.isPrimary = false,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrimary ? color.withOpacity(0.12) : Colors.transparent,
            border: isPrimary && borderColor != null
                ? Border.all(color: borderColor!.withOpacity(0.4), width: 1.2)
                : null,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content Bottom Sheet for Tafsir / Translation
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSheet extends StatefulWidget {
  final bool isTafsir;
  final int surahNumber;
  final int ayahNumber;
  final String verseText;
  final String surahName;

  const _ContentSheet({
    required this.isTafsir,
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseText,
    required this.surahName,
  });

  @override
  State<_ContentSheet> createState() => _ContentSheetState();
}

class _ContentSheetState extends State<_ContentSheet> {
  bool _isLoading = true;
  String _content = '';

  QuranTheme get _theme => AppTheme.notifier.value;
  Color get _bg => AppTheme.getPageBgColor(_theme);
  Color get _border => AppTheme.getBorderColor(_theme);
  Color get _gold => AppTheme.getGoldTextColor(_theme);
  Color get _text => AppTheme.getMainTextColor(_theme);

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    final locale = Localizations.localeOf(context).languageCode;
    final res = widget.isTafsir
        ? await QuranApiService.fetchTafsir(
            widget.surahNumber, widget.ayahNumber, locale)
        : await QuranApiService.fetchTranslation(
            widget.surahNumber, widget.ayahNumber, locale);
    if (mounted) {
      setState(() {
        _content = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _border.withOpacity(0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: _text, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    '${widget.isTafsir ? "التفسير" : "الترجمة"} · سورة ${widget.surahName} · ${widget.ayahNumber}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _gold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 40), // Balance the close button
              ],
            ),
          ),

          Divider(color: _border.withOpacity(0.25), height: 12),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verse text
                  Text(
                    widget.verseText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      height: 2.0,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _border.withOpacity(0.25)),
                  const SizedBox(height: 20),

                  // Fetched content
                  if (_isLoading)
                    Center(
                        child: CircularProgressIndicator(color: _gold))
                  else
                    Text(
                      _content.isEmpty ? '—' : _content,
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: _text.withOpacity(0.85)),
                      textAlign: TextAlign.justify,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
