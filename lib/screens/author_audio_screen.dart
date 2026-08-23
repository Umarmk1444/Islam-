import 'package:flutter/material.dart';
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

  static const Map<String, Map<String, String>> _l10n = {
    'en': {
      'search_hint': 'Search audio track (in Arabic)...',
      'confirm_delete': 'Confirm Deletion',
      'confirm_delete_msg': 'Are you sure you want to delete this audio file from your device?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'deleted_success': 'Audio file deleted successfully',
      'download_success': 'Downloaded successfully',
      'download_failed': 'Download failed. Check your internet connection.',
      'no_internet': 'No internet connection. Please check your network.',
      'bulk_started': 'Started downloading tracks...',
      'bulk_stopped': 'Download stopped. Check your internet connection.',
      'empty': 'No audio files available',
    },
    'ar': {
      'search_hint': 'البحث عن ملف صوتي (بالعربية)...',
      'confirm_delete': 'تأكيد الحذف',
      'confirm_delete_msg': 'هل أنت متأكد من حذف هذا الملف من جهازك؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'deleted_success': 'تم حذف الملف بنجاح',
      'download_success': 'تم التنزيل بنجاح',
      'download_failed': 'فشل التنزيل. تحقق من الاتصال بالإنترنت.',
      'no_internet': 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
      'bulk_started': 'بدأ تنزيل القائمة بأكملها...',
      'bulk_stopped': 'توقف التنزيل. تأكد من اتصال الإنترنت.',
      'empty': 'لا توجد ملفات صوتية متوفرة',
    },
    'am': {
      'search_hint': 'የድምጽ ፋይል ይፈልጉ...',
      'confirm_delete': 'ስረዛን ያረጋግጡ',
      'confirm_delete_msg': 'ይህን ፋይል ከመሳሪያዎ መሰረዝ ይፈልጋሉ?',
      'cancel': 'ይቅር',
      'delete': 'ሰርዝ',
      'deleted_success': 'ፋይሉ በተሳካ ሁኔታ ተሰርዟል',
      'download_success': 'በተሳካ ሁኔታ ወርዷል',
      'download_failed': 'ማውረድ አልተሳካም። የበይነመረብ ግንኙነትዎን ያረጋግጡ።',
      'no_internet': 'ምንም የበይነመረብ ግንኙነት የለም። እባክዎን አውታረ መረብዎን ያረጋግጡ።',
      'bulk_started': 'ሁሉንም ፋይሎች ማውረድ ተጀምሯል...',
      'bulk_stopped': 'ማውረድ ቆሟል። የበይነመረብ ግንኙነትዎን ያረጋግጡ።',
      'empty': 'ምንም የድምጽ ፋይሎች የሉም',
    },
    'om': {
      'search_hint': 'Sagalee barbaadi...',
      'confirm_delete': 'Haqamuu mirkaneessi',
      'confirm_delete_msg': 'Waraabbata kana meeshaa kee irraa haquu barbaaddaa?',
      'cancel': 'Dhiisi',
      'delete': 'Haqi',
      'deleted_success': 'Sagaleen milkaa\'inaan haqameera',
      'download_success': 'Milkaa\'inaan bu\'eera',
      'download_failed': 'Buusuun hin milkoofne. Intarneetii kee ilaali.',
      'no_internet': 'Konneksiyiniin intarneetii hin jiru.',
      'bulk_started': 'Hunda buusuun eegalameera...',
      'bulk_stopped': 'Buusuun dhaabbateera. Intarneetii ilaali.',
      'empty': 'Sagaleen hin jiru',
    },
  };

  String _tr(String key) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    return _l10n[lang]?[key] ?? _l10n['ar']?[key] ?? _l10n['en']![key]!;
  }

  void _confirmDelete(MinbarAudioItem track) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('confirm_delete')),
        content: Text('${_tr('confirm_delete_msg')}\n"${track.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('cancel')),
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
                  SnackBar(
                    content: Text(_tr('deleted_success'), textAlign: TextAlign.center),
                  ),
                );
              }
            },
            child: Text(_tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
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
            content: Text('${_tr('download_success')}: "${track.title}"',
                textAlign: TextAlign.center),
          ),
        );
      }
    } else if (mounted && !isBulk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('download_failed'),
              textAlign: TextAlign.center),
        ),
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
          SnackBar(
            content: Text(_tr('no_internet'),
                textAlign: TextAlign.center),
          ),
        );
      }
      return;
    }

    setState(() => _isBulkDownloading = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('bulk_started'),
              textAlign: TextAlign.center),
        ),
      );
    }

    for (var track in _filteredTracks) {
      if (!_isBulkDownloading) break;
      if (!_downloadedItems.contains(track.id)) {
        final success = await _downloadTrack(track, isBulk: true);
        if (!success && mounted && _isBulkDownloading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_tr('bulk_stopped'),
                  textAlign: TextAlign.center),
            ),
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
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';

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
            : (isDark ? AppColors.divider : AppColors.textMuted.withValues(alpha: 0.2));

        final titleAndIconColor =
            theme == QuranTheme.cream ? AppColors.emeraldDeep : textColor;

        final highlightColor =
            theme == QuranTheme.cream ? AppColors.emeraldDeep : primaryColor;

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
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: _tr('search_hint'),
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                    ),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                        // Dual Hero Action Bar (Play All + Download All)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              // Play All Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_filteredTracks.isNotEmpty) {
                                      MinbarPlayer.playPlaylist(_filteredTracks, 0, widget.authorName);
                                    }
                                  },
                                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                                  label: Text(
                                    isArabic ? 'تشغيل الكل' : 'Play All',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: highlightColor,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Download All Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _downloadAll,
                                  icon: Icon(
                                    _isBulkDownloading ? Icons.stop_rounded : Icons.download_rounded,
                                    color: _isBulkDownloading ? Colors.redAccent : highlightColor,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _isBulkDownloading
                                        ? (isArabic ? 'إيقاف التحميل' : 'Stop')
                                        : (isArabic ? 'تحميل الكل' : 'Download All'),
                                    style: TextStyle(
                                      color: _isBulkDownloading ? Colors.redAccent : highlightColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _isBulkDownloading ? Colors.redAccent : highlightColor,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: ValueListenableBuilder<Map<String, double>>(
                            valueListenable: _downloadService.downloadProgress,
                            builder: (context, progressMap, _) {
                              return ValueListenableBuilder<MinbarAudioItem?>(
                                valueListenable: MinbarPlayer.currentItemNotifier,
                                builder: (context, currentPlayingItem, _) {
                                  return ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _filteredTracks.length,
                                    separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                                    itemBuilder: (context, index) {
                                      final track = _filteredTracks[index];
                                      final isPlayingThis = currentPlayingItem?.id == track.id;

                                      final isDownloaded = _downloadedItems.contains(track.id);
                                      final progress = progressMap[track.id];
                                      final isDownloading = progress != null;

                                      final surahNum = (index + 1).toString().padLeft(3, '0');
                                      final isQuran = widget.categoryId == 'quran';

                                      return InkWell(
                                        onTap: () {
                                          MinbarPlayer.playPlaylist(
                                              _filteredTracks, index, widget.authorName);
                                        },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isPlayingThis
                                                ? highlightColor.withValues(alpha: 0.08)
                                                : cardBg.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isPlayingThis
                                                  ? highlightColor.withValues(alpha: 0.35)
                                                  : Colors.transparent,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                            children: [
                                              // Surah Number Badge or Play Icon
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: isPlayingThis
                                                      ? highlightColor.withValues(alpha: 0.2)
                                                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isPlayingThis ? highlightColor : borderColor,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: isPlayingThis
                                                      ? Icon(
                                                          Icons.equalizer_rounded,
                                                          color: highlightColor,
                                                          size: 20,
                                                        )
                                                      : Text(
                                                          surahNum,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor.withValues(alpha: 0.7),
                                                          ),
                                                        ),
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
                                                        Expanded(
                                                          child: Text(
                                                            track.title,
                                                            style: TextStyle(
                                                              fontFamily: isArabic ? 'Amiri' : null,
                                                              fontSize: 15,
                                                              fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w600,
                                                              color: isPlayingThis ? highlightColor : textColor,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (isQuran) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        isArabic ? 'سورة قرآنية كريمة' : 'Holy Quran Surah',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: textColor.withValues(alpha: 0.5),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (isDownloading)
                                                SizedBox(
                                                  width: 36,
                                                  height: 36,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        value: progress,
                                                        strokeWidth: 2.5,
                                                        valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.close, size: 14),
                                                        color: textColor,
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () {
                                                          _downloadService.cancelDownload(track.id);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                IconButton(
                                                  icon: Icon(
                                                    isDownloaded
                                                        ? Icons.check_circle_rounded
                                                        : Icons.download_rounded,
                                                  ),
                                                  color: isDownloaded
                                                      ? highlightColor
                                                      : textColor.withValues(alpha: 0.5),
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
