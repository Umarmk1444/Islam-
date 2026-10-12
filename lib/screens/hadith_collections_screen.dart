import 'package:flutter/material.dart';
import '../core/database/hadith_database_helper.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import '../language_notifier.dart';
import 'hadith_books_screen.dart';
import 'hadith_search_screen.dart';

class HadithCollectionsScreen extends StatefulWidget {
  final HadithCollection? initialCollection;
  final int? targetCollectionId;

  const HadithCollectionsScreen({
    super.key,
    this.initialCollection,
    this.targetCollectionId,
  });

  @override
  State<HadithCollectionsScreen> createState() => _HadithCollectionsScreenState();
}

class _HadithCollectionsScreenState extends State<HadithCollectionsScreen> {
  final HadithService _hadithService = HadithService();
  List<HadithCollection> _collections = [];
  bool _isLoading = true;
  bool _needsSetup = false;
  bool _isExtracting = false;
  bool _hasAutoNavigated = false;
  String? _errorMessage;

  static const Map<String, Map<String, String>> _hadithL10n = {
    'ar': {
      'title': 'موسوعة الحديث الشريف',
      'search_tooltip': 'البحث في الحديث الشريف',
      'storage_btn': 'إدارة المساحة',
      'storage_tooltip': 'معلومات الذاكرة وقاعدة البيانات',
      'setup_title': 'موسوعة الحديث الشريف الكبرى',
      'setup_desc': 'تضم الموسوعة الكتب الستة المعتمدة، موطأ مالك، رياض الصالحين، الأدب المفرد، وبلوغ المرام (٤٠,٩٣٧ حديثاً شريفاً بالسند والمتن، مع البحث الذكي وقراءة كاملة بدون إنترنت).',
      'setup_badge': 'قراءة بدون إنترنت • يمكنك مسحها لاحقاً لتوفير المساحة',
      'setup_btn': 'تهيئة الموسوعة والبدء بالقراءة',
      'extracting_title': 'جاري تهيئة موسوعة الحديث الشريف...',
      'extracting_desc': 'يتم استخراج ١٠ دواوين معتمدة (٤٠,٩٣٧ حديثاً شريفاً)\nيستغرق هذا الإجراء بضع ثوانٍ فقط...',
      'loading': 'جاري تحميل الأحاديث الشريفة...',
      'dialog_title': 'إدارة مساحة الحديث الشريف',
      'dialog_desc': 'هل ترغب في توفير مساحة على هاتفك بحذف ملفات الموسوعة المؤقتة؟\n\n• سيتم توفير حوالي ١٨٧ ميجابايت من ذاكرة هاتفك فوراً.\n• مفضلاتك وقراءاتك السابقة ستبقى محفوظة بأمان تام.\n• يمكنك إعادة تهيئة الموسوعة في أي وقت مجاناً وبدون إنترنت.',
      'cancel': 'إلغاء',
      'confirm_delete': 'توفير ~١٨٧ م.ب الآن',
      'snack_deleted': 'تم توفير ١٨٧ ميجابايت بنجاح من ذاكرة الهاتف',
      'section_kutub_sittah': 'الكتب الستة المعتمدة',
      'section_secondary': 'الجوامع والمصنفات الأخرى',
      'banner_badge': '١٠ دواوين معتمدة • ٤٠,٩٣٧ حديثاً شريفاً',
      'banner_title': 'مكتبة السنة النبوية والكتب الستة المعتمدة',
      'banner_desc': 'موسوعة السنن والمصنفات الكبرى مفهرسة بالسند والأبواب الأصلية بدون إنترنت',
      'storage_card_title': 'معلومات التخزين والقراءة بدون إنترنت',
      'storage_card_desc': 'الموسوعة مثبتة بالكامل بدون إنترنت (~١٨٧ م.ب). إذا كنت بحاجة لتوفير مساحة على هاتفك مستقبلاً، يمكنك مسح الملفات مؤقتاً وإعادة تهيئتها بأمان في أي وقت دون فقدان مفضلاتك أو علاماتك.',
      'storage_card_btn': 'إدارة المساحة',
    },
    'en': {
      'title': 'Hadith Encyclopedia',
      'search_tooltip': 'Search Hadith',
      'storage_btn': 'Manage Storage',
      'storage_tooltip': 'Offline storage & database info',
      'setup_title': 'The Grand Hadith Encyclopedia',
      'setup_desc': 'Contains the Six Canonical Books, Muwatta Malik, Riyad as-Salihin, Al-Adab Al-Mufrad, and Bulugh al-Maram (40,937 noble Hadiths with full Isnād, Matn, instant search, and complete offline access).',
      'setup_badge': '100% Offline • You can safely remove it anytime to free up storage',
      'setup_btn': 'Unpack Encyclopedia & Start Reading',
      'extracting_title': 'Unpacking Hadith Encyclopedia...',
      'extracting_desc': 'Preparing 10 canonical collections (40,937 noble Hadiths)\nTakes only a few seconds...',
      'loading': 'Loading Hadith collections...',
      'dialog_title': 'Manage Offline Storage',
      'dialog_desc': 'Would you like to clear offline database files from your phone?\n\n• Instantly frees up ~187 MB of internal storage.\n• Your favorites and reading bookmarks remain completely safe.\n• You can re-unpack the encyclopedia anytime with one tap, 100% offline.',
      'cancel': 'Cancel',
      'confirm_delete': 'Free Up ~187 MB',
      'snack_deleted': 'Hadith database cleared! ~187 MB freed successfully.',
      'section_kutub_sittah': 'The Six Canonical Books',
      'section_secondary': 'Other Compilations & Works',
      'banner_badge': '10 Canonical Collections • 40,937 Hadiths',
      'banner_title': 'Prophetic Sunnah & Canonical Hadith Library',
      'banner_desc': 'Grand encyclopedia indexed with authentic isnad and classical chapters, 100% offline',
      'storage_card_title': 'Offline Storage & Reading Info',
      'storage_card_desc': 'Complete encyclopedia installed offline (~187 MB). If your device is ever low on space, you can temporarily clear files and restore them anytime without losing your bookmarks or favorites.',
      'storage_card_btn': 'Manage Storage',
    },
    'am': {
      'title': 'የሐዲስ ኢንሳይክሎፔዲያ',
      'search_tooltip': 'ሐዲሶችን ፈልግ',
      'storage_btn': 'ማከማቻ አስተዳድር',
      'storage_tooltip': 'የማከማቻ መረጃ እና ዳታቤዝ',
      'setup_title': 'ታላቁ የሐዲስ ኢንሳይክሎፔዲያ',
      'setup_desc': 'ስድስቱን ታላላቅ የሐዲስ መጻሕፍት፣ ሙወጣእ ማሊክ፣ ሪያዱ አስ-ሷሊሒን፣ አል-አደብ አል-ሙፍረድ እና ቡሉግ አል-መራምን ያካትታል (40,937 ትክክለኛ ሐዲሶች ከሙሉ ሰነድ፣ ፈጣን ፍለጋ እና ከመስመር ውጭ ማንበብ ጋር)።',
      'setup_badge': '100% ከመስመር ውጭ • ቦታ ለመቆጠብ በማንኛውም ጊዜ ማጥፋት ይችላሉ',
      'setup_btn': 'ኢንሳይክሎፔዲያውን አዘጋጅተህ ማንበብ ጀምር',
      'extracting_title': 'የሐዲስ መዛግብት በመዘጋጀት ላይ ናቸው...',
      'extracting_desc': '10 የተመረጡ የሐዲስ ስብስቦች (40,937 ሐዲሶች) እየተዘጋጁ ነው\nጥቂት ሰኮንዶች ብቻ ይወስዳል...',
      'loading': 'ሐዲሶች በመጫን ላይ ናቸው...',
      'dialog_title': 'የማከማቻ ቦታ አስተዳድር',
      'dialog_desc': 'ከመስመር ውጭ ያለውን የሐዲስ ዳታቤዝ ከመሳሪያዎ ላይ መሰረዝ ይፈልጋሉ?\n\n• ወዲያውኑ ~187 MB የስልክ ማከማቻ ቦታ ነጻ ያደርጋል።\n• የእርስዎ ተወዳጆች እና ምልክት ያደረጓቸው ሐዲሶች በደህና ይቀመጣሉ።\n• በማንኛውም ጊዜ ያለ ኢንተርኔት በአንድ ጠቅታ መልሰው ማዘጋጀት ይችላሉ።',
      'cancel': 'ሰርዝ',
      'confirm_delete': '~187 MB ቦታ ነጻ አድርግ',
      'snack_deleted': 'የሐዲስ ዳታ ተሰርዟል! ~187 MB ማከማቻ ቦታ በተሳካ ሁኔታ ነጻ ተደርጓል።',
      'section_kutub_sittah': 'ስድስቱ ታላላቅ የሐዲስ መጻሕፍት',
      'section_secondary': 'ተጨማሪ የታወቁ የሐዲስ ስብስቦች',
      'banner_badge': '10 የተሟሉ ስብስቦች • 40,937 ትክክለኛ ሐዲሶች',
      'banner_title': 'የነቢያዊ ሱና እና የሐዲስ መዛግብት ቤተ-መጻሕፍት',
      'banner_desc': 'ከመስመር ውጭ ሙሉ በሙሉ የተሟላ የሐዲስ ኢንሳይክሎፔዲያ በምዕራፎች የተደራጀ',
      'storage_card_title': 'ከመስመር ውጭ ማከማቻ እና የማንበብ መረጃ',
      'storage_card_desc': 'ሙሉው ኢንሳይክሎፔዲያ ከመስመር ውጭ ተጭኗል (~187 MB)። ወደፊት የስልክዎ ማከማቻ ቦታ ካነሰ፣ ምልክት ያደረጓቸውን ሳያጡ ፋይሎችን ለጊዜው ማጥፋት ይችላሉ።',
      'storage_card_btn': 'ማከማቻ አስተዳድር',
    },
    'om': {
      'title': 'Muusowaa Hadiisaa',
      'search_tooltip': 'Hadiisa Barbaadi',
      'storage_btn': 'Kuusaa Bulchi',
      'storage_tooltip': 'Odeeffannoo kuusaa fi daataa',
      'setup_title': 'Muusowaa Hadiisaa Guddicha',
      'setup_desc': 'Kitaabban hadiisaa beakkamoo jahan, Muwaxxa’a Maalik, Riyaadu As-Saalihiin, Al-Adab Al-Mufrad fi Buluugul Maraam of keessaa qaba (Hadiisota kabajamoo 40,937 sanadaa fi matniin guutuu, barbaacha saffisaa fi toora interneetii malee dubbisuuf).',
      'setup_badge': '100% Toora Malee • Bakka kuusaa qusachuuf yeroo kamiyyuu haquu dandeessu',
      'setup_btn': 'Hadiisota Qopheessiitii Dubbisuu Eegali',
      'extracting_title': 'Hadiisonni qophaa\'aa jiru...',
      'extracting_desc': 'Kutaalee hadiisaa 10 (hadiisota 40,937) qopheessaa jira\nYeroo gabaabaa qofa fudhata...',
      'loading': 'Hadiisota fe\'aa jira...',
      'dialog_title': 'Kuusaa Bilbilaa Bulchuu',
      'dialog_desc': 'Kuusaa hadiisaa toora malee jiru bilbila keessan irraa haquu barbaadduu?\n\n• Battalumatti kuusaa bilbilaa ~187 MB bilisa baasa.\n• Hadiisonni jaallattanii fi as-irra gahe jettan hin banqan, nagaan taa\'u.\n• Yeroo kamiyyuu toora interneetii malee tuqaa tokkoon deebiftanii qopheeffachuu dandeessu.',
      'cancel': 'Dhiisi',
      'confirm_delete': '~187 MB Bilisa Baasi',
      'snack_deleted': 'Kuusaan hadiisaa haqameera! ~187 MB nagaan bilisa ba\'eera.',
      'section_kutub_sittah': 'Kitaabban Hadiisaa Jahan',
      'section_secondary': 'Walitti-qabaawwan Hadiisaa Biroo',
      'banner_badge': 'Kutaalee Hadiisaa 10 • Hadiisota 40,937',
      'banner_title': 'Mana Kitaaba Hadiisaa Nabiyyii fi Sunnaa',
      'banner_desc': 'Muusowaa hadiisaa guutuu sanadaa fi boqonnaadhaan qophaa\'e toora malee',
      'storage_card_title': 'Odeeffannoo Kuusaa fi Toora Malee Dubbisuu',
      'storage_card_desc': 'Muusowaan guutuun toora malee fe\'ameera (~187 MB). Gara fuulduraatti bilbilli keessan bakka yoo dhabe, mallattoolee keessan osoo hin dhabin yeroof qulqulleessuu dandeessu.',
      'storage_card_btn': 'Kuusaa Bulchi',
    },
  };

