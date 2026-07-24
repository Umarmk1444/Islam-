import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../controllers/quran_audio_controller.dart';
import '../core/database/database_helper.dart';
import 'verse_content_sheet.dart';

class AyahInteractionBottomSheet extends StatefulWidget {
  final int initialSurahNumber;
  final int initialAyahNumber;
  final String initialSurahName;
  final String initialVerseText;
  final int totalVersesInQuran;
  final List<Map<String, dynamic>> surahList;
  final Map<String, dynamic>? Function(int surah, int ayah) getVerseData;
  /// Called by the grid's 'Listen' button — lets the screen pass a scroll callback
  final void Function(int surah, int ayah)? onAyahChanged;

  AyahInteractionBottomSheet({
    Key? key,
    required this.initialSurahNumber,
    required this.initialAyahNumber,
    required this.initialSurahName,
    required String initialVerseText,
    required this.totalVersesInQuran,
    required this.surahList,
    required this.getVerseData,
    this.onAyahChanged,
  }) : initialVerseText = _sanitizeQuranText(initialVerseText),
       super(key: key);

  static String _sanitizeQuranText(String text) {
    String cleanedText = text.replaceAll(RegExp(r'([ۖۗۘۙۚۛۜ۞۩])\s+'), r'$1');
    return cleanedText.trim();
  }

  @override
  State<AyahInteractionBottomSheet> createState() =>
      _AyahInteractionBottomSheetState();
}

class _AyahInteractionBottomSheetState
    extends State<AyahInteractionBottomSheet> {
  QuranTheme get _theme    => AppTheme.notifier.value;
  Color get _pageBg        => AppTheme.getPageBgColor(_theme);
  Color get _border        => AppTheme.getBorderColor(_theme);
  Color get _gold          => AppTheme.getGoldTextColor(_theme);
  Color get _textColor     => AppTheme.getMainTextColor(_theme);

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ', style: TextStyle(fontFamily: 'Amiri'))),
    );
  }

  // ── Listen button: close sheet, hand off to global controller ─────────────

  void _startAudio() {
    Navigator.pop(context); // Close the bottom sheet immediately
    QuranAudioController.instance.startPlayback(
      surah:          widget.initialSurahNumber,
      ayah:           widget.initialAyahNumber,
      surahList:      widget.surahList,
      totalVerses:    widget.totalVersesInQuran,
      getVerseData:   widget.getVerseData,
      onAyahChanged:  widget.onAyahChanged,
    );
  }

  void _showVerseContentSheet(bool isTafsir) {
    Navigator.pop(context); // Close grid bottom sheet
    final surahName = widget.initialSurahName.isNotEmpty
        ? widget.initialSurahName
        : (widget.initialSurahNumber >= 1 && widget.initialSurahNumber <= DatabaseHelper.surahNamesArabicList.length
            ? DatabaseHelper.surahNamesArabicList[widget.initialSurahNumber - 1]
            : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VerseContentSheet(
        initialIsTafsir: isTafsir,
        surahNumber: widget.initialSurahNumber,
        ayahNumber: widget.initialAyahNumber,
        verseText: widget.initialVerseText,
        surahName: surahName,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 38, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _border.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 40), // Balance the close button
                Expanded(
                  child: Text(
                    'سورة ${widget.initialSurahName} · الآية ${widget.initialAyahNumber}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _gold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: _textColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: _border.withValues(alpha: 0.25), height: 12),

          Expanded(
            child: _buildGrid(l10n),
          ),
        ],
      ),
    );
  }

  // ── Phase 1: Action Grid ───────────────────────────────────────────────────

  Widget _buildGrid(AppLocalizations l10n) {
    final actions = <_ActionItem>[
      _ActionItem(
        icon: Icons.menu_book,
        label: l10n.actionTafsir,
        onTap: () => _showVerseContentSheet(true),
      ),
      _ActionItem(
        icon: Icons.volume_up_rounded,
        label: l10n.actionListen,
        onTap: _startAudio,
        isPrimary: true,
      ),
      _ActionItem(
        icon: Icons.copy_rounded,
        label: l10n.actionCopyAyah,
        onTap: () => _copyToClipboard(widget.initialVerseText),
      ),
      _ActionItem(
        icon: Icons.file_copy_rounded,
        label: l10n.actionCopyPage,
        onTap: () => _copyToClipboard(widget.initialVerseText),
      ),
      _ActionItem(
        icon: Icons.share_rounded,
        label: l10n.actionShareText,
        onTap: () => Share.share(widget.initialVerseText),
      ),
      _ActionItem(
        icon: Icons.image_rounded,
        label: l10n.actionShareImage,
        onTap: () {/* Implement: share image */},
      ),
      _ActionItem(
        icon: Icons.bookmark_add_rounded,
        label: l10n.actionSaveBookmark,
        onTap: () {/* Implement: bookmark */},
      ),
      _ActionItem(
        icon: Icons.bookmark_rounded,
        label: l10n.actionGoToBookmark,
        onTap: () {/* Implement: go to bookmark */},
      ),
      _ActionItem(
        icon: Icons.format_list_numbered_rounded,
        label: l10n.actionIndex,
        onTap: () => Navigator.pop(context),
      ),
      _ActionItem(
        icon: Icons.close_rounded,
        label: l10n.actionClose,
        onTap: () => Navigator.pop(context),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _buildActionCell(actions[i]),
    );
  }

  Widget _buildActionCell(_ActionItem item) {
    final isDark   = _theme == QuranTheme.dark;
    final cellBg   = isDark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.03);
    final iconColor = item.isPrimary ? _gold : _textColor;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isPrimary
                ? _gold.withValues(alpha: 0.6)
                : _border.withValues(alpha: 0.4),
            width: item.isPrimary ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 28, color: iconColor),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: item.isPrimary ? FontWeight.bold : FontWeight.normal,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
}
