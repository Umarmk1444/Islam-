import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_pdfviewer_platform_interface/pdfviewer_platform_interface.dart';

class PdfThumbnailService {
  static final PdfThumbnailService _instance = PdfThumbnailService._internal();
  factory PdfThumbnailService() => _instance;
  PdfThumbnailService._internal();

  Directory? _thumbDir;
  final Set<String> _inFlightGenerations = {};

  Future<Directory> _getThumbnailDir() async {
    if (_thumbDir != null && await _thumbDir!.exists()) {
      return _thumbDir!;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'imported_books', 'thumbnails'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _thumbDir = dir;
    return dir;
  }

  /// Returns the file path if a thumbnail for this book & page already exists on disk.
  Future<String?> getExistingThumbnailPath(int bookId, int pageNumber) async {
    try {
      final dir = await _getThumbnailDir();
      final targetFile = File(p.join(dir.path, 'book_${bookId}_p$pageNumber.png'));
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('[PdfThumbnailService] Error checking thumbnail: $e');
    }
    return null;
  }

  /// Synchronously checks if a thumbnail exists (useful inside build methods).
  String? getExistingThumbnailPathSync(int bookId, int pageNumber) {
    if (_thumbDir == null) return null;
    final targetFile = File(p.join(_thumbDir!.path, 'book_${bookId}_p$pageNumber.png'));
    if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
      return targetFile.path;
    }
    return null;
  }

  /// Generates a high-quality page thumbnail image and saves it to disk.
  /// Returns the path to the saved PNG file.
  Future<String?> generateThumbnail({
    required int bookId,
    required String filePath,
    required int pageNumber,
    int width = 360,
    int height = 500,
  }) async {
    final key = '$bookId-$pageNumber';
    if (_inFlightGenerations.contains(key)) return null;
    _inFlightGenerations.add(key);

    final docId = 'thumb_${bookId}_${DateTime.now().microsecondsSinceEpoch}';

    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        _inFlightGenerations.remove(key);
        return null;
      }

      final dir = await _getThumbnailDir();
      final targetFile = File(p.join(dir.path, 'book_${bookId}_p$pageNumber.png'));

      // If already generated, return immediately
      if (await targetFile.exists() && await targetFile.length() > 0) {
        _inFlightGenerations.remove(key);
        return targetFile.path;
      }

      // Initialize renderer on platform
      final pageCountStr = await PdfViewerPlatform.instance.loadPdfFromFile(filePath, docId, null);
      final totalCount = int.tryParse(pageCountStr ?? '') ?? 1;
      final safePage = (pageNumber > 0 && pageNumber <= totalCount) ? pageNumber : 1;

      // Extract raw bitmap pixels
      final rawBytes = await PdfViewerPlatform.instance.getPage(safePage, width, height, docId);

      // Close renderer to release file descriptor
      try {
        await PdfViewerPlatform.instance.closeDocument(docId);
      } catch (_) {}

      if (rawBytes == null || rawBytes.isEmpty) {
        _inFlightGenerations.remove(key);
        return null;
      }

      // Decode raw RGBA8888 buffer into a PNG image
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rawBytes,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image image) => completer.complete(image),
      );

      final uiImage = await completer.future;
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      uiImage.dispose();

      if (byteData == null) {
        _inFlightGenerations.remove(key);
        return null;
      }

      final pngBytes = byteData.buffer.asUint8List();
      await targetFile.writeAsBytes(pngBytes, flush: true);

      // Clean up previous page thumbnails for this book to keep storage minimal
      _cleanupOldThumbnails(dir, bookId, pageNumber);

      _inFlightGenerations.remove(key);
      return targetFile.path;
    } catch (e) {
      debugPrint('[PdfThumbnailService] Error generating thumbnail: $e');
      try {
        await PdfViewerPlatform.instance.closeDocument(docId);
      } catch (_) {}
      _inFlightGenerations.remove(key);
      return null;
    }
  }

  void _cleanupOldThumbnails(Directory dir, int bookId, int currentPage) {
    try {
      final prefix = 'book_${bookId}_p';
      final currentName = 'book_${bookId}_p$currentPage.png';
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.startsWith(prefix) && name != currentName) {
            entity.deleteSync();
          }
        }
      }
    } catch (_) {}
  }
}
