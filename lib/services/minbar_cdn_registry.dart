// lib/services/minbar_cdn_registry.dart
// ─────────────────────────────────────────────────────────────────────────────
// MinbarCdnRegistry — High-speed verified CDN endpoints for all 112 reciters.
// Resolves official global Cloudflare CDN audio streams with instant fallbacks.
// ─────────────────────────────────────────────────────────────────────────────

class MinbarReciterEndpoint {
  final String cdnUrl;
  final String fallbackUrl;

  const MinbarReciterEndpoint({
    required this.cdnUrl,
    required this.fallbackUrl,
  });
}

class MinbarCdnRegistry {
  static const Map<int, MinbarReciterEndpoint> endpoints = {
    1: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-hawashi/r1',
      fallbackUrl: 'https://server11.mp3quran.net/hawashi',
    ),
    2: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-tarabulsi/r2',
      fallbackUrl: 'https://server10.mp3quran.net/trabulsi',
    ),
    3: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-ajmi/r1',
      fallbackUrl: 'https://server10.mp3quran.net/ajm/128',
    ),
    4: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-tarabulsi/r1',
      fallbackUrl: 'https://server10.mp3quran.net/trablsi',
    ),
    5: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-saber/r1',
      fallbackUrl: 'https://server8.mp3quran.net/saber',
    ),
    6: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-amer/r1',
      fallbackUrl: 'https://server10.mp3quran.net/Aamer',
    ),
    7: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ahmad-naina/r1',
      fallbackUrl: 'https://server11.mp3quran.net/ahmad_nu',
    ),
    8: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/akram-alaqmi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/akrm',
    ),
    9: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ibrahim-akhdar/r1',
      fallbackUrl: 'https://server6.mp3quran.net/akdr',
    ),
    10: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ibrahim-dosari/r1',
      fallbackUrl: 'https://server10.mp3quran.net/ibrahim_dosri_warsh',
    ),
    11: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ibrahim-dosari/r2',
      fallbackUrl: 'https://server10.mp3quran.net/ibrahim_dosri_hafs',
    ),
    12: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abubakr-shatri/r1',
      fallbackUrl: 'https://server11.mp3quran.net/shatri',
    ),
    13: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/dokali-alim/r1',
      fallbackUrl: 'https://server7.mp3quran.net/dokali',
    ),
    14: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/zain-ahmad/r1',
      fallbackUrl: 'https://server9.mp3quran.net/alzain',
    ),
    15: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/laayoun-kouchi/r1',
      fallbackUrl: 'https://server11.mp3quran.net/koshi',
    ),
    16: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/fateh-zubair/r1',
      fallbackUrl: 'https://server6.mp3quran.net/fateh',
    ),
    17: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yassen-jazairi/r1',
      fallbackUrl: 'https://server11.mp3quran.net/qari',
    ),
    18: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/tawfeeq-sayegh/r1',
      fallbackUrl: 'https://server6.mp3quran.net/twfeeq',
    ),
    19: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/jamal-abdullah/r1',
      fallbackUrl: 'https://server6.mp3quran.net/jamal',
    ),
    20: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/jamaan-osaimi/r1',
      fallbackUrl: 'https://server6.mp3quran.net/jaman',
    ),
    21: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/hatem-waer/r1',
      fallbackUrl: 'https://server11.mp3quran.net/hatem',
    ),
    22: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/khalid-qahtani/r1',
      fallbackUrl: 'https://server10.mp3quran.net/qht',
    ),
    23: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/khalid-mohanna/r1',
      fallbackUrl: 'https://server11.mp3quran.net/mohna',
    ),
    24: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/khalid-abdulkafi/r1',
      fallbackUrl: 'https://server11.mp3quran.net/kafi',
    ),
    25: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/khalifa-tunaiji/r1',
      fallbackUrl: 'https://server12.mp3quran.net/tnjy',
    ),
    26: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/rami-duais/r1',
      fallbackUrl: 'https://server6.mp3quran.net/rami',
    ),
    27: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/zaki-daghistani/r1',
      fallbackUrl: 'https://server9.mp3quran.net/zaki',
    ),
    28: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/saad-ghamdi/r1',
      fallbackUrl: 'https://server7.mp3quran.net/s_gmd',
    ),
    29: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/saud-shuraim/r1',
      fallbackUrl: 'https://server7.mp3quran.net/shur',
    ),
    30: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/sahl-yassin/r1',
      fallbackUrl: 'https://server6.mp3quran.net/shl',
    ),
    31: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/sayed-ramadan/r1',
      fallbackUrl: 'https://server12.mp3quran.net/sayed',
    ),
    32: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/shirzad-taher/r1',
      fallbackUrl: 'https://server12.mp3quran.net/taher',
    ),
    33: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/saber-abdulhakam/r1',
      fallbackUrl: 'https://server12.mp3quran.net/hkm',
    ),
    34: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/salah-budair/r1',
      fallbackUrl: 'https://server6.mp3quran.net/s_bud',
    ),
    35: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/salah-hashim/r1',
      fallbackUrl: 'https://server12.mp3quran.net/salah_hashim_m',
    ),
    36: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/salah-bukhatir/r1',
      fallbackUrl: 'https://server8.mp3quran.net/bu_khtr',
    ),
    37: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/tareq-daawob/r1',
      fallbackUrl: 'https://server10.mp3quran.net/tareq',
    ),
    38: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/adel-kalbani/r1',
      fallbackUrl: 'https://server8.mp3quran.net/a_klb',
    ),
    39: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/adel-rayyan/r1',
      fallbackUrl: 'https://server8.mp3quran.net/ryan',
    ),
    40: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulbari-thubaiti/r1',
      fallbackUrl: 'https://server6.mp3quran.net/thubti',
    ),
    41: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulbari-muhammad/r1',
      fallbackUrl: 'https://server12.mp3quran.net/bari',
    ),
    42: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r3',
      fallbackUrl: 'https://server7.mp3quran.net/basit',
    ),
    43: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r2',
      fallbackUrl: 'https://server10.mp3quran.net/basit_warsh',
    ),
    44: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r1',
      fallbackUrl: 'https://server13.mp3quran.net/basit_mjwd',
    ),
    45: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulrahman-sudais/r1',
      fallbackUrl: 'https://server11.mp3quran.net/sds',
    ),
    46: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulrahman-oosi/r1',
      fallbackUrl: 'https://server6.mp3quran.net/aloosi',
    ),
    47: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulrahman-majed/r1',
      fallbackUrl: 'https://server10.mp3quran.net/a_majed',
    ),
    48: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulrasheed-sufi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/soufi_klf',
    ),
    49: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulrasheed-sufi/r2',
      fallbackUrl: 'https://server9.mp3quran.net/soufi',
    ),
    50: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulaziz-ahmad/r1',
      fallbackUrl: 'https://server11.mp3quran.net/a_ahmed',
    ),
    51: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulaziz-zahrani/r1',
      fallbackUrl: 'https://server9.mp3quran.net/zahrani',
    ),
    52: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdullah-khalaf/r1',
      fallbackUrl: 'https://server14.mp3quran.net/khalf',
    ),
    53: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdullah-kandari/r1',
      fallbackUrl: 'https://server10.mp3quran.net/Abdullahk',
    ),
    54: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdullah-basfar/r1',
      fallbackUrl: 'https://server6.mp3quran.net/bsfr',
    ),
    55: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdullah-khayyat/r1',
      fallbackUrl: 'https://server12.mp3quran.net/kyat',
    ),
    56: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdullah-juhani/r1',
      fallbackUrl: 'https://server13.mp3quran.net/jhn',
    ),
    57: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulmohsen-harthi/r1',
      fallbackUrl: 'https://server6.mp3quran.net/mohsin_harthi',
    ),
    58: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulmohsen-obaikan/r1',
      fallbackUrl: 'https://server12.mp3quran.net/obk',
    ),
    59: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulmohsen-qasim/r1',
      fallbackUrl: 'https://server8.mp3quran.net/qasm',
    ),
    60: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulhadi-kanakeri/r1',
      fallbackUrl: 'https://server6.mp3quran.net/kanakeri',
    ),
    61: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/abdulwadood-haneef/r1',
      fallbackUrl: 'https://server8.mp3quran.net/wdod',
    ),
    62: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ali-hudhaifi/r2',
      fallbackUrl: 'https://server9.mp3quran.net/huthifi_qalon',
    ),
    63: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ali-hudhaifi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/hthfi',
    ),
    64: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ali-jaber/r1',
      fallbackUrl: 'https://server11.mp3quran.net/a_jbr',
    ),
    65: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/ali-souissi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/hajjaj',
    ),
    66: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/imad-hafez/r1',
      fallbackUrl: 'https://server6.mp3quran.net/hafz',
    ),
    67: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/omar-kazabri/r1',
      fallbackUrl: 'https://server9.mp3quran.net/omar_warsh',
    ),
    68: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/fares-abbad/r1',
      fallbackUrl: 'https://server8.mp3quran.net/frs_a',
    ),
    69: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/maher-muaiqly/r1',
      fallbackUrl: 'https://server12.mp3quran.net/maher',
    ),
    70: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/maher-shakhashiro/r1',
      fallbackUrl: 'https://server10.mp3quran.net/shaksh',
    ),
    71: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-ayyub/r2',
      fallbackUrl: 'https://server8.mp3quran.net/ayyub',
    ),
    72: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-tablawi/r1',
      fallbackUrl: 'https://server12.mp3quran.net/tblawi',
    ),
    73: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-luhaidan/r1',
      fallbackUrl: 'https://server8.mp3quran.net/lhdan',
    ),
    74: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-jibreel/r1',
      fallbackUrl: 'https://server8.mp3quran.net/jbrl',
    ),
    75: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-shareef/r1',
      fallbackUrl: 'https://server10.mp3quran.net/rashad',
    ),
    76: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-shah/r1',
      fallbackUrl: 'https://server12.mp3quran.net/shah',
    ),
    77: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/minshawi/r1',
      fallbackUrl: 'https://server10.mp3quran.net/minsh',
    ),
    78: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/minshawi/r2',
      fallbackUrl: 'https://server11.mp3quran.net/minsh_mjwd',
    ),
    79: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-abdullah/r2',
      fallbackUrl: 'https://server12.mp3quran.net/abdullah_dori',
    ),
    80: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-abdullah/r1',
      fallbackUrl: 'https://server9.mp3quran.net/abdullah',
    ),
    81: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-abdulkareem/r2',
      fallbackUrl: 'https://server7.mp3quran.net/m_kreem_warsh',
    ),
    82: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-abdulkareem/r1',
      fallbackUrl: 'https://server12.mp3quran.net/m_krm',
    ),
    83: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muhammad-khan/r1',
      fallbackUrl: 'https://server6.mp3quran.net/khan',
    ),
    84: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-rifai/r1',
      fallbackUrl: 'https://server11.mp3quran.net/mrifai',
    ),
    85: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-sheimy/r1',
      fallbackUrl: 'https://server10.mp3quran.net/sheimy',
    ),
    86: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r1',
      fallbackUrl: 'https://server13.mp3quran.net/husr',
    ),
    87: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r3',
      fallbackUrl: 'https://server9.mp3quran.net/husr_warsh',
    ),
    88: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-husary/r2',
      fallbackUrl: 'https://server9.mp3quran.net/husr_mjwd',
    ),
    89: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-banna/r1',
      fallbackUrl: 'https://server8.mp3quran.net/bna',
    ),
    90: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mahmoud-banna/r2',
      fallbackUrl: 'https://server8.mp3quran.net/bna_mjwd',
    ),
    91: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mishary-alafasy/r1',
      fallbackUrl: 'https://server8.mp3quran.net/afs',
    ),
    92: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mustafa-ismail/r1',
      fallbackUrl: 'https://server8.mp3quran.net/mustafa',
    ),
    93: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mustafa-lahouni/r1',
      fallbackUrl: 'https://server6.mp3quran.net/lahoni',
    ),
    94: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/mustafa-azzawi/r1',
      fallbackUrl: 'https://server8.mp3quran.net/ra3ad',
    ),
    95: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/moeedh-harthi/r1',
      fallbackUrl: 'https://server8.mp3quran.net/harthi',
    ),
    96: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muftah-saltani/r5',
      fallbackUrl: 'https://server11.mp3quran.net/muftah_thakwan',
    ),
    97: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muftah-saltani/r3',
      fallbackUrl: 'https://server10.mp3quran.net/muftah',
    ),
    98: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muftah-saltani/r1',
      fallbackUrl: 'https://server9.mp3quran.net/sultany',
    ),
    99: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/muftah-saltani/r2',
      fallbackUrl: 'https://server6.mp3quran.net/saltany_kisaia',
    ),
    100: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/musa-bilal/r1',
      fallbackUrl: 'https://server11.mp3quran.net/bilal',
    ),
    101: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/nasser-qatami/r1',
      fallbackUrl: 'https://server6.mp3quran.net/qtm',
    ),
    102: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/nabil-rifai/r1',
      fallbackUrl: 'https://server9.mp3quran.net/nabil',
    ),
    103: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/neama-hassan/r1',
      fallbackUrl: 'https://server8.mp3quran.net/namh',
    ),
    104: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/hani-rifai/r1',
      fallbackUrl: 'https://server8.mp3quran.net/hani',
    ),
    105: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/wadee-yamani/r1',
      fallbackUrl: 'https://server6.mp3quran.net/wdee3',
    ),
    106: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/waleed-naehi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/waleed',
    ),
    107: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yasser-dosari/r1',
      fallbackUrl: 'https://server11.mp3quran.net/yasser',
    ),
    108: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yasser-qurashi/r1',
      fallbackUrl: 'https://server9.mp3quran.net/qurashi',
    ),
    109: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yasser-mazrouei/r1',
      fallbackUrl: 'https://server9.mp3quran.net/mzroyee',
    ),
    110: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yahya-hawwa/r1',
      fallbackUrl: 'https://server12.mp3quran.net/yahya',
    ),
    111: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yousef-shoaey/r1',
      fallbackUrl: 'https://server9.mp3quran.net/yousef',
    ),
    112: MinbarReciterEndpoint(
      cdnUrl: 'https://cdn.mp3quran.net/audio/yousef-ahmad/r1',
      fallbackUrl: 'https://server8.mp3quran.net/noah',
    ),
  };

  /// Returns the primary high-speed CDN URL for a given reciter ID and Surah number.
  static String? getPrimarySurahUrl(int reciterId, String surahNum) {
    final ep = endpoints[reciterId];
    if (ep != null) {
      return '${ep.cdnUrl}/$surahNum.mp3';
    }
    return null;
  }

  /// Returns an ordered list of candidate URLs (primary CDN -> fallback mirror -> legacy).
  static List<String> getCandidateUrls(int reciterId, String surahNum, String? defaultUrl) {
    final candidates = <String>[];
    final ep = endpoints[reciterId];
    if (ep != null) {
      candidates.add('${ep.cdnUrl}/$surahNum.mp3');
      final fbUrl = '${ep.fallbackUrl}/$surahNum.mp3';
      if (!candidates.contains(fbUrl)) {
        candidates.add(fbUrl);
      }
    }
    if (defaultUrl != null && defaultUrl.isNotEmpty && !candidates.contains(defaultUrl)) {
      candidates.add(defaultUrl);
    }
    return candidates;
  }
}
