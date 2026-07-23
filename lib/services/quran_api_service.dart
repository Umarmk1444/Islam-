import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  // Mapping language codes to Quran.com Translation IDs
  // 20: Saheeh International (English)
  // 87: Sadiq and Sani (Amharic)
  // 111: Ghali Ababor (Oromo)
  static int _getTranslationId(String languageCode) {
    switch (languageCode) {
      case 'am':
        return 87;
      case 'om':
        return 111;
      case 'en':
      default:
        return 20;
    }
  }

  static Future<String> fetchTranslation(int surah, int ayah, String languageCode) async {
    final translationId = _getTranslationId(languageCode);
    final verseKey = '$surah:$ayah';
    final url = Uri.parse('$baseUrl/verses/by_key/$verseKey?translations=$translationId');
    try {
      debugPrint('[QuranApiService] fetchTranslation url: $url');
      final response = await http.get(url);
      debugPrint('[QuranApiService] fetchTranslation status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final verse = data['verse'];
        if (verse != null && verse['translations'] != null && verse['translations'].isNotEmpty) {
          // Clean up HTML tags that the API sometimes returns
          String text = verse['translations'][0]['text'];
          return text.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      return 'Translation not available for this verse.';
    } catch (e, st) {
      debugPrint('[QuranApiService] Error fetching translation ($url): $e\n$st');
      return 'Error fetching data';
    }
  }

  static Future<String> fetchTranslationByResourceId(int surah, int ayah, int resourceId) async {
    final verseKey = '$surah:$ayah';
    final url = Uri.parse('$baseUrl/verses/by_key/$verseKey?translations=$resourceId');
    try {
      debugPrint('[QuranApiService] fetchTranslationByResourceId url: $url');
      final response = await http.get(url);
      debugPrint('[QuranApiService] fetchTranslationByResourceId status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final verse = data['verse'];
        if (verse != null && verse['translations'] != null && verse['translations'].isNotEmpty) {
          String text = verse['translations'][0]['text'];
          return text.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      return 'Translation not available for this verse.';
    } catch (e, st) {
      debugPrint('[QuranApiService] Error fetching translation by resource ID ($url): $e\n$st');
      return 'Error fetching data';
    }
  }
}

