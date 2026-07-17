import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../core/database/database_helper.dart';

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
  final int? highlightedSurah;
  final int? highlightedAyah;
  final int? bookmarkedSurah;
  final int? bookmarkedAyah;

  const StrictQcfPage({
    Key? key,
    required this.pageNumber,
    required this.theme,
    this.onTap,
    this.highlightedSurah,
    this.highlightedAyah,
    this.bookmarkedSurah,
    this.bookmarkedAyah,
  }) : super(key: key);

  @override
  State<StrictQcfPage> createState() => _StrictQcfPageState();
}

class _StrictQcfPageState extends State<StrictQcfPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  List<Map<String, dynamic>>? _verses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    ); // تم حذف repeat() القاتلة من هنا
    
    _pulseAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // تشغيل الأنيميشن فقط إذا كان هناك آية محددة
    if (widget.highlightedSurah != null) {
      _pulseController.repeat(reverse: true);
    }
    _loadPageVerses();
  }

  @override
  void didUpdateWidget(covariant StrictQcfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPageVerses();
    }
    
    // إدارة الأنيميشن بذكاء لمنع استنزاف المعالج
    if (widget.highlightedSurah != null && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.highlightedSurah == null && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPageVerses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final verses = await DatabaseHelper.instance.getVersesByPage(widget.pageNumber);
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

        if (v == 1 && widget.theme.showBasmala && widget.pageNumber != 1 && widget.pageNumber != 187) {
          if (lines.last.words.isNotEmpty) lines.add(_Line());
          lines.last.isBasmala = true;
          lines.add(_Line());
        }

        String qcf = getVerseQCF(surah, v, verseEndSymbol: true);
        final bool isPageStart = _verses != null && _verses!.isNotEmpty && 
            ((_verses!.first['sura_num'] as num?)?.toInt() == surah) && 
            ((_verses!.first['aya_num'] as num?)?.toInt() == v);
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

  bool _isWordBookmarked(_Word word) {
    if (widget.bookmarkedSurah == null || widget.bookmarkedAyah == null) return false;
    return word.surah == widget.bookmarkedSurah && word.verse == widget.bookmarkedAyah;
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

    final lines = _parseLines();
    final pageFont = "QCF_P${widget.pageNumber.toString().padLeft(3, '0')}";
    const double baseFontSize = 32.0;
    final bool isOpeningPage = widget.pageNumber == 1 || widget.pageNumber == 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.theme.pageBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
        child: Column(
          children: [
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

    final bool isShortLine = line.words.length < 8 && (index == totalLines - 1 || _isEndOfSurah(line));

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 464), 
        child: Row(
          mainAxisAlignment: isShortLine ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _buildWordWidgets(line.words, pageFont, baseFontSize),
        ),
      ),
    );
  }

  List<Widget> _buildWordWidgets(List<_Word> words, String pageFont, double baseFontSize) {
    final List<Widget> widgets = [];
    int i = 0;

    while (i < words.length) {
      final word = words[i];
      final bool isHighlighted = _isWordHighlighted(word);
      final bool isBookmarked = _isWordBookmarked(word);

      if (isHighlighted || isBookmarked) {
        final List<_Word> group = [];
        final targetSurah = word.surah;
        final targetVerse = word.verse;
        final bool groupIsHighlighted = isHighlighted;
        final bool groupIsBookmarked = isBookmarked;

        while (i < words.length &&
            words[i].surah == targetSurah &&
            words[i].verse == targetVerse &&
            (_isWordHighlighted(words[i]) == groupIsHighlighted) &&
            (_isWordBookmarked(words[i]) == groupIsBookmarked)) {
          group.add(words[i]);
          i++;
        }

        if (groupIsHighlighted) {
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
          widgets.add(
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: group.map((w) => _buildSingleWord(w, pageFont, baseFontSize)).toList(),
              ),
            ),
          );
        }
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