  String _getLang(BuildContext context) {
    return Localizations.maybeLocaleOf(context)?.languageCode ??
        AppLanguage.notifier.value.languageCode;
  }

  String _t(BuildContext context, String key) {
    final lang = _getLang(context);
    return _hadithL10n[lang]?[key] ??
        _hadithL10n['en']?[key] ??
        _hadithL10n['ar']?[key] ??
        key;
  }

  void _checkAutoNavigate(List<HadithCollection> list) {
    if (_hasAutoNavigated) return;
    HadithCollection? toOpen = widget.initialCollection;
    if (toOpen == null && widget.targetCollectionId != null) {
      try {
        toOpen = list.firstWhere((c) => c.id == widget.targetCollectionId);
      } catch (_) {}
    }
    if (toOpen != null) {
      _hasAutoNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HadithBooksScreen(collection: toOpen!)),
          );
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final isExtracted = await HadithDatabaseHelper.instance.isDatabaseExtracted();
      if (!isExtracted) {
        if (mounted) {
          setState(() {
            _needsSetup = true;
            _isLoading = false;
          });
        }
        return;
      }

      final list = await _hadithService.getCollections();
      if (mounted) {
        setState(() {
          _collections = list;
          _needsSetup = false;
          _isLoading = false;
        });
        _checkAutoNavigate(list);
      }
    } catch (e) {
      debugPrint('[HadithCollectionsScreen] Error loading collections: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startExtractionProcess() async {
    setState(() {
      _needsSetup = false;
      _isLoading = true;
      _isExtracting = true;
      _errorMessage = null;
    });
    try {
      await HadithDatabaseHelper.instance.prepareDatabase();
      final list = await _hadithService.getCollections();
      if (mounted) {
        setState(() {
          _collections = list;
          _isLoading = false;
          _isExtracting = false;
        });
        _checkAutoNavigate(list);
      }
    } catch (e) {
      debugPrint('[HadithCollectionsScreen] Extraction failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isExtracting = false;
        });
      }
    }
  }

  Future<void> _confirmClearHadithStorage(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark ||
        AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = AppTheme.getPageBgColor(AppTheme.notifier.value);
    final textColor = isDark ? Colors.white : const Color(0xFF2C2416);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t(context, 'dialog_title'),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(context, 'dialog_desc'),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13.5,
                height: 1.6,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1B8A6B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t(context, 'setup_badge'),
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B8A6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _t(context, 'cancel'),
              style: TextStyle(
                fontFamily: 'Amiri',
                color: textColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              _t(context, 'confirm_delete'),
              style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HadithDatabaseHelper.instance.deleteDatabaseFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1B8A6B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(context, 'snack_deleted'),
                    style: const TextStyle(fontFamily: 'Amiri', color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        _loadCollections();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final screenBg = AppTheme.getScreenBgColor(theme);
        final cardBg = AppTheme.getPageBgColor(theme);
        final textColor = theme == QuranTheme.dark ? Colors.white : const Color(0xFF2C2416);
        final isDark = theme == QuranTheme.dark;

        final kutubSittah = _collections.where((c) => c.sortOrder <= 6).toList();
        final secondaryCollections = _collections.where((c) => c.sortOrder > 6).toList();

        Widget bodyContent;
        if (_isLoading || _isExtracting) {
          bodyContent = _buildLoadingView(textColor, isDark);
        } else if (_needsSetup) {
          bodyContent = _buildSetupPromptView(textColor, cardBg, isDark);
        } else if (_errorMessage != null) {
          bodyContent = _buildErrorView(textColor, cardBg, isDark);
        } else {
          bodyContent = ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            children: [
              // Grand Header Banner
              _buildGrandBanner(isDark),
              const SizedBox(height: 18),

              // Section 1: الكتب الستة (The Six Canonical Books)
              _buildSectionHeader(_t(context, 'section_kutub_sittah'), Icons.stars_rounded, textColor),
              const SizedBox(height: 10),
              ...kutubSittah.map((col) => _buildCollectionCard(col, cardBg, textColor, isDark)),

              const SizedBox(height: 18),

              // Section 2: الجوامع والمصنفات الأخرى
              _buildSectionHeader(_t(context, 'section_secondary'), Icons.auto_stories_rounded, textColor),
              const SizedBox(height: 10),
              ...secondaryCollections.map((col) => _buildCollectionCard(col, cardBg, textColor, isDark)),
              const SizedBox(height: 20),

              // Bottom Peaceful Storage Utility Card ("The Latest Line")
              _buildBottomStorageUtilityCard(cardBg, textColor, isDark),
              const SizedBox(height: 24),
            ],
          );
        }

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0.5,
            centerTitle: true,
            iconTheme: IconThemeData(color: textColor),
            title: Text(
              _t(context, 'title'),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            actions: [
              if (!_needsSetup && !_isLoading && !_isExtracting)
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: _t(context, 'search_tooltip'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
                    );
                  },
                ),
            ],
          ),
          body: bodyContent,
        );
      },
    );
  }

  Widget _buildSetupPromptView(Color textColor, Color cardBg, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFD4AF37).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 38,
                  color: Color(0xFF1B8A6B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t(context, 'setup_title'),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _t(context, 'setup_desc'),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  height: 1.6,
                  color: textColor.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF6F8F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded, size: 18, color: Color(0xFF1B8A6B)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _t(context, 'setup_badge'),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.download_done_rounded, size: 22),
                  label: Text(
                    _t(context, 'setup_btn'),
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _startExtractionProcess,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(Color textColor, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: HadithDatabaseHelper.instance.isExtractingNotifier,
      builder: (context, isExtracting, _) {
        return ValueListenableBuilder<double>(
          valueListenable: HadithDatabaseHelper.instance.extractionProgressNotifier,
          builder: (context, progress, _) {
            final percent = (progress * 100).toInt();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isExtracting || progress > 0) ...[
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              color: const Color(0xFF1B8A6B),
                              backgroundColor: const Color(0xFF1B8A6B).withValues(alpha: 0.15),
                              strokeWidth: 4.5,
                            ),
                            Center(
                              child: Text(
                                '$percent%',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _t(context, 'extracting_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t(context, 'extracting_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.7),
                          height: 1.45,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B8A6B),
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _t(context, 'loading'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorView(Color textColor, Color cardBg, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 14),
              Text(
                'تعذر تحميل موسوعة الحديث الشريف',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'حدث خطأ أثناء فتح قاعدة البيانات. يمكنك إعادة المحاولة الآن.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13.5,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadCollections,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrandBanner(bool isDark) {
    return Container(
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0xFF1B8A6B),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Authentic Masterpiece Hadith Archival Artwork
            Image.asset(
              'assets/images/faculty_companions.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F382A), Color(0xFF1B5E46)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                );
              },
            ),

            // 2. Rich Multi-Stop Scrim Gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.68),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),

            // 3. Inner Gilded Rim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
              ),
            ),

            // 4. Content Structure
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Gilded Medallion + Statistics Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A1411).withValues(alpha: 0.82),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.80),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFFFD54F),
                          size: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF091210).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 12),
                            const SizedBox(width: 5),
                            Text(
                              _t(context, 'banner_badge'),
                              style: const TextStyle(
                                color: Color(0xFFFFF6D6),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Plate: Title & Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07100D).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t(context, 'banner_title'),
                          style: const TextStyle(
                            color: Color(0xFFFFFBF0),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            fontFamily: 'Amiri',
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _t(context, 'banner_desc'),
                          style: const TextStyle(
                            color: Color(0xFFDFD5C4),
                            fontSize: 10.5,
                            fontFamily: 'Amiri',
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildBottomStorageUtilityCard(Color cardBg, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFC68A2E).withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1B8A6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(context, 'storage_card_title'),
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t(context, 'storage_card_desc'),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12,
              height: 1.55,
              color: textColor.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor.withValues(alpha: 0.85),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFC68A2E).withValues(alpha: 0.4),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.storage_rounded, size: 16, color: Color(0xFF1B8A6B)),
              label: Text(
                _t(context, 'storage_card_btn'),
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirmClearHadithStorage(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC68A2E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(
    HadithCollection col,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    final isSahihayn = col.slug == 'bukhari' || col.slug == 'muslim';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSahihayn
              ? const Color(0xFFC9A84C).withValues(alpha: 0.35)
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
          width: isSahihayn ? 1.2 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HadithBooksScreen(collection: col)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Rank / Order Avatar
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSahihayn
                          ? const [Color(0xFF8D5B18), Color(0xFFC68A2E)]
                          : const [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${col.sortOrder}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.nameAr,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isSahihayn) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC68A2E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'صحيح',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC68A2E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        col.authorAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatPill('${col.totalBooks} كتاباً', textColor),
                          if (col.hasChapters && col.totalChapters > 0)
                            _buildStatPill('${col.totalChapters} باباً', textColor),
                          _buildStatPill('${col.totalHadiths} حديثاً', const Color(0xFF1B8A6B)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: textColor.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
