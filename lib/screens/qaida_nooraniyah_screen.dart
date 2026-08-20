import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../widgets/liquid_pressable.dart';

class QaidaLesson {
  final int number;
  final String titleAr;
  final String titleEn;
  final String description;
  final List<String> items;
  final int crossAxisCount;
  final double childAspectRatio;

  const QaidaLesson({
    required this.number,
    required this.titleAr,
    required this.titleEn,
    required this.description,
    required this.items,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1.05,
  });
}

const List<QaidaLesson> _kQaidaLessons = [
  // ── 1. حُرُوفُ الهِجَاءِ المُفْرَدَة ─────────────────────────────────────────
  QaidaLesson(
    number: 1,
    titleAr: 'الدرس الأول: حُرُوفُ الهِجَاءِ المُفْرَدَة',
    titleEn: 'Lesson 1: Individual Arabic Alphabet',
    description: 'نطق الحروف العربية المفردة بمخارجها الصحيحة من اليمين إلى اليسار',
    crossAxisCount: 4,
    childAspectRatio: 1.05,
    items: [
      'أ', 'ب', 'ت', 'ث',
      'ج', 'ح', 'خ', 'د',
      'ذ', 'ر', 'ز', 'س',
      'ش', 'ص', 'ض', 'ط',
      'ظ', 'ع', 'غ', 'ف',
      'ق', 'ك', 'ل', 'م',
      'ن', 'و', 'هـ', 'ء',
      'ي', 'ى', 'لا', 'ة',
    ],
  ),

  // ── 2. حُرُوفُ الهِجَاءِ المُرَكَّبَة ─────────────────────────────────────────
  QaidaLesson(
    number: 2,
    titleAr: 'الدرس الثاني: حُرُوفُ الهِجَاءِ المُرَكَّبَة',
    titleEn: 'Lesson 2: Compound Letters',
    description: 'التعرف على أشكال الحروف في أول ووسط وآخر الكلمة',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'لا', 'ألف', 'لا',
      'با', 'لا', 'كاف',
      'كاف', 'كاف', 'با كاف تا',
      'تا كاف ثا', 'با تا ثا نون يا', 'با ألف',
      'نون ألف', 'تا ألف', 'يا ألف',
      'ثا ألف', 'با سين', 'سين',
      'شين', 'صاد', 'ضاد',
      'عين', 'غين', 'با جيم',
      'تا حا', 'ثا خا', 'ها',
      'با ها', 'با جيم تا', 'يا حا با',
      'با خا تا', 'تا ها با', 'يا ها با',
      'نون با لام', 'تا نون لام', 'با يا لام',
      'يا تا لام', 'ثا ثا لام', 'نون با نون',
      'با يا نون', 'يا تا نون', 'ثا ثا نون',
      'نون يا نون', 'جيم حا خا', 'حا ثا',
      'خا با', 'جيم تا', 'يا تا',
      'تا با', 'با با', 'ثا ثا',
      'نون نون', 'يا فا', 'تا قاف',
    ],
  ),

  // ── 3. الحُرُوفُ المُقَطَّعَة ───────────────────────────────────────────────
  QaidaLesson(
    number: 3,
    titleAr: 'الدرس الثالث: الحُرُوفُ المُقَطَّعَة',
    titleEn: 'Lesson 3: Muqatta\'at Letters',
    description: 'الحروف المقطعة في فواتح السور القرآنية والمد اللازم الحرفي',
    crossAxisCount: 2,
    childAspectRatio: 1.85,
    items: [
      'الٓمٓ', 'الٓمٓصٓ',
      'الٓر', 'الٓمٓر',
      'كٓهيعٓصٓ', 'طٰهٰ',
      'طٰسٓمٓ', 'طٰسٓ',
      'يٰسٓ', 'صٓ',
      'حٰمٓ', 'حٰمٓ عٓسٓقٓ',
      'قٓ', 'نٓ',
    ],
  ),

  // ── 4. الحَرَكَات ─────────────────────────────────────────────────────────
  QaidaLesson(
    number: 4,
    titleAr: 'الدرس الرابع: الحَرَكَاتُ (الفتحة والكسرة والضمة)',
    titleEn: 'Lesson 4: Short Vowels (Harakat)',
    description: 'نطق الحركات القصيرة دون مد: فتحة، كسرة، ضمة',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    items: [
      'ءَ', 'ءِ', 'ءُ',
      'هَـ', 'هِـ', 'هُـ',
      'عَـ', 'عِـ', 'عُـ',
      'حَـ', 'حِـ', 'حُـ',
      'غَـ', 'غِـ', 'غُـ',
      'خَـ', 'خِـ', 'خُـ',
      'قَـ', 'قِـ', 'قُـ',
      'كَـ', 'كِـ', 'كُـ',
      'جَـ', 'جِـ', 'جُـ',
      'شَـ', 'شِـ', 'شُـ',
      'يَـ', 'يِـ', 'يُـ',
      'ضَـ', 'ضِـ', 'ضُـ',
      'لَـ', 'لِـ', 'لُـ',
      'نَـ', 'نِـ', 'نُـ',
      'رَـ', 'رِـ', 'رُـ',
      'طَـ', 'طِـ', 'طُـ',
      'دَـ', 'دِـ', 'دُـ',
      'تَـ', 'تِـ', 'تُـ',
      'صَـ', 'صِـ', 'صُـ',
      'زَـ', 'زِـ', 'زُـ',
      'سَـ', 'سِـ', 'سُـ',
      'ظَـ', 'ظِـ', 'ظُـ',
      'ذَـ', 'ذِـ', 'ذُـ',
      'ثَـ', 'ثِـ', 'ثُـ',
      'فَـ', 'فِـ', 'فُـ',
      'وَـ', 'وِـ', 'وُـ',
      'بَـ', 'بِـ', 'بُـ',
      'مَـ', 'مِـ', 'مُـ',
    ],
  ),

  // ── 5. الحُرُوفُ المُنَوَّنَةُ (التَّنْوِين) ──────────────────────────────────
  QaidaLesson(
    number: 5,
    titleAr: 'الدرس الخامس: الحُرُوفُ المُنَوَّنَةُ (التَّنْوِين)',
    titleEn: 'Lesson 5: Tanween (Nunation)',
    description: 'فتحتان، كسرتان، ضمتان مع إظهار نون التنوين الساكنة',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    items: [
      'مً', 'مٍ', 'مٌ',
      'بً', 'بٍ', 'بٌ',
      'وً', 'وٍ', 'وٌ',
      'فً', 'فٍ', 'فٌ',
      'ثً', 'ثٍ', 'ثٌ',
      'ذً', 'ذٍ', 'ذٌ',
      'ظً', 'ظٍ', 'ظٌ',
      'زً', 'زٍ', 'زٌ',
      'سً', 'سٍ', 'سٌ',
      'صً', 'صٍ', 'صٌ',
      'تً', 'تٍ', 'تٌ',
      'دً', 'دٍ', 'دٌ',
      'طً', 'طٍ', 'طٌ',
      'رً', 'رٍ', 'رٌ',
      'نً', 'نٍ', 'نٌ',
      'لً', 'لٍ', 'لٌ',
      'ضً', 'ضٍ', 'ضٌ',
      'يً', 'يٍ', 'يٌ',
      'شً', 'شٍ', 'شٌ',
      'جً', 'جٍ', 'جٌ',
      'كً', 'كٍ', 'كٌ',
      'قً', 'قٍ', 'قٌ',
      'خً', 'خٍ', 'خٌ',
      'غً', 'غٍ', 'غٌ',
      'حً', 'حٍ', 'حٌ',
      'عً', 'عٍ', 'عٌ',
      'هـً', 'هـٍ', 'هـٌ',
      'ءً', 'ءٍ', 'ءٌ',
    ],
  ),

  // ── 6. تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِين ──────────────────────────────
  QaidaLesson(
    number: 6,
    titleAr: 'الدرس السادس: تَدْرِيبَاتٌ عَلَى الحَرَكَاتِ وَالتَّنْوِين',
    titleEn: 'Lesson 6: Exercises on Harakat & Tanween',
    description: 'تطبيق عملي على قراءة كلمات قرآنية مشكولة بالحركات والتنوين',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'أَبَدًا', 'أَحَدٌ', 'أَخَذَ',
      'أَذِنَ', 'أَمَرَ', 'أَنَا',
      'بَخِلَ', 'بَلَغَ', 'جَعَلَ',
      'جَمَعَ', 'حَسَدَ', 'حَشَرَ',
      'خَشِيَ', 'خُلِقَ', 'ذَكَرَ',
      'رَفَعَ', 'رَقَبَةٍ', 'سُرُرٌ',
      'سَفَرَةٍ', 'صُحُفًا', 'وَسَطًا',
      'طَبَقًا', 'طَبَقٍ', 'طُوًى',
      'عَبَسَ', 'عَدَلَ', 'عَلَقٍ',
      'عَمَدٍ', 'عِنَبًا', 'غَبَرَةٌ',
      'فَعَلَ', 'قَتَرَةٌ', 'قُتِلَ',
      'قَدَرَ', 'قُرِئَ', 'قَسَمٌ',
      'كَبَدٍ', 'كُتُبٌ', 'كَسَبَ',
      'كُفُوًا', 'لَبَدًا', 'لُمَزَةٍ',
      'لَهَبٍ', 'مَسَدٍ', 'نَخِرَةً',
      'وَجَدَ', 'وَسَقَ', 'وَقَبَ',
      'وَلَدَ', 'وَهَبَ', 'هُمَزَةٍ',
      'هُدًى',
    ],
  ),

  // ── 7. الأَلِفُ الصَّغِيرَةُ وَاليَاءُ وَالوَاوُ ────────────────────────────────
  QaidaLesson(
    number: 7,
    titleAr: 'الدرس السابع: الأَلِفُ الصَّغِيرَةُ وَاليَاءُ وَالوَاوُ الصَّغِيرَة',
    titleEn: 'Lesson 7: Standing Alif, Standing Yaa, Inverted Waw',
    description: 'الألف الخنجرية والياء والواو الصغيرتان ومقدار مدها حركتان',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    items: [
      'بٰ', 'بٖ', 'بٗ',
      'تٰ', 'تٖ', 'تٗ',
      'ثٰ', 'ثٖ', 'ثٗ',
      'جٰ', 'جٖ', 'جٗ',
      'حٰ', 'حٖ', 'حٗ',
      'خٰ', 'خٖ', 'خٗ',
      'دٰ', 'دٖ', 'دٗ',
      'ذٰ', 'ذٖ', 'ذٗ',
      'رٰ', 'رٖ', 'رٗ',
      'زٰ', 'زٖ', 'زٗ',
      'سٰ', 'سٖ', 'سٗ',
      'شٰ', 'شٖ', 'شٗ',
      'صٰ', 'صٖ', 'صٗ',
      'ضٰ', 'ضٖ', 'ضٗ',
      'طٰ', 'طٖ', 'طٗ',
      'ظٰ', 'ظٖ', 'ظٗ',
      'عٰ', 'عٖ', 'عٗ',
      'غٰ', 'غٖ', 'غٗ',
      'فٰ', 'فٖ', 'فٗ',
      'قٰ', 'قٖ', 'قٗ',
      'كٰ', 'كٖ', 'كٗ',
      'لٰ', 'لٖ', 'لٗ',
      'مٰ', 'مٖ', 'مٗ',
      'نٰ', 'نٖ', 'نٗ',
      'وٰ', 'وٖ', 'وٗ',
      'هٰ', 'هٖ', 'هٗ',
      'ءٰ', 'ءٖ', 'ءٗ',
      'يٰ', 'يٖ', 'يٗ',
    ],
  ),

  // ── 8. حُرُوفُ المَدِّ وَاللِّين ─────────────────────────────────────────────
  QaidaLesson(
    number: 8,
    titleAr: 'الدرس الثامن: حُرُوفُ المَدِّ وَاللِّين',
    titleEn: 'Lesson 8: Letters of Madd and Leen',
    description: 'الألف والواو والياء الساكنة المسبوقة بحركة مجانسة وحرفا اللين',
    crossAxisCount: 3,
    childAspectRatio: 1.30,
    items: [
      'بَا', 'بُو', 'بِي',
      'تَا', 'تُو', 'تِي',
      'ثَا', 'ثُو', 'ثِي',
      'جَا', 'جُو', 'جِي',
      'حَا', 'حُو', 'حِي',
      'خَا', 'خُو', 'خِي',
      'دَا', 'دُو', 'دِي',
      'ذَا', 'ذُو', 'ذِي',
      'رَا', 'رُو', 'رِي',
      'زَا', 'زُو', 'زِي',
      'سَا', 'سُو', 'سِي',
      'شَا', 'شُو', 'شِي',
      'صَا', 'صُو', 'صِي',
      'ضَا', 'ضُو', 'ضِي',
      'طَا', 'طُو', 'طِي',
      'ظَا', 'ظُو', 'ظِي',
      'عَا', 'عُو', 'عِي',
      'غَا', 'غُو', 'غِي',
      'فَا', 'فُو', 'فِي',
      'قَا', 'قُو', 'قِي',
      'كَـا', 'كُـو', 'كِـي',
      'لَا', 'لُو', 'لِي',
      'مَا', 'مُو', 'مِي',
      'نَا', 'نُو', 'نِي',
      'وَا', 'وُو', 'وِي',
      'هَـا', 'هُـو', 'هِـي',
      'ءَا', 'ءُو', 'ءِي',
      'يَا', 'يُو', 'يِي',
      'بَوْ', 'بَيْ', 'تَوْ',
      'تَيْ', 'ثَوْ', 'ثَيْ',
      'جَوْ', 'جَيْ', 'حَوْ',
      'حَيْ', 'خَوْ', 'خَيْ',
      'دَوْ', 'دَيْ', 'ذَوْ',
      'ذَيْ', 'رَوْ', 'رَيْ',
      'زَوْ', 'زَيْ', 'سَوْ',
      'سَيْ', 'شَوْ', 'شَيْ',
      'صَوْ', 'صَيْ', 'ضَوْ',
      'ضَيْ', 'طَوْ', 'طَيْ',
      'ظَوْ', 'ظَيْ', 'عَوْ',
      'عَيْ', 'غَوْ', 'غَيْ',
      'فَوْ', 'فَيْ', 'قَوْ',
      'قَيْ', 'كَوْ', 'كَيْ',
      'لَوْ', 'لَيْ', 'مَوْ',
      'مَيْ', 'نَوْ', 'نَيْ',
      'وَوْ', 'وَيْ', 'هَوْ',
      'هَيْ', 'أَوْ', 'أَيْ',
      'يَوْ', 'يَيْ',
    ],
  ),

  // ── 9. تَدْرِيبَاتٌ عَلَى المَدِّ وَاللِّين وَالتَّنْوِين ──────────────────────
  QaidaLesson(
    number: 9,
    titleAr: 'الدرس التاسع: تَدْرِيبَاتٌ عَلَى المَدِّ وَاللِّين وَالتَّنْوِين',
    titleEn: 'Lesson 9: Exercises on Madd, Leen & Tanween',
    description: 'أمثلة تطبيقية شاملة على حروف المد وحرفي اللين مع التنوين',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'آمَنَ', 'آوَىٰ', 'آنِيَةٍ',
      'إِيلَافِهِمْ', 'أَيْنَ', 'بِهِۦ',
      'جَآءَ', 'جِيدِهَا', 'جُوعٍ',
      'خَوْفٌ', 'خَيْرٌ', 'دَاوُۥدُ',
      'ذَٰلِكَ', 'رَضِيَ', 'رَيْبٌ',
      'سِرَاجًا', 'سُوٓءَ', 'شَيْءٍ',
      'طَاغِيَةً', 'طَيْرًا', 'عَادٌ',
      'عَادِيَاتٍ', 'عَذَابٌ', 'عَطَآءً',
      'عَيْنٌ', 'غَاسِقٍ', 'غَيْثٌ',
      'غَاوُونَ', 'فِي فَلَكٍ', 'قَالُوا۟',
      'قَوْلٌ', 'قُرَيْشٍ', 'كَانَ',
      'كَيْدًا', 'كَيْفَ', 'لَوْحٍ',
      'لَيْسَ', 'مَالٍ', 'نَارٌ',
      'مَـَٔابٍ', 'مَتَاعًا', 'مِيثَاقَهُۥ',
      'فَاكِهِينَ', 'وَيْلٌ', 'يَوْمَئِذٍ',
      'يَرَوْنَهُۥ',
    ],
  ),

  // ── 10. السُّكُون ─────────────────────────────────────────────────────────
  QaidaLesson(
    number: 10,
    titleAr: 'الدرس العاشر: السُّكُونُ (الجَزْم)',
    titleEn: 'Lesson 10: Sukoon',
    description: 'نطق الحرف الساكن مع الحرف المتحرك قبله وقلقلة قطب جد',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    items: [
      'أَبْ', 'إِبْ', 'أُبْ',
      'أَتْ', 'إِتْ', 'أُتْ',
      'أَثْ', 'إِثْ', 'أُثْ',
      'أَجْ', 'إِجْ', 'أُجْ',
      'أَحْ', 'إِحْ', 'أُحْ',
      'أَخْ', 'إِخْ', 'أُخْ',
      'أَدْ', 'إِدْ', 'أُدْ',
      'أَذْ', 'إِذْ', 'أُذْ',
      'أَرْ', 'إِرْ', 'أُرْ',
      'أَزْ', 'إِزْ', 'أُزْ',
      'أَسْ', 'إِسْ', 'أُسْ',
      'أَشْ', 'إِشْ', 'أُشْ',
      'أَصْ', 'إِصْ', 'أُصْ',
      'أَضْ', 'إِضْ', 'أُضْ',
      'أَطْ', 'إِطْ', 'أُطْ',
      'أَظْ', 'إِظْ', 'أُظْ',
      'أَعْ', 'إِعْ', 'أُعْ',
      'أَغْ', 'إِغْ', 'أُغْ',
      'أَفْ', 'إِفْ', 'أُفْ',
      'أَقْ', 'إِقْ', 'أُقْ',
      'أَكْ', 'إِكْ', 'أُكْ',
      'أَلْ', 'إِلْ', 'أُلْ',
      'أَمْ', 'إِمْ', 'أُمْ',
      'أَنْ', 'إِنْ', 'أُنْ',
      'أَهْ', 'إِهْ', 'أُهْ',
      'أَوْ', 'إِوْ', 'أُوْ',
      'أَيْ', 'إِيْ', 'أُيْ',
    ],
  ),

  // ── 11. تَدْرِيبَاتٌ عَلَى السُّكُون ─────────────────────────────────────────
  QaidaLesson(
    number: 11,
    titleAr: 'الدرس الحادي عشر: تَدْرِيبَاتٌ عَلَى السُّكُون',
    titleEn: 'Lesson 11: Exercises on Sukoon',
    description: 'تدريب على نطق الكلمات القرآنية ذات المقاطع الساكنة',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'هَمْزَةٌ', 'أَبْصَارِهِمْ', 'أَبْقَىٰ',
      'أَتْقَىٰ', 'أَثْقَلَتْ', 'أَجْرٌ',
      'أَحْسَنَ', 'أَخْرَجَ', 'أَدْبَرَ',
      'أَرْسَلَ', 'أَزْلَفَتْ', 'أَسْلَمَ',
      'أَشْتَاتًا', 'أَصْبَحَ', 'أَطْعَمَهُم',
      'أَعْتَدْنَا', 'أَفْلَحَ', 'أَقْرَبُ',
      'أَكْرَمَ', 'أَلْهَىٰكُمُ', 'أَمْهِلْهُمْ',
      'أَنْعَمْتَ', 'أَوْحَىٰ', 'إِبْرَاهِيمُ',
      'تَرْجُفُ', 'تَرْمِيهِم', 'تَزْرَعُونَهُۥ',
      'تَسْمَعُ', 'تَشْهَدُ', 'تَصْلَىٰ',
      'تَعْرِفُ', 'تَغْفِرْ', 'تَقْهَرْ',
      'تَكْذِيبٍ', 'تَلْفَحُ', 'يَعْلَمُ',
      'يَخْرُجُ', 'يَدْعُو', 'يَرْزُقُ',
      'يَسْمَعُ', 'يَشْرَبُ', 'يَصْبِرُ',
      'يَطْمَعُ', 'يَعْتَصِم', 'يَغْلِب',
      'يَفْعَلُ', 'يَقْتُلُ', 'يَكْتُبُ',
    ],
  ),

  // ── 12. الشَّدَّة ─────────────────────────────────────────────────────────
  QaidaLesson(
    number: 12,
    titleAr: 'الدرس الثاني عشر: الشَّدَّةُ (التَّشْدِيد)',
    titleEn: 'Lesson 12: Shaddah (Doubled Consonants)',
    description: 'الحرف المشدد مكون من حرف ساكن يليه حرف متحرك',
    crossAxisCount: 3,
    childAspectRatio: 1.25,
    items: [
      'أَبَّ', 'أَبِّ', 'أَبُّ',
      'أَتَّ', 'أَتِّ', 'أَتُّ',
      'أَثَّ', 'أَثِّ', 'أَثُّ',
      'أَجَّ', 'أَجِّ', 'أَجُّ',
      'أَحَّ', 'أَحِّ', 'أَحُّ',
      'أَخَّ', 'أَخِّ', 'أَخُّ',
      'أَدَّ', 'أَدِّ', 'أَدُّ',
      'أَذَّ', 'أَذِّ', 'أَذُّ',
      'أَرَّ', 'أَرِّ', 'أَرُّ',
      'أَزَّ', 'أَزِّ', 'أَزُّ',
      'أَسَّ', 'أَسِّ', 'أَسُّ',
      'أَشَّ', 'أَشِّ', 'أَشُّ',
      'أَصَّ', 'أَصِّ', 'أَصُّ',
      'أَضَّ', 'أَضِّ', 'أَضُّ',
      'أَطَّ', 'أَطِّ', 'أَطُّ',
      'أَظَّ', 'أَظِّ', 'أَظُّ',
      'أَعَّ', 'أَعِّ', 'أَعُّ',
      'أَغَّ', 'أَغِّ', 'أَغُّ',
      'أَفَّ', 'أَفِّ', 'أَفُّ',
      'أَقَّ', 'أَقِّ', 'أَقُّ',
      'أَكَّ', 'أَكِّ', 'أَكُّ',
      'أَلَّ', 'أَلِّ', 'أَلُّ',
      'أَمَّ', 'أَمِّ', 'أَمُّ',
      'أَنَّ', 'أَنِّ', 'أَنُّ',
      'أَهَّ', 'أَهِّ', 'أَهُّ',
      'أَوَّ', 'أَوِّ', 'أَوُّ',
      'أَيَّ', 'أَيِّ', 'أَيُّ',
    ],
  ),

  // ── 13. تَدْرِيبَاتٌ عَلَى الشَّدَّة ─────────────────────────────────────────
  QaidaLesson(
    number: 13,
    titleAr: 'الدرس الثالث عشر: تَدْرِيبَاتٌ عَلَى الشَّدَّة',
    titleEn: 'Lesson 13: Exercises on Shaddah',
    description: 'أمثلة لكلمات قرآنية بها أحرف مشددة مع الغنة في النون والميم',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'زَكَّىٰ', 'ثَجَّاجًا', 'سَجَّاحًا',
      'وَضَّاحًا', 'فَعَّالٌ', 'كَرَّارٌ',
      'تَوَّابًا', 'غَفَّارًا', 'وَهَّابًا',
      'عَمَّ', 'إِنَّ', 'ثُمَّ',
      'رَبِّ', 'حَقٌّ', 'مَدَّ',
      'صَدَّ', 'عَدَّ', 'وَدَّ',
      'تَبَّتْ', 'خَفَّتْ', 'شَقَّتْ',
      'حُقَّتْ', 'قَدَّمَ', 'كَلَّمَ',
      'عَلَّمَ', 'يُصَدِّقُ', 'يُسَبِّحُ',
      'يُعَظِّمُ', 'كَلَّا', 'إِلَّا',
      'حَتَّىٰ',
    ],
  ),

  // ── 14. تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُون ──────────────────────────────
  QaidaLesson(
    number: 14,
    titleAr: 'الدرس الرابع عشر: تَدْرِيبَاتٌ عَلَى الشَّدَّةِ وَالسُّكُون',
    titleEn: 'Lesson 14: Shaddah with Sukoon',
    description: 'الجمع بين السكون والتشديد في الكلمة وضبط النبر والتفخيم والترقيق',
    crossAxisCount: 3,
    childAspectRatio: 1.35,
    items: [
      'يَرْضَوْنَ', 'تَزَكَّىٰ', 'يَتَزَكَّىٰ',
      'وَتَوَلَّىٰ', 'تَجَلَّىٰ', 'يَتَوَفَّىٰ',
      'يَتَذَكَّرُ', 'يَتَفَكَّرُ', 'يَتَبَيَّنُ',
      'يُدَبِّرُ', 'يُمَهِّدُ', 'يُؤَلِّفُ',
      'وَٱلصَّٰٓفَّٰتِ', 'فَٱلزَّٰجِرَٰتِ', 'فَٱلتَّٰلِيَٰتِ',
      'ٱلنَّٰشِرَٰتِ', 'فَٱلْفَٰرِقَٰتِ', 'مُسْتَقِرٌّ',
      'مُسْتَمِرٌّ', 'مُدَّكِرٍ', 'قَيِّمَةٌ',
      'بَيِّنَةٌ', 'عِشْرُونَ',
    ],
  ),

  // ── 15. تَدْرِيبَاتٌ عَلَى الشَّدَّتَيْنِ فِي كَلِمَة ──────────────────────────
  QaidaLesson(
    number: 15,
    titleAr: 'الدرس الخامس عشر: تَدْرِيبَاتٌ عَلَى الشَّدَّتَيْنِ فِي كَلِمَة',
    titleEn: 'Lesson 15: Two Consecutive Shaddahs',
    description: 'اجتماع حرفين مشددين في كلمة واحدة وإعطاء كل حرف حقه من الزمن',
    crossAxisCount: 2,
    childAspectRatio: 1.85,
    items: [
      'يَزَّكَّىٰ', 'يَذَّكَّرُ',
      'يَدَّعُونَ', 'يَطَّوَّفَ',
      'تَطَّلِعُ', 'مُزَّمِّلُ',
      'مُدَّثِّرُ', 'عِلِّيِّينَ',
      'سِجِّينٌ', 'دُرِّيٌّ',
    ],
  ),

  // ── 16. تَدْرِيبَاتٌ عَلَى الشَّدَّةِ مَعَ المَدّ ─────────────────────────────
  QaidaLesson(
    number: 16,
    titleAr: 'الدرس السادس عشر: تَدْرِيبَاتٌ عَلَى الشَّدَّةِ مَعَ المَدّ',
    titleEn: 'Lesson 16: Shaddah with Madd (Lazim)',
    description: 'المد اللازم الكلمي المثقل ومقدار مده ست حركات وجوباً',
    crossAxisCount: 2,
    childAspectRatio: 1.85,
    items: [
      'ٱلصَّآخَّةُ', 'ٱلطَّآمَّةُ',
      'دَآبَّةٍ', 'حَآفِّينَ',
      'ضَآلِّينَ', 'تَأْمُرُوٓنِّي',
      'أَتُحَآجُّوٓنِّي', 'يُوَآدُّونَ',
    ],
  ),

  // ── 17. تَدْرِيبَاتٌ شَامِلَة ───────────────────────────────────────────────
  QaidaLesson(
    number: 17,
    titleAr: 'الدرس السابع عشر: تَدْرِيبَاتٌ شَامِلَةٌ عَلَى مَا سَبَق',
    titleEn: 'Lesson 17: Comprehensive Quranic Reading',
    description: 'تلاوة آيات وسور مباركة وتطبيق كافة أحكام التجويد والنورانية',
    crossAxisCount: 1,
    childAspectRatio: 4.80,
    items: [
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
      'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
      'مَٰلِكِ يَوْمِ ٱلدِّينِ',
      'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
      'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ',
      'غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ',
      'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
      'ٱللَّهُ ٱلصَّمَدُ',
      'لَمْ يَلِدْ وَلَمْ يُولَدْ',
      'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
    ],
  ),
];

