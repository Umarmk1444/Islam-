import 'package:flutter_test/flutter_test.dart';

import 'package:qcf_quran/qcf_quran.dart';

void main() {
  test('Print QCF codes', () {
    // ignore: avoid_print
    print('Surah 2 Verse 2 (Stop mark ۛ):');
    // ignore: avoid_print
    print(getVerseQCF(2, 2, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());
    
    // ignore: avoid_print
    print('Surah 2 Verse 25 (Hizb ۞):');
    // ignore: avoid_print
    print(getVerseQCF(2, 25, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());

    // ignore: avoid_print
    print('Surah 7 Verse 206 (Sajdah ۩):');
    // ignore: avoid_print
    print(getVerseQCF(7, 206, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());
  });
}
