import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../widgets/liquid_pressable.dart';

// Authentic Qaida Color Palette
const Color _kRed = Color(0xFFC62828);
const Color _kBlue = Color(0xFF1976D2);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kTeal = Color(0xFF00838F);
const Color _kGrey = Color(0xFF757575);
const Color _kGold = Color(0xFF9E7D23);
const Color _kPurple = Color(0xFF7B1FA2);

class QaidaSegment {
  final String text;
  final Color? color;
  const QaidaSegment(this.text, [this.color]);
}

class QaidaCell {
  final String? text;
  final List<QaidaSegment>? segments;
  final String? phonetic;
  final Color? color;
  final int flex;

  const QaidaCell({
    this.text,
    this.segments,
    this.phonetic,
    this.color,
    this.flex = 1,
  });

  String get fullText => text ?? segments?.map((s) => s.text).join() ?? '';
}

class QaidaRow {
  final List<QaidaCell>? cells;
  final bool isHeader;
  final bool inlineHeader;
  final String? headerLessonTitle;
  final String? headerLessonSubtitle;
  final bool isCentered;

  const QaidaRow({
    this.cells,
    this.isHeader = false,
    this.inlineHeader = false,
    this.headerLessonTitle,
    this.headerLessonSubtitle,
    this.isCentered = false,
  });
}

class QaidaPage {
  final int pageNumber;
  final int lessonNumber;
  final String lessonTitleAr;
  final String lessonSubtitleAr;
  final String titleEn;
  final String description;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool showBismillah;
  final bool showHeader;
  final List<QaidaCell> cells;
  final List<QaidaRow>? customRows;

  const QaidaPage({
    required this.pageNumber,
    required this.lessonNumber,
    required this.lessonTitleAr,
    required this.lessonSubtitleAr,
    required this.titleEn,
    required this.description,
    this.cells = const [],
    this.customRows,
    this.crossAxisCount = 5,
    this.childAspectRatio = 1.0,
    this.showBismillah = true,
    this.showHeader = true,
  });
}

