import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/minbar_models.dart';
import '../services/minbar_player.dart';
import '../services/minbar_download_service.dart';
import '../core/database/downloads_database.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';

class MinbarDownloadsScreen extends StatefulWidget {
  const MinbarDownloadsScreen({super.key});

  @override
  State<MinbarDownloadsScreen> createState() => _MinbarDownloadsScreenState();
}

class _MinbarDownloadsScreenState extends State<MinbarDownloadsScreen> {
  final DownloadsDatabase _downloadsDb = DownloadsDatabase.instance;
  final MinbarDownloadService _downloadService = MinbarDownloadService.instance;

  // Organized data: Category -> Author -> List of Tracks
  Map<String, Map<String, List<MinbarAudioItem>>> _groupedTracks = {};

  bool _isLoading = true;

  final Map<String, String> _categoryNames = {
    'quran': 'القرآن الكريم',
    'khutbah': 'خطب',
    'dua': 'أدعية',
    'ruqyah': 'الرقية الشرعية',
    'ibtehalat': 'ابتهالات',
  };

  final Map<String, IconData> _categoryIcons = {
    'quran': Icons.menu_book_rounded,
    'khutbah': Icons.record_voice_over_rounded,
    'dua': Icons.back_hand_rounded,
    'ruqyah': Icons.healing_rounded,
    'ibtehalat': Icons.music_note_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final downloads = await _downloadsDb.getAllDownloads();

    Map<String, Map<String, List<MinbarAudioItem>>> grouped = {};
    for (var row in downloads) {
      final categoryId = row['category_id'] as String? ?? 'unknown';
      final authorName = row['author_name'] as String? ?? 'مجهول';

      final track = MinbarAudioItem(
        id: row['id'] as String,
        title: row['title'] as String,
        url: row['local_path'] as String,
        authorId: row['author_id'] as String,
      );

      grouped.putIfAbsent(categoryId, () => {});
      grouped[categoryId]!.putIfAbsent(authorName, () => []);
      grouped[categoryId]![authorName]!.add(track);
    }

    if (mounted) {
      setState(() {
        _groupedTracks = grouped;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(MinbarAudioItem track) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${track.title}" من جهازك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _downloadService.deleteDownload(track.id);
                _loadDownloads(); // Refresh list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم حذف الملف بنجاح',
                            textAlign: TextAlign.right)),
                  );
                }
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primaryColor = AppTheme.getPrimaryColor(theme);
        final borderColor = theme == QuranTheme.cream
            ? const Color(0xFFC9A84C).withValues(alpha: 0.3)
            : (isDark ? AppColors.divider : Colors.grey.shade200);

        final titleAndIconColor =
            theme == QuranTheme.cream ? AppColors.emeraldDeep : textColor;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(
              color: titleAndIconColor,
            ),
            title: Text(
              'مكتبتي (التنزيلات)',
              style: AppTextStyles.headlineMedium.copyWith(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: titleAndIconColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : _groupedTracks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_done_rounded,
                                    size: 64,
                                    color: textColor.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد ملفات محملة حتى الآن.',
                                  style: AppTextStyles.audioTitle.copyWith(
                                      color: textColor.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          )
                        : ValueListenableBuilder<MinbarAudioItem?>(
                            valueListenable: MinbarPlayer.currentItemNotifier,
                            builder: (context, currentPlayingItem, _) {
                              return ListView(
                                padding: const EdgeInsets.all(16),
                                physics: const BouncingScrollPhysics(),
                                children:
                                    _groupedTracks.entries.map((categoryEntry) {
                                  final categoryId = categoryEntry.key;
                                  final categoryDisplayName =
                                      _categoryNames[categoryId] ?? categoryId;
                                  final categoryIcon =
                                      _categoryIcons[categoryId] ??
                                          Icons.folder_rounded;
                                  final authorsMap = categoryEntry.value;

                                  return Card(
                                    color: cardBg,
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                          color: borderColor, width: 1),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: ExpansionTile(
                                          initiallyExpanded: true,
                                          collapsedIconColor:
                                              textColor.withValues(alpha: 0.6),
                                          iconColor: primaryColor,
                                          tilePadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                          leading: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                  alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(categoryIcon,
                                                color: primaryColor, size: 24),
                                          ),
                                          title: Text(
                                            categoryDisplayName,
                                            style: AppTextStyles.audioTitle
                                                .copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          children: authorsMap.entries
                                              .map((authorEntry) {
                                            final authorName = authorEntry.key;
                                            final tracks = authorEntry.value;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16.0),
                                              child: ExpansionTile(
                                                collapsedIconColor: textColor
                                                    .withValues(alpha: 0.6),
                                                iconColor: primaryColor,
                                                leading: Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    color: textColor.withValues(
                                                        alpha: 0.6)),
                                                title: Text(
                                                  authorName,
                                                  style: AppTextStyles
                                                      .audioSubtitle
                                                      .copyWith(
                                                          color: textColor,
                                                          fontSize: 15),
                                                ),
                                                children: tracks
                                                    .asMap()
                                                    .entries
                                                    .map((trackEntry) {
                                                  final index = trackEntry.key;
                                                  final track =
                                                      trackEntry.value;
                                                  final isPlayingThis =
                                                      currentPlayingItem?.id ==
                                                          track.id;
                                                  final highlightColor =
                                                      theme == QuranTheme.cream
                                                          ? AppColors
                                                              .emeraldDeep
                                                          : primaryColor;

                                                  return InkWell(
                                                    onTap: () {
                                                      MinbarPlayer.playPlaylist(
                                                          tracks,
                                                          index,
                                                          authorName);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 12),
                                                      child: Row(
                                                        textDirection:
                                                            TextDirection.rtl,
                                                        children: [
                                                          Container(
                                                            width: 36,
                                                            height: 36,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isPlayingThis
                                                                  ? highlightColor
                                                                      .withValues(
                                                                          alpha:
                                                                              0.15)
                                                                  : cardBg,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color:
                                                                      borderColor,
                                                                  width: 0.5),
                                                            ),
                                                            child: isPlayingThis
                                                                ? StreamBuilder<
                                                                    PlayerState>(
                                                                    stream: MinbarPlayer
                                                                        .player
                                                                        .playerStateStream,
                                                                    builder:
                                                                        (context,
                                                                            stateSnap) {
                                                                      final playing = stateSnap
                                                                              .data
                                                                              ?.playing ??
                                                                          false;
                                                                      return Icon(
                                                                        playing
                                                                            ? Icons.pause_rounded
                                                                            : Icons.play_arrow_rounded,
                                                                        color:
                                                                            highlightColor,
                                                                        size:
                                                                            20,
                                                                      );
                                                                    },
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .play_arrow_outlined,
                                                                    color: textColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.6),
                                                                    size: 20,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                              width: 16),
                                                          Expanded(
                                                            child: Text(
                                                              track.title,
                                                              style:
                                                                  AppTextStyles
                                                                      .audioTitle
                                                                      .copyWith(
                                                                color: isPlayingThis
                                                                    ? highlightColor
                                                                    : textColor,
                                                                fontWeight: isPlayingThis
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal,
                                                                fontSize: 14,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons
                                                                .delete_outline_rounded),
                                                            color: Colors
                                                                .redAccent
                                                                .shade200,
                                                            iconSize: 20,
                                                            onPressed: () =>
                                                                _confirmDelete(
                                                                    track),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
              ),
              const PersistentAudioBar(),
            ],
          ),
        );
      },
    );
  }
}
