// lib/services/reciter_english_directory.dart
// ─────────────────────────────────────────────────────────────────────────────
// Comprehensive English transliterations, search aliases, and curated iconic
// Quran reciters for multi-lingual search and library enrichment.
// ─────────────────────────────────────────────────────────────────────────────

import '../models/minbar_models.dart';

class ReciterInfo {
  final String englishName;
  final String searchKeywords;

  const ReciterInfo({
    required this.englishName,
    required this.searchKeywords,
  });
}

class ReciterEnglishDirectory {
  static const Map<int, ReciterInfo> directory = {
    1: ReciterInfo(englishName: 'Ahmad Al-Hawashi', searchKeywords: 'ahmad hawashi hawashy'),
    2: ReciterInfo(englishName: 'Ahmad Al-Tarabulsi', searchKeywords: 'ahmad tarabulsi trabulsi trabelsi'),
    3: ReciterInfo(englishName: 'Ahmad Al-Ajmi', searchKeywords: 'ahmad bin ali al-ajmi ahmed alajmi ajmi ajmy'),
    4: ReciterInfo(englishName: 'Ahmad Khidr Al-Tarabulsi', searchKeywords: 'ahmad khidr al-tarabulsi trablsi qaloon'),
    5: ReciterInfo(englishName: 'Ahmad Saber', searchKeywords: 'ahmad saber ahmed saber'),
    6: ReciterInfo(englishName: 'Ahmad Amer', searchKeywords: 'ahmad amer aamer'),
    7: ReciterInfo(englishName: 'Ahmad Naina', searchKeywords: 'ahmad naina naenaa naeena'),
    8: ReciterInfo(englishName: 'Akram Al-Alaqmi', searchKeywords: 'akram al-alaqmi alaqmi alakmy'),
    9: ReciterInfo(englishName: 'Ibrahim Al-Akhdar', searchKeywords: 'ibrahim al-akhdar akhdar'),
    10: ReciterInfo(englishName: 'Ibrahim Al-Dosari (Warsh)', searchKeywords: 'ibrahim al-dosari dosari dossary dossari warsh'),
    11: ReciterInfo(englishName: 'Ibrahim Al-Dosari (Hafs)', searchKeywords: 'ibrahim al-dosari dosari dossary dossari hafs'),
    12: ReciterInfo(englishName: 'Abu Bakr Al-Shatri', searchKeywords: 'abu bakr al-shatri abubakr shatri shatry'),
    13: ReciterInfo(englishName: 'Al-Dokali Muhammad Al-Alim', searchKeywords: 'al-dokali muhammad al-alim dokali doukkali'),
    14: ReciterInfo(englishName: 'Al-Zain Muhammad Ahmad', searchKeywords: 'al-zain muhammad ahmad alzain zain zayn'),
    15: ReciterInfo(englishName: 'Al-Uyun Al-Kushi', searchKeywords: 'al-uyun al-kushi laayoun kouchi koshi koushi'),
    16: ReciterInfo(englishName: 'Al-Fateh Muhammad Al-Zubair', searchKeywords: 'al-fateh muhammad al-zubair fateh zubair zubeir'),
    17: ReciterInfo(englishName: 'Al-Qari Yassen', searchKeywords: 'al-qari yassen yasin yasseen qari'),
    18: ReciterInfo(englishName: 'Tawfeeq Al-Sayegh', searchKeywords: 'tawfeeq al-sayegh tawfiq sayegh twfeeq'),
    19: ReciterInfo(englishName: 'Jamal Shaker Abdullah', searchKeywords: 'jamal shaker abdullah jamal'),
    20: ReciterInfo(englishName: 'Jamaan Al-Osaimi', searchKeywords: 'jamaan al-osaimi osaimi jaman usaimi'),
    21: ReciterInfo(englishName: 'Hatem Farid Al-Waer', searchKeywords: 'hatem farid al-waer hatim fareed waer'),
    22: ReciterInfo(englishName: 'Khaled Al-Qahtani', searchKeywords: 'khaled al-qahtani qahtani qht'),
    23: ReciterInfo(englishName: 'Khaled Al-Muhanna', searchKeywords: 'khaled al-muhanna mohna muhanna'),
    24: ReciterInfo(englishName: 'Khaled Abdel Kafi', searchKeywords: 'khaled abdel kafi kafi abdulkafi'),
    25: ReciterInfo(englishName: 'Khalifa Al-Tunaiji', searchKeywords: 'khalifa al-tunaiji tunaiji tnjy'),
    26: ReciterInfo(englishName: 'Rami Al-Dais', searchKeywords: 'rami al-dais rami dees'),
    27: ReciterInfo(englishName: 'Zaki Daghistani', searchKeywords: 'zaki daghistani daghestani zaki'),
    28: ReciterInfo(englishName: 'Saad Al-Ghamdi', searchKeywords: 'saad al-ghamdi saad al ghamdi ghamdi ghamdy s_gmd'),
    29: ReciterInfo(englishName: 'Saud Al-Shuraim', searchKeywords: 'saud al-shuraim saud shuraim shuraym shuraim shur'),
    30: ReciterInfo(englishName: 'Sahl Yassin', searchKeywords: 'sahl yassin sahl yasin'),
    31: ReciterInfo(englishName: 'Sayed Ramadan', searchKeywords: 'sayed ramadan saeed ramadan'),
    32: ReciterInfo(englishName: 'Shirzad Abdul Rahman Taher', searchKeywords: 'shirzad abdul rahman taher taher'),
    33: ReciterInfo(englishName: 'Saber Abdul Hakam', searchKeywords: 'saber abdul hakam saber hakam'),
    34: ReciterInfo(englishName: 'Salah Al-Budair', searchKeywords: 'salah al-budair budair budayr s_bud'),
    35: ReciterInfo(englishName: 'Salah Al-Hashim', searchKeywords: 'salah al-hashim hashim hashem'),
    36: ReciterInfo(englishName: 'Salah Bukhatir', searchKeywords: 'salah bukhatir bu khatir bu_khtr bakhatir'),
    37: ReciterInfo(englishName: 'Tariq Abdul Ghani Daoub', searchKeywords: 'tariq abdul ghani daoub tareq daoub'),
    38: ReciterInfo(englishName: 'Adel Al-Kalbani', searchKeywords: 'adel al-kalbani kalbani a_klb'),
    39: ReciterInfo(englishName: 'Adel Rayan', searchKeywords: 'adel ryan ryan rayan'),
    40: ReciterInfo(englishName: 'Abdul Bari Al-Thubaiti', searchKeywords: 'abdul bari al-thubaiti thubaiti thubti'),
    41: ReciterInfo(englishName: 'Abdul Bari Muhammad', searchKeywords: 'abdul bari muhammad bari'),
    42: ReciterInfo(englishName: 'Abdul Basit Abdul Samad', searchKeywords: 'abdul basit abdul samad abdulbasit abdulsamad basit murattal'),
    43: ReciterInfo(englishName: 'Abdul Basit Abdul Samad (Warsh)', searchKeywords: 'abdul basit abdul samad abdulbasit abdulsamad warsh'),
    44: ReciterInfo(englishName: 'Abdul Basit Abdul Samad (Mujawwad)', searchKeywords: 'abdul basit abdul samad abdulbasit abdulsamad mujawwad tajweed'),
    45: ReciterInfo(englishName: 'Abdul Rahman Al-Sudais', searchKeywords: 'abdul rahman al-sudais abdulrahman alsudais sudais sudaisi sds'),
    46: ReciterInfo(englishName: 'Abdul Rahman Al-Oosi', searchKeywords: 'abdul rahman al-oosi aloosi oosi awsi al-awsi'),
    47: ReciterInfo(englishName: 'Abdul Rahman Al-Majed', searchKeywords: 'abdul rahman al-majed majed a_majed'),
    48: ReciterInfo(englishName: 'Abdul Rashid Soufi (Khalaf)', searchKeywords: 'abdul rashid soufi abdurrashid sufi khalaf'),
    49: ReciterInfo(englishName: 'Abdul Rashid Soufi (Sousi)', searchKeywords: 'abdul rashid soufi abdurrashid sufi sousi'),
    50: ReciterInfo(englishName: 'Abdul Aziz Al-Ahmad', searchKeywords: 'abdul aziz al-ahmad ahmad a_ahmed'),
    51: ReciterInfo(englishName: 'Abdul Aziz Al-Zahrani', searchKeywords: 'abdul aziz al-zahrani zahrani zaharani'),
    52: ReciterInfo(englishName: 'Abdullah Al-Khalaf', searchKeywords: 'abdullah al-khalaf khalf'),
    53: ReciterInfo(englishName: 'Abdullah Al-Kandari', searchKeywords: 'abdullah al-kandari kandari kandary'),
    54: ReciterInfo(englishName: 'Abdullah Basfar', searchKeywords: 'abdullah basfar basfar bsfr'),
    55: ReciterInfo(englishName: 'Abdullah Khayyat', searchKeywords: 'abdullah khayyat kyat khayat'),
    56: ReciterInfo(englishName: 'Abdullah Awad Al-Juhani', searchKeywords: 'abdullah awad al-juhani juhani johany jhn'),
    57: ReciterInfo(englishName: 'Abdul Mohsen Al-Harthi', searchKeywords: 'abdul mohsen al-harthi harthi mohsin'),
    58: ReciterInfo(englishName: 'Abdul Mohsen Al-Obeikan', searchKeywords: 'abdul mohsen al-obeikan obeikan obk'),
    59: ReciterInfo(englishName: 'Abdul Mohsen Al-Qasim', searchKeywords: 'abdul mohsen al-qasim qasim qasm'),
    60: ReciterInfo(englishName: 'Abdul Hadi Kanakeri', searchKeywords: 'abdul hadi kanakeri kanakeri kankary'),
    61: ReciterInfo(englishName: 'Abdul Wadood Haneef', searchKeywords: 'abdul wadood haneef wadood wdod hanif'),
    62: ReciterInfo(englishName: 'Ali Al-Hudhaifi (Qaloon)', searchKeywords: 'ali al-hudhaifi hudhaifi hudhaify hothifi qaloon'),
    63: ReciterInfo(englishName: 'Ali Al-Hudhaifi (Hafs)', searchKeywords: 'ali al-hudhaifi hudhaifi hudhaify hothifi hafs hthfi'),
    64: ReciterInfo(englishName: 'Ali Jaber', searchKeywords: 'ali jaber ali abdullah jaber jbr jabir'),
    65: ReciterInfo(englishName: 'Ali Hajjaj Al-Suwaisi', searchKeywords: 'ali hajjaj al-suwaisi hajjaj suwaisi'),
    66: ReciterInfo(englishName: 'Emad Zuhair Hafez', searchKeywords: 'emad zuhair hafez hafz hafidz'),
    67: ReciterInfo(englishName: 'Omar Al-Qazabri', searchKeywords: 'omar al-qazabri qazabri kozabri kazabri warsh'),
    68: ReciterInfo(englishName: 'Fares Abbad', searchKeywords: 'fares abbad faris abbad abbad frs'),
    69: ReciterInfo(englishName: 'Maher Al-Muaiqly', searchKeywords: 'maher al-muaiqly maher al muaiqly muaiqly mueaqly maheer'),
    70: ReciterInfo(englishName: 'Maher Shakhashero', searchKeywords: 'maher shakhashero shaksh'),
    71: ReciterInfo(englishName: 'Muhammad Ayyub', searchKeywords: 'muhammad ayyub mohammad ayub ayyub ayub'),
    72: ReciterInfo(englishName: 'Mohammad Al-Tablawi', searchKeywords: 'mohammad al-tablawi mohamed tablawi tblawi'),
    73: ReciterInfo(englishName: 'Muhammad Al-Luhaidan', searchKeywords: 'muhammad al-luhaidan mohammed luhaidan lhdan lahidan'),
    74: ReciterInfo(englishName: 'Muhammad Jibril', searchKeywords: 'muhammad jibril mohamed jebril jbrl jebril'),
    75: ReciterInfo(englishName: 'Muhammad Rashad Al-Shareef', searchKeywords: 'muhammad rashad al-shareef rashad sharif'),
    76: ReciterInfo(englishName: 'Muhammad Saleh Shah', searchKeywords: 'muhammad saleh shah shah'),
    77: ReciterInfo(englishName: 'Mohamed Siddiq Al-Minshawi', searchKeywords: 'mohamed siddiq al-minshawi muhammad minshawi minshawi murattal'),
    78: ReciterInfo(englishName: 'Mohamed Siddiq Al-Minshawi (Mujawwad)', searchKeywords: 'mohamed siddiq al-minshawi muhammad minshawi minshawi mujawwad tajweed'),
    79: ReciterInfo(englishName: 'Muhammad Abdul Hakim Saeed (Douri)', searchKeywords: 'muhammad abdul hakim saeed douri'),
    80: ReciterInfo(englishName: 'Muhammad Abdul Hakim Saeed', searchKeywords: 'muhammad abdul hakim saeed bazi'),
    81: ReciterInfo(englishName: 'Muhammad Abdul Karim (Warsh)', searchKeywords: 'muhammad abdul karim kreem abdulkarim warsh'),
    82: ReciterInfo(englishName: 'Muhammad Abdul Karim (Hafs)', searchKeywords: 'muhammad abdul karim krm abdulkarim hafs'),
    83: ReciterInfo(englishName: 'Muhammad Othman Khan', searchKeywords: 'muhammad othman khan khan usman'),
    84: ReciterInfo(englishName: 'Mahmoud Al-Rifai', searchKeywords: 'mahmoud al-rifai rifai rifay'),
    85: ReciterInfo(englishName: 'Mahmoud Al-Sheimy', searchKeywords: 'mahmoud al-sheimy sheimy shimy'),
    86: ReciterInfo(englishName: 'Mahmoud Khalil Al-Husary', searchKeywords: 'mahmoud khalil al-husary al-hosary husary hosary hossary husr'),
    87: ReciterInfo(englishName: 'Mahmoud Khalil Al-Husary (Warsh)', searchKeywords: 'mahmoud khalil al-husary al-hosary husary hosary warsh'),
    88: ReciterInfo(englishName: 'Mahmoud Khalil Al-Husary (Mujawwad)', searchKeywords: 'mahmoud khalil al-husary al-hosary husary hosary mujawwad tajweed'),
    89: ReciterInfo(englishName: 'Mahmoud Ali Al-Banna', searchKeywords: 'mahmoud ali al-banna al-banna banna bna'),
    90: ReciterInfo(englishName: 'Mahmoud Ali Al-Banna (Mujawwad)', searchKeywords: 'mahmoud ali al-banna al-banna banna bna mujawwad'),
    91: ReciterInfo(englishName: 'Mishary Alafasy', searchKeywords: 'mishary alafasy mishary rashid alafasy alafasi afasi afasy afs mashary'),
    92: ReciterInfo(englishName: 'Mustafa Ismail', searchKeywords: 'mustafa ismail mostafa ismail ismaeel'),
    93: ReciterInfo(englishName: 'Mustafa Al-Lahoni', searchKeywords: 'mustafa al-lahoni lahoni lahoni'),
    94: ReciterInfo(englishName: 'Mustafa Raad Al-Azzawi', searchKeywords: 'mustafa raad al-azzawi azzawi azawi'),
    95: ReciterInfo(englishName: 'Muidh Al-Harthi', searchKeywords: 'muidh al-harthi harthi moaed'),
    96: ReciterInfo(englishName: 'Muftah Al-Saltani', searchKeywords: 'muftah al-saltani saltani sultany thakwan'),
    97: ReciterInfo(englishName: 'Muftah Al-Saltani (Hafs)', searchKeywords: 'muftah al-saltani saltani sultany hafs'),
    98: ReciterInfo(englishName: 'Muftah Al-Saltani (Douri Abu Amr)', searchKeywords: 'muftah al-saltani saltani sultany douri'),
    99: ReciterInfo(englishName: 'Muftah Al-Saltani (Douri Kisai)', searchKeywords: 'muftah al-saltani saltani sultany douri kisai'),
    100: ReciterInfo(englishName: 'Musa Bilal', searchKeywords: 'musa bilal bilal mousa'),
    101: ReciterInfo(englishName: 'Nasser Al-Qatami', searchKeywords: 'nasser al-qatami nasir alqatami qatami qatamy qtm'),
    102: ReciterInfo(englishName: 'Nabil Al-Rifai', searchKeywords: 'nabil al-rifai rifai rifay'),
    103: ReciterInfo(englishName: 'Neamah Al-Hassan', searchKeywords: 'neamah al-hassan namh nima hassan'),
    104: ReciterInfo(englishName: 'Hani Ar-Rifai', searchKeywords: 'hani ar-rifai hani rifai rifay hany'),
    105: ReciterInfo(englishName: 'Wadih Al-Yamani', searchKeywords: 'wadih al-yamani wadih yamani wadee yemeni'),
    106: ReciterInfo(englishName: 'Waleed Al-Naehi', searchKeywords: 'waleed al-naehi waleed naihi'),
    107: ReciterInfo(englishName: 'Yasser Al-Dossari', searchKeywords: 'yasser al-dossari yaser al dosari dosari dossary al-dosari yasser'),
    108: ReciterInfo(englishName: 'Yasser Al-Qurashi', searchKeywords: 'yasser al-qurashi qurashi qorashi'),
    109: ReciterInfo(englishName: 'Yasser Al-Mazrouei', searchKeywords: 'yasser al-mazrouei mazroyee mazroui'),
    110: ReciterInfo(englishName: 'Yahya Hawwa', searchKeywords: 'yahya hawwa yahya hawa'),
    111: ReciterInfo(englishName: 'Yousef Al-Showaie', searchKeywords: 'yousef al-showaie showaie yousef shoaey'),
    112: ReciterInfo(englishName: 'Yousef Bin Noah Ahmad', searchKeywords: 'yousef bin noah ahmad noah'),
    // Additional Iconic Reciters
    113: ReciterInfo(englishName: 'Idris Abkar', searchKeywords: 'idris abkar idrees abkar edrees abkar abkar'),
    114: ReciterInfo(englishName: 'Bandar Baleela', searchKeywords: 'bandar baleela bandar balilah baleelah baleela imam makkah'),
    115: ReciterInfo(englishName: 'Khalid Al-Jalil', searchKeywords: 'khalid al-jalil khaled jalil jaleel al-jaleel'),
    116: ReciterInfo(englishName: 'Raad Al-Kurdi', searchKeywords: 'raad al-kurdi raad kurdi mohammad kurdi'),
    117: ReciterInfo(englishName: 'Hazza Al-Balushi', searchKeywords: 'hazza al-balushi hazza balushi albalushi'),
    118: ReciterInfo(englishName: 'Mansour Al-Salimi', searchKeywords: 'mansour al-salimi mansur salimi mansoor'),
    119: ReciterInfo(englishName: 'Islam Sobhi', searchKeywords: 'islam sobhi islam subhi sobhy eslam subhi'),
  };

