import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../core/database/database_helper.dart';

const Set<int> _localQcfPages = {
  52, 62, 113, 120, 217, 261, 263, 267, 277, 282, 296,
  304, 307, 311, 321, 421, 473, 499, 543, 557, 563, 580
};

class _Word {
  String text;
  final int surah;
  final int verse;
  final bool isVerseNumber;
  final int wordIndex; // Maps to spoken audio index
  final bool isSymbol;

  _Word(this.text, this.surah, this.verse, this.isVerseNumber, this.wordIndex,
      {this.isSymbol = false});
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
  final int? highlightedSurah;
  final int? highlightedAyah;
  final int? bookmarkedSurah;
  final int? bookmarkedAyah;
  final int? activeWordIndex;

  const StrictQcfPage({
    Key? key,
    required this.pageNumber,
    required this.theme,
    this.onTap,
    this.highlightedSurah,
    this.highlightedAyah,
    this.bookmarkedSurah,
    this.bookmarkedAyah,
    this.activeWordIndex,
  }) : super(key: key);

  @override
  State<StrictQcfPage> createState() => _StrictQcfPageState();
}

class _StrictQcfPageState extends State<StrictQcfPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>>? _verses;
  bool _isLoading = true;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _activeWordKey = GlobalKey();

  double _highlightX = 0;
  double _highlightY = 0;
  double _highlightWidth = 0;
  double _highlightHeight = 0;
  bool _hasHighlight = false;

  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadPageVerses();
  }

  @override
  void didUpdateWidget(covariant StrictQcfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPageVerses();
    }
  }

  static final Map<String, Set<int>> _sajdahLinePositions = {
    '7_206': {12},
    '13_15': {2, 4},
    '16_49': {2, 4},
    '17_107': {18, 20, 22},
    '19_58': {29, 31},
    '22_18': {6, 8},
    '22_77': {6},
    '25_60': {5},
    '27_25': {2, 4},
    '32_15': {9, 11},
    '38_24': {33, 35},
    '41_37': {14, 16},
    '53_62': {2, 4},
    '84_21': {7},
    '96_19': {5},
  };

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _loadPageVerses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final verses =
          await DatabaseHelper.instance.getVersesByPage(widget.pageNumber);
      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading verses for page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<_Line> _parseLines() {
    List<_Line> lines = [_Line()];

    final List<Map<String, dynamic>> ranges = [];
    if (_verses != null && _verses!.isNotEmpty) {
      int currentSurah = -1;
      int startAyah = -1;
      int lastAyah = -1;
      for (final row in _verses!) {
        final surah = (row['sura_num'] as num?)?.toInt() ?? 1;
        final ayah = (row['aya_num'] as num?)?.toInt() ?? 1;
        if (surah != currentSurah) {
          if (currentSurah != -1) {
            ranges.add({
              'surah': currentSurah,
              'start': startAyah,
              'end': lastAyah,
            });
          }
          currentSurah = surah;
          startAyah = ayah;
          lastAyah = ayah;
        } else {
          lastAyah = ayah;
        }
      }
      if (currentSurah != -1) {
        ranges.add({
          'surah': currentSurah,
          'start': startAyah,
          'end': lastAyah,
        });
      }
    }

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        if (v == 1 && widget.theme.showHeader) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isHeader = true;
          lines.last.headerSurah = surah;
          lines.add(_Line());
        }

        if (v == 1 &&
            widget.theme.showBasmala &&
            widget.pageNumber != 1 &&
            widget.pageNumber != 187) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isBasmala = true;
          lines.add(_Line());
        }

        String qcf = getVerseQCF(surah, v, verseEndSymbol: true);
        final bool isPageStart = _verses != null &&
            _verses!.isNotEmpty &&
            ((_verses!.first['sura_num'] as num?)?.toInt() == surah) &&
            ((_verses!.first['aya_num'] as num?)?.toInt() == v);
        if (isPageStart && qcf.length > 1) {
          qcf = "${qcf.substring(0, 1)}\u200A${qcf.substring(1)}";
        }
        final String numGlyph = getVerseNumberQCF(surah, v);

        // ── Build a symbol-position Set from the standard Arabic DB text ──────
        // The _verses row contains the 'aya' column (standard Uthmani text).
        // Splitting it by spaces gives the same word count as the QCF font.
        // Any token consisting purely of Quranic stop/pause/symbol codepoints
        // (U+06D6–U+06DC, U+06DE, U+06E9) is a non-spoken symbol.
        // This approach is 100% offline, instant, and never returns false because
        // of a missing network fetch (which was the bug: _currentChapterSymbols
        // was only populated when audio started, so isWordSymbol always returned
        // false at page-render time).
        int lastSpokenWordTokenIndex = 0;
        final Set<int> symbolPositions = {};
        final verseRow = _verses?.firstWhere(
          (row) =>
              (row['sura_num'] as num?)?.toInt() == surah &&
              (row['aya_num'] as num?)?.toInt() == v,
          orElse: () => {},
        );
        if (verseRow != null && verseRow.containsKey('aya')) {
          final rawAya = (verseRow['aya'] as String? ?? '').trim();
          final tokens = rawAya.split(' ');
          for (int ti = 0; ti < tokens.length; ti++) {
            final token = tokens[ti].trim();
            if (token.isNotEmpty && _isQuranicSymbolWord(token)) {
              symbolPositions.add(ti + 1); // 1-based to match QCF apiWordIndex
            }
          }
          for (int ti = tokens.length - 1; ti >= 0; ti--) {
            final token = tokens[ti].trim();
            if (token.isNotEmpty && !_isQuranicSymbolWord(token)) {
              lastSpokenWordTokenIndex = ti + 1;
              break;
            }
          }
          if (surah == 2 && v == 2) {
            debugPrint(
                '[SYMBOL_DEBUG] 2:2 symbolPositions=$symbolPositions  tokens=$tokens');
          }
        }

        // ── Two-pass parse ─────────────────────────────────────────────────────
        final List<_Word> verseWords = [];
        int apiWordIndex = 1;
        int extraGlyphs = 0; // Tracks extra QCF glyphs not present in DB tokens

        for (int i = 0; i < qcf.length; i++) {
          String char = qcf[i];
          if (char == '\n') {
            verseWords.add(_Word('\n', surah, v, false, -1));
            continue;
          }
          if (char.trim().isEmpty && char != '\u200A') continue;

          bool isVerseNum = (char == numGlyph);

          if (char == '\u200A') {
            // Invisible spacing glyph — treated as a symbol attached to next word
            verseWords
                .add(_Word(char, surah, v, isVerseNum, -1, isSymbol: true));
            continue;
          }

          // Use the text-based symbol set (offline, works at page-render time)
          final bool isSajdahLine =
              _sajdahLinePositions['${surah}_$v']?.contains(apiWordIndex) ??
                  false;
          final int currentTokenIndex = apiWordIndex - extraGlyphs;

          // If we are past the last spoken word in standard Arabic, any remaining non-verse-number glyphs are also symbols.
          final bool isSymbol = isSajdahLine ||
              (!isVerseNum &&
                  (symbolPositions.contains(currentTokenIndex) ||
                      (lastSpokenWordTokenIndex > 0 &&
                          currentTokenIndex > lastSpokenWordTokenIndex)));

          if (isSajdahLine) {
            extraGlyphs++;
          }

          apiWordIndex++;

          verseWords
              .add(_Word(char, surah, v, isVerseNum, -1, isSymbol: isSymbol));
        }

        // Second pass: assign spoken indices.
        // Symbols and verse numbers get the SAME index as the preceding real word.
        // We do a forward pass so they inherit from the word that came before them in reading order.
        int spokenIndexCounter = 1;
        int inheritedIndex = 1;
        final List<int> spokenIndices = List.filled(verseWords.length, 1);
        for (int i = 0; i < verseWords.length; i++) {
          final w = verseWords[i];
          if (w.text == '\n' || w.isSymbol || w.isVerseNumber) {
            spokenIndices[i] = inheritedIndex;
          } else {
            spokenIndices[i] = spokenIndexCounter++;
            inheritedIndex = spokenIndices[i];
          }
        }

        // Now emit words into lines using the corrected indices
        for (int i = 0; i < verseWords.length; i++) {
          final raw = verseWords[i];
          if (raw.text == '\n') {
            lines.add(_Line());
            continue;
          }

          if (raw.isSymbol &&
              lines.isNotEmpty &&
              lines.last.words.isNotEmpty &&
              !lines.last.words.last.isVerseNumber) {
            lines.last.words.last.text += raw.text;
            continue;
          }

          final correctedIndex = spokenIndices[i] >= 0 ? spokenIndices[i] : 1;
          lines.last.words.add(_Word(
            raw.text,
            raw.surah,
            raw.verse,
            raw.isVerseNumber,
            correctedIndex,
            isSymbol: raw.isSymbol,
          ));
        }
      }
    }

    while (lines.isNotEmpty &&
        lines.last.words.isEmpty &&
        !lines.last.isHeader &&
        !lines.last.isBasmala) {
      lines.removeLast();
    }

    // --- FIX FOR MISSING NEWLINES IN QCF DATASET ---
    // Some pages have verses concatenated without \n between them,
    // resulting in extremely long, squished lines.
    final List<_Line> finalLines = [];
    for (final line in lines) {
      if (line.isHeader || line.isBasmala || line.words.length <= 18) {
        finalLines.add(line);
      } else {
        _Line currentLine = _Line();
        for (int i = 0; i < line.words.length; i++) {
          final word = line.words[i];
          currentLine.words.add(word);
          
          // Split at verse boundary if line is getting long enough
          if (word.isVerseNumber && currentLine.words.length >= 9 && i != line.words.length - 1) {
            finalLines.add(currentLine);
            currentLine = _Line();
          }
        }
        if (currentLine.words.isNotEmpty) {
          finalLines.add(currentLine);
        }
      }
    }
    return finalLines;
  }

  /// Returns true if [token] is a standalone Quranic symbol (stop mark, pause
  /// mark, Sajdah, Rub el-Hizb) that is NOT recited and must not consume an
  /// audio-timing index.
  ///
  /// Works on the standard Unicode Uthmani Arabic text (the 'aya' DB column),
  /// NOT on QCF Private-Use-Area glyph codes.
  ///
  /// Symbol ranges:
  ///   U+06D6–U+06DC  Small Arabic letters / stop marks (ۖ ۗ ۘ ۙ ۚ ۛ ۜ)
  ///   U+06DE          Arabic Start of Rub El Hizb (۞)
  ///   U+06E9          Arabic Place of Sajdah (۩)
  ///
  /// Tokens may also carry diacritics (U+064B–U+065F, U+0610–U+061A,
  /// U+06D0–U+06D5) which we ignore when making the determination.
  static bool _isQuranicSymbolWord(String token) {
    bool hasSymbol = false;
    for (final rune in token.runes) {
      // Allow diacritics / short vowel marks — they don't count as letters
      if ((rune >= 0x064B && rune <= 0x065F) ||
          (rune >= 0x0610 && rune <= 0x061A)) {
        continue;
      }
      // Quranic symbol code points
      if ((rune >= 0x06D6 && rune <= 0x06DC) ||
          rune == 0x06DE ||
          rune == 0x06E9) {
        hasSymbol = true;
        continue;
      }
      // Any other character means this token is a real word
      return false;
    }
    return hasSymbol;
  }

  bool _isWordHighlighted(_Word word) {
    if (widget.highlightedSurah == null || widget.highlightedAyah == null) {
      return false;
    }
    return word.surah == widget.highlightedSurah &&
        word.verse == widget.highlightedAyah;
  }

  bool _isWordActive(_Word word) {
    if (widget.highlightedSurah == null || widget.highlightedAyah == null) {
      return false;
    }
    if (word.surah != widget.highlightedSurah ||
        word.verse != widget.highlightedAyah) {
      return false;
    }
    if (widget.activeWordIndex != null) {
      // Symbols share the next real word's index, so they become active together.
      return word.wordIndex == widget.activeWordIndex;
    }
    return false;
  }

  bool _isWordBookmarked(_Word word) {
    if (widget.bookmarkedSurah == null || widget.bookmarkedAyah == null) {
      return false;
    }
    return word.surah == widget.bookmarkedSurah &&
        word.verse == widget.bookmarkedAyah;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: widget.theme.pageBackgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            color: widget.theme.verseNumberColor,
          ),
        ),
      );
    }

    if (_verses == null || _verses!.isEmpty) {
      return Container(
        color: widget.theme.pageBackgroundColor,
        child: const Center(
          child: Text(
            "تأكد من تحميل الخطوط (QCF) وبيانات القاعدة بشكل صحيح",
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    _updateHighlightPosition();

    final lines = _parseLines();
    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";
    const double baseFontSize = 32.0;
    final bool isOpeningPage = widget.pageNumber == 1 || widget.pageNumber == 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.theme.pageBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        child: Stack(
          key: _stackKey,
          children: [
            // Layer 1: The Gliding Highlight
            if (_hasHighlight)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 650),
                curve: const ElasticOutCurve(0.6),
                left: _highlightX - 2,
                top: _highlightY - 2,
                width: _highlightWidth + 4,
                height: _highlightHeight + 4,
                child: AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    final t = _breathController.value;
                    final blurRadius = 4.0 + (t * 8.0);
                    final shadowAlpha = 0.35 + (t * 0.20);
                    final bgAlpha = 0.15 + (t * 0.10);
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: bgAlpha),
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: shadowAlpha),
                            blurRadius: blurRadius,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Layer 2: The Quran Text
            Column(
              children: [
                if (isOpeningPage) const Spacer(flex: 1),
                for (int i = 0; i < lines.length; i++)
                  Expanded(
                    flex: 1,
                    child: _buildLine(
                        lines[i], i, lines.length, pageFont, baseFontSize),
                  ),
                if (isOpeningPage) const Spacer(flex: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateHighlightPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final RenderBox? stackBox =
            _stackKey.currentContext?.findRenderObject() as RenderBox?;
        final RenderBox? activeWordBox =
            _activeWordKey.currentContext?.findRenderObject() as RenderBox?;

        if (stackBox != null &&
            activeWordBox != null &&
            activeWordBox.hasSize) {
          
          // 🎮 GAME OPTIMIZATION: Frustum Culling
          // Check if this specific page/stack is actually visible on screen.
          // If the active word is on a pre-built off-screen page, do not track it.
          final stackScreenPosition = stackBox.localToGlobal(Offset.zero);
          final screenSize = MediaQuery.of(context).size;
          if (stackScreenPosition.dx > screenSize.width ||
              stackScreenPosition.dx + stackBox.size.width < 0 ||
              stackScreenPosition.dy > screenSize.height ||
              stackScreenPosition.dy + stackBox.size.height < 0) {
            return; // Page is off-screen, skip layout calculation entirely!
          }

          final position =
              activeWordBox.localToGlobal(Offset.zero, ancestor: stackBox);
          final size = activeWordBox.size;

          if (_highlightX != position.dx ||
              _highlightY != position.dy ||
              _highlightWidth != size.width ||
              _highlightHeight != size.height ||
              !_hasHighlight) {
            setState(() {
              _highlightX = position.dx;
              _highlightY = position.dy;
              _highlightWidth = size.width;
              _highlightHeight = size.height;
              _hasHighlight = true;
            });
          }
        } else if (_hasHighlight) {
          setState(() {
            _hasHighlight = false;
          });
        }
      } catch (e) {
        // Catch layout exceptions during rapid scroll/render phases
      }
    });
  }

  Widget _buildLine(_Line line, int index, int totalLines, String pageFont,
      double baseFontSize) {
    final bool isOpeningPage = widget.pageNumber == 1 || widget.pageNumber == 2;

    if (line.isHeader) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: HeaderWidget(
                suraNumber: line.headerSurah!, theme: widget.theme),
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

    final bool isShortLine = line.words.length < 8 &&
        (index == totalLines - 1 || _isEndOfSurah(line));

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 464),
        child: Row(
          mainAxisAlignment: isShortLine
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildWordWidgets(line.words, pageFont, baseFontSize),
        ),
      ),
    );
  }

  List<Widget> _buildWordWidgets(
      List<_Word> words, String pageFont, double baseFontSize) {
    final List<Widget> widgets = [];
    int i = 0;

    while (i < words.length) {
      final targetSurah = words[i].surah;
      final targetVerse = words[i].verse;

      final List<_Word> group = [];
      while (i < words.length &&
          words[i].surah == targetSurah &&
          words[i].verse == targetVerse) {
        group.add(words[i]);
        i++;
      }

      final bool groupIsHighlighted = group.any((w) => _isWordHighlighted(w));
      final bool groupIsBookmarked = group.any((w) => _isWordBookmarked(w));

      Color bgColor = Colors.transparent;
      Border? border;

      if (groupIsHighlighted) {
        bgColor = const Color(0xFFD4AF37).withValues(alpha: 0.25);
      } else if (groupIsBookmarked) {
        bgColor = const Color(0xFF2E7D32).withValues(alpha: 0.15);
        border = Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
          width: 1.0,
        );
      }

      widgets.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastLinearToSlowEaseIn,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10.0),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: group
                .map((w) => _buildSingleWord(w, pageFont, baseFontSize))
                .toList(),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSingleWord(_Word word, String pageFont, double baseFontSize) {
    final bool isActive = _isWordActive(word);

    // Determine the base color for the text
    Color textColor = word.isVerseNumber
        ? widget.theme.verseNumberColor
        : widget.theme.verseTextColor;
    if (isActive) {
      textColor = Colors.amber[700]!;
    }

    final stopMarkRegex = RegExp(r'([ۖۗۘۙۚۛۜ۞۩]+)');
    final matches = stopMarkRegex.allMatches(word.text);

    String mainWord = word.text;
    String stopMark = "";

    if (matches.isNotEmpty) {
      final match = matches.last;
      mainWord = word.text.substring(0, match.start);
      // Capture the stop mark AND any invisible trailing characters
      stopMark = word.text.substring(match.start);
    }

    // We remove the AnimatedContainer background because the Stack's overlay handles highlighting now.
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!(word.surah, word.verse);
        }
      },
      child: Container(
        key: (isActive && !word.isVerseNumber && !word.isSymbol)
            ? _activeWordKey
            : null,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: mainWord,
              ),
              if (stopMark.isNotEmpty)
                TextSpan(
                  text: stopMark,
                ),
            ],
          ),
          style: TextStyle(
            fontFamily: pageFont,
            package: _localQcfPages.contains(widget.pageNumber) ? null : 'qcf_quran',
            fontSize: baseFontSize,
            color: textColor,
            height: 1.0,
            wordSpacing: 0.0,
            letterSpacing: 0.0,
          ),
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
