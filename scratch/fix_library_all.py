import os

with open('lib/screens/library_screen.dart', 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# 1. Fix the corrupted _getPillars section
start_marker = """              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),"""

end_marker = """        _IslamicPillar(
          id: 'companions',"""

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

if idx1 == -1 or idx2 == -1:
    print(f"Error finding markers: idx1={idx1}, idx2={idx2}")
    exit(1)

proper_replacement = """
        ),
      ),
    );
  }

  // 8 Core Islamic Reference Faculties (Comprehensive Preservation • 4,680 Topics)
  List<_IslamicPillar> _getPillars(String locale) => [
        _IslamicPillar(
          id: 'quran_sciences',
          titles: {
            'ar': 'التفسير وعلوم القرآن',
            'en': 'Tafsir & Quranic Sciences',
            'am': 'ተፍሲር እና የቁርኣን ሳይንስ',
            'om': "Tafsiira fi Saayinsii Qur'aanaa",
          },
          subtitles: {
            'ar': 'التفسير الميسر، السعدي، البغوي، وعلوم التنزيل',
            'en': 'Tafsir Al-Muyassar, As-Saadi, Al-Baghawi & Sciences',
            'am': 'ተፍሲር አል-ሙየሰር፣ አስ-ሰዕዲ፣ አል-በገዊ እና ሳይንሶች',
            'om': "Tafsiira Al-Muyassar, As-Sa'dii, Al-Baghawii fi Saayinsii",
          },
          countBadge: '3 تفاسير • 174 موضوعاً',
          icon: Icons.menu_book_rounded,
          gradient: const [Color(0xFF21295C), Color(0xFF384699)],
          accentColor: const Color(0xFF667EEA),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: const {
                    'ar': 'التفسير وعلوم القرآن',
                    'en': 'Tafsir & Quranic Sciences',
                    'am': 'ተፍሲር እና የቁርኣን ሳይንስ',
                    'om': "Tafsiira fi Saayinsii Qur'aanaa",
                  }[locale] ?? 'التفسير وعلوم القرآن',
                  filterCategories: const ['القرآن الكريم', 'قصص القرآن', 'إعجاز القرآن', 'الناسخ والمنسوخ'],
                  headerWidget: _buildTafsirShowcaseCard(ctx),
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'seerah',
          titles: {
            'ar': 'السيرة النبوية والمغازي',
            'en': 'Prophetic Seerah & Battles',
            'am': 'የነቢዩ (ሰ.ዐ.ወ) ታሪክ',
            'om': 'Seenaa Nabiyyii (SAW)',
          },
          subtitles: {
            'ar': 'سيرة المصطفى ﷺ العطرة، شمائله، غزواته، ووصاياه',
            'en': 'Life of the Prophet ﷺ, Shamail, battles & sacred counsels',
            'am': 'የነቢዩ ሸማኢል እና ዘመቻዎች',
            'om': 'Amala, waraana fi gorsa nabiyyii',
          },
          countBadge: locale == 'ar' ? 'سيرة المصطفى ﷺ • 92 موضوعاً' : 'Prophetic Seerah • 92 Topics',
          icon: Icons.stars_rounded,
          gradient: const [Color(0xFF854F11), Color(0xFFC78422)],
          accentColor: const Color(0xFFE5A93C),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: const {
                    'ar': 'السيرة النبوية والمغازي',
                    'en': 'Prophetic Seerah & Battles',
                    'am': 'የነቢዩ (ሰ.ዐ.ወ) ታሪክ',
                    'om': 'Seenaa Nabiyyii (SAW)',
                  }[locale] ?? 'السيرة النبوية والمغازي',
                  filterCategories: const ['شمائل الرسول', 'غزوات الرسول', 'من وصايا الرسول'],
                  headerWidget: _buildProphetSeerahHeroCard(ctx),
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
"""

content = content[:idx1 + len(start_marker)] + proper_replacement + content[idx2:]

# 2. Fix the Islamic Heritage header overflow (Bug 1: 98px overflow)
old_faculties_header = """        // B. Section Header for Islamic Heritage Faculties
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'ar' ? 'أقسام المكتبة والعلوم الشرعية' : 'Islamic Heritage & Faculties',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: locale == 'ar' ? 'Amiri' : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _LuminousPulsingDot(color: Color(0xFF1B8A6B), size: 6.0),
                          const SizedBox(width: 5),
                          Text(
                            locale == 'ar' ? '8 أقسام • 4,680 موضوعاً' : '8 Faculties • 4,680 Topics',
                            style: const TextStyle(
                              color: Color(0xFF1B8A6B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibraryCategoryScreen(
                              domainPart: 'المكتبة',
                              domainTitle: locale == 'ar' ? 'الفهرس الشامل للمكتبة' : 'Comprehensive Library Index',
                            ),
                          ),
                        ).then((_) => _loadResumeItem());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              locale == 'ar' ? 'الفهرس الشامل' : 'Full Index',
                              style: const TextStyle(
                                color: Color(0xFF1B8A6B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1B8A6B), size: 9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),"""

new_faculties_header = """        // B. Section Header for Islamic Heritage Faculties (Responsive & Overflow-Safe)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3.5,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8A6B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          locale == 'ar' ? 'أقسام المكتبة والعلوم الشرعية' : 'Islamic Heritage & Faculties',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: locale == 'ar' ? 'Amiri' : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _LuminousPulsingDot(color: Color(0xFF1B8A6B), size: 5.5),
                          const SizedBox(width: 4),
                          Text(
                            locale == 'ar' ? '8 كليات' : '8 Faculties',
                            style: const TextStyle(
                              color: Color(0xFF1B8A6B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibraryCategoryScreen(
                              domainPart: 'المكتبة',
                              domainTitle: locale == 'ar' ? 'الفهرس الشامل للمكتبة' : 'Comprehensive Library Index',
                            ),
                          ),
                        ).then((_) => _loadResumeItem());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              locale == 'ar' ? 'الفهرس الشامل' : 'Full Index',
                              style: const TextStyle(
                                color: Color(0xFF1B8A6B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1B8A6B), size: 9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),"""

if old_faculties_header in content:
    content = content.replace(old_faculties_header, new_faculties_header)
    print("Fixed Islamic Heritage faculties header overflow!")
else:
    print("Warning: old_faculties_header not found exactly!")

# 3. Fix the Hadith Bookshelf header overflow (Bug 2: Hadith bookshelf overflow)
old_hadith_header = """              // Line 1: Title and Count Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC68A2E),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'ar' ? 'دواوين السنة النبوية' : 'Canonical Hadith Bookshelf',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68A2E).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC68A2E).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LuminousPulsingDot(color: Color(0xFFC68A2E), size: 5.5),
                        const SizedBox(width: 5),
                        Text(
                          locale == 'ar' ? '10 دواوين • 40,937 حديثاً' : '10 Books • 40,937 Hadiths',
                          style: const TextStyle(
                            color: Color(0xFFC68A2E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),"""

new_hadith_header = """              // Line 1: Title and Count Badge (Responsive & Overflow-Safe)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 3.5,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC68A2E),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            locale == 'ar' ? 'دواوين السنة النبوية' : 'Canonical Hadith Bookshelf',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68A2E).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC68A2E).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LuminousPulsingDot(color: Color(0xFFC68A2E), size: 5.5),
                        const SizedBox(width: 4),
                        Text(
                          locale == 'ar' ? '10 دواوين • 40,937 حديثاً' : '10 Books • 40,937 Hadiths',
                          style: const TextStyle(
                            color: Color(0xFFC68A2E),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),"""

if old_hadith_header in content:
    content = content.replace(old_hadith_header, new_hadith_header)
    print("Fixed Hadith Bookshelf header overflow!")
else:
    print("Warning: old_hadith_header not found exactly!")

with open('lib/screens/library_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully written updated library_screen.dart in clean UTF-8!")
