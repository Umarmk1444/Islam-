import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_zone/l10n/app_localizations.dart';
import 'package:quran_zone/models/minbar_models.dart';
import 'package:quran_zone/screens/live_tv_screen.dart';
import 'package:quran_zone/screens/minbar_tab.dart';
import 'package:quran_zone/services/minbar_cdn_registry.dart';
import 'package:quran_zone/services/minbar_download_service.dart';
import 'package:quran_zone/services/quran_radio_service.dart';
import 'package:quran_zone/services/reciter_english_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minbar CDN Registry Unit Tests', () {
    test('Registry contains all 112 reciters from muslim_house.db and 7 iconic additions (119 total)', () {
      expect(MinbarCdnRegistry.endpoints.length, equals(119));

      for (int id = 1; id <= 119; id++) {
        expect(MinbarCdnRegistry.endpoints.containsKey(id), isTrue,
            reason: 'Reciter ID $id must be present in MinbarCdnRegistry.endpoints');
        final config = MinbarCdnRegistry.endpoints[id]!;
        expect(config.cdnUrl.isNotEmpty, isTrue, reason: 'Reciter $id must have non-empty cdnUrl');
        expect(config.fallbackUrl.isNotEmpty, isTrue, reason: 'Reciter $id must have non-empty fallbackUrl');
        expect(config.cdnUrl, startsWith('https://cdn.mp3quran.net/audio/'));
      }
    });

    test('Primary Surah URLs are generated with 3-digit numbering', () {
      // Reciter 3: Ahmad Al-Ajmi
      final urlSurah1 = MinbarCdnRegistry.getPrimarySurahUrl(3, '001');
      expect(urlSurah1, equals('https://cdn.mp3quran.net/audio/ahmad-ajmi/r1/001.mp3'));

      final urlSurah114 = MinbarCdnRegistry.getPrimarySurahUrl(3, '114');
      expect(urlSurah114, equals('https://cdn.mp3quran.net/audio/ahmad-ajmi/r1/114.mp3'));

      // Reciter 54: Abdullah Basfar
      final urlBasfar = MinbarCdnRegistry.getPrimarySurahUrl(54, '002');
      expect(urlBasfar, equals('https://cdn.mp3quran.net/audio/abdullah-basfar/r1/002.mp3'));

      // Additional Reciter 113: Idris Abkar
      final urlAbkar = MinbarCdnRegistry.getPrimarySurahUrl(113, '001');
      expect(urlAbkar, equals('https://cdn.mp3quran.net/audio/idrees-abkar/r1/001.mp3'));
    });

    test('Candidate URLs provide high-speed CDN primary and legacy fallback without broken backup', () {
      const legacyUrl = 'http://server6.mp3quran.net/akdr/001.mp3';
      final candidates = MinbarCdnRegistry.getCandidateUrls(4, '001', legacyUrl);

      // Primary candidate is the high-speed Cloudflare CDN
      expect(candidates.first, equals('https://cdn.mp3quran.net/audio/ahmad-tarabulsi/r1/001.mp3'));
      // Fallback candidate includes legacy URL
      expect(candidates.contains(legacyUrl), isTrue);
      // Ensure broken backup.qurango.net is never included
      expect(candidates.any((url) => url.contains('backup.qurango.net')), isFalse);
    });

    test('Special Riwayah mappings are preserved accurately', () {
      // ID 4: Ahmad Khidr Al-Tarabulsi - Qaloon
      expect(MinbarCdnRegistry.endpoints[4]?.cdnUrl, equals('https://cdn.mp3quran.net/audio/ahmad-tarabulsi/r1'));

      // ID 62: Ali Al-Hudhaifi - Qaloon
      expect(MinbarCdnRegistry.endpoints[62]?.cdnUrl, equals('https://cdn.mp3quran.net/audio/ali-hudhaifi/r2'));

      // ID 99: Muftah Al-Saltani - Douri
      expect(MinbarCdnRegistry.endpoints[99]?.cdnUrl, equals('https://cdn.mp3quran.net/audio/muftah-saltani/r2'));

      // IDs 10 & 11: Ibrahim Al-Dosari Warsh vs Hafs
      expect(MinbarCdnRegistry.endpoints[10]?.cdnUrl, equals('https://cdn.mp3quran.net/audio/ibrahim-dosari/r1'));
      expect(MinbarCdnRegistry.endpoints[11]?.cdnUrl, equals('https://cdn.mp3quran.net/audio/ibrahim-dosari/r2'));
    });

    test('Non-Quran legacy audio tracks (lectures/duas) maintain their source URLs safely', () {
      const lectureUrl = 'https://archive.org/download/islamic_lectures/lesson01.mp3';
      final candidates = MinbarCdnRegistry.getCandidateUrls(0, '001', lectureUrl);
      expect(candidates.length, equals(1));
      expect(candidates.first, equals(lectureUrl));
    });
  });

  group('Reciter English Directory & Multi-lingual Search Tests', () {
    test('English Directory maps famous reciters to English names and search keywords', () {
      expect(ReciterEnglishDirectory.getEnglishName(91), equals('Mishary Alafasy'));
      expect(ReciterEnglishDirectory.getEnglishName(45), equals('Abdul Rahman Al-Sudais'));
      expect(ReciterEnglishDirectory.getEnglishName(42), equals('Abdul Basit Abdul Samad'));
      expect(ReciterEnglishDirectory.getEnglishName(28), equals('Saad Al-Ghamdi'));
      expect(ReciterEnglishDirectory.getEnglishName(69), equals('Maher Al-Muaiqly'));
      expect(ReciterEnglishDirectory.getEnglishName(107), equals('Yasser Al-Dossari'));
      expect(ReciterEnglishDirectory.getEnglishName(113), equals('Idris Abkar'));
      expect(ReciterEnglishDirectory.getEnglishName(114), equals('Bandar Baleela'));
      expect(ReciterEnglishDirectory.getEnglishName(119), equals('Islam Sobhi'));
    });

    test('Multi-lingual search matches in English (lowercase, prefixes, aliases)', () {
      const authorMishary = MinbarAuthor(id: '91', name: 'مشاري العفاسي', englishName: 'Mishary Alafasy');
      expect(ReciterEnglishDirectory.matches(authorMishary, 'mishary'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorMishary, 'alafasy'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorMishary, 'afasi'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorMishary, 'العفاسي'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorMishary, 'مشاري'), isTrue);

      const authorSudais = MinbarAuthor(id: '45', name: 'عبدالرحمن السديس', englishName: 'Abdul Rahman Al-Sudais');
      expect(ReciterEnglishDirectory.matches(authorSudais, 'sudais'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorSudais, 'abdul rahman'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorSudais, 'السديس'), isTrue);

      const authorGhamdi = MinbarAuthor(id: '28', name: 'سعد الغامدي', englishName: 'Saad Al-Ghamdi');
      expect(ReciterEnglishDirectory.matches(authorGhamdi, 'ghamdi'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorGhamdi, 'saad'), isTrue);

      const authorDossari = MinbarAuthor(id: '107', name: 'ياسر الدوسري', englishName: 'Yasser Al-Dossari');
      expect(ReciterEnglishDirectory.matches(authorDossari, 'dossari'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorDossari, 'dosari'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorDossari, 'yasser'), isTrue);

      const authorSobhi = MinbarAuthor(id: '119', name: 'إسلام صبحي', englishName: 'Islam Sobhi');
      expect(ReciterEnglishDirectory.matches(authorSobhi, 'islam sobhi'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorSobhi, 'sobhi'), isTrue);
      expect(ReciterEnglishDirectory.matches(authorSobhi, 'اسلام'), isTrue);
    });

    test('Curated additional reciters list has 7 verified modern reciters', () {
      expect(ReciterEnglishDirectory.additionalReciters.length, equals(7));
      final names = ReciterEnglishDirectory.additionalReciters.map((r) => r.englishName).toList();
      expect(names, containsAll([
        'Idris Abkar',
        'Bandar Baleela',
        'Khalid Al-Jalil',
        'Raad Al-Kurdi',
        'Hazza Al-Balushi',
        'Mansour Al-Salimi',
        'Islam Sobhi',
      ]));
    });
  });

  group('Live TV Channel Stream Verification Tests', () {
    test('LiveTvScreen has verified active 24/7 video IDs for Makkah and Madinah', () {
      expect(LiveTvScreen.channels.length, equals(2));

      final makkah = LiveTvScreen.channels.firstWhere((c) => c.videoId == 'eC4LfEVxvKg');
      expect(makkah.titleAr, contains('المسجد الحرام'));
      expect(makkah.titleEn, contains('Makkah'));
      expect(makkah.videoId, equals('eC4LfEVxvKg'));

      final madinah = LiveTvScreen.channels.firstWhere((c) => c.videoId == 'Rs7St51oDDc');
      expect(madinah.titleAr, contains('المسجد النبوي'));
      expect(madinah.titleEn, contains('Madinah'));
      expect(madinah.videoId, equals('Rs7St51oDDc'));
    });
  });

  group('Minbar Download Service Engine Tests', () {
    test('Dio client is initialized with proper User-Agent and redirects enabled', () {
      final dio = MinbarDownloadService.instance.dio;
      expect(dio.options.headers['User-Agent'], isNotNull);
      expect(dio.options.headers['User-Agent'].toString(), contains('Mozilla/5.0'));
      expect(dio.options.followRedirects, isTrue);
      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
    });
  });

  group('MinbarTab UI Hierarchy & Layout Tests', () {
    testWidgets('MinbarTab renders Live Broadcasts at top, Quran Hero, and Regional card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: [Locale('ar'), Locale('en')],
          locale: Locale('ar'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MinbarTab(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Quran reciter hero card should be present
      expect(find.text('القرآن الكريم'), findsWidgets);
      expect(find.text('تلاوات ومصاحف كبار القراء'), findsOneWidget);
      expect(find.text('١٠٠+ قارئ'), findsOneWidget);

      // Bento secondary cards
      expect(find.text('الدروس والخطب'), findsOneWidget);
      expect(find.text('المحفوظات'), findsOneWidget);

      // Live broadcasts
      expect(find.text('البث المباشر الحي'), findsOneWidget);
      expect(find.text('الإذاعات الإسلامية'), findsOneWidget);
      expect(find.text('تلفزيون الحرمين'), findsOneWidget);

      // Verify that Regional African languages card is preserved
      expect(find.text('الدروس (አማርኛ & Oromoo)'), findsOneWidget);
      expect(find.text('قريباً'), findsOneWidget);
    });
  });

  group('Quran Radio Service Station & Playback Tests', () {
    test('Service has at least 185 stations with Cairo and Saudi stations featured', () {
      expect(QuranRadioService.stations.length, greaterThanOrEqualTo(185));

      final cairo = QuranRadioService.stations.firstWhere((s) => s.id == 'cairo_quran_radio');
      expect(cairo.name, contains('القاهرة'));
      expect(cairo.englishName, contains('Cairo'));
      expect(cairo.isFeatured, isTrue);
      expect(cairo.url, startsWith('https://stream.radiojar.com/'));

      final saudi = QuranRadioService.stations.firstWhere((s) => s.id == 'saudi_quran_radio');
      expect(saudi.name, contains('السعودية'));
      expect(saudi.englishName, contains('Saudi'));
      expect(saudi.isFeatured, isTrue);
      expect(saudi.url, startsWith('https://stream.radiojar.com/'));
    });

    test('Every radio station has valid id, non-empty names, valid http URL, and category', () {
      for (final station in QuranRadioService.stations) {
        expect(station.id.isNotEmpty, isTrue, reason: 'Station ID should not be empty');
        expect(station.name.isNotEmpty, isTrue, reason: 'Station ${station.id} name should not be empty');
        expect(station.englishName.isNotEmpty, isTrue, reason: 'Station ${station.id} englishName should not be empty');
        expect(station.url.startsWith('http'), isTrue, reason: 'Station ${station.id} url should be valid');
        expect(station.category.isNotEmpty, isTrue, reason: 'Station ${station.id} category should not be empty');
      }
    });

    test('Candidate URLs provide resilient fallback options', () {
      final mishary = QuranRadioService.stations.firstWhere((s) => s.id == 'mishary_alafasi');
      expect(mishary.url, equals('https://qurango.net/radio/mishary_alafasi'));
      expect(mishary.fallbackUrl, equals('https://backup.qurango.net/radio/mishary_alafasi'));
      expect(mishary.candidateUrls.length, equals(2));
      expect(mishary.candidateUrls.first, equals('https://qurango.net/radio/mishary_alafasi'));
      expect(mishary.candidateUrls.last, equals('https://backup.qurango.net/radio/mishary_alafasi'));
    });

    test('Famous reciter and thematic stations are all present and configured correctly', () {
      final famousIds = [
        'cairo_quran_radio',
        'saudi_quran_radio',
        'mishary_alafasi',
        'abdulbasit_abdulsamad',
        'maher_muaiqly',
        'saad_alghamdi',
        'yasser_aldosari',
        'alminshawi',
        'idrees_abkr',
        'khalid_aljileel',
        'bandar_balilah',
        'hazza_albalushi',
        'tarateel_radio',
        'surah_al_mulk',
        'roqiah_radio',
        'athkar_sabah_radio',
        'seerah_radio',
      ];

      for (final id in famousIds) {
        final station = QuranRadioService.stations.firstWhere(
          (s) => s.id == id,
          orElse: () => throw Exception('Station $id not found in QuranRadioService.stations'),
        );
        expect(station.url.isNotEmpty, isTrue);
      }
    });
  });
}