  /// Additional curated reciters who have high quality global CDNs on MP3Quran
  static const List<MinbarAuthor> additionalReciters = [
    MinbarAuthor(
      id: '113',
      name: 'إدريس أبكر',
      englishName: 'Idris Abkar',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'idrees-abkar',
    ),
    MinbarAuthor(
      id: '114',
      name: 'بندر بليلة',
      englishName: 'Bandar Baleela',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'bandar-baleela',
    ),
    MinbarAuthor(
      id: '115',
      name: 'خالد الجليل',
      englishName: 'Khalid Al-Jalil',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'khalid-jalil',
    ),
    MinbarAuthor(
      id: '116',
      name: 'رعد محمد الكردي',
      englishName: 'Raad Al-Kurdi',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'raad-kurdi',
    ),
    MinbarAuthor(
      id: '117',
      name: 'هزاع البلوشي',
      englishName: 'Hazza Al-Balushi',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'hazza-balushi',
    ),
    MinbarAuthor(
      id: '118',
      name: 'منصور السالمي',
      englishName: 'Mansour Al-Salimi',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'mansour-salimi',
    ),
    MinbarAuthor(
      id: '119',
      name: 'إسلام صبحي',
      englishName: 'Islam Sobhi',
      type: 'حفص عن عاصم',
      serverNum: 'cdn',
      engName: 'islam-sobhi',
    ),
  ];

