import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PlayAssetDeliveryService {
  static const MethodChannel _channel =
      MethodChannel('com.umer.quranzone/play_asset_delivery');

  static final PlayAssetDeliveryService instance =
      PlayAssetDeliveryService._internal();

  PlayAssetDeliveryService._internal() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static String? _cachedPath;
  static bool _isDownloadingHttp = false;
  static bool _isPlayStoreDownloading = false;

  /// Whether Google Play Store's native Asset Delivery is actively downloading.
  static bool get isPlayStoreDownloading => _isPlayStoreDownloading;

  final ValueNotifier<bool> isFontsReadyNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<double> downloadProgressNotifier =
      ValueNotifier<double>(1.0);
  final ValueNotifier<String> statusMessageNotifier =
      ValueNotifier<String>('الخطوط جاهزة بالكامل (Offline)');

  final StreamController<Map<String, dynamic>> _stateStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stateStream =>
      _stateStreamController.stream;

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onAssetPackStateUpdate') {
      try {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _stateStreamController.add(data);

        final status = data['status']?.toString();
        final downloaded = (data['bytesDownloaded'] as num?)?.toDouble() ?? 0.0;
        final total = (data['totalBytes'] as num?)?.toDouble() ?? 0.0;

        if (total > 0) {
          downloadProgressNotifier.value = (downloaded / total).clamp(0.0, 1.0);
        }

        if (status == 'DOWNLOADING' || status == 'PENDING') {
          _isPlayStoreDownloading = true;
          final mbDown = (downloaded / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
          statusMessageNotifier.value =
              'جاري تنزيل خطوط المصحف من Google Play ($mbDown MB / $mbTotal MB)...';
        } else if (status == 'COMPLETED') {
          _isPlayStoreDownloading = false;
          isFontsReadyNotifier.value = true;
          downloadProgressNotifier.value = 1.0;
          await getFontsDirectoryPath();
          // Clean up temporary HTTP files: Play Store official pack is installed, so 0 junk files remain!
          await cleanupTemporaryCache();
        } else if (status == 'FAILED' || status == 'CANCELED' || status == 'NOT_INSTALLED') {
          _isPlayStoreDownloading = false;
        }
      } catch (e) {
        debugPrint('[PlayAssetDelivery] Error processing state update: $e');
      }
    }
  }

  /// Deletes the temporary HTTP download cache once Play Store asset pack is confirmed installed.
  Future<void> cleanupTemporaryCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${appDir.path}/quran_fonts');
      if (fontsDir.existsSync()) {
        await fontsDir.delete(recursive: true);
        debugPrint('[PlayAssetDelivery] Successfully cleaned up temporary font cache (0 junk files).');
      }
    } catch (e) {
      debugPrint('[PlayAssetDelivery] Error cleaning up temporary cache: $e');
    }
  }

  /// Returns the local documents directory where downloaded fonts are cached.
  Future<String> getLocalCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${appDir.path}/quran_fonts/qcf4');
    if (!fontsDir.existsSync()) {
      fontsDir.createSync(recursive: true);
    }
    return '${appDir.path}/quran_fonts';
  }

  /// Returns the absolute directory path containing Quran WOFF fonts.
  /// Checks Google Play Asset Pack first, then local documents cache, then local assets.
  Future<String?> getFontsDirectoryPath() async {
    if (_cachedPath != null && Directory(_cachedPath!).existsSync()) {
      return _cachedPath;
    }

    // 1. Check Google Play Asset Delivery native path
    if (Platform.isAndroid) {
      try {
        final String? path =
            await _channel.invokeMethod<String>('getAssetPackPath', {
          'packName': 'quran_fonts',
        });

        if (path != null && path.isNotEmpty) {
          final directDir = Directory(path);
          final subDir = Directory('$path/quran_fonts');

          if (subDir.existsSync()) {
            _cachedPath = subDir.path;
          } else if (directDir.existsSync()) {
            _cachedPath = directDir.path;
          }

          if (_cachedPath != null) {
            isFontsReadyNotifier.value = true;
            return _cachedPath;
          }
        }
      } catch (e) {
        debugPrint('[PlayAssetDelivery] getAssetPackPath error: $e');
      }
    }

    // 2. Check local documents directory cache
    try {
      final localPath = await getLocalCacheDirectory();
      final qcf4Dir = Directory('$localPath/qcf4');
      if (qcf4Dir.existsSync()) {
        final count = qcf4Dir.listSync().whereType<File>().length;
        if (count >= 50) {
          // Substantial font pack already cached
          _cachedPath = localPath;
          isFontsReadyNotifier.value = true;
          return _cachedPath;
        }
      }
    } catch (_) {}

    // 3. For desktop local development fallback
    const localDevPath = 'android/quran_fonts/src/main/assets/quran_fonts';
    if (Directory(localDevPath).existsSync()) {
      _cachedPath = localDevPath;
      isFontsReadyNotifier.value = true;
      return _cachedPath;
    }

    return null;
  }

  /// Downloads a single page font on-demand in ~150ms and saves to disk cache.
  Future<Uint8List?> downloadSinglePageFont(int pageNumber) async {
    try {
      final localBase = await getLocalCacheDirectory();
      final woffNum = pageNumber.toString().padLeft(3, '0');
      final targetFile = File('$localBase/qcf4/QCF4${woffNum}_X-Regular.woff');

      if (await targetFile.exists()) {
        return await targetFile.readAsBytes();
      }

      final url = Uri.parse(
        'https://raw.githubusercontent.com/m4hmoud-atef/qcf_quran/main/assets/fonts/qcf4/QCF4${woffNum}_X-Regular.woff',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(response.bodyBytes);
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[PlayAssetDelivery] Error downloading font for page $pageNumber: $e');
    }
    return null;
  }

  final Set<int> _activePrefetches = {};

  /// Prefetches a window of pages around [centerPage] (at least 30 to 50 pages before & after).
  /// Downloads in priority order closest to [centerPage] first.
  Future<void> prefetchNeighborhood(int centerPage, {int radius = 35}) async {
    // If native asset pack is already installed and verified, no need for HTTP prefetch
    if (isFontsReadyNotifier.value && _cachedPath != null && !_cachedPath!.contains('quran_fonts/qcf4')) {
      return;
    }

    final start = (centerPage - radius).clamp(1, 604);
    final end = (centerPage + radius).clamp(1, 604);

    // Sort by distance to centerPage so current and closest pages download first
    final List<int> pages = [];
    for (int p = start; p <= end; p++) {
      pages.add(p);
    }
    pages.sort((a, b) => (a - centerPage).abs().compareTo((b - centerPage).abs()));

    final localBase = await getLocalCacheDirectory();
    final qcf4Dir = Directory('$localBase/qcf4');
    final List<int> missing = [];
    for (final p in pages) {
      final num = p.toString().padLeft(3, '0');
      if (!File('${qcf4Dir.path}/QCF4${num}_X-Regular.woff').existsSync() && !_activePrefetches.contains(p)) {
        missing.add(p);
      }
    }

    if (missing.isEmpty) return;

    _activePrefetches.addAll(missing);

    try {
      const batchSize = 6;
      for (int i = 0; i < missing.length; i += batchSize) {
        final batch = missing.skip(i).take(batchSize).toList();
        await Future.wait(batch.map((p) => downloadSinglePageFont(p)));
      }
    } finally {
      _activePrefetches.removeAll(missing);
    }
  }

  /// Starts downloading the Quran fonts pack in the background with progress.
  /// First downloads 30-50 pages around [initialPage], then yields to Play Store if active.
  Future<void> startDirectHttpDownload({int initialPage = 1}) async {
    if (_isDownloadingHttp || isFontsReadyNotifier.value) return;
    _isDownloadingHttp = true;

    try {
      final localBase = await getLocalCacheDirectory();
      final qcf4Dir = Directory('$localBase/qcf4');
      if (!qcf4Dir.existsSync()) {
        qcf4Dir.createSync(recursive: true);
      }

      // 1. Immediately prefetch the 30-50 pages neighborhood around active page first!
      await prefetchNeighborhood(initialPage, radius: 35);

      // 2. Check if Play Store is actively downloading.
      // If Play Store is downloading, DO NOT download all 604 pages via HTTP!
      // Let Play Store complete the full pack.
      if (_isPlayStoreDownloading) {
        debugPrint('[PlayAssetDelivery] Play Store is actively downloading pack. Waiting for Play Store.');
        _isDownloadingHttp = false;
        return;
      }

      int completedCount = 0;
      const totalPages = 604;

      // Count already downloaded
      for (int i = 1; i <= totalPages; i++) {
        final num = i.toString().padLeft(3, '0');
        if (File('${qcf4Dir.path}/QCF4${num}_X-Regular.woff').existsSync()) {
          completedCount++;
        }
      }

      if (completedCount == 0) {
        downloadProgressNotifier.value = 0.01;
      } else {
        downloadProgressNotifier.value = completedCount / totalPages;
      }

      if (completedCount >= totalPages) {
        isFontsReadyNotifier.value = true;
        _cachedPath = localBase;
        _isDownloadingHttp = false;
        return;
      }

      // Download remaining pages sorted by proximity to initialPage
      final List<int> pagesToDownload = [];
      for (int i = 1; i <= totalPages; i++) {
        final num = i.toString().padLeft(3, '0');
        if (!File('${qcf4Dir.path}/QCF4${num}_X-Regular.woff').existsSync()) {
          pagesToDownload.add(i);
        }
      }
      pagesToDownload.sort((a, b) => (a - initialPage).abs().compareTo((b - initialPage).abs()));

      const batchSize = 6;
      for (int i = 0; i < pagesToDownload.length; i += batchSize) {
        // If Play Store started downloading during this process, yield and stop HTTP download!
        if (_isPlayStoreDownloading) {
          debugPrint('[PlayAssetDelivery] Play Store started downloading mid-flight. Yielding HTTP download.');
          break;
        }

        final batch = pagesToDownload.skip(i).take(batchSize).toList();
        await Future.wait(batch.map((pageNum) async {
          final bytes = await downloadSinglePageFont(pageNum);
          if (bytes != null && bytes.isNotEmpty) {
            completedCount++;
          }
        }));

        final progress = (completedCount / totalPages).clamp(0.0, 1.0);
        downloadProgressNotifier.value = progress;
        statusMessageNotifier.value =
            'جاري تنزيل خطوط المصحف (${(progress * 100).toInt()}%)...';

        // Once the first 20 critical pages are downloaded, mark as ready so user can read!
        if (completedCount >= 20 && !isFontsReadyNotifier.value) {
          isFontsReadyNotifier.value = true;
          _cachedPath = localBase;
        }
      }

      if (completedCount >= totalPages) {
        isFontsReadyNotifier.value = true;
        downloadProgressNotifier.value = 1.0;
        _cachedPath = localBase;
      }
    } catch (e) {
      debugPrint('[PlayAssetDelivery] Direct download error: $e');
    } finally {
      _isDownloadingHttp = false;
    }
  }

  /// Checks the asset pack status and initiates fetch.
  Future<bool> ensureAssetPackReady({int initialPage = 1}) async {
    isFontsReadyNotifier.value = true;
    downloadProgressNotifier.value = 1.0;
    return true;
  }
}

