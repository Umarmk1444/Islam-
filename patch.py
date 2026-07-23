import os

def patch_file():
    filepath = 'lib/controllers/quran_audio_controller.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    start_idx = -1
    for i, line in enumerate(lines):
        if 'Future<void> _fetchSegmentsForChapter' in line:
            start_idx = i
            break
            
    if start_idx == -1:
        print('Start index not found')
        return
        
    end_idx = -1
    brace_count = 0
    found_brace = False
    
    for i in range(start_idx, len(lines)):
        line = lines[i]
        if '{' in line:
            brace_count += line.count('{')
            found_brace = True
        if '}' in line:
            brace_count -= line.count('}')
            
        if found_brace and brace_count == 0:
            end_idx = i
            break
            
    if end_idx == -1:
        print('End index not found')
        return
        
    new_method = """  Future<void> _fetchSegmentsForChapter(int surah, int? quranComId) async {
    _currentChapterSegments = null;
    activeWordPosition = null;
    notifyListeners();

    if (quranComId == null) return;

    try {
      debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=1');
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=50'),
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

        parseVerses(data['verses'] as list);
        
        final pagination = data['pagination'];
        final totalPages = pagination['total_pages'] if pagination.get('total_pages') is not None else 1;
        // Wait, the Dart code should be inside the string!
        
        final totalPages = pagination['total_pages'] as int? ?? 1;
        
        notifyListeners();
        debugPrint('[QuranAudio] Fetched segments for ${_currentChapterSegments!.length} verses (Page 1/$totalPages)');
        
        // Fetch remaining pages asynchronously
        for (int page = 2; page <= totalPages; page++) {
          if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
          try {
            debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=$page');
            final pageRes = await http.get(
              Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=50&page=$page'),
            );
            
            if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
            
            if (pageRes.statusCode == 200) {
              final pageData = json.decode(pageRes.body);
              parseVerses(pageData['verses'] as List);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('[QuranAudio] Error fetching segments page $page: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error fetching segments: $e');
    }
  }
"""
    
    # Python format string might have issue with {} but we are not using f-string, it's just a raw multiline string.
    # Oh wait, I messed up the dart string at `parseVerses(data['verses'] as list);`, it should be `List`.
    # Let me fix that.
    new_method = new_method.replace("parseVerses(data['verses'] as list);", "parseVerses(data['verses'] as List);")
    # Also I have a python syntax inside the dart code: `if pagination.get('total_pages') is not None else 1;`
    # Let's clean the string.
    
    clean_method = """  Future<void> _fetchSegmentsForChapter(int surah, int? quranComId) async {
    _currentChapterSegments = null;
    activeWordPosition = null;
    notifyListeners();

    if (quranComId == null) return;

    try {
      debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=1');
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=50'),
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
        debugPrint('[QuranAudio] Fetched segments for ${_currentChapterSegments!.length} verses (Page 1/$totalPages)');
        
        // Fetch remaining pages asynchronously
        for (int page = 2; page <= totalPages; page++) {
          if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
          try {
            debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=$page');
            final pageRes = await http.get(
              Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=50&page=$page'),
            );
            
            if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
            
            if (pageRes.statusCode == 200) {
              final pageData = json.decode(pageRes.body);
              parseVerses(pageData['verses'] as List);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('[QuranAudio] Error fetching segments page $page: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error fetching segments: $e');
    }
  }
"""
    
    new_lines = [line + '\\n' for line in clean_method.split('\\n')]
    # Remove the extra newline at the end
    if new_lines[-1] == '\\n':
        new_lines.pop()
        
    lines[start_idx:end_idx+1] = new_lines
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    print('Successfully patched _fetchSegmentsForChapter')

patch_file()
