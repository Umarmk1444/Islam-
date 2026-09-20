import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/play_asset_delivery_service.dart';

class WoffFontLoader {
  static final Set<String> _loadedFonts = {};
  static final Map<int, Future<bool>> _loadingFutures = {};

  static bool isPageFontLoaded(int pageNumber) {
    final fontName = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    return _loadedFonts.contains(fontName);
  }

  static const Set<int> localQcfPages = {
    52, 62, 113, 120, 217, 261, 263, 267, 277, 282, 296,
    304, 307, 311, 321, 421, 473, 499, 543, 557, 563, 580
  };

  /// Decodes a WOFF 1.0 font binary into a standard TrueType / OpenType (TTF) binary.
  static Uint8List? woffToTtf(Uint8List woffBytes) {
    if (woffBytes.length < 44) return null;
    final ByteData bd = ByteData.sublistView(woffBytes);

    final magic = bd.getUint32(0);
    // If not 'wOFF' (0x774F4646), it is already TTF/OTF
    if (magic != 0x774F4646) {
      return woffBytes;
    }

    final flavor = bd.getUint32(4);
    final numTables = bd.getUint16(12);
    final totalSfntSize = bd.getUint32(16);

    int maxPowerOf2 = 1;
    while ((maxPowerOf2 * 2) <= numTables) {
      maxPowerOf2 *= 2;
    }
    final searchRange = maxPowerOf2 * 16;
    int entrySelector = 0;
    int temp = maxPowerOf2;
    while (temp > 1) {
      entrySelector++;
      temp ~/= 2;
    }
    final rangeShift = (numTables * 16) - searchRange;

    final headerSize = 12 + (numTables * 16);
    final ttfData = Uint8List(totalSfntSize);
    final ttfBd = ByteData.sublistView(ttfData);

    ttfBd.setUint32(0, flavor);
    ttfBd.setUint16(4, numTables);
    ttfBd.setUint16(6, searchRange);
    ttfBd.setUint16(8, entrySelector);
    ttfBd.setUint16(10, rangeShift);

    int currentTtfOffset = headerSize;
    int woffDirOffset = 44;

    for (int i = 0; i < numTables; i++) {
      final tag = bd.getUint32(woffDirOffset);
      final offset = bd.getUint32(woffDirOffset + 4);
      final compLength = bd.getUint32(woffDirOffset + 8);
      final origLength = bd.getUint32(woffDirOffset + 12);
      final origChecksum = bd.getUint32(woffDirOffset + 16);

      Uint8List tableData;
      final rawSlice = Uint8List.sublistView(woffBytes, offset, offset + compLength);
      if (compLength < origLength) {
        tableData = Uint8List.fromList(zlib.decode(rawSlice));
      } else {
        tableData = rawSlice;
      }

      final dirRecordOffset = 12 + (i * 16);
      ttfBd.setUint32(dirRecordOffset, tag);
      ttfBd.setUint32(dirRecordOffset + 4, origChecksum);
      ttfBd.setUint32(dirRecordOffset + 8, currentTtfOffset);
      ttfBd.setUint32(dirRecordOffset + 12, origLength);

      ttfData.setRange(currentTtfOffset, currentTtfOffset + tableData.length, tableData);

      int paddedLength = (origLength + 3) & ~3;
      currentTtfOffset += paddedLength;
      woffDirOffset += 20;
    }

    return ttfData;
  }

  /// Dynamically converts and registers the font for a specific Quran page.
  static Future<bool> ensurePageFontLoaded(int pageNumber) async {
    if (kIsWeb) return true;

    // Always ensure shared fonts (surah names, Basmala) are loaded
    await ensureCommonFontsLoaded();

    final fontName = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    if (_loadedFonts.contains(fontName)) return true;

    if (_loadingFutures.containsKey(pageNumber)) {
      return await _loadingFutures[pageNumber]!;
    }

    final future = _loadFontInternal(pageNumber, fontName);
    _loadingFutures[pageNumber] = future;
    try {
      return await future;
    } finally {
      _loadingFutures.remove(pageNumber);
    }
  }

