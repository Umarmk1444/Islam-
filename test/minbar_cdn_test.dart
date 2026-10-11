import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_zone/l10n/app_localizations.dart';
import 'package:quran_zone/screens/minbar_tab.dart';
import 'package:quran_zone/services/minbar_cdn_registry.dart';
import 'package:quran_zone/services/minbar_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minbar CDN Registry Unit Tests', () {
    test('Registry contains all 112 reciters from muslim_house.db qoraa table', () {
      expect(MinbarCdnRegistry.endpoints.length, equals(112));

      for (int id = 1; id <= 112; id++) {
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
      // When reciter ID is 0 or unmapped, candidates fall back to defaultUrl
      final candidates = MinbarCdnRegistry.getCandidateUrls(0, '001', lectureUrl);
      expect(candidates.length, equals(1));
      expect(candidates.first, equals(lectureUrl));
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
    testWidgets('MinbarTab renders Holy Quran Recitations Hero at top and Live Broadcasts',
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

      // Verify that deprecated "Coming Soon" regional languages card is NOT present
      expect(find.text('الدروس (አማርኛ & Oromoo)'), findsNothing);
      expect(find.text('قريباً'), findsNothing);
    });
  });
}
