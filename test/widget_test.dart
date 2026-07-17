import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_dawah/screens/quran_screen.dart';

void main() {
  testWidgets('adds bottom padding when an overlay bar is shown', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranPageContentWrapper(
            hasOverlay: true,
            child: SizedBox(height: 200, width: 200),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(find.byType(Padding).first);
    final edgeInsets = padding.padding as EdgeInsets;

    expect(edgeInsets.bottom, equals(120.0));
  });

  testWidgets('does not add bottom padding when no overlay bar is shown', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranPageContentWrapper(
            hasOverlay: false,
            child: SizedBox(height: 200, width: 200),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(find.byType(Padding).first);
    final edgeInsets = padding.padding as EdgeInsets;

    expect(edgeInsets.bottom, equals(0.0));
  });
}
