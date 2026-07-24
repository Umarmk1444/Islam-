import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/minbar_models.dart';
import '../services/minbar_repository.dart';
import '../services/minbar_player.dart';
import '../services/minbar_download_service.dart';
import '../core/database/downloads_database.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class AuthorAudioScreen extends StatefulWidget {
  final String categoryId;
  final String authorId;
  final String authorName;

  const AuthorAudioScreen({
    super.key,
    required this.categoryId,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorAudioScreen> createState() => _AuthorAudioScreenState();
}

class _AuthorAudioScreenState extends State<AuthorAudioScreen> {
  final MinbarRepository _repository = MinbarRepository();
  final MinbarDownloadService _downloadService = MinbarDownloadService.instance;
  final DownloadsDatabase _downloadsDb = DownloadsDatabase.instance;

  late Future<List<MinbarAudioItem>> _audioItemsFuture;

  List<MinbarAudioItem> _allTracks = [];
  List<MinbarAudioItem> _filteredTracks = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final Set<String> _downloadedItems = {};
  bool _isBulkDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadedItems();
    _audioItemsFuture =
        _repository.getAudioItemsForAuthor(widget.categoryId, widget.authorId);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadDownloadedItems() async {
    final ids = await _downloadsDb.getAllDownloadedIds();
    if (mounted) {
      setState(() {
        _downloadedItems.addAll(ids);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTracks = _allTracks;
      } else {
        _filteredTracks = _allTracks.where((track) {
          return track.title.toLowerCase().contains(query);
        }).toList();
      }
    });
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
                setState(() {
                  _downloadedItems.remove(track.id);
                });
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

  Future<bool> _downloadTrack(MinbarAudioItem track,
      {bool isBulk = false}) async {
    final success = await _downloadService.downloadItem(
      item: track,
      authorName: widget.authorName,
      categoryId: widget.categoryId,
    );
    if (success && mounted) {
      setState(() {
        _downloadedItems.add(track.id);
      });
      if (!isBulk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم تنزيل "${track.title}" بنجاح',
                  textAlign: TextAlign.right)),
        );
      }
    } else if (mounted && !isBulk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('فشل التنزيل. تحقق من الاتصال بالإنترنت.',
                textAlign: TextAlign.right)),
      );
    }
    return success;
  }

  Future<void> _downloadAll() async {
    if (_isBulkDownloading) {
      setState(() => _isBulkDownloading = false);
      for (var track in _filteredTracks) {
        _downloadService.cancelDownload(track.id);
      }
      return;
    }

    final hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
                  textAlign: TextAlign.right)),
        );
      }
      return;
    }

    setState(() => _isBulkDownloading = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('بدأ تنزيل القائمة بأكملها...',
                textAlign: TextAlign.right)),
      );
    }

    for (var track in _filteredTracks) {
      if (!_isBulkDownloading) break;
      if (!_downloadedItems.contains(track.id)) {
        final success = await _downloadTrack(track, isBulk: true);
        if (!success && mounted && _isBulkDownloading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('توقف التنزيل. تأكد من اتصال الإنترنت.',
                    textAlign: TextAlign.right)),
          );
          break;
        }
      }
    }

    if (mounted) {
      setState(() => _isBulkDownloading = false);
    }
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
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTextStyles.audioTitle.copyWith(
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'البحث عن ملف صوتي...',
                      hintStyle: AppTextStyles.audioSubtitle.copyWith(
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                    ),
                    textDirection: TextDirection.rtl,
                  )
                : Text(
                    widget.authorName,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      color: titleAndIconColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchController.clear();
                      _isSearching = false;
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<MinbarAudioItem>>(
                  future: _audioItemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'عذرًا، حدث خطأ أثناء تحميل البيانات.',
                                style: AppTextStyles.audioTitle
                                    .copyWith(color: textColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final tracks = snapshot.data ?? [];
                    if (tracks.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد ملفات صوتية.',
                          style: AppTextStyles.audioTitle
                              .copyWith(color: textColor),
                        ),
                      );
                    }

                    if (_allTracks.isEmpty && !_isSearching) {
                      _allTracks = tracks;
                      _filteredTracks = tracks;
                    }

                    return Column(
                      children: [
                        // Bulk Download Button
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: _downloadAll,
                            icon: Icon(
                                _isBulkDownloading
                                    ? Icons.stop_rounded
                                    : Icons.download_rounded,
                                color: Colors.white),
                            label: Text(
                              _isBulkDownloading
                                  ? 'إيقاف التنزيل'
                                  : (widget.categoryId == 'quran'
                                      ? 'تنزيل المصحف كاملاً'
                                      : 'تنزيل الكل'),
                              style: AppTextStyles.audioTitle
                                  .copyWith(color: Colors.white, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isBulkDownloading
                                  ? Colors.red
                                  : primaryColor,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        Expanded(
                          child: ValueListenableBuilder<Map<String, double>>(
                            valueListenable: _downloadService.downloadProgress,
                            builder: (context, progressMap, _) {
                              return ValueListenableBuilder<MinbarAudioItem?>(
                                valueListenable:
                                    MinbarPlayer.currentItemNotifier,
                                builder: (context, currentPlayingItem, _) {
                                  return ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 4,
                                        16, 16), // Adjusted bottom padding
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _filteredTracks.length,
                                    separatorBuilder: (_, __) =>
                                        Divider(color: borderColor, height: 1),
                                    itemBuilder: (context, index) {
                                      final track = _filteredTracks[index];
                                      final isPlayingThis =
                                          currentPlayingItem?.id == track.id;

                                      final isDownloaded =
                                          _downloadedItems.contains(track.id);
                                      final progress = progressMap[track.id];
                                      final isDownloading = progress != null;

                                      final highlightColor =
                                          theme == QuranTheme.cream
                                              ? AppColors.emeraldDeep
                                              : primaryColor;

                                      return InkWell(
                                        onTap: () {
                                          MinbarPlayer.playPlaylist(
                                              _filteredTracks,
                                              index,
                                              widget.authorName);
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 14),
                                          child: Row(
                                            textDirection: TextDirection.rtl,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: isPlayingThis
                                                      ? highlightColor
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : cardBg,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: borderColor,
                                                      width: 0.5),
                                                ),
                                                child: isPlayingThis
                                                    ? StreamBuilder<
                                                        PlayerState>(
                                                        stream: MinbarPlayer
                                                            .player
                                                            .playerStateStream,
                                                        builder: (context,
                                                            stateSnap) {
                                                          final playing =
                                                              stateSnap.data
                                                                      ?.playing ??
                                                                  false;
                                                          return Icon(
                                                            playing
                                                                ? Icons
                                                                    .pause_rounded
                                                                : Icons
                                                                    .play_arrow_rounded,
                                                            color:
                                                                highlightColor,
                                                            size: 22,
                                                          );
                                                        },
                                                      )
                                                    : Icon(
                                                        Icons
                                                            .play_arrow_outlined,
                                                        color: textColor
                                                            .withValues(
                                                                alpha: 0.6),
                                                        size: 20,
                                                      ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  children: [
                                                    Text(
                                                      track.title,
                                                      style: AppTextStyles
                                                          .audioTitle
                                                          .copyWith(
                                                        color: isPlayingThis
                                                            ? highlightColor
                                                            : textColor,
                                                        fontWeight:
                                                            isPlayingThis
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isDownloading)
                                                SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        value: progress,
                                                        strokeWidth: 3,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                highlightColor),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            size: 16),
                                                        color: textColor,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed: () {
                                                          _downloadService
                                                              .cancelDownload(
                                                                  track.id);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                IconButton(
                                                  icon: Icon(isDownloaded
                                                      ? Icons
                                                          .delete_outline_rounded
                                                      : Icons.download_rounded),
                                                  color: isDownloaded
                                                      ? Colors
                                                          .redAccent.shade200
                                                      : textColor.withValues(
                                                          alpha: 0.6),
                                                  iconSize: 22,
                                                  onPressed: () {
                                                    if (isDownloaded) {
                                                      _confirmDelete(track);
                                                    } else {
                                                      _downloadTrack(track);
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Mini Player
              const PersistentAudioBar(),
            ],
          ),
        );
      },
    );
  }
}
