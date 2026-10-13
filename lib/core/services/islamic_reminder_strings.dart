class IslamicReminderContent {
  final String title;
  final String body;
  final String? expandedText;
  final String? summary;
  final String? actionLabel;
  final String payload;

  const IslamicReminderContent({
    required this.title,
    required this.body,
    this.expandedText,
    this.summary,
    this.actionLabel,
    required this.payload,
  });
}

class IslamicReminderStrings {
  static String normalizeLang(String? appLang) {
    if (appLang == null) return 'en';
    final lower = appLang.toLowerCase().trim();
    if (lower.startsWith('ar') || lower == 'arabic') return 'ar';
    if (lower.startsWith('am') || lower == 'amharic') return 'am';
    if (lower.startsWith('om') || lower == 'oromo') return 'om';
    return 'en';
  }

  static IslamicReminderContent getReminder(int slotId, String? appLang) {
    final lang = normalizeLang(appLang);
    switch (slotId) {
      case 1: // Morning Adhkar
        return _getMorningAdhkar(lang);
      case 2: // Duha Prayer
        return _getDuhaPrayer(lang);
      case 3: // Evening Adhkar
        return _getEveningAdhkar(lang);
      case 4: // Sleep Adhkar & Al-Mulk
        return _getSleepAdhkar(lang);
      case 10: // Friday Al-Kahf
        return _getFridayKahf(lang);
      case 11: // Monday Fasting
        return _getMondayFasting(lang);
      case 12: // Thursday Fasting
        return _getThursdayFasting(lang);
      default:
        return _getMorningAdhkar(lang);
    }
  }

