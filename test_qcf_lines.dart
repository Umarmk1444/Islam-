import 'package:qcf_quran/qcf_quran.dart';

void main() {
  int pageNum = 2; // Surah Al-Baqarah, first page
  var ranges = getPageData(pageNum);
  
  List<String> lines = [""];
  for (var r in ranges) {
    int surah = r['surah'];
    int start = r['start'];
    int end = r['end'];
    for (int v = start; v <= end; v++) {
      String qcf = getVerseQCF(surah, v, verseEndSymbol: true);
      // Iterate chars
      for (int i = 0; i < qcf.length; i++) {
        String char = qcf[i];
        if (char == '\n') {
          lines.add("");
        } else {
          lines[lines.length - 1] += char;
        }
      }
    }
  }

  print('Page $pageNum has ${lines.length} lines');
  for (int i = 0; i < lines.length; i++) {
    print('Line ${i + 1}: length ${lines[i].length} characters');
  }
}
