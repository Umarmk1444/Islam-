import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WoffFontLoader {
  static final Set<String> _loadedFonts = {};

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

  /// Dynamically converts and registers the WOFF font for a specific Quran page
  /// on platforms that do not natively decode WOFF in DirectWrite (such as Windows).
  static Future<void> ensurePageFontLoaded(int pageNumber) async {
    if (kIsWeb || (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
      return;
    }

    final fontName = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    if (_loadedFonts.contains(fontName)) return;
    _loadedFonts.add(fontName);

    try {
      final woffNum = pageNumber.toString().padLeft(3, '0');
      final possiblePaths = [
        'packages/qcf_quran/assets/fonts/qcf4/QCF4${woffNum}_X-Regular.woff',
        'assets/fonts/QCF4${woffNum}_X-Regular.woff',
      ];

      ByteData? byteData;
      for (final p in possiblePaths) {
        try {
          byteData = await rootBundle.load(p);
          break;
        } catch (_) {}
      }

      if (byteData == null) return;

      final rawBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final ttfBytes = woffToTtf(rawBytes);

      if (ttfBytes != null) {
        final fontLoader = FontLoader(fontName);
        fontLoader.addFont(Future.value(ByteData.view(ttfBytes.buffer, ttfBytes.offsetInBytes, ttfBytes.lengthInBytes)));
        await fontLoader.load();
      }
    } catch (e) {
      debugPrint('[WoffFontLoader] Failed to load font $fontName: $e');
    }
  }
}