  static IslamicReminderContent _getMorningAdhkar(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🌅 أذكار الصباح',
          body: 'أصبحنا وأصبح الملك لله والحمد لله.. حان وقت أذكار الصباح لحفظك وبركة يومك',
          expandedText:
              '«أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير»\n\n✨ حصّن يومك وبركة نهارك بالذكر والتسبيح.. اضغط هنا لقراءة أذكار الصباح كاملة.',
          summary: '📖 أذكار الصباح',
          actionLabel: '📖 فتح أذكار الصباح',
          payload: 'morning_azkar',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🌅 የጠዋት አዝካር',
          body: 'ቀኑን በአላህ ምስጋና ጀምረናል.. ቀናችሁን በአዝካር በመጠበቅ የበረካ ባለቤት ይሁኑ።',
          expandedText:
              '«አስበሕና ወአስበሐል ሙልኩ ሊላህ፣ ወልሐምዱ ሊላህ..»\n\n✨ ቀናችሁን በአላህ ማስታወስ እና በተስቢሕ ይጠብቁ.. ሙሉ የጠዋት አዝካርን ለማንበብ እዚህ ይጫኑ።',
          summary: '📖 የጠዋት አዝካር',
          actionLabel: '📖 የጠዋት አዝካርን ክፈት',
          payload: 'morning_azkar',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🌅 Azkaara Ganamaa',
          body: 'Guyyaan haaraan faaruu Rabbitiin eegale.. Guyyaa keessan azkaaraan tiksaa, barakaa argadhaa.',
          expandedText:
              '«Asbahnaa wa asbahal mulku lillaah, walhamdu lillaah..»\n\n✨ Guyyaa keessan zikrii fi tasbiihaan eegaa.. Azkaara ganamaa guutuu qara\'uuf as tuqaa.',
          summary: '📖 Azkaara Ganamaa',
          actionLabel: '📖 Azkaara Ganamaa Bani',
          payload: 'morning_azkar',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🌅 Morning Adhkar',
          body: 'A new day has begun in praise of Allah. Protect your day and gain blessings with the Morning Adhkar.',
          expandedText:
              '«We have entered a new day and unto Allah belongs all sovereignty, and all praise is for Allah..»\n\n✨ Fortify your day with remembrance and Tasbeeh. Tap here to read the full Morning Adhkar.',
          summary: '📖 Morning Adhkar',
          actionLabel: '📖 Open Morning Adhkar',
          payload: 'morning_azkar',
        );
    }
  }

  static IslamicReminderContent _getDuhaPrayer(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '☀️ صلاة الضحى (صلاة الأوابين)',
          body: 'ركعتا الضحى صدقة عن كل مفصل في جسدك، لا تفوت أجرها العظيم',
          payload: 'duha_prayer',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '☀️ የዱሓ ሶላት (የአዋቢን ሶላት)',
          body: 'የዱሓ ሁለት ረከዓዎች በሰውነትህ ላሉ እያንዳንዱ መገጣጠሚያዎች ሰደቃ ናቸው፤ ታላቁን ምንዳ አያምልጥዎ።',
          payload: 'duha_prayer',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '☀️ Salaata Duhaa (Salaata Awwaabiin)',
          body: 'Raka\'aan lamaan Duhaa buusaa qaama keetii hundaaf sadaqaa taati; mindaa guddaa kana hin dhabinaa.',
          payload: 'duha_prayer',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '☀️ Duha Prayer (Prayer of the Penitent)',
          body: 'Two units of Duha prayer serve as charity for every joint in your body. Do not miss this great reward.',
          payload: 'duha_prayer',
        );
    }
  }

  static IslamicReminderContent _getEveningAdhkar(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🌇 أذكار المساء',
          body: 'أمسينا وأمسى الملك لله والحمد لله.. حصّن نفسك وأهلك بأذكار المساء',
          summary: '📖 أذكار المساء',
          actionLabel: '📖 فتح أذكار المساء',
          payload: 'evening_azkar',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🌇 የምሽት አዝካር',
          body: 'ምሽቱን በአላህ ምስጋና ተቀብለናል.. እራስዎን እና ቤተሰብዎን በምሽት አዝካር ይጠብቁ።',
          summary: '📖 የምሽት አዝካር',
          actionLabel: '📖 የምሽት አዝካርን ክፈት',
          payload: 'evening_azkar',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🌇 Azkaara Galgalaa',
          body: 'Galgala kana faaruu Rabbitiin simanneerra.. Ofii fi maatii keessan azkaara galgalaatiin tiksaa.',
          summary: '📖 Azkaara Galgalaa',
          actionLabel: '📖 Azkaara Galgalaa Bani',
          payload: 'evening_azkar',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🌇 Evening Adhkar',
          body: 'We have entered the evening in praise of Allah. Protect yourself and family with the Evening Adhkar.',
          summary: '📖 Evening Adhkar',
          actionLabel: '📖 Open Evening Adhkar',
          payload: 'evening_azkar',
        );
    }
  }

  static IslamicReminderContent _getSleepAdhkar(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🌙 أذكار النوم وسورة الملك',
          body: 'باسمك ربي وضعت جنبي وبك أرفعه.. اختم يومك بذكر الله وتلاوة سورة الملك المنجية',
          expandedText:
              '«باسمك ربي وضعت جنبي وبك أرفعه، فإن أمسكت نفسي فارحمها وإن أرسلتها فاحفظها بما تحفظ به عبادك الصالحين»\n\n✨ تلاوة سورة الملك المنجية من عذاب القبر.. اضغط هنا لقراءة أذكار النوم وسورة الملك.',
          summary: '📖 أذكار النوم وسورة الملك',
          actionLabel: '📖 فتح أذكار النوم',
          payload: 'sleep_azkar',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🌙 የእንቅልፍ አዝካር እና ሱረቱል ሙልክ',
          body: 'በስምህ ጌታዬ ሆይ ጎኔን አሳረፍኩ.. ቀንዎን በአላህ ማስታወስ እና ሱረቱል ሙልክን በማንበብ ያጠናቅቁ።',
          expandedText:
              '«ቢስሚከ ረቢ ወደዕቱ ጀምቢ ወቢከ አርፈዑህ..»\n\n✨ ከቀብር ቅጣት የምታድነውን ሱረቱል ሙልክን ይቅሩ.. የእንቅልፍ አዝካርን እና ሱረቱል ሙልክን ለማንበብ እዚህ ይጫኑ።',
          summary: '📖 የእንቅልፍ አዝካር እና ሱረቱል ሙልክ',
          actionLabel: '📖 የእንቅልፍ አዝካርን ክፈት',
          payload: 'sleep_azkar',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🌙 Azkaara Rafuu fi Suuraa Al-Mulk',
          body: 'Yaa Rabbii maqaa keetiin ciise.. Guyyaa kee zikrii fi Suuraa Al-Mulk qara\'uun xumuri.',
          expandedText:
              '«Bismika Rabbii wada\'tu jambii wa bika arfa\'uh..»\n\n✨ Suuraa Al-Mulk azaaba qabrii irraa nama baraartu qara\'aa.. Azkaara rafuu guutuu qara\'uuf as tuqaa.',
          summary: '📖 Azkaara Rafuu fi Suuraa Al-Mulk',
          actionLabel: '📖 Azkaara Rafuu Bani',
          payload: 'sleep_azkar',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🌙 Sleep Adhkar & Surah Al-Mulk',
          body: 'In Your name, my Lord, I lie down. Conclude your day with the remembrance of Allah and Surah Al-Mulk.',
          expandedText:
              '«In Your name, my Lord, I lie down and in Your name I rise. If You take my soul, have mercy upon it, and if You release it, protect it..»\n\n✨ Recite Surah Al-Mulk, the protector from the punishment of the grave. Tap here to read.',
          summary: '📖 Sleep Adhkar & Surah Al-Mulk',
          actionLabel: '📖 Open Sleep Adhkar',
          payload: 'sleep_azkar',
        );
    }
  }

  static IslamicReminderContent _getFridayKahf(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🕌 جمعة مباركة: سورة الكهف والصلاة على النبي ﷺ',
          body: 'نور ما بين الجمعتين.. أكثروا من الصلاة على الحبيب المصطفى ﷺ واقرؤوا سورة الكهف',
          payload: 'friday_kahf',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🕌 ጁምዓ ሙባረክ፡ ሱረቱል ካህፍ እና ሰለዋት',
          body: 'በሁለቱ ጁምዓዎች መካከል ያለ ብርሃን.. በነቢዩ ﷺ ላይ ሰለዋት ያብዙ፣ ሱረቱል ካህፍንም ያንብቡ።',
          payload: 'friday_kahf',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🕌 Juma\'aa Gaarii: Suuraa Al-Kahf fi Salawaata',
          body: 'Ifaa Juma\'aa lamaan gidduu.. Nabiyyii ﷺ irratti salawaata baay\'isaa, Suuraa Al-Kahfis qara\'aa.',
          payload: 'friday_kahf',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🕌 Blessed Friday: Surah Al-Kahf & Salawat',
          body: 'A light between two Fridays. Send abundant blessings upon the Prophet ﷺ and recite Surah Al-Kahf.',
          payload: 'friday_kahf',
        );
    }
  }

  static IslamicReminderContent _getMondayFasting(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🌿 صيام الاثنين المبارك',
          body: 'غداً الاثنين يُستحب صيامه، تُعرض فيه الأعمال على الله عز وجل',
          payload: 'fasting_reminder',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🌿 የተባረከው የሰኞ ፆም',
          body: 'ነገ ሰኞ የሱና ፆም ቀን ነው፤ ስራዎች ወደ አላህ የሚቀርቡበት የተባረከ ቀን።',
          payload: 'fasting_reminder',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🌿 Sooma Wixata Barakaa',
          body: 'Bori Wixata, guyyaa soomana sunnaa hojiin gara Rabbii dhihaatu dha.',
          payload: 'fasting_reminder',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🌿 Virtues of Monday Fasting',
          body: 'Tomorrow is Monday, a Sunnah day of fasting when deeds are presented to Allah.',
          payload: 'fasting_reminder',
        );
    }
  }

  static IslamicReminderContent _getThursdayFasting(String lang) {
    switch (lang) {
      case 'ar':
        return const IslamicReminderContent(
          title: '🌿 صيام الخميس المبارك',
          body: 'غداً الخميس يُستحب صيامه، لا تفوت أجر الصيام وعظيم الثواب',
          payload: 'fasting_reminder',
        );
      case 'am':
        return const IslamicReminderContent(
          title: '🌿 የተባረከው የሐሙስ ፆም',
          body: 'ነገ ሐሙስ የሱና ፆም ቀን ነው፤ ታላቁን ምንዳ እንዳያመልጥዎ።',
          payload: 'fasting_reminder',
        );
      case 'om':
        return const IslamicReminderContent(
          title: '🌿 Sooma Kamisa Barakaa',
          body: 'Bori Kamisa, guyyaa soomana sunnaa ti. Mindaa guddaa kana hin dhabinaa.',
          payload: 'fasting_reminder',
        );
      case 'en':
      default:
        return const IslamicReminderContent(
          title: '🌿 Virtues of Thursday Fasting',
          body: 'Tomorrow is Thursday, a Sunnah day of fasting. Do not miss the tremendous reward.',
          payload: 'fasting_reminder',
        );
    }
  }
}
