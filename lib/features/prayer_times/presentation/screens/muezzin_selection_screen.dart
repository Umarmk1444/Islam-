import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';
import '../../data/models/muezzin_model.dart';
import '../../data/services/muezzin_manager.dart';
import '../controllers/prayer_controller.dart';

class MuezzinSelectionScreen extends StatefulWidget {
  final PrayerController controller;
  final String? prayerName;

  const MuezzinSelectionScreen({
    super.key,
    required this.controller,
    this.prayerName,
  });

  @override
  State<MuezzinSelectionScreen> createState() => _MuezzinSelectionScreenState();
}

class _MuezzinSelectionScreenState extends State<MuezzinSelectionScreen> {
  final MuezzinManager _manager = MuezzinManager();
  final AudioPlayer _previewPlayer = AudioPlayer();
  
  bool _isLoading = true;
  bool _applyToAll = false;
  String _searchQuery = '';
  String? _playingMuezzinId;
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadedState = {};

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  Future<void> _initManager() async {
    await _manager.init();
    
    // Check download states
    for (var m in _manager.muezzins) {
      if (!m.isLocal) {
        _downloadedState[m.id] = await _manager.isDownloaded(m);
      } else {
        _downloadedState[m.id] = true;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(MuezzinModel m) async {
    if (_playingMuezzinId == m.id) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playingMuezzinId = null);
    } else {
      await _previewPlayer.stop();
      if (mounted) setState(() => _playingMuezzinId = m.id);
      try {
        final isDownloaded = _downloadedState[m.id] ?? false;
        final mediaItem = MediaItem(
          id: m.id,
          title: m.name,
          artist: '${m.mosque} • ${m.country}',
        );

        AudioSource source;
        if (m.isLocal) {
          final path = await _manager.getAudioPath(m);
          source = AudioSource.uri(
            Uri.parse('asset:///$path'),
            tag: mediaItem,
          );
        } else if (isDownloaded) {
          final path = await _manager.getAudioPath(m);
          source = AudioSource.uri(
            Uri.file(path),
            tag: mediaItem,
          );
        } else {
          source = AudioSource.uri(
            Uri.parse(m.url),
            tag: mediaItem,
          );
        }

        await _previewPlayer.setAudioSource(source);
        await _previewPlayer.play();
        
        Future.delayed(const Duration(seconds: 20), () async {
          if (mounted && _playingMuezzinId == m.id) {
            await _previewPlayer.stop();
            if (mounted) setState(() => _playingMuezzinId = null);
          }
        });
      } catch (e) {
        debugPrint('Preview error: $e');
        if (mounted) {
          setState(() => _playingMuezzinId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot stream audio preview: $e')),
          );
        }
      }
    }
  }

  Future<void> _download(MuezzinModel m) async {
    setState(() {
      _downloadProgress[m.id] = 0.01;
    });
    try {
      await _manager.downloadMuezzin(m, (prog) {
        if (mounted) {
          setState(() {
            _downloadProgress[m.id] = prog;
          });
        }
      });
      if (mounted) {
        setState(() {
          _downloadProgress.remove(m.id);
          _downloadedState[m.id] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(m.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _delete(MuezzinModel m) async {
    await _manager.deleteDownload(m);
    if (mounted) {
      setState(() {
        _downloadedState[m.id] = false;
      });
    }
  }

  void _onSaveMuezzin(MuezzinModel m) {
    if (_downloadedState[m.id] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please download the Adhan first before selecting it.')),
      );
      return;
    }

    final cfg = widget.controller.config;
    final newMap = Map<String, String>.from(cfg.prayerMuezzins);

    final isGlobal = _applyToAll || widget.prayerName == null;
    if (isGlobal) {
      for (var k in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        newMap[k] = m.id;
      }
    } else {
      newMap[widget.prayerName!] = m.id;
    }

    widget.controller.updateConfig(cfg.copyWith(prayerMuezzins: newMap));
    
    final prayerDisplay = widget.prayerName != null 
        ? '${widget.prayerName![0].toUpperCase()}${widget.prayerName!.substring(1)}'
        : 'all prayers';

    final msg = isGlobal
        ? '${m.name} selected for all prayers!'
        : '${m.name} selected for $prayerDisplay!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
        final primary = AppTheme.getPrimaryColor(theme);

        final targetPrayer = widget.prayerName ?? 'fajr';
        final currentMuezzinId = widget.controller.config.prayerMuezzins[targetPrayer] ?? 'adhan_abdulbasit';

        List<MuezzinModel> filtered = _manager.muezzins.where((m) {
          final q = _searchQuery.toLowerCase();
          return m.name.toLowerCase().contains(q) ||
                 m.country.toLowerCase().contains(q) ||
                 m.mosque.toLowerCase().contains(q);
        }).toList();

        // Sort: Favorites first
        filtered.sort((a, b) {
          final aFav = _manager.isFavorite(a.id) ? 1 : 0;
          final bFav = _manager.isFavorite(b.id) ? 1 : 0;
          return bFav.compareTo(aFav);
        });

        final appBarTitle = widget.prayerName != null 
            ? 'Select Muezzin (${widget.prayerName![0].toUpperCase()}${widget.prayerName!.substring(1)})'
            : 'Select Muezzin';

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text(appBarTitle),
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                if (widget.prayerName != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, color: primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Apply to all prayers',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _applyToAll,
                          activeThumbColor: primary,
                          onChanged: (val) => setState(() => _applyToAll = val),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Mosque, or Country...',
                      prefixIcon: Icon(Icons.search, color: primary),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      final isSelected = currentMuezzinId == m.id;
                      final isPlaying = _playingMuezzinId == m.id;
                      final isFav = _manager.isFavorite(m.id);
                      final isDownloaded = _downloadedState[m.id] ?? true;
                      final progress = _downloadProgress[m.id];

                      return Hero(
                        tag: 'muezzin_${m.id}',
                        child: GestureDetector(
                          onTap: () => _onSaveMuezzin(m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? primary.withValues(alpha: isDark ? 0.15 : 0.08)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? primary.withValues(alpha: 0.5) 
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await _manager.toggleFavorite(m.id);
                                    setState(() {});
                                  },
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? Colors.redAccent : textColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: isSelected ? primary : textColor,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${m.mosque} • ${m.country}',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: textColor.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!m.isLocal && !isDownloaded && progress == null)
                                  IconButton(
                                    icon: Icon(Icons.cloud_download_rounded, color: primary),
                                    onPressed: () => _download(m),
                                  ),
                                if (!m.isLocal && progress != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(value: progress, color: primary, strokeWidth: 2),
                                    ),
                                  ),
                                if (!m.isLocal && isDownloaded && !isSelected)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: textColor.withValues(alpha: 0.4)),
                                    onPressed: () => _delete(m),
                                  ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _togglePreview(m),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPlaying ? primary : primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                      color: isPlaying ? Colors.white : primary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