  static Future<bool> _loadFontInternal(int pageNumber, String fontName) async {
    try {
      final woffNum = pageNumber.toString().padLeft(3, '0');
      Uint8List? rawBytes;

      // 1. If it's one of the preserved offline fonts in assets/fonts/
      if (localQcfPages.contains(pageNumber)) {
        try {
          final bd = await rootBundle.load('assets/fonts/QCF4${woffNum}_X-Regular.woff');
          rawBytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
        } catch (_) {}
      }

      // 2. Load from Google Play Asset Pack directory
      if (rawBytes == null) {
        final fontsDir = await PlayAssetDeliveryService.instance.getFontsDirectoryPath();
        if (fontsDir != null) {
          final candidateFiles = [
            File('$fontsDir/qcf4/QCF4${woffNum}_X-Regular.woff'),
            File('$fontsDir/QCF4${woffNum}_X-Regular.woff'),
          ];
          for (final f in candidateFiles) {
            if (await f.exists()) {
              rawBytes = await f.readAsBytes();
              break;
            }
          }
        }
      }

      // 3. Load from local documents cache or download on-demand (28 KB)
      rawBytes ??= await PlayAssetDeliveryService.instance.downloadSinglePageFont(pageNumber);

      // 4. Last fallback: rootBundle
      if (rawBytes == null) {
        try {
          final bd = await rootBundle.load('assets/fonts/QCF4${woffNum}_X-Regular.woff');
          rawBytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
        } catch (_) {}
      }

      if (rawBytes == null) return false;

      // Convert WOFF to TTF if needed
      final ttfBytes = woffToTtf(rawBytes) ?? rawBytes;

      // Register under both bare font name and package font name for maximum compatibility
      for (final name in [fontName, 'packages/qcf_quran/$fontName']) {
        final fontLoader = FontLoader(name);
        fontLoader.addFont(Future.value(ByteData.view(ttfBytes.buffer, ttfBytes.offsetInBytes, ttfBytes.lengthInBytes)));
        await fontLoader.load();
      }

      _loadedFonts.add(fontName);
      return true;
    } catch (e) {
      debugPrint('[WoffFontLoader] Failed to load font $fontName: $e');
      return false;
    }
  }

  /// Loads common shared fonts like Surah name calligraphy ('surahname') and Basmala ('QCF_BSML')
  static Future<void> ensureCommonFontsLoaded() async {
    if (kIsWeb) return;

    if (_loadedFonts.contains('__common_fonts__')) return;
    _loadedFonts.add('__common_fonts__');

    // 1. Load Surah Name calligraphy font
    await _loadCustomFont(
      assetPaths: ['assets/fonts/surah-name-v2.woff'],
      assetPackSubPaths: ['surah-name-v2.woff', 'qcf4/../surah-name-v2.woff'],
      fontFamilies: ['surahname', 'packages/qcf_quran/surahname', 'SurahName', 'packages/qcf_quran/SurahName'],
    );

    // 2. Load BSML (Basmala) font
    await _loadCustomFont(
      assetPaths: ['assets/fonts/QCF4_QBSML-Regular.woff'],
      assetPackSubPaths: ['QCF2BSMLfonts/QCF4_QBSML-Regular.woff'],
      fontFamilies: ['QCF_BSML', 'packages/qcf_quran/QCF_BSML'],
    );
  }

  static Future<void> _loadCustomFont({
    required List<String> assetPaths,
    required List<String> assetPackSubPaths,
    required List<String> fontFamilies,
  }) async {
    try {
      Uint8List? rawBytes;

      // 1. Try root bundle
      for (final p in assetPaths) {
        try {
          final bd = await rootBundle.load(p);
          rawBytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
          break;
        } catch (_) {}
      }

      // 2. Try asset pack
      if (rawBytes == null) {
        final fontsDir = await PlayAssetDeliveryService.instance.getFontsDirectoryPath();
        if (fontsDir != null) {
          for (final sub in assetPackSubPaths) {
            final f = File('$fontsDir/$sub');
            if (await f.exists()) {
              rawBytes = await f.readAsBytes();
              break;
            }
          }
        }
      }

      if (rawBytes == null) return;

      final ttfBytes = woffToTtf(rawBytes) ?? rawBytes;

      for (final family in fontFamilies) {
        final fontLoader = FontLoader(family);
        fontLoader.addFont(Future.value(ByteData.view(ttfBytes.buffer, ttfBytes.offsetInBytes, ttfBytes.lengthInBytes)));
        await fontLoader.load();
      }
    } catch (e) {
      debugPrint('[WoffFontLoader] Failed to load custom font $fontFamilies: $e');
    }
  }
}
