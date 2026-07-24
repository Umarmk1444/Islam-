import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../models/minbar_models.dart';
import '../core/database/downloads_database.dart';
import 'dart:developer' as dev;

class MinbarDownloadService {
  MinbarDownloadService._internal();
  static final MinbarDownloadService instance = MinbarDownloadService._internal();
  factory MinbarDownloadService() => instance;

  final Dio _dio = Dio();
  final DownloadsDatabase _db = DownloadsDatabase.instance;
  
  // Real-time progress map: { itemId: progressPercentage (0.0 to 1.0) }
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

  // Active cancel tokens
  final Map<String, CancelToken> _cancelTokens = {};

  Future<void> init() async {
    // Optional initialization
  }

  /// Check if an item is already downloaded and returns its path
  Future<String?> getLocalPath(String itemId) async {
    return await _db.getLocalPath(itemId);
  }

  /// Downloads a single item
  Future<bool> downloadItem({
    required MinbarAudioItem item,
    required String authorName,
    required String categoryId,
  }) async {
    // 1. Check Internet connection
    final hasConnection = await InternetConnection().hasInternetAccess;
    if (!hasConnection) {
      dev.log('No internet connection', name: 'MinbarDownloadService');
      return false;
    }

    // 2. Prevent duplicate downloads
    if (_cancelTokens.containsKey(item.id)) {
      dev.log('Already downloading ${item.id}', name: 'MinbarDownloadService');
      return false;
    }

    if (await getLocalPath(item.id) != null) {
      dev.log('Already downloaded ${item.id}', name: 'MinbarDownloadService');
      return true;
    }

    // 3. Setup CancelToken and Path
    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    final docDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(p.join(docDir.path, 'minbar_audio'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    // e.g. minbar_audio/quran_1_114.mp3
    final fileName = '${item.id}.mp3';
    final savePath = p.join(downloadsDir.path, fileName);

    try {
      dev.log('Starting download for ${item.id} -> $savePath', name: 'MinbarDownloadService');
      
      // Initialize progress at 0.01 so UI shows downloading state immediately
      _updateProgress(item.id, 0.01);

      await _dio.download(
        item.url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            _updateProgress(item.id, progress);
          }
        },
      );

      // Save to Database
      await _db.saveDownloadRecord(
        track: item,
        localPath: savePath,
        authorName: authorName,
        categoryId: categoryId,
      );
      dev.log('Download complete for ${item.id}', name: 'MinbarDownloadService');
      return true;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        dev.log('Download cancelled for ${item.id}', name: 'MinbarDownloadService');
      } else {
        dev.log('Download failed for ${item.id}: $e', name: 'MinbarDownloadService');
      }
      // Cleanup partial file if exists
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }
      return false;
    } finally {
      _cancelTokens.remove(item.id);
      _removeProgress(item.id);
    }
  }

  /// Cancels an active download
  void cancelDownload(String itemId) {
    if (_cancelTokens.containsKey(itemId)) {
      _cancelTokens[itemId]?.cancel('User cancelled download');
      _cancelTokens.remove(itemId);
      _removeProgress(itemId);
    }
  }

  /// Deletes a downloaded file and its database record
  Future<void> deleteDownload(String itemId) async {
    cancelDownload(itemId); // In case it's currently downloading
    final path = await _db.getLocalPath(itemId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await _db.deleteDownloadRecord(itemId);
      dev.log('Deleted downloaded file for $itemId', name: 'MinbarDownloadService');
    }
  }

  /// Helper to update progress map
  void _updateProgress(String id, double progress) {
    final currentMap = Map<String, double>.from(downloadProgress.value);
    currentMap[id] = progress;
    downloadProgress.value = currentMap;
  }

  /// Helper to remove progress map entry
  void _removeProgress(String id) {
    final currentMap = Map<String, double>.from(downloadProgress.value);
    currentMap.remove(id);
    downloadProgress.value = currentMap;
  }
}