  static String? getEnglishName(dynamic id) {
    final intId = id is int ? id : int.tryParse(id.toString());
    if (intId == null) return null;
    return directory[intId]?.englishName;
  }

  static MinbarAuthor? getAdditionalReciter(dynamic id) {
    final strId = id.toString();
    for (final r in additionalReciters) {
      if (r.id == strId) return r;
    }
    return null;
  }

  /// Normalizes Arabic strings (strips diacritics, unifies alifs and yeh)
  static String normalizeArabic(String text) {
    var s = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // Tashkeel
    s = s.replaceAll('ـ', ''); // Tatweel
    s = s.replaceAll(RegExp(r'[إأآا]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    return s.toLowerCase().trim();
  }

  /// Normalizes English strings (lowercase, removes hyphens, dots, common prefixes)
  static String normalizeEnglish(String text) {
    var s = text.toLowerCase().trim();
    s = s.replaceAll(RegExp(r"['\-_.]"), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  /// Comprehensive multi-lingual search matching Arabic & English names + aliases
  static bool matches(MinbarAuthor author, String query) {
    if (query.isEmpty) return true;

    final trimmedQuery = query.trim();
    final normQueryAr = normalizeArabic(trimmedQuery);
    final normQueryEn = normalizeEnglish(trimmedQuery);

    // 1. Check Arabic name
    final normAuthorAr = normalizeArabic(author.name);
    if (normAuthorAr.contains(normQueryAr)) return true;

    // 2. Check type / Riwayah
    if (author.type != null) {
      final normType = normalizeArabic(author.type!);
      if (normType.contains(normQueryAr)) return true;
    }

    // 3. Check English name & keywords
    final intId = int.tryParse(author.id);
    final info = intId != null ? directory[intId] : null;

    final engName = author.englishName ?? info?.englishName;
    if (engName != null) {
      final normEng = normalizeEnglish(engName);
      if (normEng.contains(normQueryEn)) return true;
    }

    if (info != null) {
      final normKeywords = normalizeEnglish(info.searchKeywords);
      if (normKeywords.contains(normQueryEn)) return true;
    }

    // 4. Fallback check on engName folder slug
    if (author.engName != null) {
      final slugClean = normalizeEnglish(author.engName!);
      if (slugClean.contains(normQueryEn)) return true;
    }

    return false;
  }
}