const List<QaidaPage> _kQaidaPages = [
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 : الدَّرْسُ الأَوَّل - حُرُوفُ الهِجَاءِ المُفْرَدَة (5 columns x 6 rows)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 1,
    lessonNumber: 1,
    lessonTitleAr: 'الدَّرْسُ الأَوَّلُ',
    lessonSubtitleAr: 'حُرُوفُ الهِجَاءِ المُفْرَدَة',
    titleEn: 'Lesson 1: Individual Letters',
    description: 'نطق الحروف العربية المفردة بمخارجها الصحيحة من اليمين إلى اليسار',
    crossAxisCount: 5,
    childAspectRatio: 0.95,
    showBismillah: true,
    cells: [
      // Row 1
      QaidaCell(text: 'ا', phonetic: 'أَلِف'),
      QaidaCell(text: 'ب', phonetic: 'با'),
      QaidaCell(text: 'ت', phonetic: 'تا'),
      QaidaCell(text: 'ث', phonetic: 'ثا'),
      QaidaCell(text: 'ج', phonetic: 'جيم'),

      // Row 2
      QaidaCell(text: 'ح', phonetic: 'حا'),
      QaidaCell(text: 'خ', phonetic: 'خا'),
      QaidaCell(text: 'د', phonetic: 'دال'),
      QaidaCell(text: 'ذ', phonetic: 'ذال'),
      QaidaCell(text: 'ر', phonetic: 'را'),

      // Row 3
      QaidaCell(text: 'ز', phonetic: 'زا'),
      QaidaCell(text: 'س', phonetic: 'سين'),
      QaidaCell(text: 'ش', phonetic: 'شين'),
      QaidaCell(text: 'ص', phonetic: 'صاد'),
      QaidaCell(text: 'ض', phonetic: 'ضاد'),

      // Row 4
      QaidaCell(text: 'ط', phonetic: 'طا'),
      QaidaCell(text: 'ظ', phonetic: 'ظا'),
      QaidaCell(text: 'ع', phonetic: 'عين'),
      QaidaCell(text: 'غ', phonetic: 'غين'),
      QaidaCell(text: 'ف', phonetic: 'فا'),

      // Row 5
      QaidaCell(text: 'ق', phonetic: 'قاف'),
      QaidaCell(text: 'ك', phonetic: 'كاف'),
      QaidaCell(text: 'ل', phonetic: 'لام'),
      QaidaCell(text: 'م', phonetic: 'ميم'),
      QaidaCell(text: 'ن', phonetic: 'نون'),

      // Row 6
      QaidaCell(text: 'و', phonetic: 'واو'),
      QaidaCell(text: 'هـ', phonetic: 'ها'),
      QaidaCell(text: 'ء', phonetic: 'همزة'),
      QaidaCell(text: 'ي', phonetic: 'يا'),
      QaidaCell(text: 'ے', phonetic: 'يا'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 : الدَّرْسُ الثَّانِي - حُرُوفُ الهِجَاءِ المُرَكَّبَة (Authentic Colors)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 2,
    lessonNumber: 2,
    lessonTitleAr: 'الدَّرْسُ الثَّانِي',
    lessonSubtitleAr: 'حُرُوفُ الهِجَاءِ المُرَكَّبَة',
    titleEn: 'Lesson 2: Compound Letters (Part 1)',
    description: 'التعرف على أشكال الحروف المركبة بالألوان التعليمية',
    crossAxisCount: 6,
    childAspectRatio: 1.05,
    showBismillah: false,
    cells: [
      // Row 1
      QaidaCell(text: 'ا'),
      QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
      QaidaCell(text: 'ل', color: _kRed),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ا')]),
      QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
      QaidaCell(text: 'ل', color: _kRed),

      // Row 2
      QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ل', _kRed), QaidaSegment('ح', _kGreen)]),
      QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ل', _kBlue), QaidaSegment('ب', _kBlue)]),
      QaidaCell(text: 'ك'),
      QaidaCell(text: 'ك'),

      // Row 3
      QaidaCell(segments: [QaidaSegment('ك', _kBlue), QaidaSegment('ب', _kBlue)]),
      QaidaCell(segments: [QaidaSegment('ك', _kBlue), QaidaSegment('ب', _kBlue)]),
      QaidaCell(segments: [QaidaSegment('ك'), QaidaSegment('ا', _kGrey)]),
      QaidaCell(segments: [QaidaSegment('ك'), QaidaSegment('ا', _kGrey)]),
      QaidaCell(segments: [QaidaSegment('ب', _kGrey), QaidaSegment('ك', _kBlue), QaidaSegment('ت', _kGrey)]),
      QaidaCell(segments: [QaidaSegment('ت', _kGrey), QaidaSegment('ك'), QaidaSegment('ث', _kGrey)]),

      // Row 4
      QaidaCell(text: 'ب', color: _kBlue),
      QaidaCell(text: 'ت'),
      QaidaCell(text: 'ث'),
      QaidaCell(text: 'ن', color: _kRed),
      QaidaCell(text: 'ى', color: _kRed),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ا')]),

      // Row 5
      QaidaCell(segments: [QaidaSegment('ن'), QaidaSegment('ا', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ا', _kGrey)]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ا')]),
      QaidaCell(segments: [QaidaSegment('ث', _kGrey), QaidaSegment('ا')]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('س')]),
      QaidaCell(segments: [QaidaSegment('ي'), QaidaSegment('س', _kRed)]),

      // Row 6
      QaidaCell(segments: [QaidaSegment('ن'), QaidaSegment('س', _kRed)]),
      QaidaCell(text: 'تس'),
      QaidaCell(text: 'ثس'),
      QaidaCell(text: 'ثج'),
      QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ح', _kGreen)]),
      QaidaCell(segments: [QaidaSegment('ن', _kGreen), QaidaSegment('خ', _kRed)]),

      // Row 7
      QaidaCell(segments: [QaidaSegment('ي', _kGreen), QaidaSegment('ح', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ج')]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ه', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('م', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('م', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ت', _kRed), QaidaSegment('م', _kRed)]),

      // Row 8
      QaidaCell(segments: [QaidaSegment('ث'), QaidaSegment('م', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ي', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ى', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('ى', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ت', _kRed), QaidaSegment('ى', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ث', _kRed), QaidaSegment('ى', _kRed)]),

      // Row 9
      QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('ب', _kBlue), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ت', _kRed), QaidaSegment('ن'), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ي', _kRed), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ت', _kRed), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ث'), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('ب', _kBlue), QaidaSegment('ن', _kRed)]),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 3 : الدَّرْسُ الثَّانِي - حُرُوفُ الهِجَاءِ المُرَكَّبَة (تابع - Colors)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 3,
    lessonNumber: 2,
    lessonTitleAr: 'الدَّرْسُ الثَّانِي',
    lessonSubtitleAr: 'حُرُوفُ الهِجَاءِ المُرَكَّبَة (تابع)',
    titleEn: 'Lesson 2: Compound Letters (Part 2)',
    description: 'متابعة أشكال الحروف المركبة وثلاثية التركيب',
    crossAxisCount: 6,
    childAspectRatio: 1.05,
    showBismillah: false,
    showHeader: false,
    cells: [
      // Row 1
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ن', _kRed), QaidaSegment('ن', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ي', _kRed), QaidaSegment('ن', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ت'), QaidaSegment('ن', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ث', _kGrey), QaidaSegment('ث', _kGrey), QaidaSegment('ن', _kRed)]),
      QaidaCell(text: 'ج'),
      QaidaCell(text: 'ح', color: _kGreen),

      // Row 2
      QaidaCell(text: 'خ', color: _kGreen),
      QaidaCell(segments: [QaidaSegment('ح', _kGreen), QaidaSegment('ث')]),
      QaidaCell(segments: [QaidaSegment('خ', _kGreen), QaidaSegment('ب', _kBlue)]),
      QaidaCell(text: 'جت'),
      QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ح', _kGreen), QaidaSegment('ت')]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ج'), QaidaSegment('ب', _kBlue)]),

      // Row 3
      QaidaCell(segments: [QaidaSegment('ب'), QaidaSegment('خ', _kGreen), QaidaSegment('ت')]),
      QaidaCell(text: 'ة'),
      QaidaCell(text: 'ه', color: _kGreen),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ة')]),
      QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ه', _kGreen)]),
      QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ه', _kGreen)]),

      // Row 4
      QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('ة')]),
      QaidaCell(text: 'ه', color: _kGreen),
      QaidaCell(segments: [QaidaSegment('ي', _kBlue), QaidaSegment('ه', _kRed), QaidaSegment('ب', _kBlue)]),
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ه', _kGreen), QaidaSegment('ا')]),
      QaidaCell(segments: [QaidaSegment('ب', _kRed), QaidaSegment('ه', _kBlue), QaidaSegment('م')]),
      QaidaCell(text: 'د'),

      // Row 5
      QaidaCell(text: 'ذ'),
      QaidaCell(segments: [QaidaSegment('ج', _kGrey), QaidaSegment('د')]),
      QaidaCell(segments: [QaidaSegment('خ', _kGreen), QaidaSegment('ذ')]),
      QaidaCell(text: 'ر', color: _kRed),
      QaidaCell(text: 'ز'),
      QaidaCell(segments: [QaidaSegment('ج', _kRed), QaidaSegment('ر')]),

      // Row 6
      QaidaCell(segments: [QaidaSegment('خ', _kGreen), QaidaSegment('ز')]),
      QaidaCell(text: 'ر', color: _kRed),
      QaidaCell(text: 'ز'),
      QaidaCell(text: 'ر', color: _kRed),
      QaidaCell(text: 'ز'),
      QaidaCell(text: 'س'),

      // Row 7
      QaidaCell(text: 'ش'),
      QaidaCell(segments: [QaidaSegment('س'), QaidaSegment('ل', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ش'), QaidaSegment('ل', _kRed)]),
      QaidaCell(text: 'ص'),
      QaidaCell(text: 'ض'),
      QaidaCell(text: 'ط'),

      // Row 8
      QaidaCell(text: 'ظ'),
      QaidaCell(segments: [QaidaSegment('ص'), QaidaSegment('ب', _kBlue)]),
      QaidaCell(segments: [QaidaSegment('ط'), QaidaSegment('ب', _kBlue)]),
      QaidaCell(segments: [QaidaSegment('ض', _kGrey), QaidaSegment('ا')]),
      QaidaCell(segments: [QaidaSegment('ظ', _kGrey), QaidaSegment('ا')]),
      QaidaCell(text: 'ع', color: _kGreen),

      // Row 9
      QaidaCell(text: 'غ', color: _kGreen),
      QaidaCell(text: 'ء', color: _kGreen),
      QaidaCell(segments: [QaidaSegment('ع', _kGreen), QaidaSegment('ز')]),
      QaidaCell(segments: [QaidaSegment('غ', _kGreen), QaidaSegment('ر', _kRed)]),
      QaidaCell(segments: [QaidaSegment('ص', _kGreen), QaidaSegment('ع', _kGreen)]),
      QaidaCell(segments: [QaidaSegment('ض', _kGreen), QaidaSegment('غ', _kGreen)]),

      // Row 10
      QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ع', _kGreen), QaidaSegment('د')]),
      QaidaCell(text: 'تغذ'),
      QaidaCell(text: 'أ', color: _kGreen),
      QaidaCell(text: 'ؤ', color: _kGreen),
      QaidaCell(text: 'ئ', color: _kGreen),
      QaidaCell(text: 'ف'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 4 : خاتمة الدرس الثاني + الدَّرْسُ الثَّالِث (الحُرُوفُ المُقَطَّعَة)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 4,
    lessonNumber: 3,
    lessonTitleAr: 'الدَّرْسُ الثَّالِثُ',
    lessonSubtitleAr: 'الحُرُوفُ المُقَطَّعَة',
    titleEn: 'Lesson 3: The Muqatta\'at Letters',
    description: 'تكملة الحروف المركبة وبداية الحروف المقطعة مع المدود',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Lesson 2 ──
      // Row 1 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ق'),
          QaidaCell(text: 'و', color: _kRed),
          QaidaCell(text: 'قو', color: _kRed),
          QaidaCell(text: 'فو'),
          QaidaCell(text: 'فقل', color: _kRed),
        ],
      ),

      // Row 2 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('قف'), QaidaSegment('ل', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ي'), QaidaSegment('ف', _kRed)]),
          QaidaCell(text: 'م', color: _kRed),
          QaidaCell(text: 'م', color: _kRed),
          QaidaCell(segments: [QaidaSegment('ح', _kTeal), QaidaSegment('م', _kRed)]),
        ],
      ),

      // Row 3 (3 wide items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ل', _kRed), QaidaSegment('م', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ت', _kRed), QaidaSegment('م')]),
          QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('م', _kRed), QaidaSegment('ت')]),
        ],
      ),

      // ── Mid Section: Lesson 3 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الثَّالِثُ',
        headerLessonSubtitle: 'الحُرُوفُ المُقَطَّعَة',
      ),

      // ── Bottom Section: Lesson 3 Muqatta'at with Red Madd marks ──
      // Row 4 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ا'), QaidaSegment('لٓ', _kRed), QaidaSegment('مٓ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ا'), QaidaSegment('لٓ', _kRed), QaidaSegment('مٓ', _kRed), QaidaSegment('صٓ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ا'), QaidaSegment('لٓ', _kRed), QaidaSegment('ر')]),
          QaidaCell(segments: [QaidaSegment('ا'), QaidaSegment('لٓ', _kRed), QaidaSegment('مٓ', _kRed), QaidaSegment('ر')]),
        ],
      ),

      // Row 5 (3 items: 1 wide + 2 normal)
      QaidaRow(
        cells: [
          QaidaCell(
            flex: 2,
            segments: [
              QaidaSegment('كٓ', _kRed),
              QaidaSegment('هـ'),
              QaidaSegment('ي'),
              QaidaSegment('عٓ', _kRed),
              QaidaSegment('صٓ', _kRed),
            ],
          ),
          QaidaCell(flex: 1, text: 'طه'),
          QaidaCell(flex: 1, segments: [QaidaSegment('ط'), QaidaSegment('سٓ', _kRed), QaidaSegment('مٓ', _kRed)]),
        ],
      ),

      // Row 6 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ط'), QaidaSegment('سٓ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ي'), QaidaSegment('سٓ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('صٓ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ح'), QaidaSegment('مٓ', _kRed)]),
        ],
      ),

      // Row 7 (3 items: 1 wide + 2 normal)
      QaidaRow(
        cells: [
          QaidaCell(
            flex: 2,
            segments: [
              QaidaSegment('ح'),
              QaidaSegment('مٓ', _kRed),
              QaidaSegment(' ۬ '),
              QaidaSegment('عٓ', _kRed),
              QaidaSegment('سٓ', _kRed),
              QaidaSegment('قٓ', _kRed),
            ],
          ),
          QaidaCell(flex: 1, segments: [QaidaSegment('قٓ', _kRed)]),
          QaidaCell(flex: 1, segments: [QaidaSegment('نٓ', _kRed)]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 5 : الدَّرْسُ الرَّابِع - الحُرُوفُ المُتَحَرِّكَةُ ( الحَرَكَاتُ )
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 5,
    lessonNumber: 4,
    lessonTitleAr: 'الدَّرْسُ الرَّابِعُ',
    lessonSubtitleAr: 'الحُرُوفُ المُتَحَرِّكَةُ ( الحَرَكَاتُ )',
    titleEn: 'Lesson 4: Short Vowels (Harakat) - Part 1',
    description: 'نطق الحركات القصيرة: الفتحة والكسرة والضمة',
    crossAxisCount: 6,
    childAspectRatio: 1.05,
    showBismillah: false,
    showHeader: true,
    cells: [
      // Row 1 (Gold)
      QaidaCell(text: 'أَ', color: _kGold),
      QaidaCell(text: 'إِ', color: _kGold),
      QaidaCell(text: 'أُ', color: _kGold),
      QaidaCell(text: 'هَ', color: _kGold),
      QaidaCell(text: 'هِ', color: _kGold),
      QaidaCell(text: 'هُ', color: _kGold),

      // Row 2 (Gold)
      QaidaCell(text: 'عَ', color: _kGold),
      QaidaCell(text: 'عِ', color: _kGold),
      QaidaCell(text: 'عُ', color: _kGold),
      QaidaCell(text: 'حَ', color: _kGold),
      QaidaCell(text: 'حِ', color: _kGold),
      QaidaCell(text: 'حُ', color: _kGold),

      // Row 3 (Gold)
      QaidaCell(text: 'خَ', color: _kGold),
      QaidaCell(text: 'خِ', color: _kGold),
      QaidaCell(text: 'خُ', color: _kGold),
      QaidaCell(text: 'غَ', color: _kGold),
      QaidaCell(text: 'غِ', color: _kGold),
      QaidaCell(text: 'غُ', color: _kGold),

      // Row 4 (Purple)
      QaidaCell(text: 'قَ', color: _kPurple),
      QaidaCell(text: 'قِ', color: _kPurple),
      QaidaCell(text: 'قُ', color: _kPurple),
      QaidaCell(text: 'كَ', color: _kPurple),
      QaidaCell(text: 'كِ', color: _kPurple),
      QaidaCell(text: 'كُ', color: _kPurple),

      // Row 5 (Purple)
      QaidaCell(text: 'جَ', color: _kPurple),
      QaidaCell(text: 'جِ', color: _kPurple),
      QaidaCell(text: 'جُ', color: _kPurple),
      QaidaCell(text: 'شَ', color: _kPurple),
      QaidaCell(text: 'شِ', color: _kPurple),
      QaidaCell(text: 'شُ', color: _kPurple),

      // Row 6 (Purple)
      QaidaCell(text: 'يَ', color: _kPurple),
      QaidaCell(text: 'يِ', color: _kPurple),
      QaidaCell(text: 'يُ', color: _kPurple),
      QaidaCell(text: 'ضَ', color: _kPurple),
      QaidaCell(text: 'ضِ', color: _kPurple),
      QaidaCell(text: 'ضُ', color: _kPurple),

      // Row 7 (Purple)
      QaidaCell(text: 'لَ', color: _kPurple),
      QaidaCell(text: 'لِ', color: _kPurple),
      QaidaCell(text: 'لُ', color: _kPurple),
      QaidaCell(text: 'نَ', color: _kPurple),
      QaidaCell(text: 'نِ', color: _kPurple),
      QaidaCell(text: 'نُ', color: _kPurple),

      // Row 8 (Purple)
      QaidaCell(text: 'رَ', color: _kPurple),
      QaidaCell(text: 'رِ', color: _kPurple),
      QaidaCell(text: 'رُ', color: _kPurple),
      QaidaCell(text: 'طَ', color: _kPurple),
      QaidaCell(text: 'طِ', color: _kPurple),
      QaidaCell(text: 'طُ', color: _kPurple),

      // Row 9 (Purple)
      QaidaCell(text: 'دَ', color: _kPurple),
      QaidaCell(text: 'دِ', color: _kPurple),
      QaidaCell(text: 'دُ', color: _kPurple),
      QaidaCell(text: 'تَ', color: _kPurple),
      QaidaCell(text: 'تِ', color: _kPurple),
      QaidaCell(text: 'تُ', color: _kPurple),

      // Row 10 (Purple)
      QaidaCell(text: 'صَ', color: _kPurple),
      QaidaCell(text: 'صِ', color: _kPurple),
      QaidaCell(text: 'صُ', color: _kPurple),
      QaidaCell(text: 'سَ', color: _kPurple),
      QaidaCell(text: 'سِ', color: _kPurple),
      QaidaCell(text: 'سُ', color: _kPurple),

      // Row 11 (Purple)
      QaidaCell(text: 'زَ', color: _kPurple),
      QaidaCell(text: 'زِ', color: _kPurple),
      QaidaCell(text: 'زُ', color: _kPurple),
      QaidaCell(text: 'ظَ', color: _kPurple),
      QaidaCell(text: 'ظِ', color: _kPurple),
      QaidaCell(text: 'ظُ', color: _kPurple),

      // Row 12 (Purple)
      QaidaCell(text: 'ذَ', color: _kPurple),
      QaidaCell(text: 'ذِ', color: _kPurple),
      QaidaCell(text: 'ذُ', color: _kPurple),
      QaidaCell(text: 'ثَ', color: _kPurple),
      QaidaCell(text: 'ثِ', color: _kPurple),
      QaidaCell(text: 'ثُ', color: _kPurple),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 6 : خاتمة الدرس الرابع + الدَّرْسُ الخَامِس (الحُرُوفُ المُنَوَّنَةُ)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 6,
    lessonNumber: 5,
    lessonTitleAr: 'الدَّرْسُ الخَامِسُ',
    lessonSubtitleAr: 'الحُرُوفُ المُنَوَّنَةُ ( التَّنْوِين )',
    titleEn: 'Lesson 5: Tanween (Nunation)',
    description: 'تكملة الحركات وبداية الحروف المنونة',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Lesson 4 (8 items) ──
      // Row 1 (8 items, Blue)
      QaidaRow(
        cells: [
          QaidaCell(text: 'فَ', color: _kBlue),
          QaidaCell(text: 'فِ', color: _kBlue),
          QaidaCell(text: 'فُ', color: _kBlue),
          QaidaCell(text: 'وَ', color: _kBlue),
          QaidaCell(text: 'وِ', color: _kBlue),
          QaidaCell(text: 'وُ', color: _kBlue),
          QaidaCell(text: 'بَ', color: _kBlue),
          QaidaCell(text: 'بِ', color: _kBlue),
        ],
      ),

      // Row 2 (4 items + Inline Header Box spanning 4 columns)
      QaidaRow(
        inlineHeader: true,
        headerLessonTitle: 'الدَّرْسُ الخَامِسُ',
        headerLessonSubtitle: 'الحُرُوفُ المُنَوَّنَةُ\nالتَّنْوِين: ً ٍ ٌ',
        cells: [
          QaidaCell(text: 'بُ', color: _kBlue),
          QaidaCell(text: 'مَ', color: _kBlue),
          QaidaCell(text: 'مِ', color: _kBlue),
          QaidaCell(text: 'مُ', color: _kBlue),
        ],
      ),

      // ── Bottom Section: Lesson 5 Tanween Letters (8 items each) ──
      // Row 3 (Blue)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مً', color: _kBlue),
          QaidaCell(text: 'مٍ', color: _kBlue),
          QaidaCell(text: 'مٌ', color: _kBlue),
          QaidaCell(text: 'بً', color: _kBlue),
          QaidaCell(text: 'بٍ', color: _kBlue),
          QaidaCell(text: 'بٌ', color: _kBlue),
          QaidaCell(text: 'وً', color: _kBlue),
          QaidaCell(text: 'وٍ', color: _kBlue),
        ],
      ),

      // Row 4
      QaidaRow(
        cells: [
          QaidaCell(text: 'وٌ', color: _kBlue),
          QaidaCell(text: 'فً', color: _kBlue),
          QaidaCell(text: 'فٍ', color: _kBlue),
          QaidaCell(text: 'فٌ', color: _kBlue),
          QaidaCell(text: 'ثً', color: _kPurple),
          QaidaCell(text: 'ثٍ', color: _kPurple),
          QaidaCell(text: 'ثٌ', color: _kPurple),
          QaidaCell(text: 'ذً', color: _kPurple),
        ],
      ),

      // Row 5 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ذٍ', color: _kPurple),
          QaidaCell(text: 'ذٌ', color: _kPurple),
          QaidaCell(text: 'ظً', color: _kPurple),
          QaidaCell(text: 'ظٍ', color: _kPurple),
          QaidaCell(text: 'ظٌ', color: _kPurple),
          QaidaCell(text: 'زً', color: _kPurple),
          QaidaCell(text: 'زٍ', color: _kPurple),
          QaidaCell(text: 'زٌ', color: _kPurple),
        ],
      ),

      // Row 6 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'سً', color: _kPurple),
          QaidaCell(text: 'سٍ', color: _kPurple),
          QaidaCell(text: 'سٌ', color: _kPurple),
          QaidaCell(text: 'صً', color: _kPurple),
          QaidaCell(text: 'صٍ', color: _kPurple),
          QaidaCell(text: 'صٌ', color: _kPurple),
          QaidaCell(text: 'تً', color: _kPurple),
          QaidaCell(text: 'تٍ', color: _kPurple),
        ],
      ),

      // Row 7 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'تٌ', color: _kPurple),
          QaidaCell(text: 'دً', color: _kPurple),
          QaidaCell(text: 'دٍ', color: _kPurple),
          QaidaCell(text: 'دٌ', color: _kPurple),
          QaidaCell(text: 'طً', color: _kPurple),
          QaidaCell(text: 'طٍ', color: _kPurple),
          QaidaCell(text: 'طٌ', color: _kPurple),
          QaidaCell(text: 'رً', color: _kPurple),
        ],
      ),

      // Row 8 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'رٍ', color: _kPurple),
          QaidaCell(text: 'رٌ', color: _kPurple),
          QaidaCell(text: 'نً', color: _kPurple),
          QaidaCell(text: 'نٍ', color: _kPurple),
          QaidaCell(text: 'نٌ', color: _kPurple),
          QaidaCell(text: 'لً', color: _kPurple),
          QaidaCell(text: 'لٍ', color: _kPurple),
          QaidaCell(text: 'لٌ', color: _kPurple),
        ],
      ),

      // Row 9 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ضً', color: _kPurple),
          QaidaCell(text: 'ضٍ', color: _kPurple),
          QaidaCell(text: 'ضٌ', color: _kPurple),
          QaidaCell(text: 'يً', color: _kPurple),
          QaidaCell(text: 'يٍ', color: _kPurple),
          QaidaCell(text: 'يٌ', color: _kPurple),
          QaidaCell(text: 'شً', color: _kPurple),
          QaidaCell(text: 'شٍ', color: _kPurple),
        ],
      ),

      // Row 10 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'شٌ', color: _kPurple),
          QaidaCell(text: 'جً', color: _kPurple),
          QaidaCell(text: 'جٍ', color: _kPurple),
          QaidaCell(text: 'جٌ', color: _kPurple),
          QaidaCell(text: 'كً', color: _kPurple),
          QaidaCell(text: 'كٍ', color: _kPurple),
          QaidaCell(text: 'كٌ', color: _kPurple),
          QaidaCell(text: 'قً', color: _kPurple),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 7 : خاتمة الدرس الخامس + الدَّرْسُ السَّادِس (تَدْرِيبَاتٌ)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 7,
    lessonNumber: 6,
    lessonTitleAr: 'الدَّرْسُ السَّادِسُ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِين',
    titleEn: 'Lesson 6: Exercises on Harakat & Tanween',
    description: 'تكملة التنوين وبداية التدريبات العملية على الكلمات',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Lesson 5 (8 columns) ──
      // Row 1 (8 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قٍ', color: _kPurple),
          QaidaCell(text: 'قٌ', color: _kPurple),
          QaidaCell(text: 'خً', color: _kGold),
          QaidaCell(text: 'خٍ', color: _kGold),
          QaidaCell(text: 'خٌ', color: _kGold),
          QaidaCell(text: 'غً', color: _kGold),
          QaidaCell(text: 'غٍ', color: _kGold),
          QaidaCell(text: 'غٌ', color: _kGold),
        ],
      ),

      // Row 2 (8 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'حً', color: _kGold),
          QaidaCell(text: 'حٍ', color: _kGold),
          QaidaCell(text: 'حٌ', color: _kGold),
          QaidaCell(text: 'عً', color: _kGold),
          QaidaCell(text: 'عٍ', color: _kGold),
          QaidaCell(text: 'عٌ', color: _kGold),
          QaidaCell(text: 'هً', color: _kGold),
          QaidaCell(text: 'هٍ', color: _kGold),
        ],
      ),

      // Row 3 (4 items centered in 8-column layout)
      QaidaRow(
        isCentered: true,
        cells: [
          QaidaCell(text: 'هٌ', color: _kGold),
          QaidaCell(text: 'ءً', color: _kGold),
          QaidaCell(text: 'ءٍ', color: _kGold),
          QaidaCell(text: 'ءٌ', color: _kGold),
        ],
      ),

      // ── Mid Section: Full Width Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ السَّادِسُ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِين',
      ),

      // ── Bottom Section: Lesson 6 Words (6 columns x 6 rows = 36 words) ──
      // Row 4 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَبَدًا'),
          QaidaCell(text: 'أَحَدٌ', color: _kBlue),
          QaidaCell(text: 'أَخَذَ'),
          QaidaCell(text: 'أَذِنَ', color: _kBlue),
          QaidaCell(text: 'أَمَرَ'),
          QaidaCell(text: 'أَنَا۠', color: _kBlue),
        ],
      ),

      // Row 5 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'بَخِلَ'),
          QaidaCell(text: 'بَرَرَةٍ', color: _kBlue),
          QaidaCell(text: 'جَعَلَ'),
          QaidaCell(text: 'جَمَعَ', color: _kBlue),
          QaidaCell(text: 'حَسَدَ'),
          QaidaCell(text: 'حَشَرَ', color: _kBlue),
        ],
      ),

      // Row 6 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'خَشِيَ'),
          QaidaCell(text: 'خَلَقَ'),
          QaidaCell(text: 'خُلِقَ', color: _kBlue),
          QaidaCell(text: 'ذَكَرَ', color: _kBlue),
          QaidaCell(text: 'رَفَعَ'),
          QaidaCell(text: 'رَقَبَةٍ', color: _kBlue),
        ],
      ),

      // Row 7 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'سُرُرٌ'),
          QaidaCell(text: 'سَفَرَةٍ', color: _kBlue),
          QaidaCell(text: 'صُحُفًا'),
          QaidaCell(text: 'وَسَطًا', color: _kBlue),
          QaidaCell(text: 'طَبَقٍ'),
          QaidaCell(text: 'طَبَقًا', color: _kBlue),
        ],
      ),

      // Row 8 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'طُوًى'),
          QaidaCell(text: 'عَبَسَ', color: _kBlue),
          QaidaCell(text: 'عَدَلَ'),
          QaidaCell(text: 'عَلَقٍ', color: _kBlue),
          QaidaCell(text: 'عَمَدٍ'),
          QaidaCell(text: 'عِنَبًا', color: _kBlue),
        ],
      ),

      // Row 9 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'غَبَرَةٌ'),
          QaidaCell(text: 'فَعَلَ', color: _kBlue),
          QaidaCell(text: 'قَتَرَةٌ'),
          QaidaCell(text: 'قُتِلَ', color: _kBlue),
          QaidaCell(text: 'قَدَرَ'),
          QaidaCell(text: 'قُرِئَ', color: _kBlue),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 8 : الدَّرْسُ السَّادِس - تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ (الجزء الثاني)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 8,
    lessonNumber: 6,
    lessonTitleAr: 'الدَّرْسُ السَّادِسُ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ (تابع)',
    titleEn: 'Lesson 6: Exercises on Harakat & Tanween (Part 2)',
    description: 'متابعة كلمات الحركات الثلاث والتنوين',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: false,
    cells: [
      QaidaCell(text: 'وَسَطًا'),
      QaidaCell(text: 'طَبَقًا'),
      QaidaCell(text: 'طَبَقٍ'),
      QaidaCell(text: 'طُوًى'),
      QaidaCell(text: 'عَبَسَ'),
      QaidaCell(text: 'عَدَلَ'),
      QaidaCell(text: 'عَلَقٍ'),
      QaidaCell(text: 'عَمَدٍ'),
      QaidaCell(text: 'عِنَبًا'),
      QaidaCell(text: 'غَبَرَةٌ'),
      QaidaCell(text: 'فَعَلَ'),
      QaidaCell(text: 'قَتَرَةٌ'),
      QaidaCell(text: 'قُتِلَ'),
      QaidaCell(text: 'قَدَرَ'),
      QaidaCell(text: 'قُرِئَ'),
      QaidaCell(text: 'قَسَمٌ'),
      QaidaCell(text: 'كَبَدٍ'),
      QaidaCell(text: 'كُتُبٌ'),
      QaidaCell(text: 'كَسَبَ'),
      QaidaCell(text: 'كَفَرَ'),
      QaidaCell(text: 'كُفُوًا'),
      QaidaCell(text: 'لُبَدًا'),
      QaidaCell(text: 'لُمَزَةٍ'),
      QaidaCell(text: 'لَهَبٍ'),
      QaidaCell(text: 'مَسَدٍ'),
      QaidaCell(text: 'نَخِرَةً'),
      QaidaCell(text: 'وَجَدَ'),
      QaidaCell(text: 'وَسَقَ'),
      QaidaCell(text: 'وَقَبَ'),
      QaidaCell(text: 'وَلَدَ'),
      QaidaCell(text: 'وَهَبَ'),
      QaidaCell(text: 'هُمَزَةٍ'),
      QaidaCell(text: 'هُدًى'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 9 : الدَّرْسُ السَّابِع - الأَلِفُ الصَّغِيرَةُ وَاليَاءُ الصَّغِيرَةُ
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 9,
    lessonNumber: 7,
    lessonTitleAr: 'الدَّرْسُ السَّابِعُ',
    lessonSubtitleAr: 'الأَلِفُ الصَّغِيرَةُ وَاليَاءُ الصَّغِيرَةُ وَالوَاوُ الصَّغِيرَة',
    titleEn: 'Lesson 7: Small Alif, Small Yaa & Small Waw',
    description: 'المد الطبيعي الحركي بحركات التمكين الصغرى',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'بٰـ'),
      QaidaCell(text: 'بِۦ'),
      QaidaCell(text: 'بُۥ'),
      QaidaCell(text: 'يٰـ'),
      QaidaCell(text: 'يِۦ'),
      QaidaCell(text: 'يُۥ'),
      QaidaCell(text: 'رٰـ'),
      QaidaCell(text: 'رِۦ'),
      QaidaCell(text: 'رُۥ'),
      QaidaCell(text: 'مٰـ'),
      QaidaCell(text: 'مِۦ'),
      QaidaCell(text: 'مُۥ'),
      QaidaCell(text: 'لٰـ'),
      QaidaCell(text: 'لِۦ'),
      QaidaCell(text: 'لُۥ'),
      QaidaCell(text: 'وٰـ'),
      QaidaCell(text: 'وِۦ'),
      QaidaCell(text: 'وُۥ'),
      QaidaCell(text: 'نٰـ'),
      QaidaCell(text: 'نِۦ'),
      QaidaCell(text: 'نُۥ'),
      QaidaCell(text: 'هٰـ'),
      QaidaCell(text: 'هِۦ'),
      QaidaCell(text: 'هُۥ'),
      QaidaCell(text: 'ءٰ'),
      QaidaCell(text: 'ءِۦ'),
      QaidaCell(text: 'ءُۥ'),
      QaidaCell(text: 'جٰـ'),
      QaidaCell(text: 'دٰـ'),
      QaidaCell(text: 'ذٰـ'),
      QaidaCell(text: 'زٰـ'),
      QaidaCell(text: 'سٰـ'),
      QaidaCell(text: 'شٰـ'),
      QaidaCell(text: 'صٰـ'),
      QaidaCell(text: 'ضٰـ'),
      QaidaCell(text: 'طٰـ'),
      QaidaCell(text: 'ظٰـ'),
      QaidaCell(text: 'عٰـ'),
      QaidaCell(text: 'غٰـ'),
      QaidaCell(text: 'فٰـ'),
      QaidaCell(text: 'قٰـ'),
      QaidaCell(text: 'كٰـ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 10 : الدَّرْسُ الثَّامِن - حُرُوفُ المَدِّ وَاللِّين
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 10,
    lessonNumber: 8,
    lessonTitleAr: 'الدَّرْسُ الثَّامِنُ',
    lessonSubtitleAr: 'حُرُوفُ المَدِّ وَاللِّين',
    titleEn: 'Lesson 8: Letters of Madd & Leen',
    description: 'أحرف المد الثلاثة: الألف والواو والياء وحرفا اللين',
    crossAxisCount: 3,
    childAspectRatio: 1.30,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'بَا'),
      QaidaCell(text: 'بُو'),
      QaidaCell(text: 'بِي'),
      QaidaCell(text: 'تَا'),
      QaidaCell(text: 'تُو'),
      QaidaCell(text: 'تِي'),
      QaidaCell(text: 'ثَا'),
      QaidaCell(text: 'ثُو'),
      QaidaCell(text: 'ثِي'),
      QaidaCell(text: 'جَا'),
      QaidaCell(text: 'جُو'),
      QaidaCell(text: 'جِي'),
      QaidaCell(text: 'حَا'),
      QaidaCell(text: 'حُو'),
      QaidaCell(text: 'حِي'),
      QaidaCell(text: 'خَا'),
      QaidaCell(text: 'خُو'),
      QaidaCell(text: 'خِي'),
      QaidaCell(text: 'دَا'),
      QaidaCell(text: 'دُو'),
      QaidaCell(text: 'دِي'),
      QaidaCell(text: 'بَوْ'),
      QaidaCell(text: 'بَيْ'),
      QaidaCell(text: 'تَوْ'),
      QaidaCell(text: 'تَيْ'),
      QaidaCell(text: 'ثَوْ'),
      QaidaCell(text: 'ثَيْ'),
      QaidaCell(text: 'جَوْ'),
      QaidaCell(text: 'جَيْ'),
      QaidaCell(text: 'حَوْ'),
      QaidaCell(text: 'حَيْ'),
      QaidaCell(text: 'خَوْ'),
      QaidaCell(text: 'خَيْ'),
      QaidaCell(text: 'دَوْ'),
      QaidaCell(text: 'دَيْ'),
      QaidaCell(text: 'ذَوْ'),
      QaidaCell(text: 'ذَيْ'),
      QaidaCell(text: 'رَوْ'),
      QaidaCell(text: 'رَيْ'),
      QaidaCell(text: 'زَوْ'),
      QaidaCell(text: 'زَيْ'),
      QaidaCell(text: 'سَوْ'),
      QaidaCell(text: 'سَيْ'),
      QaidaCell(text: 'شَوْ'),
      QaidaCell(text: 'شَيْ'),
      QaidaCell(text: 'صَوْ'),
      QaidaCell(text: 'صَيْ'),
      QaidaCell(text: 'ضَوْ'),
      QaidaCell(text: 'ضَيْ'),
      QaidaCell(text: 'طَوْ'),
      QaidaCell(text: 'طَيْ'),
      QaidaCell(text: 'ظَوْ'),
      QaidaCell(text: 'ظَيْ'),
      QaidaCell(text: 'عَوْ'),
      QaidaCell(text: 'عَيْ'),
      QaidaCell(text: 'غَوْ'),
      QaidaCell(text: 'غَيْ'),
      QaidaCell(text: 'فَوْ'),
      QaidaCell(text: 'فَيْ'),
      QaidaCell(text: 'قَوْ'),
      QaidaCell(text: 'قَيْ'),
      QaidaCell(text: 'كَوْ'),
      QaidaCell(text: 'كَيْ'),
      QaidaCell(text: 'لَوْ'),
      QaidaCell(text: 'لَيْ'),
      QaidaCell(text: 'مَوْ'),
      QaidaCell(text: 'مَيْ'),
      QaidaCell(text: 'نَوْ'),
      QaidaCell(text: 'نَيْ'),
      QaidaCell(text: 'هَوْ'),
      QaidaCell(text: 'هَيْ'),
      QaidaCell(text: 'أَوْ'),
      QaidaCell(text: 'أَيْ'),
      QaidaCell(text: 'يَوْ'),
      QaidaCell(text: 'يَيْ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 11 : الدَّرْسُ التَّاسِع - تَدْرِيبَاتٌ عَلَى المَدِّ وَاللِّين
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 11,
    lessonNumber: 9,
    lessonTitleAr: 'الدَّرْسُ التَّاسِعُ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى المَدِّ وَاللِّين وَالتَّنْوِين',
    titleEn: 'Lesson 9: Exercises on Madd, Leen & Tanween',
    description: 'أمثلة تطبيقية شاملة على حروف المد وحرفي اللين مع التنوين',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'آمَنَ'),
      QaidaCell(text: 'آوَىٰ'),
      QaidaCell(text: 'آنِيَةٍ'),
      QaidaCell(text: 'إِيلَافِهِمْ'),
      QaidaCell(text: 'أَيْنَ'),
      QaidaCell(text: 'بِهِۦ'),
      QaidaCell(text: 'جَآءَ'),
      QaidaCell(text: 'جِيدِهَا'),
      QaidaCell(text: 'جُوعٍ'),
      QaidaCell(text: 'خَوْفٌ'),
      QaidaCell(text: 'خَيْرٌ'),
      QaidaCell(text: 'دَاوُۥدُ'),
      QaidaCell(text: 'ذَٰلِكَ'),
      QaidaCell(text: 'رَضِيَ'),
      QaidaCell(text: 'رَيْبٌ'),
      QaidaCell(text: 'سِرَاجًا'),
      QaidaCell(text: 'سُوٓءَ'),
      QaidaCell(text: 'شَيْءٍ'),
      QaidaCell(text: 'طَاغِيَةً'),
      QaidaCell(text: 'طَيْرًا'),
      QaidaCell(text: 'عَادٌ'),
      QaidaCell(text: 'عَادِيَاتٍ'),
      QaidaCell(text: 'عَذَابٌ'),
      QaidaCell(text: 'عَطَآءً'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 12 : الدَّرْسُ العَاشِر - السُّكُون
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 12,
    lessonNumber: 10,
    lessonTitleAr: 'الدَّرْسُ العَاشِرُ',
    lessonSubtitleAr: 'السُّكُونُ (الجَزْم)',
    titleEn: 'Lesson 10: Sukoon',
    description: 'نطق الحرف الساكن مع الحرف المتحرك قبله وقلقلة قطب جد',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'أَبْ'),
      QaidaCell(text: 'إِبْ'),
      QaidaCell(text: 'أُبْ'),
      QaidaCell(text: 'أَتْ'),
      QaidaCell(text: 'إِتْ'),
      QaidaCell(text: 'أُتْ'),
      QaidaCell(text: 'أَثْ'),
      QaidaCell(text: 'إِثْ'),
      QaidaCell(text: 'أُثْ'),
      QaidaCell(text: 'أَجْ'),
      QaidaCell(text: 'إِجْ'),
      QaidaCell(text: 'أُجْ'),
      QaidaCell(text: 'أَحْ'),
      QaidaCell(text: 'إِحْ'),
      QaidaCell(text: 'أُحْ'),
      QaidaCell(text: 'أَخْ'),
      QaidaCell(text: 'إِخْ'),
      QaidaCell(text: 'أُخْ'),
      QaidaCell(text: 'أَدْ'),
      QaidaCell(text: 'إِدْ'),
      QaidaCell(text: 'أُدْ'),
      QaidaCell(text: 'أَذْ'),
      QaidaCell(text: 'إِذْ'),
      QaidaCell(text: 'أُذْ'),
      QaidaCell(text: 'أَرْ'),
      QaidaCell(text: 'إِرْ'),
      QaidaCell(text: 'أُرْ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 13 : الدَّرْسُ الحَادِي عَشَر - تَدْرِيبَاتٌ عَلَى السُّكُون
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 13,
    lessonNumber: 11,
    lessonTitleAr: 'الدَّرْسُ الحَادِي عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى السُّكُون',
    titleEn: 'Lesson 11: Exercises on Sukoon',
    description: 'تدريب على نطق الكلمات القرآنية ذات المقاطع الساكنة',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'هَمْزَةٌ'),
      QaidaCell(text: 'أَبْصَارِهِمْ'),
      QaidaCell(text: 'أَبْقَىٰ'),
      QaidaCell(text: 'أَتْقَىٰ'),
      QaidaCell(text: 'أَثْقَلَتْ'),
      QaidaCell(text: 'أَجْرٌ'),
      QaidaCell(text: 'أَحْسَنَ'),
      QaidaCell(text: 'أَخْرَجَ'),
      QaidaCell(text: 'أَدْبَرَ'),
      QaidaCell(text: 'أَرْسَلَ'),
      QaidaCell(text: 'أَزْلَفَتْ'),
      QaidaCell(text: 'أَسْلَمَ'),
      QaidaCell(text: 'أَشْتَاتًا'),
      QaidaCell(text: 'أَصْبَحَ'),
      QaidaCell(text: 'أَطْعَمَهُم'),
      QaidaCell(text: 'أَعْتَدْنَا'),
      QaidaCell(text: 'أَفْلَحَ'),
      QaidaCell(text: 'أَقْرَبُ'),
      QaidaCell(text: 'أَكْرَمَ'),
      QaidaCell(text: 'أَلْهَىٰكُمُ'),
      QaidaCell(text: 'أَمْهِلْهُمْ'),
      QaidaCell(text: 'أَنْعَمْتَ'),
      QaidaCell(text: 'أَوْحَىٰ'),
      QaidaCell(text: 'إِبْرَاهِيمُ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 14 : الدَّرْسُ الثَّانِي عَشَر - الشَّدَّة
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 14,
    lessonNumber: 12,
    lessonTitleAr: 'الدَّرْسُ الثَّانِي عَشَرَ',
    lessonSubtitleAr: 'الشَّدَّةُ (التَّشْدِيد)',
    titleEn: 'Lesson 12: Shaddah (Doubled Consonants)',
    description: 'الحرف المشدد مكون من حرف ساكن يليه حرف متحرك',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'أَبَّ'),
      QaidaCell(text: 'أَبِّ'),
      QaidaCell(text: 'أَبُّ'),
      QaidaCell(text: 'أَتَّ'),
      QaidaCell(text: 'أَتِّ'),
      QaidaCell(text: 'أَتُّ'),
      QaidaCell(text: 'أَثَّ'),
      QaidaCell(text: 'أَثِّ'),
      QaidaCell(text: 'أَثُّ'),
      QaidaCell(text: 'أَجَّ'),
      QaidaCell(text: 'أَجِّ'),
      QaidaCell(text: 'أَجُّ'),
      QaidaCell(text: 'أَحَّ'),
      QaidaCell(text: 'أَحِّ'),
      QaidaCell(text: 'أَحُّ'),
      QaidaCell(text: 'أَخَّ'),
      QaidaCell(text: 'أَخِّ'),
      QaidaCell(text: 'أَخُّ'),
      QaidaCell(text: 'أَدَّ'),
      QaidaCell(text: 'أَدِّ'),
      QaidaCell(text: 'أَدُّ'),
      QaidaCell(text: 'أَذَّ'),
      QaidaCell(text: 'أَذِّ'),
      QaidaCell(text: 'أَذُّ'),
      QaidaCell(text: 'أَرَّ'),
      QaidaCell(text: 'أَرِّ'),
      QaidaCell(text: 'أَرُّ'),
      QaidaCell(text: 'أَزَّ'),
      QaidaCell(text: 'أَزِّ'),
      QaidaCell(text: 'أَزُّ'),
      QaidaCell(text: 'أَسَّ'),
      QaidaCell(text: 'أَسِّ'),
      QaidaCell(text: 'أَسُّ'),
      QaidaCell(text: 'أَشَّ'),
      QaidaCell(text: 'أَشِّ'),
      QaidaCell(text: 'أَشُّ'),
      QaidaCell(text: 'أَصَّ'),
      QaidaCell(text: 'أَصِّ'),
      QaidaCell(text: 'أَصُّ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 15 : الدَّرْسُ الثَّالِث عَشَر - تَدْرِيبَاتٌ عَلَى الشَّدَّة
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 15,
    lessonNumber: 13,
    lessonTitleAr: 'الدَّرْسُ الثَّالِثَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّة',
    titleEn: 'Lesson 13: Exercises on Shaddah',
    description: 'أمثلة لكلمات قرآنية بها أحرف مشددة مع الغنة في النون والميم',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'زَكَّىٰ'),
      QaidaCell(text: 'ثَجَّاجًا'),
      QaidaCell(text: 'سَجَّاحًا'),
      QaidaCell(text: 'وَضَّاحًا'),
      QaidaCell(text: 'فَعَّالٌ'),
      QaidaCell(text: 'كَرَّارٌ'),
      QaidaCell(text: 'تَوَّابًا'),
      QaidaCell(text: 'غَفَّارًا'),
      QaidaCell(text: 'وَهَّابًا'),
      QaidaCell(text: 'عَمَّ'),
      QaidaCell(text: 'إِنَّ'),
      QaidaCell(text: 'ثُمَّ'),
      QaidaCell(text: 'رَبِّ'),
      QaidaCell(text: 'حَقٌّ'),
      QaidaCell(text: 'مَدَّ'),
      QaidaCell(text: 'صَدَّ'),
      QaidaCell(text: 'عَدَّ'),
      QaidaCell(text: 'وَدَّ'),
      QaidaCell(text: 'تَبَّتْ'),
      QaidaCell(text: 'خَفَّتْ'),
      QaidaCell(text: 'شَقَّتْ'),
      QaidaCell(text: 'حُقَّتْ'),
      QaidaCell(text: 'قَدَّمَ'),
      QaidaCell(text: 'كَلَّمَ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 16 : الدَّرْسُ الرَّابِع عَشَر - تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُون
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 16,
    lessonNumber: 14,
    lessonTitleAr: 'الدَّرْسُ الرَّابِعَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُون',
    titleEn: 'Lesson 14: Shaddah with Sukoon',
    description: 'الجمع بين السكون والتشديد في الكلمة وضبط النبر والتفخيم والترقيق',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'يَرْضَوْنَ'),
      QaidaCell(text: 'تَزَكَّىٰ'),
      QaidaCell(text: 'يَتَزَكَّىٰ'),
      QaidaCell(text: 'وَتَوَلَّىٰ'),
      QaidaCell(text: 'تَجَلَّىٰ'),
      QaidaCell(text: 'يَتَوَفَّىٰ'),
      QaidaCell(text: 'يَتَذَكَّرُ'),
      QaidaCell(text: 'يَتَفَكَّرُ'),
      QaidaCell(text: 'يَتَبَيَّنُ'),
      QaidaCell(text: 'يُدَبِّرُ'),
      QaidaCell(text: 'يُمَهِّدُ'),
      QaidaCell(text: 'يُؤَلِّفُ'),
      QaidaCell(text: 'وَٱلصَّٰٓفَّٰتِ'),
      QaidaCell(text: 'فَٱلزَّٰجِرَٰتِ'),
      QaidaCell(text: 'فَٱلتَّٰلِيَٰتِ'),
      QaidaCell(text: 'ٱلنَّٰشِرَٰتِ'),
      QaidaCell(text: 'فَٱلْفَٰرِقَٰتِ'),
      QaidaCell(text: 'مُسْتَقِرٌّ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 17 : الدَّرْسُ الخَامِس عَشَر & السَّادِس عَشَر - الشَّدَّتَيْنِ & الشَّدَّة مَعَ المَدّ
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 17,
    lessonNumber: 15,
    lessonTitleAr: 'الدَّرْسُ الخَامِسَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّتَيْنِ فِي كَلِمَة',
    titleEn: 'Lesson 15 & 16: Consecutive Shaddahs & Madd Lazim',
    description: 'اجتماع حرفين مشددين والمد اللازم الكلمي المثقل 6 حركات',
    crossAxisCount: 2,
    childAspectRatio: 1.85,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'يَزَّكَّىٰ'),
      QaidaCell(text: 'يَذَّكَّرُ'),
      QaidaCell(text: 'يَدَّعُونَ'),
      QaidaCell(text: 'يَطَّوَّفَ'),
      QaidaCell(text: 'تَطَّلِعُ'),
      QaidaCell(text: 'مُزَّمِّلُ'),
      QaidaCell(text: 'مُدَّثِّرُ'),
      QaidaCell(text: 'عِلِّيِّينَ'),
      QaidaCell(text: 'سِجِّينٌ'),
      QaidaCell(text: 'دُرِّيٌّ'),
      QaidaCell(text: 'ٱلصَّآخَّةُ'),
      QaidaCell(text: 'ٱلطَّآمَّةُ'),
      QaidaCell(text: 'دَآبَّةٍ'),
      QaidaCell(text: 'حَآفِّينَ'),
      QaidaCell(text: 'ضَآلِّينَ'),
      QaidaCell(text: 'تَأْمُرُوٓنِّي'),
      QaidaCell(text: 'أَتُحَآجُّوٓنِّي'),
      QaidaCell(text: 'يُوَآدُّونَ'),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 18 : الدَّرْسُ السَّابِع عَشَر - تَدْرِيبَاتٌ شَامِلَة
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 18,
    lessonNumber: 17,
    lessonTitleAr: 'الدَّرْسُ السَّابِعَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ شَامِلَةٌ عَلَى مَا سَبَق',
    titleEn: 'Lesson 17: Comprehensive Reading',
    description: 'تلاوة آيات وسور مباركة وتطبيق كافة أحكام التجويد والنورانية',
    crossAxisCount: 1,
    childAspectRatio: 4.80,
    showBismillah: true,
    cells: [
      QaidaCell(text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
      QaidaCell(text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
      QaidaCell(text: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
      QaidaCell(text: 'مَٰلِكِ يَوْمِ ٱلدِّينِ'),
      QaidaCell(text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'),
      QaidaCell(text: 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ'),
      QaidaCell(text: 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ'),
      QaidaCell(text: 'غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ'),
      QaidaCell(text: 'قُلْ هُوَ ٱللَّهُ أَحَدٌ'),
      QaidaCell(text: 'ٱللَّهُ ٱلصَّمَدُ'),
      QaidaCell(text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ'),
      QaidaCell(text: 'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ'),
    ],
  ),
];

class QaidaNooraniyahScreen extends StatefulWidget {
  final int initialPageIndex;

  const QaidaNooraniyahScreen({
    super.key,
    this.initialPageIndex = 0,
  });

  @override
  State<QaidaNooraniyahScreen> createState() => _QaidaNooraniyahScreenState();
}

class _QaidaNooraniyahScreenState extends State<QaidaNooraniyahScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  String _selectedItem = '';
  final double _fontSizeScale = 1.0;
  bool _isPlaying = false;
  int _repeatCount = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex.clamp(0, _kQaidaPages.length - 1);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index >= 0 && index < _kQaidaPages.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentPageIndex = index;
        _selectedItem = '';
      });
    }
  }

  void _showPagePicker() {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'فهرس صفحات القاعدة النورانية',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _kQaidaPages.length,
                        itemBuilder: (ctx, idx) {
                          final page = _kQaidaPages[idx];
                          final isSelected = idx == _currentPageIndex;
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFC5A059)
                                    : (isDark ? Colors.white10 : const Color(0xFFF3EDE0)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC5A059).withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${page.pageNumber}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white : const Color(0xFF8D6E63)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  page.lessonTitleAr,
                                  style: const TextStyle(
                                    color: Color(0xFFB71C1C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'Amiri',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    page.lessonSubtitleAr,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? textColor : (isDark ? AppColors.textPrimary : const Color(0xFF4A3B32)),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              page.titleEn,
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFFC5A059), size: 22)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              _goToPage(idx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showItemDetail(QaidaCell cell, String lessonTitle) {
    setState(() => _selectedItem = cell.fullText);
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = isDark ? const Color(0xFF1B2420) : const Color(0xFFFFFDF9);

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lessonTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : const Color(0xFF8D6E63),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  if (cell.phonetic != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'النطق: ${cell.phonetic!}',
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141C18) : const Color(0xFFFAF6EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: _buildCellContent(cell, isDark, 48),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LiquidPressable(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC5A059).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final outerBg = isDark ? const Color(0xFF0F1512) : const Color(0xFFF4EFE6);
    final topIconColor = isDark ? AppColors.textPrimary : const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: outerBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: topIconColor),
        centerTitle: true,
        title: Text(
          'القاعدة النورانية',
          style: TextStyle(
            color: topIconColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Amiri',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'فهرس الصفحات',
            onPressed: _showPagePicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main Swipeable PageView with Authentic Book Layout (Scrolls Right-to-Left)
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _kQaidaPages.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPageIndex = idx;
                      _selectedItem = '';
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _kQaidaPages[index];
                    return _buildAuthenticNooraniaPage(page, isDark);
                  },
                ),
              ),
            ),

            // Bottom Page Switcher & Control Toolbar
            _buildBottomControls(isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTIC NOORANIYAH PAGE CARD (Ornate Frame, Bismillah, Dual Header, Grid)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAuthenticNooraniaPage(QaidaPage page, bool isDark) {
    final pageBg = isDark ? const Color(0xFF161E1A) : const Color(0xFFFFFDF9);
    const borderColor = Color(0xFFC5A059);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: pageBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _IslamicPageBorderPainter(
            borderColor: borderColor,
            isDark: isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                // 1. Top Bismillah (Optional per page)
                if (page.showBismillah) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18 * _fontSizeScale,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE8DFC8) : const Color(0xFF2C241E),
                      ),
                    ),
                  ),
                ],

                // 2. Authentic Dual Header Box (Right: Lesson No. | Left: Lesson Name)
                if (page.showHeader) ...[
                  _buildDualHeaderBox(
                    page.lessonTitleAr,
                    page.lessonSubtitleAr,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                ],

                // 3. Grid or Custom Rows (e.g. Page 4, 6, 7 multi-section layout)
                Expanded(
                  child: page.customRows != null
                      ? _buildCustomRowsPage(page, isDark)
                      : _buildGridPage(page, isDark),
                ),

                // 4. Page Number Badge Inside the Page Frame
                _buildPageNumberBadge(page.pageNumber, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STANDARD GRID PAGE BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGridPage(QaidaPage page, bool isDark) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: page.crossAxisCount,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: page.childAspectRatio,
        ),
        itemCount: page.cells.length,
        itemBuilder: (context, cellIndex) {
          final cell = page.cells[cellIndex];
          return _buildAuthenticCell(cell, page, isDark);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOM ROWS PAGE BUILDER (For Multi-Section Pages like Page 4, 6, 7)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCustomRowsPage(QaidaPage page, bool isDark) {
    final rows = page.customRows!;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: rows.map((r) {
          if (r.isHeader) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildDualHeaderBox(
                r.headerLessonTitle ?? '',
                r.headerLessonSubtitle ?? '',
                isDark,
              ),
            );
          }

          if (r.inlineHeader) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    // Right 4 cells (in RTL)
                    ...?r.cells?.map((c) => Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildAuthenticCell(c, page, isDark),
                          ),
                        )),
                    // Left inline header box (in RTL, spans width of 4 columns)
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildDualHeaderBox(
                          r.headerLessonTitle ?? '',
                          r.headerLessonSubtitle ?? '',
                          isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (r.isCentered) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    ...?r.cells?.map((c) => Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildAuthenticCell(c, page, isDark),
                          ),
                        )),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: r.cells!.map((c) {
                  return Expanded(
                    flex: c.flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildAuthenticCell(c, page, isDark),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DUAL COMPARTMENT LESSON HEADER BOX (Original Noorania Book Style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDualHeaderBox(String titleAr, String subtitleAr, bool isDark) {
    const borderColor = Color(0xFFC5A059);
    final headerBg = isDark ? const Color(0xFF1E2824) : const Color(0xFFFAF7F0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Right Part in RTL (First child): Lesson Title / Number (e.g. "الدَّرْسُ الأَوَّل")
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Center(
                    child: Text(
                      titleAr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * _fontSizeScale,
                        color: isDark ? const Color(0xFFE57373) : const Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                ),
              ),

              // Vertical Separator
              VerticalDivider(
                color: borderColor,
                thickness: 1.4,
                width: 1.4,
              ),

              // Left Part in RTL (Second child): Lesson Subtitle / Name (e.g. "حُرُوفُ الهِجَاءِ المُفْرَدَة")
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Center(
                    child: Text(
                      subtitleAr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 15 * _fontSizeScale,
                        color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF9C640C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CELL CONTENT (Supports Multi-Colored Segments & Single Text)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCellContent(QaidaCell cell, bool isDark, double fontSize) {
    final defaultColor = isDark ? const Color(0xFFF2EADC) : const Color(0xFF1F1B18);

    if (cell.segments != null && cell.segments!.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: cell.segments!.map((seg) {
            Color segColor = seg.color ?? defaultColor;
            if (isDark) {
              if (seg.color == _kRed) segColor = const Color(0xFFEF5350);
              if (seg.color == _kBlue) segColor = const Color(0xFF42A5F5);
              if (seg.color == _kGreen) segColor = const Color(0xFF66BB6A);
              if (seg.color == _kTeal) segColor = const Color(0xFF26C6DA);
              if (seg.color == _kGrey) segColor = const Color(0xFFBDBDBD);
              if (seg.color == _kGold) segColor = const Color(0xFFFFD54F);
              if (seg.color == _kPurple) segColor = const Color(0xFFCE93D8);
            }
            return TextSpan(
              text: seg.text,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: segColor,
                height: 1.25,
              ),
            );
          }).toList(),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      );
    }

    Color mainColor = cell.color ?? defaultColor;
    if (isDark && cell.color != null) {
      if (cell.color == _kRed) mainColor = const Color(0xFFEF5350);
      if (cell.color == _kBlue) mainColor = const Color(0xFF42A5F5);
      if (cell.color == _kGreen) mainColor = const Color(0xFF66BB6A);
      if (cell.color == _kTeal) mainColor = const Color(0xFF26C6DA);
      if (cell.color == _kGrey) mainColor = const Color(0xFFBDBDBD);
      if (cell.color == _kGold) mainColor = const Color(0xFFFFD54F);
      if (cell.color == _kPurple) mainColor = const Color(0xFFCE93D8);
    }

    return Text(
      cell.text ?? '',
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: mainColor,
        height: 1.25,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTIC CELL (Clean Rounded Border, Red Corner Pronunciation, Bold Arabic)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAuthenticCell(QaidaCell cell, QaidaPage page, bool isDark) {
    final isSelected = _selectedItem == cell.fullText;
    final cellBg = isDark
        ? (isSelected ? const Color(0xFF23362C) : const Color(0xFF19221E))
        : (isSelected ? const Color(0xFFFBF4E2) : const Color(0xFFFFFFFF));

    final borderColor = isSelected
        ? const Color(0xFFB71C1C)
        : const Color(0xFFC5A059).withValues(alpha: isDark ? 0.45 : 0.60);

    // Font size scaling according to crossAxisCount or row layout
    double baseFontSize = 26;
    if (page.customRows != null) {
      baseFontSize = 22;
    } else if (page.crossAxisCount >= 6) {
      baseFontSize = 20;
    } else if (page.crossAxisCount == 5) {
      baseFontSize = 24;
    } else if (page.crossAxisCount == 4) {
      baseFontSize = 25;
    } else if (page.crossAxisCount == 3) {
      baseFontSize = 27;
    } else if (page.crossAxisCount == 2) {
      baseFontSize = 32;
    } else if (page.crossAxisCount == 1) {
      baseFontSize = 22;
    }

    final double effectiveFontSize = baseFontSize * _fontSizeScale;

    return LiquidPressable(
      onTap: () => _showItemDetail(cell, '${page.lessonTitleAr}: ${page.lessonSubtitleAr}'),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Small Red Phonetic / Pronunciation Name in Corner (e.g. 'أَلِف', 'با', 'تا')
            if (cell.phonetic != null)
              Positioned(
                top: 2,
                left: 4,
                child: Text(
                  cell.phonetic!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: (10.5 * _fontSizeScale).clamp(8.0, 14.0),
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
                    height: 1.0,
                  ),
                ),
              ),

            // Main Central Letter (Multi-colored or styled)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: _buildCellContent(cell, isDark, effectiveFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE NUMBER BADGE (Bottom Emblem)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPageNumberBadge(int pageNumber, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2824) : const Color(0xFFFAF7F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC5A059).withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: isDark ? const Color(0xFFE8DFC8) : const Color(0xFF5D4037),
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Amiri',
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM CONTROLS (Audio Toolbar, Loop, Navigation Arrows)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomControls(bool isDark) {
    final barBg = isDark ? const Color(0xFF141A17) : const Color(0xFFEFE8DA);
    const iconColor = Color(0xFFC5A059);
    final hasPrev = _currentPageIndex > 0;
    final hasNext = _currentPageIndex < _kQaidaPages.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFC5A059).withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Next Page Button (Left side in RTL book flow)
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 30,
              color: hasNext ? iconColor : iconColor.withValues(alpha: 0.3),
            ),
            tooltip: 'الصفحة التالية',
            onPressed: hasNext ? () => _goToPage(_currentPageIndex + 1) : null,
          ),

          // Page Index Quick Jump
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              size: 22,
              color: iconColor,
            ),
            tooltip: 'فهرس الصفحات',
            onPressed: _showPagePicker,
          ),

          // Play / Pause Audio
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              size: 32,
              color: iconColor,
            ),
            tooltip: _isPlaying ? 'إيقاف مؤقت' : 'تشغيل قراءة الصفحة',
            onPressed: () {
              setState(() => _isPlaying = !_isPlaying);
            },
          ),

          // Stop Audio
          IconButton(
            icon: Icon(
              Icons.stop_circle_outlined,
              size: 30,
              color: iconColor,
            ),
            tooltip: 'إيقاف',
            onPressed: () {
              setState(() => _isPlaying = false);
            },
          ),

          // Repeat / Loop Counter
          LiquidPressable(
            onTap: () {
              setState(() {
                _repeatCount = (_repeatCount + 1) % 4; // 0, 1, 2, 3
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat_rounded, size: 18, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    ': $_repeatCount',
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Previous Page Button (Right side in RTL book flow)
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: hasPrev ? iconColor : iconColor.withValues(alpha: 0.3),
            ),
            tooltip: 'الصفحة السابقة',
            onPressed: hasPrev ? () => _goToPage(_currentPageIndex - 1) : null,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ISLAMIC PAGE BORDER PAINTER (Ornate Golden Double Border with Corner Arches)
// ═════════════════════════════════════════════════════════════════════════════
class _IslamicPageBorderPainter extends CustomPainter {
  final Color borderColor;
  final bool isDark;

  const _IslamicPageBorderPainter({
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padOuter = 4.0;
    const double padInner = 8.0;

    final outerPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.75 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.40 : 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padOuter,
        padOuter,
        size.width - padOuter * 2,
        size.height - padOuter * 2,
      ),
      const Radius.circular(14),
    );

    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padInner,
        padInner,
        size.width - padInner * 2,
        size.height - padInner * 2,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(outerRRect, outerPaint);
    canvas.drawRRect(innerRRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _IslamicPageBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor || oldDelegate.isDark != isDark;
  }
}
