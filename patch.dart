import 'dart:io';

void main() {
  final file = File('lib/controllers/quran_audio_controller.dart');
  final lines = file.readAsLinesSync();
  
  final startIdx = lines.indexWhere((l) => l.contains('Future<void> _fetchSegmentsForChapter'));
  if (startIdx == -1) {
    print('Could not find start index');
    return;
  }
  
  int endIdx = -1;
  int braceCount = 0;
  bool foundBrace = false;
  
  for (int i = startIdx; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('{')) {
      braceCount += line.split('{').length - 1;
      foundBrace = true;
    }
    if (line.contains('}')) {
      braceCount -= line.split('}').length - 1;
    }
    
    if (foundBrace && braceCount == 0) {
      endIdx = i;
      break;
    }
  }
  
  if (endIdx == -1) {
    print('Could not find end index');
    return;
  }
  
  final newMethod = '''
  Future<void> _fetchSegmentsForChapter(int surah, int? quranComId) async {
    _currentChapterSegments = null;
    activeWordPosition = null;
    notifyListeners();

    if (quranComId == null) return;

    try {
      debugPrint('[QuranAudio] Fetching segments for surah=\$surah audio=\$quranComId page=1');
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/\$surah?words=true&audio=\$quranComId&per_page=50'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentChapterSegments = {};
        
        void parseVerses(List verses) {
          if (_currentChapterSegments == null) return;
          for (final verse in verses) {
            final audio = verse['audio'];
            if (audio != null && audio['segments'] != null) {
              _currentChapterSegments![verse['verse_key']] = audio['segments'];
            }
          }
        }

        parseVerses(data['verses'] as List);
        
        final pagination = data['pagination'];
        final totalPages = pagination['total_pages'] as int? ?? 1;
        
        notifyListeners();
        debugPrint('[QuranAudio] Fetched segments for \${_currentChapterSegments!.length} verses (Page 1/\$totalPages)');
        
        // Fetch remaining pages asynchronously
        for (int page = 2; page <= totalPages; page++) {
          if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
          try {
            debugPrint('[QuranAudio] Fetching segments for surah=\$surah audio=\$quranComId page=\$page');
            final pageRes = await http.get(
              Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/\$surah?words=true&audio=\$quranComId&per_page=50&page=\$page'),
            );
            
            if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
            
            if (pageRes.statusCode == 200) {
              final pageData = json.decode(pageRes.body);
              parseVerses(pageData['verses'] as List);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('[QuranAudio] Error fetching segments page \$page: \$e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error fetching segments: \$e');
    }
  }'''.split('\\n');
  
  lines.replaceRange(startIdx, endIdx + 1, newMethod);
  file.writeAsStringSync(lines.join('\\n'));
  print('Successfully patched _fetchSegmentsForChapter');
}
