import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

class _Word {
  final String text;
  final int surah;
  final int verse;
  final bool isVerseNumber;

  _Word(this.text, this.surah, this.verse, this.isVerseNumber);
}

class _Line {
  final List<_Word> words = [];
  bool isHeader = false;
  int? headerSurah;
  bool isBasmala = false;
}

class StrictQcfPage extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final void Function(int surahNumber, int verseNumber)? onTap;

  const StrictQcfPage({
    Key? key,
    required this.pageNumber,
    required this.theme,
    this.onTap,
  }) : super(key: key);

  List<_Line> _parseLines() {
    List<_Line> lines = [_Line()];
    final ranges = getPageData(pageNumber);

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        // 1. Surah Header
        if (v == 1 && theme.showHeader) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isHeader = true;
          lines.last.headerSurah = surah;
          lines.add(_Line());
        }

        // 2. Basmala
        if (v == 1 && theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isBasmala = true;
          lines.add(_Line());
        }

        // 3. Verse Text & Number (unified parsing to keep the sequence of \n intact)
        String qcf = getVerseQCF(surah, v, verseEndSymbol: true);
        final pageData = getPageData(pageNumber);
        final bool isPageStart = pageData.isNotEmpty && pageData[0]["start"] == v;
        if (isPageStart && qcf.length > 1) {
          qcf = "${qcf.substring(0, 1)}\u200A${qcf.substring(1)}";
        }
        final String numGlyph = getVerseNumberQCF(surah, v);
        for (int i = 0; i < qcf.length; i++) {
          String char = qcf[i];
          if (char == '\n') {
            lines.add(_Line());
          } else if (char.trim().isNotEmpty || char == '\u200A') {
            bool isVerseNum = (char == numGlyph);
            lines.last.words.add(_Word(char, surah, v, isVerseNum));
          }
        }
      }
    }

    // Clean up trailing empty lines
    while (lines.isNotEmpty &&
        lines.last.words.isEmpty &&
        !lines.last.isHeader &&
        !lines.last.isBasmala) {
      lines.removeLast();
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _parseLines();
    final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";

    // We adjust the base font size slightly depending on the container,
    // but the outer FittedBox will scale it down perfectly to fit.
    const double baseFontSize = 32.0;

    // Fatiha (Page 1) has only ~8 lines, not 15.
    // Using Expanded for each line on page 1 makes each slot ~96px tall,
    // creating large visible gaps between the Basmala and the verses.
    // Instead, for page 1 we center the lines without stretching them.
    if (pageNumber == 1) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: theme.pageBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              for (int i = 0; i < lines.length; i++)
                Padding(
                  // Tight vertical padding to keep lines visually snug —
                  // matching the appearance of a standard 15-line page.
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: _buildLine(lines[i], i, lines.length, pageFont, baseFontSize),
                ),
            ],
          ),
        ),
      );
    }

    // Page 2 (start of Al-Baqarah) and all normal pages use Expanded slots
    // so the text fills the full 770px container proportionally.
    final bool isSpecialPage = pageNumber == 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: theme.pageBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        child: Column(
          children: [
            if (isSpecialPage) const Spacer(flex: 2),

            for (int i = 0; i < lines.length; i++)
              Expanded(
                flex: 1,
                child: _buildLine(lines[i], i, lines.length, pageFont, baseFontSize),
              ),

            if (isSpecialPage) const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(_Line line, int index, int totalLines, String pageFont, double baseFontSize) {
    if (line.isHeader) {
      return Center(
        child: HeaderWidget(suraNumber: line.headerSurah!, theme: theme),
      );
    }

    if (line.isBasmala) {
      return Center(
        child: Text(
          " ﱁ  ﱂﱃﱄ ",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "QCF_P001",
            package: 'qcf_quran',
            fontSize: baseFontSize * 0.9,
            color: theme.basmalaColor,
          ),
        ),
      );
    }

    if (line.words.isEmpty) {
      return const SizedBox();
    }

    // For pages 1 & 2: force center alignment without any word spacing stretching
    final bool isOpeningPage = pageNumber == 1 || pageNumber == 2;

    if (isOpeningPage) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: line.words.map((word) {
            return GestureDetector(
              onTap: () {
                if (onTap != null) {
                  onTap!(word.surah, word.verse);
                }
              },
              child: Text(
                word.text,
                style: TextStyle(
                  fontFamily: pageFont,
                  package: 'qcf_quran',
                  fontSize: baseFontSize,
                  color: word.isVerseNumber ? theme.verseNumberColor : theme.verseTextColor,
                  height: 1.0,
                  wordSpacing: 0.0,
                  letterSpacing: 0.0,
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    // For normal pages: determine if line should be centered or justified
    final bool isShortLine = line.words.length < 8 && (index == totalLines - 1 || _isEndOfSurah(line));

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 464), // 500 - (18*2) padding
        child: Row(
          mainAxisAlignment: isShortLine ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: line.words.map((word) {
            return GestureDetector(
              onTap: () {
                if (onTap != null) {
                  onTap!(word.surah, word.verse);
                }
              },
              child: Text(
                word.text,
                style: TextStyle(
                  fontFamily: pageFont,
                  package: 'qcf_quran',
                  fontSize: baseFontSize,
                  color: word.isVerseNumber ? theme.verseNumberColor : theme.verseTextColor,
                  height: 1.0,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isEndOfSurah(_Line line) {
    if (line.words.isEmpty) return false;
    final lastWord = line.words.last;
    if (lastWord.isVerseNumber) {
      final totalVerses = getVerseCount(lastWord.surah);
      return lastWord.verse == totalVerses;
    }
    return false;
  }
}
