import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../services/quran_api_service.dart';
import '../controllers/quran_audio_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// View state enum
// ─────────────────────────────────────────────────────────────────────────────

enum _BottomSheetView { grid, translation, tafsir }

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

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

  const AyahInteractionBottomSheet({
    Key? key,
    required this.initialSurahNumber,
    required this.initialAyahNumber,
    required this.initialSurahName,
    required this.initialVerseText,
    required this.totalVersesInQuran,
    required this.surahList,
    required this.getVerseData,
    this.onAyahChanged,
  }) : super(key: key);

  @override
  State<AyahInteractionBottomSheet> createState() =>
      _AyahInteractionBottomSheetState();
}

class _AyahInteractionBottomSheetState
    extends State<AyahInteractionBottomSheet> {
  _BottomSheetView _view = _BottomSheetView.grid;

  // Dynamic content state
  bool _isLoadingData = false;
  String _fetchedData  = '';

  QuranTheme get _theme    => AppTheme.notifier.value;
  Color get _pageBg        => AppTheme.getPageBgColor(_theme);
  Color get _border        => AppTheme.getBorderColor(_theme);
  Color get _gold          => AppTheme.getGoldTextColor(_theme);
  Color get _textColor     => AppTheme.getMainTextColor(_theme);

  // ── Dynamic fetch helpers ──────────────────────────────────────────────────

  Future<void> _fetchTranslation() async {
    setState(() { _isLoadingData = true; _fetchedData = ''; });
    final locale = Localizations.localeOf(context).languageCode;
    final res = await QuranApiService.fetchTranslation(
        widget.initialSurahNumber, widget.initialAyahNumber, locale);
    if (mounted) setState(() { _fetchedData = res; _isLoadingData = false; });
  }

  Future<void> _fetchTafsir() async {
    setState(() { _isLoadingData = true; _fetchedData = ''; });
    final locale = Localizations.localeOf(context).languageCode;
    final res = await QuranApiService.fetchTafsir(
        widget.initialSurahNumber, widget.initialAyahNumber, locale);
    if (mounted) setState(() { _fetchedData = res; _isLoadingData = false; });
  }

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
                if (_view != _BottomSheetView.grid)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: _textColor, size: 20),
                    onPressed: () => setState(() => _view = _BottomSheetView.grid),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                Expanded(
                  child: Text(
                    'سورة ${widget.initialSurahName} · الآية ${widget.initialAyahNumber}',
                    textAlign: _view == _BottomSheetView.grid
                        ? TextAlign.start
                        : TextAlign.center,
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
            child: _view == _BottomSheetView.grid
                ? _buildGrid(l10n)
                : _buildDynamicContent(),
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
        onTap: () {
          setState(() => _view = _BottomSheetView.tafsir);
          _fetchTafsir();
        },
      ),
      _ActionItem(
        icon: Icons.translate,
        label: l10n.actionTranslation,
        onTap: () {
          setState(() => _view = _BottomSheetView.translation);
          _fetchTranslation();
        },
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
        onTap: () {/* TODO: share image */},
      ),
      _ActionItem(
        icon: Icons.bookmark_add_rounded,
        label: l10n.actionSaveBookmark,
        onTap: () {/* TODO: bookmark */},
      ),
      _ActionItem(
        icon: Icons.bookmark_rounded,
        label: l10n.actionGoToBookmark,
        onTap: () {/* TODO: go to bookmark */},
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

  // ── Phase 2: Dynamic Content (Translation / Tafsir) ───────────────────────

  Widget _buildDynamicContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verse text
          Text(
            widget.initialVerseText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 2.0,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: _border.withValues(alpha: 0.25)),
          const SizedBox(height: 20),

          // Fetched content
          if (_isLoadingData)
            Center(child: CircularProgressIndicator(color: _gold))
          else
            Text(
              _fetchedData.isEmpty ? '—' : _fetchedData,
              style: TextStyle(fontSize: 15, height: 1.7, color: _textColor.withValues(alpha: 0.85)),
              textAlign: TextAlign.justify,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

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
