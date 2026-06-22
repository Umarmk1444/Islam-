import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  // Mapping language codes to Quran.com Translation IDs
  // 131: Clear Quran (English)
  // 9: Dr. Mustafa Khattab (English) - default
  // 31: Amharic (Muhammed Sadiq)
  // 109: Oromo (Abubakar Ousman)
  static int _getTranslationId(String languageCode) {
    switch (languageCode) {
      case 'am':
        return 31;
      case 'om':
        return 109;
      case 'ar':
        return 9; // Arabic doesn't need translation, but providing fallback
      case 'en':
      default:
        return 131; // Clear Quran
    }
  }

  // Tafsir IDs
  // 169: Tafsir Ibn Kathir (English)
  // Note: Quran.com might not have Amharic/Oromo tafsir, fallback to English/Arabic
  static int _getTafsirId(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 16; // Tafsir Al-Jalalayn
      case 'en':
      default:
        return 169; // Ibn Kathir
    }
  }

  static Future<String> fetchTranslation(int surah, int ayah, String languageCode) async {
    try {
      final translationId = _getTranslationId(languageCode);
      // endpoint: /api/v4/quran/translations/:id
      // However, to get a specific ayah translation, it's better to use:
      // /api/v4/verses/by_key/:surah_number::ayah_number?translations=:id
      final verseKey = '$surah:$ayah';
      final response = await http.get(Uri.parse('$baseUrl/verses/by_key/$verseKey?translations=$translationId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verse = data['verse'];
        if (verse != null && verse['translations'] != null && verse['translations'].isNotEmpty) {
          // Clean up HTML tags that the API sometimes returns
          String text = verse['translations'][0]['text'];
          return text.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      return 'Translation not available for this verse.';
    } catch (e) {
      debugPrint('Error fetching translation: $e');
      return 'Error fetching data';
    }
  }

  static Future<String> fetchTafsir(int surah, int ayah, String languageCode) async {
    try {
      final tafsirId = _getTafsirId(languageCode);
      final verseKey = '$surah:$ayah';
      final response = await http.get(Uri.parse('$baseUrl/tafsirs/$tafsirId/by_ayah/$verseKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tafsir = data['tafsir'];
        if (tafsir != null && tafsir['text'] != null) {
          String text = tafsir['text'];
          return text.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      return 'Tafsir not available for this verse.';
    } catch (e) {
      debugPrint('Error fetching tafsir: $e');
      return 'Error fetching data';
    }
  }
}
