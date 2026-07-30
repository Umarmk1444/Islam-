import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';
import '../../data/models/muezzin_model.dart';
import '../../data/services/muezzin_manager.dart';
import '../controllers/prayer_controller.dart';

class MuezzinSelectionScreen extends StatefulWidget {
  final PrayerController controller;
  const MuezzinSelectionScreen({super.key, required this.controller});

  @override
  State<MuezzinSelectionScreen> createState() => _MuezzinSelectionScreenState();
}

class _MuezzinSelectionScreenState extends State<MuezzinSelectionScreen> {
  final MuezzinManager _manager = MuezzinManager();
  final AudioPlayer _previewPlayer = AudioPlayer();
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _playingMuezzinId;
  Map<String, double> _downloadProgress = {};
  Map<String, bool> _downloadedState = {};

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
        final path = await _manager.getAudioPath(m);
        if (m.isLocal || (m.isLocal == false && path.startsWith('/'))) {
           if (m.isLocal) {
             await _previewPlayer.setAsset(path);
           } else {
             await _previewPlayer.setFilePath(path);
           }
        } else {
           // It's remote and not downloaded, play from URL or fallback
           await _previewPlayer.setAsset('assets/audio/adhan_abdulbasit.mp3');
        }

        _previewPlayer.play();
        
        Future.delayed(const Duration(seconds: 15), () async {
          if (mounted && _playingMuezzinId == m.id) {
            await _previewPlayer.stop();
            if (mounted) setState(() => _playingMuezzinId = null);
          }
        });
      } catch (e) {
        debugPrint('Preview error: $e');
        if (mounted) setState(() => _playingMuezzinId = null);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please download the Adhan first.')));
      return;
    }

    final cfg = widget.controller.config;
    final newMap = {
      'fajr': m.id,
      'sunrise': m.id,
      'dhuhr': m.id,
      'asr': m.id,
      'maghrib': m.id,
      'isha': m.id,
    };
    widget.controller.updateConfig(cfg.copyWith(prayerMuezzins: newMap));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.name} selected for all prayers!'), behavior: SnackBarBehavior.floating),
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

        final currentMuezzinId = widget.controller.config.prayerMuezzins['fajr'] ?? 'adhan_abdulbasit';

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

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: const Text('Premium Muezzins'),
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
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? primary : cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? primary : (isDark ? Colors.white12 : Colors.black12),
                                width: 2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
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
                                    color: isFav ? AppColors.coralRed : (isSelected ? Colors.white70 : textColor.withValues(alpha: 0.5)),
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
                                          color: isSelected ? Colors.white : textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${m.mosque} • ${m.country}',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: isSelected ? Colors.white70 : textColor.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!m.isLocal && !isDownloaded && progress == null)
                                  IconButton(
                                    icon: Icon(Icons.cloud_download_rounded, color: isSelected ? Colors.white : primary),
                                    onPressed: () => _download(m),
                                  ),
                                if (!m.isLocal && progress != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(value: progress, color: isSelected ? Colors.white : primary, strokeWidth: 2),
                                    ),
                                  ),
                                if (!m.isLocal && isDownloaded && !isSelected)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: textColor.withValues(alpha: 0.5)),
                                    onPressed: () => _delete(m),
                                  ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _togglePreview(m),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                      color: isSelected ? primary : primary,
                                      size: 24,
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