class QaidaNooraniyahScreen extends StatefulWidget {
  final int initialLessonIndex;

  const QaidaNooraniyahScreen({
    super.key,
    this.initialLessonIndex = 0,
  });

  @override
  State<QaidaNooraniyahScreen> createState() => _QaidaNooraniyahScreenState();
}

class _QaidaNooraniyahScreenState extends State<QaidaNooraniyahScreen> {
  late int _currentLessonIndex;
  String _selectedItem = '';
  double _fontSize = 30.0;

  @override
  void initState() {
    super.initState();
    _currentLessonIndex = widget.initialLessonIndex;
  }

  void _showLessonPicker() {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'فهرس دروس القاعدة النورانية',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _kQaidaLessons.length,
                    itemBuilder: (ctx, idx) {
                      final lesson = _kQaidaLessons[idx];
                      final isSelected = idx == _currentLessonIndex;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? AppColors.emeraldLight
                              : (isDark ? Colors.white10 : Colors.black12),
                          child: Text(
                            '${lesson.number}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          lesson.titleAr,
                          style: TextStyle(
                            color: isSelected ? AppColors.emeraldLight : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          lesson.titleEn,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.emeraldLight, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _currentLessonIndex = idx;
                            _selectedItem = '';
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showItemDetail(String item, String lessonTitle) {
    setState(() => _selectedItem = item);
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lessonTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A2F), const Color(0xFF0F2019)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.emeraldLight.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: item.length > 12 ? 28 : (item.length > 5 ? 40 : 58),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LiquidPressable(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emeraldLight, AppColors.emeraldDeep],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldDeep.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    final lesson = _kQaidaLessons[_currentLessonIndex];
    final hasPrev = _currentLessonIndex > 0;
    final hasNext = _currentLessonIndex < _kQaidaLessons.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          centerTitle: true,
          title: Text(
            'القاعدة النورانية',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded),
              tooltip: 'فهرس الدروس',
              onPressed: _showLessonPicker,
            ),
            PopupMenuButton<double>(
              icon: const Icon(Icons.format_size_rounded),
              tooltip: 'حجم الخط',
              onSelected: (val) => setState(() => _fontSize = val),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 22.0, child: Text('خط صغير')),
                const PopupMenuItem(value: 30.0, child: Text('خط متوسط (افتراضي)')),
                const PopupMenuItem(value: 38.0, child: Text('خط كبير')),
                const PopupMenuItem(value: 48.0, child: Text('خط كبير جداً')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Lesson Header Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1B4D3E), const Color(0xFF0D281E)]
                      : [AppColors.emeraldLight, AppColors.emeraldDeep],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldDeep.withValues(alpha: isDark ? 0.4 : 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${lesson.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.titleAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LiquidPressable(
                    onTap: _showLessonPicker,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Authentic RTL Items Grid View
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: lesson.crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: lesson.childAspectRatio,
                ),
                itemCount: lesson.items.length,
                itemBuilder: (context, index) {
                  final item = lesson.items[index];
                  final isSelected = _selectedItem == item;

                  return LiquidPressable(
                    onTap: () => _showItemDetail(item, lesson.titleAr),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.emeraldLight.withValues(alpha: 0.25)
                                : AppColors.emeraldLight.withValues(alpha: 0.15))
                            : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.emeraldLight
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.07)),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.22 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            item,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: lesson.crossAxisCount == 1
                                  ? (_fontSize * 0.70)
                                  : (lesson.crossAxisCount == 2
                                      ? (_fontSize * 0.82)
                                      : _fontSize),
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.emeraldLight : textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Bar (Prev / Next Lesson - RTL oriented)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button (Right side in RTL)
                  LiquidPressable(
                    onTap: hasPrev
                        ? () => setState(() {
                              _currentLessonIndex--;
                              _selectedItem = '';
                            })
                        : () {},
                    child: Opacity(
                      opacity: hasPrev ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: textColor),
                            const SizedBox(width: 6),
                            Text(
                              'الدرس السابق',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Indicator
                  Text(
                    'الدرس ${lesson.number} من ${_kQaidaLessons.length}',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  // Next Button (Left side in RTL)
                  LiquidPressable(
                    onTap: hasNext
                        ? () => setState(() {
                              _currentLessonIndex++;
                              _selectedItem = '';
                            })
                        : () {},
                    child: Opacity(
                      opacity: hasNext ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: hasNext
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.emeraldLight,
                                    AppColors.emeraldDeep
                                  ],
                                )
                              : null,
                          color: hasNext
                              ? null
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'الدرس التالي',
                              style: TextStyle(
                                color: hasNext ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 14,
                              color: hasNext ? Colors.white : textColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
