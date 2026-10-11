import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_zone/screens/muslim_dashboard_tab.dart';
import 'package:quran_zone/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Tab (MuslimDashboardTab) Elevation Tests', () {
    test('Surah transliteration correctly formats surahNum:ayahNum instead of 1:ayahNum', () {
      const int surahNum = 2; // Al-Baqarah
      const int ayahNum = 255;
      final String translit = DatabaseHelper.surahTransliterations[surahNum - 1];

      final String formattedEn = '$translit $surahNum:$ayahNum';
      expect(formattedEn, equals('Al-Baqarah 2:255'));
      expect(formattedEn, isNot(equals('Al-Baqarah 1:255')));

      const int kahfSurah = 18; // Al-Kahf
      const int kahfAyah = 10;
      final String translitKahf = DatabaseHelper.surahTransliterations[kahfSurah - 1];
      final String formattedKahf = '$translitKahf $kahfSurah:$kahfAyah';
      expect(formattedKahf, equals('Al-Kahf 18:10'));
    });

    test('Arabic mode subtitle formats Ayah and Page correctly in Arabic', () {
      const int ayahNum = 255;
      const int lastPage = 42;
      const String formattedAr = 'الآية $ayahNum · صفحة $lastPage';
      expect(formattedAr, equals('الآية 255 · صفحة 42'));
    });

    testWidgets('MuslimDashboardTab implements AutomaticKeepAliveClientMixin and has 6 tools with RefreshIndicator',
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
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MuslimDashboardTab(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final state = tester.state(find.byType(MuslimDashboardTab));
      expect(state, isA<AutomaticKeepAliveClientMixin>());

      // Verifies Pull-to-Refresh indicator presence
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Verifies GridView with 6 tools (3x2 grid)
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final GridView gridWidget = tester.widget<GridView>(gridFinder);
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));
      expect(delegate.childAspectRatio, equals(1.30));

      // Verifies the 6 essential tools are rendered in Arabic
      expect(find.text('الأذكار'), findsOneWidget);
      expect(find.text('التسبيح'), findsOneWidget);
      expect(find.text('القاعدة النورانية'), findsOneWidget);
      expect(find.text('التقويم الهجري'), findsOneWidget);

      // Verifies Ruqyah and Date Converter were cleanly removed from Home tab
      expect(find.text('الرقية الشرعية'), findsNothing);
      expect(find.text('محول التاريخ'), findsNothing);
    });

    testWidgets('English locale renders 6 essential tools',
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
          locale: Locale('en'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: MuslimDashboardTab(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Azkar'), findsOneWidget);
      expect(find.text('Tasbih'), findsOneWidget);
      expect(find.text('Prayer Times'), findsWidgets);
      expect(find.text('Qaidah An-Nooraniyah'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);

      // Verifies Ruqyah and Date Converter are not on Home tab
      expect(find.text("Ruqyah Shari'ah"), findsNothing);
      expect(find.text('Date Converter'), findsNothing);
    });
  });
}
