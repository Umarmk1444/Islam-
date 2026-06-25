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

class StrictQcfPage extends StatefulWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// When set, the corresponding ayah glyphs get a subtle gold highlight.
  final int? highlightedSurah;
  final int? highlightedAyah;

  const StrictQcfPage({
    Key? key,
    required this.pageNumber,
    required this.theme,
    this.onTap,
    this.highlightedSurah,
    this.highlightedAyah,
  }) : super(key: key);

  @override
  State<StrictQcfPage> createState() => _StrictQcfPageState();
}

class _StrictQcfPageState extends State<StrictQcfPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_Line> _parseLines() {
    List<_Line> lines = [_Line()];
    final ranges = getPageData(widget.pageNumber);

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        // 1. Surah Header
        if (v == 1 && widget.theme.showHeader) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isHeader = true;
          lines.last.headerSurah = surah;
          lines.add(_Line());
        }

        // 2. Basmala
        if (v == 1 && widget.theme.showBasmala && widget.pageNumber != 1 && widget.pageNumber != 187) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isBasmala = true;
          lines.add(_Line());
        }

        // 3. Verse Text & Number (unified parsing to keep the sequence of \n intact)
        String qcf = getVerseQCF(surah, v, verseEndSymbol: true);
        final pageData = getPageData(widget.pageNumber);
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

  bool _isWordHighlighted(_Word word) {
    if (widget.highlightedSurah == null || widget.highlightedAyah == null) return false;
    return word.surah == widget.highlightedSurah && word.verse == widget.highlightedAyah;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _parseLines();
    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";

    const double baseFontSize = 32.0;

    // Unified layout: all pages use Expanded slots per line.
    // Pages 1 & 2 get vertical centering via surrounding Spacers.
    final bool isOpeningPage = widget.pageNumber == 1 || widget.pageNumber == 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.theme.pageBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        child: Column(
          children: [
            // Opening pages: push content toward center with spacers
            if (isOpeningPage) const Spacer(flex: 1),

            for (int i = 0; i < lines.length; i++)
              Expanded(
                flex: 1,
                child: _buildLine(lines[i], i, lines.length, pageFont, baseFontSize),
              ),

            if (isOpeningPage) const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(_Line line, int index, int totalLines, String pageFont, double baseFontSize) {
    final bool isOpeningPage = widget.pageNumber == 1 || widget.pageNumber == 2;

    if (line.isHeader) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: HeaderWidget(suraNumber: line.headerSurah!, theme: widget.theme),
          ),
        ),
      );
    }

    if (line.isBasmala) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              " ﱁ  ﱂﱃﱄ ",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "QCF_P001",
                package: 'qcf_quran',
                fontSize: baseFontSize * 0.9,
                color: widget.theme.basmalaColor,
              ),
            ),
          ),
        ),
      );
    }

    if (line.words.isEmpty) {
      return const SizedBox();
    }

    // For pages 1 & 2: force center alignment without any word spacing stretching
    if (isOpeningPage) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildWordWidgets(line.words, pageFont, baseFontSize),
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
          children: _buildWordWidgets(line.words, pageFont, baseFontSize),
        ),
      ),
    );
  }

  /// Builds word widgets, grouping consecutive words of the same highlighted
  /// ayah under a single highlight container for a clean, continuous look.
  List<Widget> _buildWordWidgets(List<_Word> words, String pageFont, double baseFontSize) {
    final List<Widget> widgets = [];
    int i = 0;

    while (i < words.length) {
      final word = words[i];
      final bool isHighlighted = _isWordHighlighted(word);

      if (isHighlighted) {
        // Group consecutive highlighted words of the same ayah
        final List<_Word> group = [];
        while (i < words.length &&
            words[i].surah == word.surah &&
            words[i].verse == word.verse &&
            _isWordHighlighted(words[i])) {
          group.add(words[i]);
          i++;
        }

        widgets.add(
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(_pulseAnimation.value),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: group.map((w) => _buildSingleWord(w, pageFont, baseFontSize)).toList(),
            ),
          ),
        );
      } else {
        widgets.add(_buildSingleWord(word, pageFont, baseFontSize));
        i++;
      }
    }

    return widgets;
  }

  Widget _buildSingleWord(_Word word, String pageFont, double baseFontSize) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!(word.surah, word.verse);
        }
      },
      child: Text(
        word.text,
        style: TextStyle(
          fontFamily: pageFont,
          package: 'qcf_quran',
          fontSize: baseFontSize,
          color: word.isVerseNumber ? widget.theme.verseNumberColor : widget.theme.verseTextColor,
          height: 1.0,
          wordSpacing: 0.0,
          letterSpacing: 0.0,
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
