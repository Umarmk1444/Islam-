import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

void main() {
  test('Print QCF codes', () {
    print('Surah 2 Verse 2 (Stop mark ۛ):');
    print(getVerseQCF(2, 2, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());
    
    print('Surah 2 Verse 25 (Hizb ۞):');
    print(getVerseQCF(2, 25, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());

    print('Surah 7 Verse 206 (Sajdah ۩):');
    print(getVerseQCF(7, 206, verseEndSymbol: true).runes.map((r) => r.toRadixString(16).padLeft(4, '0')).toList());
  });
}
