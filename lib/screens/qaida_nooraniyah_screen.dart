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
  final String? cornerBadge;
  final Color? cornerBadgeBg;

  const QaidaCell({
    this.text,
    this.segments,
    this.phonetic,
    this.color,
    this.flex = 1,
    this.cornerBadge,
    this.cornerBadgeBg,
  });

  String get fullText => text ?? segments?.map((s) => s.text).join() ?? '';
}

class QaidaRow {
  final List<QaidaCell>? cells;
  final bool isHeader;
  final bool inlineHeader;
  final int inlineHeaderFlex;
  final bool inlineHeaderStacked;
  final String? headerLessonTitle;
  final String? headerLessonSubtitle;
  final bool isCentered;
  final String? sideBadgeText;
  final Color? sideBadgeColor;
  final Widget? customWidget;

  const QaidaRow({
    this.cells,
    this.isHeader = false,
    this.inlineHeader = false,
    this.inlineHeaderFlex = 4,
    this.inlineHeaderStacked = false,
    this.headerLessonTitle,
    this.headerLessonSubtitle,
    this.isCentered = false,
    this.sideBadgeText,
    this.sideBadgeColor,
    this.customWidget,
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
    description:
        'نطق الحروف العربية المفردة بمخارجها الصحيحة من اليمين إلى اليسار',
    showBismillah: true,
    customRows: [
      // Row 1 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ا', phonetic: 'أَلِف'),
          QaidaCell(text: 'ب', phonetic: 'با'),
          QaidaCell(text: 'ت', phonetic: 'تا'),
          QaidaCell(text: 'ث', phonetic: 'ثا'),
          QaidaCell(text: 'ج', phonetic: 'جيم'),
        ],
      ),

      // Row 2 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ح', phonetic: 'حا'),
          QaidaCell(text: 'خ', phonetic: 'خا'),
          QaidaCell(text: 'د', phonetic: 'دال'),
          QaidaCell(text: 'ذ', phonetic: 'ذال'),
          QaidaCell(text: 'ر', phonetic: 'را'),
        ],
      ),

      // Row 3 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ز', phonetic: 'زا'),
          QaidaCell(text: 'س', phonetic: 'سين'),
          QaidaCell(text: 'ش', phonetic: 'شين'),
          QaidaCell(text: 'ص', phonetic: 'صاد'),
          QaidaCell(text: 'ض', phonetic: 'ضاد'),
        ],
      ),

      // Row 4 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ط', phonetic: 'طا'),
          QaidaCell(text: 'ظ', phonetic: 'ظا'),
          QaidaCell(text: 'ع', phonetic: 'عين'),
          QaidaCell(text: 'غ', phonetic: 'غين'),
          QaidaCell(text: 'ف', phonetic: 'فا'),
        ],
      ),

      // Row 5 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ق', phonetic: 'قاف'),
          QaidaCell(text: 'ك', phonetic: 'كاف'),
          QaidaCell(text: 'ل', phonetic: 'لام'),
          QaidaCell(text: 'م', phonetic: 'ميم'),
          QaidaCell(text: 'ن', phonetic: 'نون'),
        ],
      ),

      // Row 6 (4 items + Hamzah/Yaa = 5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'و', phonetic: 'واو'),
          QaidaCell(text: 'هـ', phonetic: 'ها'),
          QaidaCell(text: 'ء', phonetic: 'همزة'),
          QaidaCell(text: 'ي', phonetic: 'يا'),
          QaidaCell(text: 'ے', phonetic: 'يا'),
        ],
      ),
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
    showBismillah: false,
    customRows: [
      // Row 1
      QaidaRow(
        cells: [
          QaidaCell(text: 'ا'),
          QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
          QaidaCell(text: 'ل', color: _kRed),
          QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ا')]),
          QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
          QaidaCell(text: 'ل', color: _kRed),
        ],
      ),

      // Row 2
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ل', _kRed), QaidaSegment('ح', _kGreen)]),
          QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ا', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ل', _kBlue), QaidaSegment('ب', _kBlue)]),
          QaidaCell(text: 'ك'),
          QaidaCell(text: 'ك'),
        ],
      ),

      // Row 3
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('ك', _kBlue), QaidaSegment('ب', _kBlue)]),
          QaidaCell(
              segments: [QaidaSegment('ك', _kBlue), QaidaSegment('ب', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ك'), QaidaSegment('ا', _kGrey)]),
          QaidaCell(segments: [QaidaSegment('ك'), QaidaSegment('ا', _kGrey)]),
          QaidaCell(segments: [
            QaidaSegment('ب', _kGrey),
            QaidaSegment('ك', _kBlue),
            QaidaSegment('ت', _kGrey)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ت', _kGrey),
            QaidaSegment('ك'),
            QaidaSegment('ث', _kGrey)
          ]),
        ],
      ),

      // Row 4
      QaidaRow(
        cells: [
          QaidaCell(text: 'ب', color: _kBlue),
          QaidaCell(text: 'ت'),
          QaidaCell(text: 'ث'),
          QaidaCell(text: 'ن', color: _kRed),
          QaidaCell(text: 'ى', color: _kRed),
          QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ا')]),
        ],
      ),

      // Row 5
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ن'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ا', _kGrey)]),
          QaidaCell(segments: [QaidaSegment('ي', _kRed), QaidaSegment('ا')]),
          QaidaCell(segments: [QaidaSegment('ث', _kGrey), QaidaSegment('ا')]),
          QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('س')]),
          QaidaCell(segments: [QaidaSegment('ي'), QaidaSegment('س', _kRed)]),
        ],
      ),

      // Row 6
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ن'), QaidaSegment('س', _kRed)]),
          QaidaCell(text: 'تس'),
          QaidaCell(text: 'ثس'),
          QaidaCell(text: 'ثج'),
          QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ح', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('ن', _kGreen), QaidaSegment('خ', _kRed)]),
        ],
      ),

      // Row 7
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('ي', _kGreen), QaidaSegment('ح', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ج')]),
          QaidaCell(
              segments: [QaidaSegment('ي', _kRed), QaidaSegment('ه', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ب', _kBlue), QaidaSegment('م', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ن', _kRed), QaidaSegment('م', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ت', _kRed), QaidaSegment('م', _kRed)]),
        ],
      ),

      // Row 8
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ث'), QaidaSegment('م', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ي', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ي', _kRed), QaidaSegment('ى', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ن', _kRed), QaidaSegment('ى', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ت', _kRed), QaidaSegment('ى', _kRed)]),
          QaidaCell(
              segments: [QaidaSegment('ث', _kRed), QaidaSegment('ى', _kRed)]),
        ],
      ),

      // Row 9
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ن', _kRed),
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ل', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ت', _kRed),
            QaidaSegment('ن'),
            QaidaSegment('ل', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ي', _kRed),
            QaidaSegment('ل', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ي', _kRed),
            QaidaSegment('ت', _kRed),
            QaidaSegment('ل', _kRed)
          ]),
          QaidaCell(segments: [QaidaSegment('ث'), QaidaSegment('ل', _kRed)]),
          QaidaCell(segments: [
            QaidaSegment('ن', _kRed),
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ن', _kRed)
          ]),
        ],
      ),
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
    showBismillah: false,
    showHeader: false,
    customRows: [
      // Row 1
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ن', _kRed),
            QaidaSegment('ن', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ت'),
            QaidaSegment('ي', _kRed),
            QaidaSegment('ن', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ي', _kRed),
            QaidaSegment('ت'),
            QaidaSegment('ن', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ث', _kGrey),
            QaidaSegment('ث', _kGrey),
            QaidaSegment('ن', _kRed)
          ]),
          QaidaCell(text: 'ج'),
          QaidaCell(text: 'ح', color: _kGreen),
        ],
      ),

      // Row 2
      QaidaRow(
        cells: [
          QaidaCell(text: 'خ', color: _kGreen),
          QaidaCell(segments: [QaidaSegment('ح', _kGreen), QaidaSegment('ث')]),
          QaidaCell(segments: [
            QaidaSegment('خ', _kGreen),
            QaidaSegment('ب', _kBlue)
          ]),
          QaidaCell(text: 'جت'),
          QaidaCell(segments: [
            QaidaSegment('ت'),
            QaidaSegment('ح', _kGreen),
            QaidaSegment('ت')
          ]),
          QaidaCell(segments: [
            QaidaSegment('ي', _kRed),
            QaidaSegment('ج'),
            QaidaSegment('ب', _kBlue)
          ]),
        ],
      ),

      // Row 3
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ب'),
            QaidaSegment('خ', _kGreen),
            QaidaSegment('ت')
          ]),
          QaidaCell(text: 'ة'),
          QaidaCell(text: 'ه', color: _kGreen),
          QaidaCell(segments: [QaidaSegment('ب', _kBlue), QaidaSegment('ة')]),
          QaidaCell(
              segments: [QaidaSegment('ي', _kRed), QaidaSegment('ه', _kGreen)]),
          QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ه', _kGreen)]),
        ],
      ),

      // Row 4
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ن', _kRed), QaidaSegment('ة')]),
          QaidaCell(text: 'ه', color: _kGreen),
          QaidaCell(segments: [
            QaidaSegment('ي', _kBlue),
            QaidaSegment('ه', _kRed),
            QaidaSegment('ب', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ه', _kGreen),
            QaidaSegment('ا')
          ]),
          QaidaCell(segments: [
            QaidaSegment('ب', _kRed),
            QaidaSegment('ه', _kBlue),
            QaidaSegment('م')
          ]),
          QaidaCell(text: 'د'),
        ],
      ),

      // Row 5
      QaidaRow(
        cells: [
          QaidaCell(text: 'ذ'),
          QaidaCell(segments: [QaidaSegment('ج', _kGrey), QaidaSegment('د')]),
          QaidaCell(segments: [QaidaSegment('خ', _kGreen), QaidaSegment('ذ')]),
          QaidaCell(text: 'ر', color: _kRed),
          QaidaCell(text: 'ز'),
          QaidaCell(segments: [QaidaSegment('ج', _kRed), QaidaSegment('ر')]),
        ],
      ),

      // Row 6
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('خ', _kGreen), QaidaSegment('ز')]),
          QaidaCell(text: 'ر', color: _kRed),
          QaidaCell(text: 'ز'),
          QaidaCell(text: 'ر', color: _kRed),
          QaidaCell(text: 'ز'),
          QaidaCell(text: 'س'),
        ],
      ),

      // Row 7
      QaidaRow(
        cells: [
          QaidaCell(text: 'ش'),
          QaidaCell(segments: [QaidaSegment('س'), QaidaSegment('ل', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ش'), QaidaSegment('ل', _kRed)]),
          QaidaCell(text: 'ص'),
          QaidaCell(text: 'ض'),
          QaidaCell(text: 'ط'),
        ],
      ),

      // Row 8
      QaidaRow(
        cells: [
          QaidaCell(text: 'ظ'),
          QaidaCell(segments: [QaidaSegment('ص'), QaidaSegment('ب', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ط'), QaidaSegment('ب', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ض', _kGrey), QaidaSegment('ا')]),
          QaidaCell(segments: [QaidaSegment('ظ', _kGrey), QaidaSegment('ا')]),
          QaidaCell(text: 'ع', color: _kGreen),
        ],
      ),

      // Row 9
      QaidaRow(
        cells: [
          QaidaCell(text: 'غ', color: _kGreen),
          QaidaCell(text: 'ء', color: _kGreen),
          QaidaCell(segments: [QaidaSegment('ع', _kGreen), QaidaSegment('ز')]),
          QaidaCell(
              segments: [QaidaSegment('غ', _kGreen), QaidaSegment('ر', _kRed)]),
          QaidaCell(segments: [
            QaidaSegment('ص', _kGreen),
            QaidaSegment('ع', _kGreen)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ض', _kGreen),
            QaidaSegment('غ', _kGreen)
          ]),
        ],
      ),

      // Row 10
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ب', _kBlue),
            QaidaSegment('ع', _kGreen),
            QaidaSegment('د')
          ]),
          QaidaCell(text: 'تغذ'),
          QaidaCell(text: 'أ', color: _kGreen),
          QaidaCell(text: 'ؤ', color: _kGreen),
          QaidaCell(text: 'ئ', color: _kGreen),
          QaidaCell(text: 'ف'),
        ],
      ),
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
          QaidaCell(
              segments: [QaidaSegment('ح', _kTeal), QaidaSegment('م', _kRed)]),
        ],
      ),

      // Row 3 (3 wide items)
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('ل', _kRed), QaidaSegment('م', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ت', _kRed), QaidaSegment('م')]),
          QaidaCell(segments: [
            QaidaSegment('ت'),
            QaidaSegment('م', _kRed),
            QaidaSegment('ت')
          ]),
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
          QaidaCell(segments: [
            QaidaSegment('ا'),
            QaidaSegment('لٓ', _kRed),
            QaidaSegment('مٓ', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ا'),
            QaidaSegment('لٓ', _kRed),
            QaidaSegment('مٓ', _kRed),
            QaidaSegment('صٓ', _kRed)
          ]),
          QaidaCell(segments: [
            QaidaSegment('ا'),
            QaidaSegment('لٓ', _kRed),
            QaidaSegment('ر')
          ]),
          QaidaCell(segments: [
            QaidaSegment('ا'),
            QaidaSegment('لٓ', _kRed),
            QaidaSegment('مٓ', _kRed),
            QaidaSegment('ر')
          ]),
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
          QaidaCell(flex: 1, segments: [
            QaidaSegment('ط'),
            QaidaSegment('سٓ', _kRed),
            QaidaSegment('مٓ', _kRed)
          ]),
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
    showBismillah: false,
    showHeader: true,
    customRows: [
      // Row 1 (8 items, Gold - Hamzah, Haa, Ayn)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَ', color: _kGold),
          QaidaCell(text: 'إِ', color: _kGold),
          QaidaCell(text: 'أُ', color: _kGold),
          QaidaCell(text: 'هَ', color: _kGold),
          QaidaCell(text: 'هِ', color: _kGold),
          QaidaCell(text: 'هُ', color: _kGold),
          QaidaCell(text: 'عَ', color: _kGold),
          QaidaCell(text: 'عِ', color: _kGold),
        ],
      ),

      // Row 2 (8 items, Gold - Ayn, Haa, Khaa, Ghayn)
      QaidaRow(
        cells: [
          QaidaCell(text: 'عُ', color: _kGold),
          QaidaCell(text: 'حَ', color: _kGold),
          QaidaCell(text: 'حِ', color: _kGold),
          QaidaCell(text: 'حُ', color: _kGold),
          QaidaCell(text: 'خَ', color: _kGold),
          QaidaCell(text: 'خِ', color: _kGold),
          QaidaCell(text: 'خُ', color: _kGold),
          QaidaCell(text: 'غَ', color: _kGold),
        ],
      ),

      // Row 3 (8 items: 2 Gold Ghayn + 6 Purple Qaaf, Kaaf)
      QaidaRow(
        cells: [
          QaidaCell(text: 'غِ', color: _kGold),
          QaidaCell(text: 'غُ', color: _kGold),
          QaidaCell(text: 'قَ', color: _kPurple),
          QaidaCell(text: 'قِ', color: _kPurple),
          QaidaCell(text: 'قُ', color: _kPurple),
          QaidaCell(text: 'كَ', color: _kPurple),
          QaidaCell(text: 'كِ', color: _kPurple),
          QaidaCell(text: 'كُ', color: _kPurple),
        ],
      ),

      // Row 4 (8 items, Purple - Jeem, Sheen, Yaa)
      QaidaRow(
        cells: [
          QaidaCell(text: 'جَ', color: _kPurple),
          QaidaCell(text: 'جِ', color: _kPurple),
          QaidaCell(text: 'جُ', color: _kPurple),
          QaidaCell(text: 'شَ', color: _kPurple),
          QaidaCell(text: 'شِ', color: _kPurple),
          QaidaCell(text: 'شُ', color: _kPurple),
          QaidaCell(text: 'يَ', color: _kPurple),
          QaidaCell(text: 'يِ', color: _kPurple),
        ],
      ),

      // Row 5 (8 items, Purple - Yaa, Daad, Laam, Noon)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يُ', color: _kPurple),
          QaidaCell(text: 'ضَ', color: _kPurple),
          QaidaCell(text: 'ضِ', color: _kPurple),
          QaidaCell(text: 'ضُ', color: _kPurple),
          QaidaCell(text: 'لَ', color: _kPurple),
          QaidaCell(text: 'لِ', color: _kPurple),
          QaidaCell(text: 'لُ', color: _kPurple),
          QaidaCell(text: 'نَ', color: _kPurple),
        ],
      ),

      // Row 6 (8 items, Purple - Noon, Raa, Taa)
      QaidaRow(
        cells: [
          QaidaCell(text: 'نِ', color: _kPurple),
          QaidaCell(text: 'نُ', color: _kPurple),
          QaidaCell(text: 'رَ', color: _kPurple),
          QaidaCell(text: 'رِ', color: _kPurple),
          QaidaCell(text: 'رُ', color: _kPurple),
          QaidaCell(text: 'طَ', color: _kPurple),
          QaidaCell(text: 'طِ', color: _kPurple),
          QaidaCell(text: 'طُ', color: _kPurple),
        ],
      ),

      // Row 7 (8 items, Purple - Daal, Taa, Saad)
      QaidaRow(
        cells: [
          QaidaCell(text: 'دَ', color: _kPurple),
          QaidaCell(text: 'دِ', color: _kPurple),
          QaidaCell(text: 'دُ', color: _kPurple),
          QaidaCell(text: 'تَ', color: _kPurple),
          QaidaCell(text: 'تِ', color: _kPurple),
          QaidaCell(text: 'تُ', color: _kPurple),
          QaidaCell(text: 'صَ', color: _kPurple),
          QaidaCell(text: 'صِ', color: _kPurple),
        ],
      ),

      // Row 8 (8 items, Purple - Saad, Seen, Zaay, Zaa)
      QaidaRow(
        cells: [
          QaidaCell(text: 'صُ', color: _kPurple),
          QaidaCell(text: 'سَ', color: _kPurple),
          QaidaCell(text: 'سِ', color: _kPurple),
          QaidaCell(text: 'سُ', color: _kPurple),
          QaidaCell(text: 'زَ', color: _kPurple),
          QaidaCell(text: 'زِ', color: _kPurple),
          QaidaCell(text: 'زُ', color: _kPurple),
          QaidaCell(text: 'ظَ', color: _kPurple),
        ],
      ),

      // Row 9 (8 items, Purple - Zaa, Dhaal, Thaa)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ظِ', color: _kPurple),
          QaidaCell(text: 'ظُ', color: _kPurple),
          QaidaCell(text: 'ذَ', color: _kPurple),
          QaidaCell(text: 'ذِ', color: _kPurple),
          QaidaCell(text: 'ذُ', color: _kPurple),
          QaidaCell(text: 'ثَ', color: _kPurple),
          QaidaCell(text: 'ثِ', color: _kPurple),
          QaidaCell(text: 'ثُ', color: _kPurple),
        ],
      ),
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
        headerLessonSubtitle: 'الحُرُوفُ المُنَوَّنَةُ\n\nالتَّنْوِين: ً  ٍ  ٌ',
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
          QaidaCell(text: 'مًا', color: _kBlue),
          QaidaCell(text: 'مٍ', color: _kBlue),
          QaidaCell(text: 'مٌ', color: _kBlue),
          QaidaCell(text: 'بًا', color: _kBlue),
          QaidaCell(text: 'بٍ', color: _kBlue),
          QaidaCell(text: 'بٌ', color: _kBlue),
          QaidaCell(text: 'وًا', color: _kBlue),
          QaidaCell(text: 'وٍ', color: _kBlue),
        ],
      ),

      // Row 4
      QaidaRow(
        cells: [
          QaidaCell(text: 'وٌ', color: _kBlue),
          QaidaCell(text: 'فًا', color: _kBlue),
          QaidaCell(text: 'فٍ', color: _kBlue),
          QaidaCell(text: 'فٌ', color: _kBlue),
          QaidaCell(text: 'ثًا', color: _kPurple),
          QaidaCell(text: 'ثٍ', color: _kPurple),
          QaidaCell(text: 'ثٌ', color: _kPurple),
          QaidaCell(text: 'ذًا', color: _kPurple),
        ],
      ),

      // Row 5 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ذٍ', color: _kPurple),
          QaidaCell(text: 'ذٌ', color: _kPurple),
          QaidaCell(text: 'ظًا', color: _kPurple),
          QaidaCell(text: 'ظٍ', color: _kPurple),
          QaidaCell(text: 'ظٌ', color: _kPurple),
          QaidaCell(text: 'زًا', color: _kPurple),
          QaidaCell(text: 'زٍ', color: _kPurple),
          QaidaCell(text: 'زٌ', color: _kPurple),
        ],
      ),

      // Row 6 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'سًا', color: _kPurple),
          QaidaCell(text: 'سٍ', color: _kPurple),
          QaidaCell(text: 'سٌ', color: _kPurple),
          QaidaCell(text: 'صًا', color: _kPurple),
          QaidaCell(text: 'صٍ', color: _kPurple),
          QaidaCell(text: 'صٌ', color: _kPurple),
          QaidaCell(text: 'ةً', color: _kPurple),
          QaidaCell(text: 'تٍ', color: _kPurple),
        ],
      ),

      // Row 7 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ةٌ', color: _kPurple),
          QaidaCell(text: 'دً', color: _kPurple),
          QaidaCell(text: 'دٍ', color: _kPurple),
          QaidaCell(text: 'دٌ', color: _kPurple),
          QaidaCell(text: 'طًا', color: _kPurple),
          QaidaCell(text: 'طٍ', color: _kPurple),
          QaidaCell(text: 'طٌ', color: _kPurple),
          QaidaCell(text: 'رًا', color: _kPurple),
        ],
      ),

      // Row 8 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'رٍ', color: _kPurple),
          QaidaCell(text: 'رٌ', color: _kPurple),
          QaidaCell(text: 'نًا', color: _kPurple),
          QaidaCell(text: 'نٍ', color: _kPurple),
          QaidaCell(text: 'نٌ', color: _kPurple),
          QaidaCell(text: 'لًا', color: _kPurple),
          QaidaCell(text: 'لٍ', color: _kPurple),
          QaidaCell(text: 'لٌ', color: _kPurple),
        ],
      ),

      // Row 9 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ضًا', color: _kPurple),
          QaidaCell(text: 'ضٍ', color: _kPurple),
          QaidaCell(text: 'ضٌ', color: _kPurple),
          QaidaCell(text: 'يً', color: _kPurple),
          QaidaCell(text: 'يٍ', color: _kPurple),
          QaidaCell(text: 'يٌ', color: _kPurple),
          QaidaCell(text: 'شًا', color: _kPurple),
          QaidaCell(text: 'شٍ', color: _kPurple),
        ],
      ),

      // Row 10 (Purple)
      QaidaRow(
        cells: [
          QaidaCell(text: 'شٌ', color: _kPurple),
          QaidaCell(text: 'جًا', color: _kPurple),
          QaidaCell(text: 'جٍ', color: _kPurple),
          QaidaCell(text: 'جٌ', color: _kPurple),
          QaidaCell(text: 'كًا', color: _kPurple),
          QaidaCell(text: 'كٍ', color: _kPurple),
          QaidaCell(text: 'كٌ', color: _kPurple),
          QaidaCell(text: 'قًا', color: _kPurple),
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
          QaidaCell(text: 'خًا', color: _kGold),
          QaidaCell(text: 'خٍ', color: _kGold),
          QaidaCell(text: 'خٌ', color: _kGold),
          QaidaCell(text: 'غًا', color: _kGold),
          QaidaCell(text: 'غٍ', color: _kGold),
          QaidaCell(text: 'غٌ', color: _kGold),
        ],
      ),

      // Row 2 (8 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'حًا', color: _kGold),
          QaidaCell(text: 'حٍ', color: _kGold),
          QaidaCell(text: 'حٌ', color: _kGold),
          QaidaCell(text: 'عًا', color: _kGold),
          QaidaCell(text: 'عٍ', color: _kGold),
          QaidaCell(text: 'عٌ', color: _kGold),
          QaidaCell(text: 'هـًا', color: _kGold),
          QaidaCell(text: 'هـٍ', color: _kGold),
        ],
      ),

      // Row 3 (4 items centered in 8-column layout)
      QaidaRow(
        isCentered: true,
        cells: [
          QaidaCell(text: 'هـٌ', color: _kGold),
          QaidaCell(text: 'ءً', color: _kGold),
          QaidaCell(text: 'ءٍ', color: _kGold),
          QaidaCell(text: 'ءٌ', color: _kGold),
        ],
      ),

      // ── Mid Section: Full Width Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ السَّادِسُ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِينِ',
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
          QaidaCell(text: 'أَنَا', color: _kBlue),
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
          QaidaCell(text: 'خَلَقَ', color: _kBlue),
          QaidaCell(text: 'خُلِقَ'),
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
  // PAGE 8 : خاتمة الدرس السادس + الدَّرْسُ السَّابِع (الأَلِفُ وَاليَاءُ وَالوَاوُ الصَّغِيرَة)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 8,
    lessonNumber: 7,
    lessonTitleAr: 'الدَّرْسُ السَّابِعُ',
    lessonSubtitleAr:
        'الأَلِفُ الصَّغِيرَةُ وَاليَاءُ الصَّغِيرَةُ وَالوَاوُ الصَّغِيرَةُ',
    titleEn: 'Lesson 7: Small Alif, Small Yaa & Small Waw',
    description: 'خاتمة تدريبات الحركات والتنوين وبداية درس الحركات الصغيرة',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Lesson 6 Words (6 columns) ──
      // Row 1 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قَسَمٌ'),
          QaidaCell(text: 'كَبَدٍ', color: _kBlue),
          QaidaCell(text: 'كُتُبٌ'),
          QaidaCell(text: 'كَسَبَ', color: _kBlue),
          QaidaCell(text: 'كَفَرَ'),
          QaidaCell(text: 'كُفُوًا', color: _kBlue),
        ],
      ),

      // Row 2 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لُبَدًا'),
          QaidaCell(text: 'لُمَزَةٍ', color: _kBlue),
          QaidaCell(text: 'لَهَبٍ'),
          QaidaCell(text: 'مَسَدٍ', color: _kBlue),
          QaidaCell(text: 'نَخِرَةً'),
          QaidaCell(text: 'وَجَدَ', color: _kBlue),
        ],
      ),

      // Row 3 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَسَقَ'),
          QaidaCell(text: 'وَقَبَ', color: _kBlue),
          QaidaCell(text: 'وَلَدَ'),
          QaidaCell(text: 'وَهَبَ', color: _kBlue),
          QaidaCell(text: 'هُمَزَةٍ'),
          QaidaCell(text: 'هُدًى', color: _kBlue),
        ],
      ),

      // ── Mid Section: Lesson 7 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ السَّابِعُ',
        headerLessonSubtitle:
            'الأَلِفُ الصَّغِيرَةُ وَاليَاءُ الصَّغِيرَةُ\n\n وَالوَاوُ الصَّغِيرَةُ',
      ),

      // ── Bottom Section: Lesson 7 Letters (7 columns) ──
      // Row 4 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ب'), QaidaSegment('ٰ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ي'), QaidaSegment('ٰ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ر'), QaidaSegment('ٰ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('م'), QaidaSegment('ٰ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ل'), QaidaSegment('ٰ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('و'), QaidaSegment('ٰ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ن'), QaidaSegment('ٰ', _kRed)]),
        ],
      ),

      // Row 5 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ء'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('هـ'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('ع'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('ح'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('غ'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('خ'), QaidaSegment('ٰ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('ت'), QaidaSegment('ٰ', _kGold)]),
        ],
      ),

      // Row 6 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ث'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ج'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('د'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ذ'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ز'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('س'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ش'), QaidaSegment('ٰ', _kGold)]),
        ],
      ),

      // Row 7 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ص'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ض'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ط'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ظ'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ف'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ق'), QaidaSegment('ٰ', _kGold)]),
          QaidaCell(segments: [QaidaSegment('ك'), QaidaSegment('ٰ', _kGold)]),
        ],
      ),

      // Row 8 (7 items: Small Yaa & Small Waw)
      QaidaRow(
        cells: [
          QaidaCell(text: '◆'),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('ۦ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('هِ'), QaidaSegment('ۦ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('وُ'), QaidaSegment('ۥ', _kRed)]),
          QaidaCell(segments: [QaidaSegment('هُ'), QaidaSegment('ۥ', _kTeal)]),
          QaidaCell(segments: [QaidaSegment('ءُ'), QaidaSegment('ۥ', _kTeal)]),
          QaidaCell(text: '◆'),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 9 : الدَّرْسُ الثَّامِن - حُرُوفُ المَدِّ وَاللِّين (7 columns x 9 rows)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 9,
    lessonNumber: 8,
    lessonTitleAr: 'الدَّرْسُ الثَّامِنُ',
    lessonSubtitleAr: 'حُرُوفُ المَدِّ وَاللِّينِ',
    titleEn: 'Lesson 8: Letters of Madd & Leen (Part 1)',
    description: 'أحرف المد الثلاثة: الألف والواو والياء وحرفا اللين',
    showBismillah: false,
    showHeader: true,
    customRows: [
      // Row 1 (7 items: Col 1 has embedded 'المَدّ' corner badge inside the letter box)
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [QaidaSegment('بَ'), QaidaSegment('ا', _kRed)],
            cornerBadge: 'المَدّ',
            cornerBadgeBg: Color(0xFFC62828),
          ),
          QaidaCell(segments: [QaidaSegment('بُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('بِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('تَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('تُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('تِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ثَ'), QaidaSegment('ا', _kRed)]),
        ],
      ),

      // Row 2 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ثُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ثِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('حَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('حُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('حِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('خَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('خُ'), QaidaSegment('و', _kRed)]),
        ],
      ),

      // Row 3 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('خِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('رَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('رُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('رِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('زَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('زُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('زِ'), QaidaSegment('ي', _kRed)]),
        ],
      ),

      // Row 4 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('طَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('طُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('طِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ظَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ظُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ظِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('فَ'), QaidaSegment('ا', _kRed)]),
        ],
      ),

      // Row 5 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('فُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('فِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('هَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('هُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('هِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('يَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('يُ'), QaidaSegment('و', _kRed)]),
        ],
      ),

      // Row 6 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('يِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ءَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ءُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ءِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('جَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('جُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('جِ'), QaidaSegment('ي', _kRed)]),
        ],
      ),

      // Row 7 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('دَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('دُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('دِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ذَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ذُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ذِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('سَ'), QaidaSegment('ا', _kRed)]),
        ],
      ),

      // Row 8 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('سُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('سِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('شَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('شُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('شِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('صَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('صُ'), QaidaSegment('و', _kRed)]),
        ],
      ),

      // Row 9 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('صِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ضَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ضُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('ضِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('عَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('عُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('عِ'), QaidaSegment('ي', _kRed)]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 10 : الدَّرْسُ الثَّامِن - حُرُوفُ المَدِّ وَاللِّين (7 columns x 10 rows)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 10,
    lessonNumber: 8,
    lessonTitleAr: 'الدَّرْسُ الثَّامِنُ',
    lessonSubtitleAr: 'حُرُوفُ المَدِّ وَاللِّينِ (تابع - اللِّين)',
    titleEn: 'Lesson 8: Letters of Madd & Leen (Part 2)',
    description: 'تكملة أحرف المد وبداية حروف اللين مع السكون',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Madd (Rows 1 to 3) ──
      // Row 1 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('غَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('غُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('غِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('قَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('قُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('قِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('كَ'), QaidaSegment('ا', _kRed)]),
        ],
      ),

      // Row 2 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('كُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('كِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('لَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('لُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('لِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('مَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('مُ'), QaidaSegment('و', _kRed)]),
        ],
      ),

      // Row 3 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('مِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('نَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('نُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('نِ'), QaidaSegment('ي', _kRed)]),
          QaidaCell(segments: [QaidaSegment('وَ'), QaidaSegment('ا', _kRed)]),
          QaidaCell(segments: [QaidaSegment('وُ'), QaidaSegment('و', _kRed)]),
          QaidaCell(segments: [QaidaSegment('وِ'), QaidaSegment('ي', _kRed)]),
        ],
      ),

      // ── Bottom Section: Leen Letters (Sukoon in Blue with Quranic Ra's Khah ۡ) (Rows 4 to 10) ──
      // Row 4 (7 items: Col 1 has embedded 'اللِّين' corner badge inside the letter box)
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [QaidaSegment('تَ'), QaidaSegment('وۡ', _kBlue)],
            cornerBadge: 'اللِّين',
            cornerBadgeBg: Color(0xFF1976D2),
          ),
          QaidaCell(segments: [QaidaSegment('تَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ثَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ثَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('دَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('دَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ذَ'), QaidaSegment('وۡ', _kBlue)]),
        ],
      ),

      // Row 5 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('ذَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('رَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('رَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('زَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('زَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('سَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('سَ'), QaidaSegment('يۡ', _kBlue)]),
        ],
      ),

      // Row 6 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('شَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('شَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('صَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('صَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ضَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ضَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('طَ'), QaidaSegment('وۡ', _kBlue)]),
        ],
      ),

      // Row 7 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('طَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ظَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('ظَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('لَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('لَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('نَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('نَ'), QaidaSegment('يۡ', _kBlue)]),
        ],
      ),

      // Row 8 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('بَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('بَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('جَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('جَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('حَ'), QaidaSegment('وۡ', _kBlue)]),
        ],
      ),

      // Row 9 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('حَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('خَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('خَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('عَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('عَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('غَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('غَ'), QaidaSegment('يۡ', _kBlue)]),
        ],
      ),

      // Row 10 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('فَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('فَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('قَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('قَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('كَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('كَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('مَ'), QaidaSegment('وۡ', _kBlue)]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 11 : خاتمة حروف اللين + الدَّرْسُ التَّاسِع (تَدْرِيبَاتٌ عَلَى التَّنْوِين وَالمَدّ وَاللِّين)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 11,
    lessonNumber: 9,
    lessonTitleAr: 'الدَّرْسُ التَّاسِعُ',
    lessonSubtitleAr:
        'تَدْرِيبَاتٌ عَلَى التَّنْوِينِ وَأَحْرُفِ المَدِّ الثَّلَاثَةِ وَحَرْفَيِ اللِّينِ',
    titleEn: 'Lesson 9: Exercises on Tanween, Madd & Leen (Part 1)',
    description: 'تكملة حروف اللين وبداية التدريبات الشاملة',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: Conclusion of Leen letters (7 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('مَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('وَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('وَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('هَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('هَ'), QaidaSegment('يۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('يَ'), QaidaSegment('وۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('يَ'), QaidaSegment('يۡ', _kBlue)]),
        ],
      ),

      // ── Mid Section: Lesson 9 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ التَّاسِعُ',
        headerLessonSubtitle:
            'تَدْرِيبَاتٌ عَلَى التَّنْوِينِ وَأَحْرُفِ المَدِّ الثَّلَاثَةِ وَحَرْفَيِ اللِّينِ',
      ),

      // ── Lesson 9 Words (6 columns per row) ──
      // Row 2 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ءَامَنَ'),
          QaidaCell(text: 'ءَاوَىٰ', color: _kBlue),
          QaidaCell(text: 'ءَانِيَةٍ'),
          QaidaCell(text: 'إِيلَٰفِ', color: _kBlue),
          QaidaCell(text: 'أَيۡنَ'),
          QaidaCell(text: 'بِهِۦ', color: _kBlue),
        ],
      ),

      // Row 3 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('جَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءَ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('جِ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ىءَ', _kBlue)
          ]),
          QaidaCell(text: 'جُوعٍ'),
          QaidaCell(text: 'خَوۡفٍ', color: _kBlue),
          QaidaCell(text: 'خَيۡرٌ'),
          QaidaCell(text: 'دَاوُۥدُ', color: _kBlue),
        ],
      ),

      // Row 4 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ذَٰلِكَ'),
          QaidaCell(text: 'رَضُواْ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('شَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءَ')
          ]),
          QaidaCell(text: 'مَالِكِ', color: _kBlue),
          QaidaCell(text: 'شَىۡءٍ'),
          QaidaCell(text: 'طَغَىٰ', color: _kBlue),
        ],
      ),

      // Row 5 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'طَغَوۡاْ'),
          QaidaCell(text: 'طَيۡرًا', color: _kBlue),
          QaidaCell(text: 'عَادٍ'),
          QaidaCell(text: 'عَلَىٰ', color: _kBlue),
          QaidaCell(text: 'عَيۡنٌ'),
          QaidaCell(text: 'فِيهِ', color: _kBlue),
        ],
      ),

      // Row 6 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قَالَ'),
          QaidaCell(text: 'قَوۡلٌ', color: _kBlue),
          QaidaCell(text: 'كَانَ'),
          QaidaCell(text: 'كَيۡدًا', color: _kBlue),
          QaidaCell(text: 'كَيۡفَ'),
          QaidaCell(text: 'لَوۡحٍ', color: _kBlue),
        ],
      ),

      // Row 7 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لَيۡسَ'),
          QaidaCell(text: 'مَالًا', color: _kBlue),
          QaidaCell(text: 'نَارًا'),
          QaidaCell(segments: [
            QaidaSegment('مَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءٍ', _kBlue)
          ]),
          QaidaCell(text: 'وَيۡلٌ'),
          QaidaCell(text: 'يَوۡمٍ', color: _kBlue),
        ],
      ),

      // Row 8 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَرَهُۥ'),
          QaidaCell(text: 'حَاسِدٍ', color: _kBlue),
          QaidaCell(text: 'حَافِظٌ'),
          QaidaCell(text: 'دَافِقٍ', color: _kBlue),
          QaidaCell(text: 'شَاهِدٍ'),
          QaidaCell(text: 'عَابِدٌ', color: _kBlue),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 12 : الدَّرْسُ التَّاسِع (تَدْرِيبَاتٌ عَلَى التَّنْوِين وَالمَدّ وَاللِّين - تابع)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 12,
    lessonNumber: 9,
    lessonTitleAr: 'الدَّرْسُ التَّاسِعُ',
    lessonSubtitleAr:
        'تَدْرِيبَاتٌ عَلَى التَّنْوِينِ وَأَحْرُفِ المَدِّ وَاللِّين (تابع)',
    titleEn: 'Lesson 9: Exercises on Tanween, Madd & Leen (Part 2)',
    description: 'متابعة كلمات تدريبات التنوين وحروف المد واللين',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // Row 1 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('عَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ئِلًا')
          ]),
          QaidaCell(text: 'غَاسِقٍ', color: _kBlue),
          QaidaCell(text: 'نَاصِرٍ'),
          QaidaCell(text: 'وَالِدٍ', color: _kBlue),
          QaidaCell(text: 'أَعُوذُ'),
          QaidaCell(text: 'أَكِيدُ', color: _kBlue),
        ],
      ),

      // Row 2 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَخَافُ'),
          QaidaCell(text: 'يَدَاهُ', color: _kBlue),
          QaidaCell(text: 'يُقَالُ'),
          QaidaCell(text: 'تُرَابًا', color: _kBlue),
          QaidaCell(text: 'حِسَابًا'),
          QaidaCell(text: 'سُبَاتًا', color: _kBlue),
        ],
      ),

      // Row 3 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'سِرَاجًا'),
          QaidaCell(text: 'سَلَٰمٌ', color: _kBlue),
          QaidaCell(text: 'شِدَادًا'),
          QaidaCell(text: 'شَرَابًا', color: _kBlue),
          QaidaCell(text: 'صَوَابًا'),
          QaidaCell(text: 'طَعَامٍ', color: _kBlue),
        ],
      ),

      // Row 4 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'عَذَابٌ'),
          QaidaCell(segments: [
            QaidaSegment('عَطَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءً', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('غُثَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءً')
          ]),
          QaidaCell(text: 'كِتَٰبًا', color: _kBlue),
          QaidaCell(text: 'كِرَامًا'),
          QaidaCell(text: 'لِبَاسًا', color: _kBlue),
        ],
      ),

      // Row 5 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لِسَانًا'),
          QaidaCell(text: 'مَـَٔابًا', color: _kBlue),
          QaidaCell(text: 'مَتَٰعًا'),
          QaidaCell(text: 'مُطَاعٍ', color: _kBlue),
          QaidaCell(text: 'مَعَاشًا'),
          QaidaCell(text: 'مَفَازًا', color: _kBlue),
        ],
      ),

      // Row 6 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مِهَٰدًا'),
          QaidaCell(text: 'نَبَاتًا', color: _kBlue),
          QaidaCell(text: 'وِفَاقًا'),
          QaidaCell(text: 'ثُبُورًا', color: _kBlue),
          QaidaCell(text: 'رَسُولٍ'),
          QaidaCell(text: 'شُهُودٌ', color: _kBlue),
        ],
      ),

      // Row 7 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قُعُودٌ'),
          QaidaCell(text: 'وُجُوهٌ', color: _kBlue),
          QaidaCell(text: 'أَثِيمٍ'),
          QaidaCell(text: 'أَلِيمٍ', color: _kBlue),
          QaidaCell(text: 'بَصِيرًا'),
          QaidaCell(text: 'خَبِيرًا', color: _kBlue),
        ],
      ),

      // Row 8 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'رَحِيقٍ'),
          QaidaCell(text: 'شَهِيدٌ', color: _kBlue),
          QaidaCell(text: 'عَظِيمٍ'),
          QaidaCell(text: 'قَرِيبًا', color: _kBlue),
          QaidaCell(text: 'كَرِيمٍ'),
          QaidaCell(text: 'مَجِيدٌ', color: _kBlue),
        ],
      ),

      // Row 9 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مُحِيطٌ'),
          QaidaCell(text: 'نَعِيمٍ', color: _kBlue),
          QaidaCell(text: 'يَتِيمًا'),
          QaidaCell(text: 'يَسِيرًا', color: _kBlue),
          QaidaCell(text: 'رُوَيۡدًا'),
          QaidaCell(text: 'قُرَيۡشٍ', color: _kBlue),
        ],
      ),

      // Row 10 (3 wide items: 2 flex each)
      QaidaRow(
        cells: [
          QaidaCell(text: 'عِيشَةٍ', flex: 2),
          QaidaCell(text: 'ٱلۡمَوۡءُۥدَةُ', color: _kBlue, flex: 2),
          QaidaCell(text: 'مَوۡضُوعَةٌ', flex: 2),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 13 : خاتمة تدريبات المَدّ واللِّين + الدَّرْسُ العَاشِر (السُّكُون)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 13,
    lessonNumber: 10,
    lessonTitleAr: 'الدَّرْسُ العَاشِرُ',
    lessonSubtitleAr: 'السُّكُونُ ( ۡ )',
    titleEn: 'Lesson 10: The Sukoon',
    description:
        'نطق الحرف الساكن مع ما قبله وقلقلة قطب جد وتفخيم الراء وترقيقها',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Top Section: 2 wide cells concluding Lesson 9 ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'مَوَازِينُهُۥ', flex: 1),
          QaidaCell(text: 'يَوۡمَئِذٍ', color: _kBlue, flex: 1),
        ],
      ),

      // ── Mid Section: Lesson 10 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ العَاشِرُ',
        headerLessonSubtitle: 'السُّكُونُ ( ۡ )',
      ),

      // ── Lesson 10 Sukoon Letters (6 columns per row) ──
      // Row 3 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('بۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('بۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('بۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('تۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('تۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('تۡ', _kGreen)]),
        ],
      ),

      // Row 4 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('ثۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('ثۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('ثۡ', _kBlue)]),
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('جۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('جۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('جۡ', _kGreen)]),
        ],
      ),

      // Row 5 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('حۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('حۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('حۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('خۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('خۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('خۡ', _kBlue)]),
        ],
      ),

      // Row 6 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('دۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('دۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('دۡ', _kGreen)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('ذۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('ذۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('ذۡ', _kBlue)]),
        ],
      ),

      // Row 7 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('رۡ', _kPurple)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('رۡ', _kPurple)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('رۡ', _kPurple)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('زۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('زۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('زۡ', _kBlue)]),
        ],
      ),

      // Row 8 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('سۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('سۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('سۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('شۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('شۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('شۡ', _kBlue)]),
        ],
      ),

      // Row 9 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('صۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('صۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('صۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('ضۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('ضۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('ضۡ', _kBlue)]),
        ],
      ),

      // Row 10 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(
              segments: [QaidaSegment('أَ'), QaidaSegment('طۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('إِ'), QaidaSegment('طۡ', _kGreen)]),
          QaidaCell(
              segments: [QaidaSegment('أُ'), QaidaSegment('طۡ', _kGreen)]),
          QaidaCell(segments: [QaidaSegment('أَ'), QaidaSegment('ظۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('إِ'), QaidaSegment('ظۡ', _kBlue)]),
          QaidaCell(segments: [QaidaSegment('أُ'), QaidaSegment('ظۡ', _kBlue)]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 14 : الدَّرْسُ الحَادِي عَشَر - تَدْرِيبَاتٌ عَلَى السُّكُون (جزء 1)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 14,
    lessonNumber: 11,
    lessonTitleAr: 'الدَّرْسُ الحَادِي عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى السُّكُونِ',
    titleEn: 'Lesson 11: Exercises on Sukoon (Part 1)',
    description:
        'تدريبات تطبيقية شاملة على نطق السكون مع القلقلة والهمزة والإخفاء',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الحَادِي عَشَرَ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى السُّكُونِ',
      ),

      // Row 2 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('أَ'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('تَ')
          ]),
          QaidaCell(text: 'إِهۡدِ', color: _kBlue),
          QaidaCell(text: 'بَعۡدُ'),
          QaidaCell(segments: [
            QaidaSegment('بَ', _kBlue),
            QaidaSegment('طۡ', _kGreen),
            QaidaSegment('شَ', _kBlue)
          ]),
          QaidaCell(text: 'سَعۡىُ'),
          QaidaCell(segments: [
            QaidaSegment('كُ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('تُ', _kBlue)
          ]),
        ],
      ),

      // Row 3 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لَسۡتَ'),
          QaidaCell(text: 'أَمۡرٍ', color: _kBlue),
          QaidaCell(text: 'بَرۡدًا'),
          QaidaCell(text: 'جَمۡعًا', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('حَ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('لٌ')
          ]),
          QaidaCell(text: 'خُسۡرٍ', color: _kBlue),
        ],
      ),

      // Row 4 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'خَلۡقًا'),
          QaidaCell(segments: [
            QaidaSegment('سَ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('حًا', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('سَ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('قًا')
          ]),
          QaidaCell(text: 'شَأۡنٌ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('صُ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('حًا')
          ]),
          QaidaCell(segments: [
            QaidaSegment('ضَ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('حًا', _kBlue)
          ]),
        ],
      ),

      // Row 5 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('عَ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('دًا')
          ]),
          QaidaCell(segments: [
            QaidaSegment('عَ', _kBlue),
            QaidaSegment('دۡ', _kGreen),
            QaidaSegment('نٍ', _kBlue)
          ]),
          QaidaCell(text: 'عَشۡرٍ'),
          QaidaCell(text: 'عَصۡفٍ', color: _kBlue),
          QaidaCell(text: 'غَرۡقًا'),
        ],
      ),

      // Row 6 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'غَلۡبًا'),
          QaidaCell(text: 'فَصۡلٌ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('قَ'),
            QaidaSegment('دۡ', _kGreen),
            QaidaSegment('حًا')
          ]),
          QaidaCell(text: 'قَضۡبًا', color: _kBlue),
          QaidaCell(text: 'كَأۡسًا'),
          QaidaCell(segments: [
            QaidaSegment('كَـ', _kBlue),
            QaidaSegment('دۡ', _kGreen),
            QaidaSegment('حًا', _kBlue)
          ]),
        ],
      ),

      // Row 7 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لَغۡوًا'),
          QaidaCell(text: 'مِسۡكٌ', color: _kBlue),
          QaidaCell(text: 'نَخۡلًا'),
          QaidaCell(text: 'نَشۡطًا', color: _kBlue),
          QaidaCell(text: 'نَفۡسٍ'),
          QaidaCell(segments: [
            QaidaSegment('نَ', _kBlue),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('عًا', _kBlue)
          ]),
        ],
      ),

      // Row 8 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يُسۡرًا'),
          QaidaCell(segments: [
            QaidaSegment('أَ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('قَىٰ', _kBlue)
          ]),
          QaidaCell(text: 'تَرۡضَىٰ'),
          QaidaCell(segments: [
            QaidaSegment('تَ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('سَىٰ', _kBlue)
          ]),
          QaidaCell(text: 'يَخۡشَىٰ'),
          QaidaCell(text: 'يَسۡعَىٰ', color: _kBlue),
        ],
      ),

      // Row 9 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَتۡلُواْ'),
          QaidaCell(segments: [
            QaidaSegment('يَ', _kBlue),
            QaidaSegment('دۡ', _kGreen),
            QaidaSegment('عُواْ', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('تَ'),
            QaidaSegment('جۡ', _kGreen),
            QaidaSegment('رِى')
          ]),
          QaidaCell(text: 'يَهۡدِى', color: _kBlue),
          QaidaCell(text: 'يُغۡنِى'),
        ],
      ),

      // Row 10 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَلۡقَتۡ'),
          QaidaCell(text: 'أَمۡهِلۡ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('إِ'),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('رَأۡ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('فَارۡ', _kBlue),
            QaidaSegment('غَبۡ', _kGreen)
          ]),
          QaidaCell(segments: [
            QaidaSegment('فَا'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('صَ'),
            QaidaSegment('بۡ', _kGreen),
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 15 : الدَّرْسُ الحَادِي عَشَر - تَدْرِيبَاتٌ عَلَى السُّكُون (جزء 2)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 15,
    lessonNumber: 11,
    lessonTitleAr: 'الدَّرْسُ الحَادِي عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى السُّكُونِ (تابع)',
    titleEn: 'Lesson 11: Exercises on Sukoon (Part 2)',
    description: 'متابعة كلمات تدريبات السكون القرآنية',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // Row 1 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَانۡحَرۡ'),
          QaidaCell(text: 'أَخۡرَجَ', color: _kBlue),
          QaidaCell(text: 'أَرۡسَلَ'),
          QaidaCell(text: 'أَغۡطَشَ', color: _kBlue),
          QaidaCell(text: 'أَفۡلَحَ'),
        ],
      ),

      // Row 2 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَكۡرَمَ'),
          QaidaCell(text: 'أَلۡهَمَ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('أَ'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('شَرَ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('أَ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('قَضَ', _kBlue)
          ]),
          QaidaCell(text: 'دَمۡدَمَ'),
        ],
      ),

      // Row 3 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'عَسۡعَسَ'),
          QaidaCell(text: 'أَعۡبُدُ', color: _kBlue),
          QaidaCell(text: 'نَعۡبُدُ'),
          QaidaCell(text: 'يَخۡرُجُ', color: _kBlue),
          QaidaCell(text: 'يَحۡسَبُ'),
        ],
      ),

      // Row 4 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَشۡرَبُ'),
          QaidaCell(text: 'يَشۡهَدُ', color: _kBlue),
          QaidaCell(text: 'تَرۡهَقُ'),
          QaidaCell(text: 'تَعۡرِفُ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('أُ'),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('سِمُ')
          ]),
        ],
      ),

      // Row 5 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('يُ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('دِئُ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('يُ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('فَخُ', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('يُ'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('قَلِبُ')
          ]),
          QaidaCell(text: 'يُوَسۡوِسُ', color: _kBlue),
          QaidaCell(text: 'ثَقُلَتۡ'),
        ],
      ),

      // Row 6 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'حُشِرَتۡ'),
          QaidaCell(text: 'سُطِحَتۡ', color: _kBlue),
          QaidaCell(text: 'كُشِطَتۡ'),
          QaidaCell(text: 'نُشِرَتۡ', color: _kBlue),
        ],
      ),

      // Row 7 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'نُصِبَتۡ'),
          QaidaCell(text: 'أَثۡرَنَ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('وَسَ'),
            QaidaSegment('طۡ', _kGreen),
            QaidaSegment('نَ')
          ]),
          QaidaCell(text: 'فَرَغۡتَ', color: _kBlue),
          QaidaCell(text: 'تَأۡتُونَ'),
        ],
      ),

      // Row 8 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَسۡقُونَ'),
          QaidaCell(text: 'يَفۡعَلُونَ', color: _kBlue),
          QaidaCell(text: 'يَعۡمَلُونَ'),
          QaidaCell(text: 'يَعۡلَمُونَ', color: _kBlue),
        ],
      ),

      // Row 9 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَضۡحَكُونَ'),
          QaidaCell(text: 'يَكۡسِبُونَ', color: _kBlue),
          QaidaCell(text: 'يَدۡخُلُونَ'),
          QaidaCell(segments: [
            QaidaSegment('يَ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('ظُرُونَ', _kBlue)
          ]),
        ],
      ),

      // Row 10 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'تَعۡبُدُونَ'),
          QaidaCell(segments: [
            QaidaSegment('أَ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('عَمۡتَ', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('أَ'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('ذَرۡنَا')
          ]),
          QaidaCell(segments: [
            QaidaSegment('أَ', _kBlue),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('زَلۡنَا', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('خَلَ'),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('نَا')
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 16 : الدَّرْسُ الحَادِي عَشَر - تَدْرِيبَاتٌ عَلَى السُّكُون (جزء 3)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 16,
    lessonNumber: 11,
    lessonTitleAr: 'الدَّرْسُ الحَادِي عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى السُّكُونِ (خاتمة)',
    titleEn: 'Lesson 11: Exercises on Sukoon (Part 3)',
    description: 'خاتمة تدريبات السكون والعبارات القرآنية المركبة',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // Row 1 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'رَفَعۡنَا'),
          QaidaCell(text: 'وَضَعۡنَا', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('نُ'),
            QaidaSegment('طۡ', _kGreen),
            QaidaSegment('فَةٍ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('عِ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('رَةً', _kBlue)
          ]),
          QaidaCell(segments: [
            QaidaSegment('زَ'),
            QaidaSegment('جۡ', _kGreen),
            QaidaSegment('رَةٌ')
          ]),
        ],
      ),

      // Row 2 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'تَذۡكِرَةٌ'),
          QaidaCell(text: 'مُسۡفِرَةٌ', color: _kBlue),
          QaidaCell(text: 'مُؤۡصَدَةٌ'),
          QaidaCell(text: 'مَسۡغَبَةٍ', color: _kBlue),
        ],
      ),

      // Row 3 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('مَ'),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('رَبَةٍ')
          ]),
          QaidaCell(text: 'مَتۡرَبَةٍ', color: _kBlue),
          QaidaCell(text: 'تَضۡلِيلٍ'),
          QaidaCell(segments: [
            QaidaSegment('تَ', _kBlue),
            QaidaSegment('قۡ', _kGreen),
            QaidaSegment('وِيمٍ', _kBlue)
          ]),
          QaidaCell(text: 'تَكۡذِيبٍ'),
        ],
      ),

      // Row 4 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'تَسۡنِيمٍ'),
          QaidaCell(text: 'مِسۡكِينًا', color: _kBlue),
          QaidaCell(text: 'مَمۡنُونٍ'),
          QaidaCell(text: 'مَحۡفُوظٍ', color: _kBlue),
        ],
      ),

      // Row 5 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مَخۡتُومٍ'),
          QaidaCell(text: 'مَسۡرُورًا', color: _kBlue),
          QaidaCell(text: 'مَشۡهُودٍ'),
          QaidaCell(segments: [
            QaidaSegment('أَ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('وَابًا', _kBlue)
          ]),
        ],
      ),

      // Row 6 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مَصۡفُوفَةٍ'),
          QaidaCell(text: 'أَزۡوَاجًا', color: _kBlue),
          QaidaCell(text: 'أَشۡتَاتًا'),
          QaidaCell(segments: [
            QaidaSegment('إِ', _kBlue),
            QaidaSegment('طۡ', _kGreen),
            QaidaSegment('عَامٌ', _kBlue)
          ]),
          QaidaCell(text: 'أَعۡنَابًا'),
        ],
      ),

      // Row 7 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَفۡوَاجًا'),
          QaidaCell(text: 'أَلۡفَافًا', color: _kBlue),
          QaidaCell(text: 'قُرۡءَانٌ'),
          QaidaCell(text: 'ٱلۡحَمۡدُ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('وَٱلۡفَ'),
            QaidaSegment('جۡ', _kGreen),
            QaidaSegment('رِ')
          ]),
        ],
      ),

      // Row 8 (3 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَٱلۡفَتۡحُ'),
          QaidaCell(text: 'وَٱلۡعَصۡرِ', color: _kBlue),
          QaidaCell(text: 'مِنَ ٱلۡمُعۡصِرَاتِ'),
        ],
      ),

      // Row 9 (3 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مَعَ ٱلۡعُسۡرِ'),
          QaidaCell(text: 'مَا ٱلۡقَارِعَةُ', color: _kBlue),
          QaidaCell(text: 'وَإِذَا ٱلۡمَوۡءُۥدَةُ'),
        ],
      ),

      // Row 10 (2 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('يَ'),
            QaidaSegment('نۡ', _kRed),
            QaidaSegment('ظُرُ ٱلۡمَرۡءُ')
          ]),
          QaidaCell(segments: [
            QaidaSegment('كَٱلۡفَرَاشِ ٱلۡمَ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('ثُوثِ', _kBlue)
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 17 : خاتمة تدريبات السكون + الدَّرْسُ الثَّانِي عَشَر - الشَّدَّة
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 17,
    lessonNumber: 12,
    lessonTitleAr: 'الدَّرْسُ الثَّانِي عَشَرَ',
    lessonSubtitleAr: 'الشَّدَّةُ ( ّ )',
    titleEn: 'Lesson 12: The Shaddah',
    description:
        'خاتمة تدريبات السكون وبداية درس الشدة مع الحركات الثلاث والتنوين',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Section 1: Conclusion of Lesson 11 (Exercises on Sukoon) ──
      // Row 1 (2 wide boxes)
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('كَٱلۡعِهۡنِ ٱلۡمَ'),
              QaidaSegment('نۡ', _kRed),
              QaidaSegment('فُوشِ')
            ],
            flex: 1,
          ),
          QaidaCell(
            segments: [
              QaidaSegment('لَيۡلَةُ ٱلۡقَ', _kBlue),
              QaidaSegment('دۡ', _kGreen),
              QaidaSegment('رِ', _kBlue)
            ],
            flex: 1,
          ),
        ],
      ),

      // Row 2 (2 wide boxes)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَخۡرَجَتِ ٱلۡأَرۡضُ', flex: 1),
          QaidaCell(text: 'مِنۡ أَهۡلِ ٱلۡكِتَٰبِ', color: _kBlue, flex: 1),
        ],
      ),

      // Row 3 (2 wide boxes)
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('عِ'),
              QaidaSegment('نۡ', _kRed),
              QaidaSegment('دَ ذِى ٱلۡعَرۡشِ')
            ],
            flex: 1,
          ),
          QaidaCell(text: 'يَمۡنَعُونَ ٱلۡمَاعُونَ', color: _kBlue, flex: 1),
        ],
      ),

      // Row 4 (1 full-width box)
      QaidaRow(
        cells: [
          QaidaCell(
            text: 'وَهُوَ ٱلۡغَفُورُ ٱلۡوَدُودُ ذُو ٱلۡعَرۡشِ ٱلۡمَجِيدُ',
            flex: 1,
          ),
        ],
      ),

      // Row 5 (1 full-width box)
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('لَقَ', _kBlue),
              QaidaSegment('دۡ ', _kGreen),
              QaidaSegment('خَلَقۡنَا ', _kGreen),
              QaidaSegment('ٱلۡإِ', _kBlue),
              QaidaSegment('نۡ', _kRed),
              QaidaSegment('سَٰنَ ', _kBlue),
              QaidaSegment('فِىٓ ', _kRed),
              QaidaSegment('أَحۡسَنِ ', _kBlue),
              QaidaSegment('تَقۡوِيمٍ', _kGreen),
            ],
            flex: 1,
          ),
        ],
      ),

      // Row 6 (2 wide boxes)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَعۡطَيۡنَٰكَ ٱلۡكَوْثَرَ', flex: 1),
          QaidaCell(
            segments: [
              QaidaSegment('ءَ', _kBlue),
              QaidaSegment('آ', _kRed),
              QaidaSegment('لۡـَٰٔنَ', _kBlue)
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Section 2: Lesson 12 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الثَّانِي عَشَرَ',
        headerLessonSubtitle: 'الشَّـــــدَّةُ ( ّ )',
      ),

      // ── Lesson 12 Shaddah Letters (7 columns per row) ──
      // Row 8 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَبَّ'),
          QaidaCell(text: 'أَبِّ'),
          QaidaCell(text: 'أَبُّ'),
          QaidaCell(text: 'إِبَّ'),
          QaidaCell(text: 'إِبِّ'),
          QaidaCell(text: 'إِبُّ'),
          QaidaCell(text: 'أُبَّ'),
        ],
      ),

      // Row 9 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أُبِّ'),
          QaidaCell(text: 'أُبُّ'),
          QaidaCell(text: 'أَبًّا'),
          QaidaCell(text: 'أَبٍّ'),
          QaidaCell(text: 'أَبٌّ'),
          QaidaCell(text: 'إِبًّا'),
          QaidaCell(text: 'إِبٍّ'),
        ],
      ),

      // Row 10 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'إِبٌّ'),
          QaidaCell(text: 'أُبًّا'),
          QaidaCell(text: 'أُبٍّ'),
          QaidaCell(text: 'أُبٌّ'),
          QaidaCell(text: 'أَتَّ'),
          QaidaCell(text: 'أَتِّ'),
          QaidaCell(text: 'أَتُّ'),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 18 : خاتمة درس الشدة + الدَّرْسُ الثَّالِث عَشَر - تَدْرِيبَاتٌ عَلَى الشَّدَّة
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 18,
    lessonNumber: 13,
    lessonTitleAr: 'الدَّرْسُ الثَّالِثَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّة',
    titleEn: 'Lesson 13: Exercises on Shaddah (Part 1)',
    description:
        'متابعة حروف الشدة مع الحركات والتنوين وبداية التدريبات القرآنية',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Section 1: Conclusion of Lesson 12 Shaddah Letters (7 cols) ──
      // Row 1 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'إِتَّ'),
          QaidaCell(text: 'إِتِّ'),
          QaidaCell(text: 'إِتُّ'),
          QaidaCell(text: 'أُتَّ'),
          QaidaCell(text: 'أُتِّ'),
          QaidaCell(text: 'أُتُّ'),
          QaidaCell(text: 'أَتًّا'),
        ],
      ),

      // Row 2 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَتٍّ'),
          QaidaCell(text: 'أَتٌّ'),
          QaidaCell(text: 'إِتًّا'),
          QaidaCell(text: 'إِتٍّ'),
          QaidaCell(text: 'إِتٌّ'),
          QaidaCell(text: 'أُتًّا'),
          QaidaCell(text: 'أُتٍّ'),
        ],
      ),

      // Row 3 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أُتٌّ'),
          QaidaCell(text: 'أَثَّ'),
          QaidaCell(text: 'أَثِّ'),
          QaidaCell(text: 'أَثُّ'),
          QaidaCell(text: 'إِثَّ'),
          QaidaCell(text: 'إِثِّ'),
          QaidaCell(text: 'إِثُّ'),
        ],
      ),

      // Row 4 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أُثَّ'),
          QaidaCell(text: 'أُثِّ'),
          QaidaCell(text: 'أُثُّ'),
          QaidaCell(text: 'أَثًّا'),
          QaidaCell(text: 'أَثٍّ'),
          QaidaCell(text: 'أَثٌّ'),
          QaidaCell(text: 'إِثًّا'),
        ],
      ),

      // Row 5 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'إِثٍّ'),
          QaidaCell(text: 'إِثٌّ'),
          QaidaCell(text: 'أُثًّا'),
          QaidaCell(text: 'أُثٍّ'),
          QaidaCell(text: 'أُثٌّ'),
          QaidaCell(text: 'أَجَّ'),
          QaidaCell(text: 'أَجِّ'),
        ],
      ),

      // Row 6 (7 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَجُّ'),
          QaidaCell(text: 'إِجَّ'),
          QaidaCell(text: 'إِجِّ'),
          QaidaCell(text: 'إِجُّ'),
          QaidaCell(text: 'أُجَّ'),
          QaidaCell(text: 'أُجِّ'),
          QaidaCell(text: 'أُجُّ'),
        ],
      ),

      // Row 7 (7 items with Center/End Emblem)
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَجًّا'),
          QaidaCell(text: 'أَجٍّ'),
          QaidaCell(text: 'أَجٌّ'),
          QaidaCell(text: 'إِجًّا'),
          QaidaCell(text: 'إِجٍّ'),
          QaidaCell(text: 'إِجٌّ'),
          QaidaCell(text: '◆', color: _kGold),
        ],
      ),

      // ── Section 2: Lesson 13 Header Box ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الثَّالِثَ عَشَرَ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ',
      ),

      // ── Lesson 13 Words (Rows 9 & 10) ──
      // Row 9 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'بَرَّزَ'),
          QaidaCell(text: 'حُصِّلَ', color: _kBlue),
          QaidaCell(text: 'صَدَّقَ'),
          QaidaCell(text: 'عَدَّدَ', color: _kBlue),
          QaidaCell(text: 'قَدَّرَ'),
        ],
      ),

      // Row 10 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'كَذَّبَ'),
          QaidaCell(text: 'نَعَّمَ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('يَ'),
            QaidaSegment('ظُنُّ', _kRed),
          ]),
          QaidaCell(text: 'يَحُضُّ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('جَ'),
            QaidaSegment('نَّةٍ', _kRed),
          ]),
          QaidaCell(text: 'ذَرَّةٍ', color: _kBlue),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 19 : الدَّرْسُ الثَّالِث عَشَر - تَدْرِيبَاتٌ عَلَى الشَّدَّة (جزء 2)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 19,
    lessonNumber: 13,
    lessonTitleAr: 'الدَّرْسُ الثَّالِثَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّة (تابع)',
    titleEn: 'Lesson 13: Exercises on Shaddah (Part 2)',
    description: 'متابعة تدريبات الشدة والتنوين والمد المتصل والمنفصل',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // Row 1 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قُوَّةٍ'),
          QaidaCell(text: 'كَرَّةً', color: _kBlue),
          QaidaCell(text: 'سُعِّرَتۡ'),
          QaidaCell(text: 'قُدِّمَتۡ', color: _kBlue),
          QaidaCell(text: 'كُذِّبَتۡ'),
        ],
      ),

      // Row 2 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'زُوِّجَتۡ'),
          QaidaCell(text: 'سُجِّرَتۡ', color: _kBlue),
          QaidaCell(text: 'فُجِّرَتۡ'),
          QaidaCell(text: 'سُيِّرَتۡ', color: _kBlue),
          QaidaCell(text: 'عُطِّلَتۡ'),
        ],
      ),

      // Row 3 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'كُوِّرَتۡ'),
          QaidaCell(text: 'تَطَّلِعُ', color: _kBlue),
          QaidaCell(text: 'تُحَدِّثُ'),
          QaidaCell(text: 'نُيَسِّرُهُ', color: _kBlue),
          QaidaCell(text: 'هُمُ ٱلۡبَيِّنَةُ'),
        ],
      ),

      // Row 4 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'قَيِّمَةٌ'),
          QaidaCell(text: 'عَشِيَّةً', color: _kBlue),
          QaidaCell(text: 'مُذَكِّرٌ'),
          QaidaCell(text: 'أَيَّانَ', color: _kBlue),
          QaidaCell(text: 'إِيَّاكَ'),
        ],
      ),

      // Row 5 (6 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'لِلَّهِ'),
          QaidaCell(text: 'تَجَلَّىٰ', color: _kBlue),
          QaidaCell(text: 'تَصَدَّىٰ'),
          QaidaCell(text: 'تَزَكَّىٰ', color: _kBlue),
          QaidaCell(text: 'تَوَلَّىٰ'),
          QaidaCell(text: 'تَوَّابًا', color: _kBlue),
        ],
      ),

      // Row 6 (5 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'ثَجَّاجًا'),
          QaidaCell(text: 'غَسَّاقًا', color: _kBlue),
          QaidaCell(text: 'فَعَّالٌ'),
          QaidaCell(text: 'كِذَّابًا', color: _kBlue),
          QaidaCell(text: 'وَهَّاجًا'),
        ],
      ),

      // Row 7 (4 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'مُمَدَّدَةٍ'),
          QaidaCell(text: 'مُكَرَّمَةٍ', color: _kBlue),
          QaidaCell(text: 'مُطَهَّرَةٍ'),
          QaidaCell(segments: [
            QaidaSegment('وَٱلسَّ', _kBlue),
            QaidaSegment('مَآ', _kRed),
            QaidaSegment('ءِ', _kBlue),
          ]),
        ],
      ),

      // Row 8 (3 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('وَٱلتَّ'),
            QaidaSegment('رَآ', _kRed),
            QaidaSegment('ئِبِ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('وَٱل', _kBlue),
            QaidaSegment('نَّٰ', _kRed),
            QaidaSegment('شِطَٰتِ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('وَٱل'),
            QaidaSegment('نَّٰ', _kRed),
            QaidaSegment('زِعَٰتِ'),
          ]),
        ],
      ),

      // Row 9 (3 items)
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَٱلسَّٰبِحَٰتِ'),
          QaidaCell(text: 'فَٱلسَّٰبِقَٰتِ', color: _kBlue),
          QaidaCell(text: 'فَٱلۡمُدَبِّرَٰتِ'),
        ],
      ),

      // Row 10 (3 items)
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('تُ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('لَى ٱلسَّ'),
            QaidaSegment('رَآ', _kRed),
            QaidaSegment('ئِرُ'),
          ]),
          QaidaCell(text: 'فَمَهِّلِ ٱلۡكَٰفِرِينَ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('بِٱلۡخُ'),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment('سِ'),
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 20 : الدَّرْسُ الرَّابِعَ عَشَرَ + الدَّرْسُ الخَامِسَ عَشَرَ (بداية)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 20,
    lessonNumber: 14,
    lessonTitleAr: 'الدَّرْسُ الرَّابِعَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُونِ',
    titleEn: 'Lesson 14: Exercises on Shaddah and Sukoon',
    description:
        'تَدْرِيبَاتٌ قُرْآنِيَّةٌ عَلَى اجْتِمَاعِ الشَّدَّةِ مَعَ السُّكُونِ',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Row 1 (2 wide items - Conclusion of Lesson 13) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('ٱلۡجَوَارِ ٱلۡكُ'),
              QaidaSegment('نَّ', _kRed),
              QaidaSegment('سِ'),
            ],
            flex: 1,
          ),
          QaidaCell(
            text: 'ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ',
            color: _kBlue,
            flex: 1,
          ),
        ],
      ),

      // ── Row 2 (Dual Header Box - Lesson 14) ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الرَّابِعَ عَشَرَ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُونِ',
      ),

      // ── Row 3 (6 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'مَرُّوا'),
          QaidaCell(text: 'رَبِّى', color: _kBlue),
          QaidaCell(text: 'مُدَّتۡ'),
          QaidaCell(text: 'حُقَّتۡ', color: _kBlue),
          QaidaCell(text: 'خَفَّتۡ'),
          QaidaCell(text: 'تَبَّتۡ', color: _kBlue),
        ],
      ),

      // ── Row 4 (4 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'تَخَلَّتۡ'),
          QaidaCell(text: 'قُدِّمَتۡ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('وَٱلصُّ'),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('حِ'),
          ]),
          QaidaCell(text: 'وَٱلشَّمۡسِ', color: _kBlue),
        ],
      ),

      // ── Row 5 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَٱلشَّفۡعِ'),
          QaidaCell(segments: [
            QaidaSegment('بِٱلصَّ', _kBlue),
            QaidaSegment('بۡ', _kGreen),
            QaidaSegment('رِ', _kBlue),
          ]),
          QaidaCell(text: 'وَٱلَّيۡلِ', color: _kBlue),
        ],
      ),

      // ── Row 6 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَٱلتِّينِ وَٱلزَّيۡتُونِ'),
          QaidaCell(text: 'سِجِّيلٍ', color: _kBlue),
          QaidaCell(text: 'سِجِّينٌ'),
        ],
      ),

      // ── Row 7 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('مُ'),
            QaidaSegment('ن', _kRed),
            QaidaSegment('فَكِّينَ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('فَإِ', _kBlue),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment(' ٱلۡجَ', _kBlue),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment('ةَ', _kBlue),
          ]),
          QaidaCell(text: 'لِحُبِّ ٱلۡخَيۡرِ'),
        ],
      ),

      // ── Row 8 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('إِذَا ٱلسَّ'),
              QaidaSegment('مَآ', _kRed),
              QaidaSegment('ءُ ٱ'),
              QaidaSegment('ن', _kRed),
              QaidaSegment('شَقَّتۡ'),
            ],
            flex: 1,
          ),
          QaidaCell(
            segments: [
              QaidaSegment('مَا ٱلطَّارِقُ ٱل', _kBlue),
              QaidaSegment('نَّ', _kRed),
              QaidaSegment('جۡ', _kGreen),
              QaidaSegment('مُ', _kBlue),
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Row 9 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'ٱلثَّاقِبُ', color: _kBlue, flex: 1),
          QaidaCell(
            segments: [
              QaidaSegment('مِ'),
              QaidaSegment('ن', _kRed),
              QaidaSegment(' شَرِّ ٱلۡوَسۡوَاسِ ٱلۡخَ'),
              QaidaSegment('نَّ', _kRed),
              QaidaSegment('اسِ'),
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Row 10 (Inline Header for Lesson 15 + 2 cells) ──
      QaidaRow(
        inlineHeader: true,
        inlineHeaderStacked: true,
        headerLessonTitle: 'الدَّرْسُ الخَامِسَ عَشَرَ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى الشَّدَّتَيْنِ فِي كَلِمَةٍ',
        inlineHeaderFlex: 2,
        cells: [
          QaidaCell(text: 'يَزَّكَّىٰ', color: _kBlue, flex: 1),
          QaidaCell(text: 'يَذَّكَّرُ', flex: 1),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 21 : الدَّرْسُ السَّادِسَ عَشَرَ + الدَّرْسُ الأَخِيرُ
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 21,
    lessonNumber: 16,
    lessonTitleAr: 'الدَّرْسُ السَّادِسَ عَشَرَ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُونِ مَعَ المَدِّ',
    titleEn: 'Lesson 16: Exercises on Shaddah and Sukoon with Madd',
    description:
        'تَدْرِيبَاتٌ عَلَى المَدِّ اللَّازِمِ الكَلِمِيِّ المُثَقَّلِ مَعَ الشَّدَّةِ',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Row 1 (4 items - Conclusion of Lesson 15) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'ٱلۡمُدَّثِّرُ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('ٱلۡمُزَّ'),
            QaidaSegment('مِّ', _kRed),
            QaidaSegment('لُ'),
          ]),
          QaidaCell(text: 'عِلِّيِّينَ', color: _kBlue),
          QaidaCell(text: 'عِلِّيُّونَ'),
        ],
      ),

      // ── Row 2 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('إِ', _kBlue),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment(' ٱلَّذِينَ', _kBlue),
          ]),
          QaidaCell(text: 'إِلَّا ٱلَّذِينَ'),
          QaidaCell(segments: [
            QaidaSegment('مِّ', _kRed),
            QaidaSegment('ن', _kBlue),
          ]),
        ],
      ),

      // ── Row 3 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('شَرِّ ٱل', _kBlue),
              QaidaSegment('نَّ', _kRed),
              QaidaSegment('فَّٰثَٰتِ', _kBlue),
            ],
            flex: 1,
          ),
          QaidaCell(text: 'فَعَّالٌ لِّمَا يُرِيدُ', flex: 1),
        ],
      ),

      // ── Row 4 (Dual Header Box - Lesson 16) ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ السَّادِسَ عَشَرَ',
        headerLessonSubtitle:
            'تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُونِ مَعَ المَدِّ',
      ),

      // ── Row 5 (4 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ضَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('لًّا'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('دَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('بَّةٍ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('حَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('جَّكَ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('حَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('جُّوكَ', _kBlue),
          ]),
        ],
      ),

      // ── Row 6 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('لَضَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('لُّونَ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('وَلَا ٱلضَّ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('لِّينَ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('أَتُ'),
            QaidaSegment('حَآ', _kRed),
            QaidaSegment('جُّوٓ'),
            QaidaSegment('نِّ', _kRed),
            QaidaSegment('ى'),
          ]),
        ],
      ),

      // ── Row 7 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('وَلَا تَ', _kBlue),
            QaidaSegment('حَآ', _kRed),
            QaidaSegment('ضُّونَ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('وَٱلصَّ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('فَّٰتِ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('جَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءَتۡ', _kBlue),
          ]),
        ],
      ),

      // ── Row 8 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('ٱلصَّ', _kBlue),
              QaidaSegment('آ', _kRed),
              QaidaSegment('خَّةُ', _kBlue),
            ],
            flex: 1,
          ),
          QaidaCell(
            segments: [
              QaidaSegment('فَإِذَا جَ'),
              QaidaSegment('آ', _kRed),
              QaidaSegment('ءَتِ ٱلطَّ'),
              QaidaSegment('آ', _kRed),
              QaidaSegment('مَّةُ ٱلۡكُ'),
              QaidaSegment('بۡ', _kGreen),
              QaidaSegment('رَىٰ'),
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Row 9 (Dual Header Box - Lesson 17) ──
      QaidaRow(
        isHeader: true,
        headerLessonTitle: 'الدَّرْسُ الأَخِيرُ',
        headerLessonSubtitle: 'تَدْرِيبَاتٌ عَلَى مَا سَبَقَ',
      ),

      // ── Row 10 (4 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('جَزَ', _kBlue),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءً', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('ٱلۡمَلَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ئِكَةُ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('إِ', _kBlue),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment('آ ', _kRed),
            QaidaSegment('أَعۡطَيۡنَٰكَ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('إِلَيۡ'),
            QaidaSegment('نَآ', _kRed),
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 22 : الدَّرْسُ الأَخِيرُ - تَدْرِيبَاتٌ عَلَى مَا سَبَقَ (تابع 1)
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 22,
    lessonNumber: 17,
    lessonTitleAr: 'الدَّرْسُ الأَخِيرُ',
    lessonSubtitleAr: 'تَدْرِيبَاتٌ عَلَى مَا سَبَقَ (تابع)',
    titleEn: 'Lesson 17: General Exercises on Tajweed Rules (Part 1)',
    description: 'تَدْرِيبَاتٌ شَامِلَةٌ عَلَى الإِدْغَامِ وَالإِخْفَاءِ وَالإِقْلابِ',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Row 1 (4 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'إِيَابَهُمۡ'),
          QaidaCell(segments: [
            QaidaSegment('خَيۡ', _kBlue),
            QaidaSegment('رٗا', _kRed),
            QaidaSegment(' يَرَهُۥ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('شَرّ'),
            QaidaSegment('ٗا', _kRed),
            QaidaSegment(' يَرَهُۥ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('مِي', _kBlue),
            QaidaSegment('قَٰتٗا', _kRed),
          ]),
        ],
      ),

      // ── Row 2 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'يَوۡمَ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('فَمَ'),
            QaidaSegment('ن ', _kRed),
            QaidaSegment('يَعۡمَلۡ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('يَوۡمَئِ', _kBlue),
            QaidaSegment('ذٍ ', _kRed),
            QaidaSegment('يَصۡدُرُ', _kBlue),
          ]),
        ],
      ),

      // ── Row 3 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'ٱلنَّاسُ', color: _kBlue),
          QaidaCell(text: 'مِن رَّبِّكَ'),
          QaidaCell(segments: [
            QaidaSegment('رَّسُو', _kBlue),
            QaidaSegment('لٌ ', _kRed),
            QaidaSegment('مِّنَ ٱللَّهِ', _kBlue),
          ]),
        ],
      ),

      // ── Row 4 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('صُحُفٗا '),
              QaidaSegment('مُّطَهَّرَةٗ'),
            ],
            flex: 1,
          ),
          QaidaCell(
            text: 'صَفّٗا لَّا يَتَكَلَّمُونَ',
            color: _kBlue,
            flex: 1,
          ),
        ],
      ),

      // ── Row 5 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(
            segments: [
              QaidaSegment('قُلُو'),
              QaidaSegment('بٌ ', _kRed),
              QaidaSegment('يَوۡمَئِ'),
              QaidaSegment('ذٍ ', _kRed),
              QaidaSegment('وَاجِفَةٌ أَبۡصَٰرُهَا'),
            ],
            flex: 1,
          ),
          QaidaCell(
            segments: [
              QaidaSegment('سِرَا', _kBlue),
              QaidaSegment('جٗا', _kRed),
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Row 6 (4 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَهَّاجٗا', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('وَأَ'),
            QaidaSegment('ن', _kRed),
            QaidaSegment('زَلۡنَا'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('أَكۡلٗا ', _kBlue),
            QaidaSegment('لَّ', _kBlue),
            QaidaSegment('مّٗا', _kRed),
          ]),
          QaidaCell(text: 'وَتُحِبُّونَ', color: _kBlue),
        ],
      ),

      // ── Row 7 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('ٱلۡمَالَ حُبّٗا ', _kBlue),
            QaidaSegment('جَ', _kBlue),
            QaidaSegment('مّٗا', _kRed),
          ]),
          QaidaCell(segments: [
            QaidaSegment('غُثَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءً أَحۡوَىٰ'),
          ]),
          QaidaCell(text: 'مُعۡتَدٍ', color: _kBlue),
        ],
      ),

      // ── Row 8 (2 wide items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'أَثِيمٍ إِذَا تُتۡلَىٰ', color: _kBlue, flex: 1),
          QaidaCell(
            segments: [
              QaidaSegment('نَارًا حَامِيَةً تُسۡقَىٰ مِنۡ'),
            ],
            flex: 1,
          ),
        ],
      ),

      // ── Row 9 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'عَيۡنٍ ءَانِيَةٍ'),
          QaidaCell(segments: [
            QaidaSegment('مَّ', _kRed),
            QaidaSegment('ن بَخِلَ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('لَيُ'),
            QaidaSegment('نۢ', _kRed),
            QaidaSegment('بَذَ'),
            QaidaSegment('نَّ', _kRed),
          ]),
        ],
      ),

      // ── Row 10 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('مِ', _kBlue),
            QaidaSegment('نۢ', _kRed),
            QaidaSegment(' بَعۡدِ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('مِ'),
            QaidaSegment('نۢ', _kRed),
            QaidaSegment(' بَيۡنِ ٱلصُّلۡبِ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('لَنَسۡفَ', _kBlue),
            QaidaSegment('عَۢا', _kRed),
          ]),
        ],
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 23 : خاتمة القاعدة النورانية + جدول رسم المصحف العثماني
  // ═══════════════════════════════════════════════════════════════════════════
  QaidaPage(
    pageNumber: 23,
    lessonNumber: 17,
    lessonTitleAr: 'الدَّرْسُ الأَخِيرُ',
    lessonSubtitleAr: 'خَاتِمَةُ القَاعِدَةِ النُّورَانِيَّةِ وَرَسْمُ المُصْحَفِ',
    titleEn: 'Lesson 17: Conclusion & Uthmani Script Reference Table',
    description: 'خَاتِمَةُ التَّدْرِيبَاتِ وَجَدْوَلُ الكَلِمَاتِ القُرْآنِيَّةِ بِرَسْمِ المُصْحَفِ',
    showBismillah: false,
    showHeader: false,
    customRows: [
      // ── Row 1 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(segments: [
            QaidaSegment('بِٱل', _kBlue),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment('اصِيَةِ', _kBlue),
          ]),
          QaidaCell(segments: [
            QaidaSegment('بِذَ'),
            QaidaSegment('نۢ', _kRed),
            QaidaSegment('بِهِمۡ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('مُّطَهَّرَةٍۭ', _kBlue),
            QaidaSegment(' بِأَيۡدِى', _kBlue),
          ]),
        ],
      ),

      // ── Row 2 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'سَفَرَةٍ كِرَامٍۭ بَرَرَةٍ'),
          QaidaCell(text: 'هُمۡ فِيهَا'),
          QaidaCell(text: 'لَكُمۡ دِينُكُمۡ', color: _kBlue),
        ],
      ),

      // ── Row 3 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'وَلِىَ دِينِ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('إِ'),
            QaidaSegment('نَّ', _kRed),
            QaidaSegment(' رَبَّهُم '),
            QaidaSegment('بِ', _kRed),
            QaidaSegment('هِمۡ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('تَرۡ', _kBlue),
            QaidaSegment('مِي', _kRed),
            QaidaSegment('هِم', _kBlue),
          ]),
        ],
      ),

      // ── Row 4 (3 items) ──
      QaidaRow(
        cells: [
          QaidaCell(text: 'بِحِجَارَةٍ', color: _kBlue),
          QaidaCell(segments: [
            QaidaSegment('لَّهُم '),
            QaidaSegment('مَّا', _kRed),
            QaidaSegment('يَشَ'),
            QaidaSegment('آ', _kRed),
            QaidaSegment('ءُونَ'),
          ]),
          QaidaCell(segments: [
            QaidaSegment('مِّ', _kRed),
            QaidaSegment('مۡ ', _kBlue),
            QaidaSegment('ٱللَّ'),
            QaidaSegment('هُمَّ', _kRed),
          ]),
        ],
      ),

      // ── Row 5: Calligraphic Conclusion & Table (Flex: 6) ──
      QaidaRow(
        inlineHeaderFlex: 6,
        customWidget: _UthmaniReferenceWidget(),
      ),
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
    _currentPageIndex =
        widget.initialPageIndex.clamp(0, _kQaidaPages.length - 1);
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
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFF3EDE0)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC5A059)
                                      .withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${page.pageNumber}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF8D6E63)),
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
                                      color: isSelected
                                          ? textColor
                                          : (isDark
                                              ? AppColors.textPrimary
                                              : const Color(0xFF4A3B32)),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
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
                      color: isDark
                          ? AppColors.textSecondary
                          : const Color(0xFF8D6E63),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  if (cell.phonetic != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141C18)
                          : const Color(0xFFFAF6EC),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFC5A059).withValues(alpha: 0.35),
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
    final topIconColor =
        isDark ? AppColors.textPrimary : const Color(0xFF5D4037);

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
    final pageBg = isDark ? const Color(0xFF161E1A) : const Color(0xFFFAF7EE);
    const borderColor = Color(0xFFC5A059);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: pageBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _IslamicPageBorderPainter(
            borderColor: borderColor,
            isDark: isDark,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 9, 9, 7),
            child: Column(
              children: [
                // 1. Top Bismillah (Optional per page)
                if (page.showBismillah) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 34 * _fontSizeScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFFE8DFC8)
                              : const Color(0xFF2C241E),
                          height: 1.2,
                        ),
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
                  const SizedBox(height: 6),
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
  // CUSTOM ROWS PAGE BUILDER (For Multi-Section Pages like Page 4, 6, 7, 8, 11, 13)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCustomRowsPage(QaidaPage page, bool isDark) {
    final rows = page.customRows!;

    // Contextual lesson title for split pages before headers
    String activeLessonTitle =
        '${page.lessonTitleAr}: ${page.lessonSubtitleAr}';
    if (page.pageNumber == 8) {
      activeLessonTitle =
          'الدَّرْسُ السَّادِسُ: تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِينِ';
    } else if (page.pageNumber == 11) {
      activeLessonTitle = 'الدَّرْسُ الثَّامِنُ: حُرُوفُ المَدِّ وَاللِّينِ';
    } else if (page.pageNumber == 13) {
      activeLessonTitle =
          'الدَّرْسُ التَّاسِعُ: تَدْرِيبَاتٌ عَلَى التَّنْوِينِ وَأَحْرُفِ المَدِّ وَاللِّين';
    } else if (page.pageNumber == 17) {
      activeLessonTitle =
          'الدَّرْسُ الحَادِي عَشَرَ: تَدْرِيبَاتٌ عَلَى السُّكُونِ';
    } else if (page.pageNumber == 18) {
      activeLessonTitle = 'الدَّرْسُ الثَّانِي عَشَرَ: الشَّدَّةُ ( ّ )';
    } else if (page.pageNumber == 20) {
      activeLessonTitle =
          'الدَّرْسُ الثَّالِثَ عَشَرَ: تَدْرِيبَاتٌ عَلَى الشَّدَّة';
    } else if (page.pageNumber == 21) {
      activeLessonTitle =
          'الدَّرْسُ الخَامِسَ عَشَرَ: تَدْرِيبَاتٌ عَلَى الشَّدَّتَيْنِ فِي كَلِمَةٍ';
    } else if (page.pageNumber == 22 || page.pageNumber == 23) {
      activeLessonTitle =
          'الدَّرْسُ الأَخِيرُ: تَدْرِيبَاتٌ عَلَى مَا سَبَقَ';
    }

    final List<Widget> rowWidgets = [];
    for (final r in rows) {
      if (r.isHeader) {
        if (r.headerLessonTitle != null && r.headerLessonSubtitle != null) {
          activeLessonTitle =
              '${r.headerLessonTitle}: ${r.headerLessonSubtitle}';
        }
        rowWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: _buildDualHeaderBox(
              r.headerLessonTitle ?? '',
              r.headerLessonSubtitle ?? '',
              isDark,
            ),
          ),
        );
        continue;
      }

      if (r.inlineHeader) {
        if (r.headerLessonTitle != null && r.headerLessonSubtitle != null) {
          activeLessonTitle =
              '${r.headerLessonTitle}: ${r.headerLessonSubtitle}';
        }
        final currentLesson = activeLessonTitle;
        rowWidgets.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: Row(
                children: [
                  Expanded(
                    flex: r.inlineHeaderFlex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: _buildDualHeaderBox(
                        r.headerLessonTitle ?? '',
                        r.headerLessonSubtitle ?? '',
                        isDark,
                        isInline: true,
                        isStacked: r.inlineHeaderStacked,
                      ),
                    ),
                  ),
                  ...?r.cells?.map((c) => Expanded(
                        flex: c.flex,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: _buildAuthenticCell(
                            c,
                            page,
                            isDark,
                            customLessonTitle: currentLesson,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
        continue;
      }

      if (r.customWidget != null) {
        rowWidgets.add(
          Expanded(
            flex: r.inlineHeaderFlex,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: r.customWidget!,
            ),
          ),
        );
        continue;
      }

      final currentLesson = activeLessonTitle;
      if (r.isCentered) {
        rowWidgets.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  ...?r.cells?.map((c) => Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: _buildAuthenticCell(
                            c,
                            page,
                            isDark,
                            customLessonTitle: currentLesson,
                          ),
                        ),
                      )),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
        continue;
      }

      rowWidgets.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              children: r.cells!.map((c) {
                return Expanded(
                  flex: c.flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: _buildAuthenticCell(
                      c,
                      page,
                      isDark,
                      customLessonTitle: currentLesson,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: rowWidgets),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DUAL COMPARTMENT LESSON HEADER BOX (Original Noorania Book Style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDualHeaderBox(
    String titleAr,
    String subtitleAr,
    bool isDark, {
    bool isInline = false,
    bool isStacked = false,
  }) {
    const borderColor = Color(0xFFC8A86B);
    final headerBg = isDark ? const Color(0xFF1E2824) : const Color(0xFFFAF6EC);

    final double titleFontSize = isStacked
        ? 18.0 * _fontSizeScale
        : (isInline ? 17.0 * _fontSizeScale : 22.0 * _fontSizeScale);
    final double subtitleFontSize = isStacked
        ? 14.5 * _fontSizeScale
        : (isInline ? 14.5 * _fontSizeScale : 18.5 * _fontSizeScale);
    final EdgeInsets boxPadding = isInline
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 7);

    if (isStacked) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: borderColor.withValues(alpha: isDark ? 0.7 : 0.9),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    titleAr,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                      color: isDark
                          ? const Color(0xFFEF5350)
                          : const Color(0xFFB71C1C),
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitleAr,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize,
                      color: isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF946F17),
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: BorderRadius.circular(isInline ? 6 : 9),
          border: Border.all(
            color: borderColor.withValues(alpha: isDark ? 0.7 : 0.9),
            width: isInline ? 1.0 : 1.3,
          ),
          boxShadow: isInline
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Right Part in RTL (First child): Lesson Title / Number (e.g. "الدَّرْسُ الأَوَّل")
              Expanded(
                flex: isInline ? 1 : 2,
                child: Padding(
                  padding: boxPadding,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        titleAr,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: isInline ? 2 : 1,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          color: isDark
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFB71C1C),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Vertical Separator
              VerticalDivider(
                color: borderColor.withValues(alpha: isDark ? 0.7 : 0.9),
                thickness: isInline ? 1.0 : 1.3,
                width: isInline ? 1.0 : 1.3,
              ),

              // Left Part in RTL (Second child): Lesson Subtitle / Name (e.g. "حُرُوفُ الهِجَاءِ المُفْرَدَة")
              Expanded(
                flex: isInline ? 1 : 3,
                child: Padding(
                  padding: boxPadding,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitleAr,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleFontSize,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF946F17),
                          height: 1.15,
                        ),
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
    final defaultColor =
        isDark ? const Color(0xFFF2EADC) : const Color(0xFF1F1B18);

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
                height: 1.05,
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
        height: 1.05,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTHENTIC CELL (Clean Rounded Border, Large Prominent Letter, Delicate Outline)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAuthenticCell(
    QaidaCell cell,
    QaidaPage page,
    bool isDark, {
    String? customLessonTitle,
  }) {
    final isSelected = _selectedItem == cell.fullText;
    final cellBg = isDark
        ? (isSelected ? const Color(0xFF23362C) : const Color(0xFF1E2824))
        : (isSelected ? const Color(0xFFFBF4E2) : const Color(0xFFFFFFFF));

    final borderColor = isSelected
        ? const Color(0xFFB71C1C)
        : const Color(0xFFD4B982).withValues(alpha: isDark ? 0.45 : 0.75);

    // Large base font size so letters fill the cell with prominence
    double baseFontSize = 32;
    if (page.customRows != null) {
      baseFontSize = 30;
    } else if (page.crossAxisCount >= 6) {
      baseFontSize = 28;
    } else if (page.crossAxisCount == 5) {
      baseFontSize = 32;
    } else if (page.crossAxisCount == 4) {
      baseFontSize = 34;
    } else if (page.crossAxisCount <= 3) {
      baseFontSize = 36;
    }

    final double effectiveFontSize = baseFontSize * _fontSizeScale;

    return LiquidPressable(
      onTap: () => _showItemDetail(
        cell,
        customLessonTitle ?? '${page.lessonTitleAr}: ${page.lessonSubtitleAr}',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Small Red Phonetic / Pronunciation Name in Corner (e.g. 'أَلِف', 'با', 'تا')
            if (cell.phonetic != null)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  cell.phonetic!,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: (10.0 * _fontSizeScale).clamp(8.0, 13.0),
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFEF9A9A)
                        : const Color(0xFFC62828),
                    height: 1.0,
                  ),
                ),
              ),

            // Embedded Corner Badge Tag (e.g. 'المَدّ' in red or 'اللِّين' in blue)
            if (cell.cornerBadge != null)
              Positioned(
                right: 2,
                top: 2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0, vertical: 1.0),
                  decoration: BoxDecoration(
                    color: cell.cornerBadgeBg ?? const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        cell.cornerBadge!,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Main Central Letter (Fitted to scale down dynamically and fill the box)
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 2,
                  right: cell.cornerBadge != null ? 14.0 : 2.0,
                  top: 1,
                  bottom: 1,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildCellContent(cell, isDark, effectiveFontSize),
                ),
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
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2824) : const Color(0xFFFAF7EE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFC5A059).withValues(alpha: 0.75),
            width: 1.0,
          ),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF9E7D23),
            fontWeight: FontWeight.bold,
            fontSize: 13 * _fontSizeScale,
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
            icon: const Icon(
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
              _isPlaying
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
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
            icon: const Icon(
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
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat_rounded, size: 18, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    ': $_repeatCount',
                    style: const TextStyle(
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
    const double padOuter = 3.0;
    const double padInner = 6.5;

    final outerPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.70 : 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padOuter,
        padOuter,
        size.width - padOuter * 2,
        size.height - padOuter * 2,
      ),
      const Radius.circular(12),
    );

    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padInner,
        padInner,
        size.width - padInner * 2,
        size.height - padInner * 2,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(outerRRect, outerPaint);
    canvas.drawRRect(innerRRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _IslamicPageBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.isDark != isDark;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UTHMANI SCRIPT REFERENCE TABLE WIDGET (Page 23 Conclusion)
// ═════════════════════════════════════════════════════════════════════════════
class _UthmaniReferenceWidget extends StatelessWidget {
  const _UthmaniReferenceWidget();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tableBorderColor = Color(0xFFC5A059);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // 1. Calligraphic Conclusion "تَمَّتۡ"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'تَمَّتۡ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFEF5350) : const Color(0xFFB71C1C),
                  height: 1.1,
                ),
              ),
            ],
          ),

          // 2. Subtitle Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'الكَلِمَاتُ القُرْآنِيَّةُ الَّتِي تُكْتَبُ وِفْقَ رَسْمِ المُصْحَفِ بَيْنَمَا تُقْرَأُ بِطَرِيقَةٍ مُخْتَلِفَةٍ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE8DFC8) : const Color(0xFF3E2723),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),

          // 3. Comparison Table (Side-by-side Dual Table)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2824) : const Color(0xFFFAF6EC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: tableBorderColor.withValues(alpha: isDark ? 0.7 : 0.9),
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Row(
                  children: [
                    // Right Table (Entries 1 to 8 in RTL)
                    Expanded(
                      child: _buildSubTable(
                        isDark: isDark,
                        startIdx: 1,
                        items: const [
                          ('أَنَا۟', 'أَنَا', 'في أي موضع'),
                          ('يَبۡصُۜطُ', 'يَبۡسُطُ', '٢٤٥ ، ٢'),
                          ('أَفَإِي۟ن', 'أَفَإِن', '١٤٤ ، ٣\n٣٤ ، ٢١'),
                          ('بَصۜۡطَةٗ', 'بَسۡطَةً', '٦٩ ، ٧'),
                          ('مَلَإِي۟هِ', 'مَلَئِهِ', 'في أي موضع'),
                          ('ثَمُودَا۟', 'ثَمُودَ', '٦٨،١١ / ٣٨،٢٥\n٥١،٥٣ / ٣٨،٢٩'),
                          ('لِتَتۡلُوَا۟', 'لِتَتۡلُوَ', '٣٠ ، ١٣'),
                          ('لَن نَّدۡعُوَا۟', 'لَن نَّدۡعُوَ', '١٤ ، ١٨'),
                        ],
                      ),
                    ),

                    // Center Divider
                    Container(
                      width: 1.0,
                      color: tableBorderColor.withValues(alpha: isDark ? 0.7 : 0.9),
                    ),

                    // Left Table (Entries 9 to 16 in RTL)
                    Expanded(
                      child: _buildSubTable(
                        isDark: isDark,
                        startIdx: 9,
                        items: const [
                          ('لَشَا۟ىۡءٍ', 'لِشَىۡءٍ', '٢٣ ، ١٨'),
                          ('لَّٰكِنَّا۟', 'لَٰكِنَّ', '٣٨ ، ١٨'),
                          ('لَأَا۟ذۡبَحَنَّهُۥ', 'لَأَذۡبَحَنَّهُ', '٢١ ، ٢٧'),
                          ('سَلَٰسِلَا۟', 'سَلَاسِلَ', '٤ ، ٧٦'),
                          ('قَوَارِيرَا۟', 'قَوَارِيرَ', '١٦ ، ٧٦'),
                          ('وَمَلَإِي۟هِمۡ', 'وَمَلَئِهِمۡ', '٨٣ ، ١٠'),
                          ('لِيَبۡلُوَا۟', 'لِيَبۡلُوَ', '٤ ، ٤٧'),
                          ('لِيَرۡبُوَا۟', 'لِيَرۡبُوَ', '٣٩ ، ٣٠'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTable({
    required bool isDark,
    required int startIdx,
    required List<(String, String, String)> items,
  }) {
    const tableBorderColor = Color(0xFFC5A059);
    final borderColor = tableBorderColor.withValues(alpha: isDark ? 0.4 : 0.5);

    return Column(
      children: [
        // Table Header
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C3930)
                : const Color(0xFFEDE0C8),
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              _buildHeaderCell('رقم', flex: 1, isDark: isDark),
              _buildHeaderCell('طريقة الكتابة', flex: 3, isDark: isDark),
              _buildHeaderCell('طريقة القراءة', flex: 3, isDark: isDark),
              _buildHeaderCell('رقم السورة\nورقم الآية', flex: 3, isDark: isDark),
            ],
          ),
        ),

        // Table Rows
        Expanded(
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = startIdx + entry.key;
              final (kitabah, qiraah, ayah) = entry.value;
              final isLast = entry.key == items.length - 1;

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: borderColor, width: 0.7)),
                  ),
                  child: Row(
                    children: [
                      // Index
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            '$idx',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),
                      _vDivider(borderColor),

                      // Kitabah (Red)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              kitabah,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFEF5350)
                                    : const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _vDivider(borderColor),

                      // Qira'ah (Green)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              qiraah,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _vDivider(borderColor),

                      // Surah & Ayah (Blue / Muted)
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              ayah,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 9.5,
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                    : const Color(0xFF5D4037),
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title, {required int flex, required bool isDark}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8D6E63),
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _vDivider(Color color) {
    return Container(
      width: 0.7,
      color: color,
    );
  }
}

