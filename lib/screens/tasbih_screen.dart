import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../theme_notifier.dart';

// ============================================
// نموذج بيانات الذكر
// ============================================
class Dhikr {
  int id;
  String text;
  int target;
  String icon;
  String category;

  Dhikr({
    required this.id,
    required this.text,
    required this.target,
    required this.icon,
    this.category = 'custom',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'target': target,
    'icon': icon,
    'category': category,
  };

  factory Dhikr.fromJson(Map<String, dynamic> json) => Dhikr(
    id: json['id'],
    text: json['text'],
    target: json['target'],
    icon: json['icon'],
    category: json['category'] ?? 'custom',
  );
}

// ============================================
// الشاشة الرئيسية
// ============================================
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {

  // Localizations for UI elements
  static const _translations = {
    'en': {
      'title': 'Digital Tasbih',
      'goal': 'Goal:',
      'times': 'times',
      'dhikrs': 'Dhikrs',
      'manage': 'Manage Dhikrs',
      'type_new': 'Type new dhikr...',
      'goal_hint': 'Goal (e.g. 33)',
      'add_new': 'Add new dhikr',
      'edit_delete': 'Edit / Delete',
      'edit': 'Edit Dhikr',
      'text': 'Text',
      'cancel': 'Cancel',
      'save': 'Save',
      'active': 'Active Dhikr',
      'session': 'This Session',
      'sub': 'Subhanallah wa bihamdihi',
      'tasbih_btn': 'Tasbih',
      'error_last': 'You must keep at least one dhikr',
    },
    'ar': {
      'title': 'التسبيح الرقمي',
      'goal': 'الهدف:',
      'times': 'مرة',
      'dhikrs': 'الأذكار',
      'manage': 'إدارة الأذكار',
      'type_new': 'اكتب الذكر الجديد...',
      'goal_hint': 'الهدف (مثلاً 33)',
      'add_new': 'إضافة ذكر جديد',
      'edit_delete': 'تعديل / حذف',
      'edit': 'تعديل الذكر',
      'text': 'النص',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'active': 'ذكر نشط',
      'session': 'هذه الجلسة',
      'sub': 'سبحان الله وبحمده',
      'tasbih_btn': 'تسبيح',
      'error_last': 'يجب أن يبقى ذكر واحد على الأقل',
    },
    'am': {
      'title': 'ዲጂታል ተስቢህ',
      'goal': 'ግብ፡',
      'times': 'ጊዜ',
      'dhikrs': 'ዚክር',
      'manage': 'ዚክር አስተዳድር',
      'type_new': 'አዲስ ዚክር ይፃፉ...',
      'goal_hint': 'ግብ (ለምሳሌ 33)',
      'add_new': 'አዲስ ዚክር ጨምር',
      'edit_delete': 'አስተካክል / አጥፋ',
      'edit': 'ዚክር አስተካክል',
      'text': 'ጽሑፍ',
      'cancel': 'ሰርዝ',
      'save': 'አስቀምጥ',
      'active': 'ንቁ ዚክር',
      'session': 'ይህ ክፍለ ጊዜ',
      'sub': 'ሱብሃነላህ ወቢሃምዲሂ',
      'tasbih_btn': 'ተስቢህ',
      'error_last': 'ቢያንስ አንድ ዚክር መተው አለብዎት',
    },
    'om': {
      'title': 'Tasbiiha Dijitaalaa',
      'goal': 'Galma:',
      'times': 'yeroo',
      'dhikrs': 'Dhikrii',
      'manage': 'Dhikrii To\'adhu',
      'type_new': 'Dhikrii haaraa barreessi...',
      'goal_hint': 'Galma (fkn 33)',
      'add_new': 'Dhikrii haaraa dabali',
      'edit_delete': 'Sirreessi / Haqii',
      'edit': 'Dhikrii Sirreessi',
      'text': 'Barruu',
      'cancel': 'Haqi',
      'save': 'Olkaawi',
      'active': 'Dhikrii Ammaa',
      'session': 'Yeroo kana',
      'sub': 'Subhaanallaahi Wa Bi Hamdihii',
      'tasbih_btn': 'Tasbiiha',
      'error_last': 'Yoo xiqqaate dhikrii tokko dhiisuu qabda',
    },
  };
  
  String _t(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return _translations[locale]?[key] ?? _translations['en']![key]!;
  }

  // الأذكار الافتراضية
  List<Dhikr> dhikrs = [
    Dhikr(id: 1, text: 'سبحان الله', target: 33, icon: '📿', category: 'default'),
    Dhikr(id: 2, text: 'الحمد لله', target: 33, icon: '🤲', category: 'default'),
    Dhikr(id: 3, text: 'الله أكبر', target: 33, icon: '⭐', category: 'default'),
    Dhikr(id: 4, text: 'لا إله إلا الله', target: 100, icon: '🌙', category: 'default'),
    Dhikr(id: 5, text: 'أستغفر الله', target: 100, icon: '☪️', category: 'default'),
    Dhikr(id: 6, text: 'لا حول ولا قوة إلا بالله', target: 100, icon: '💎', category: 'default'),
    Dhikr(id: 7, text: 'اللهم صل على محمد', target: 100, icon: '🕊️', category: 'default'),
    Dhikr(id: 8, text: 'سبحان الله وبحمده', target: 100, icon: '🔮', category: 'default'),
  ];

  late Dhikr currentDhikr;
  int count = 0;
  int sessionTotal = 0;
  int nextId = 9;

  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    currentDhikr = dhikrs[0];
    _loadDhikrs();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // تحميل الأذكار والتأكد من تاريخ الجلسة
  Future<void> _loadDhikrs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Dhikrs
    final saved = prefs.getString('dhikrs');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      dhikrs = decoded.map((e) => Dhikr.fromJson(e)).toList();
      if (dhikrs.isNotEmpty) {
        nextId = dhikrs.map((d) => d.id).reduce(math.max) + 1;
      }
    }
    
    // Load state
    final lastSavedDateStr = prefs.getString('tasbih_date');
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastSavedDateStr == todayStr) {
      count = prefs.getInt('tasbih_count') ?? 0;
      sessionTotal = prefs.getInt('tasbih_session') ?? 0;
      final currentId = prefs.getInt('tasbih_current_id') ?? dhikrs[0].id;
      currentDhikr = dhikrs.firstWhere((d) => d.id == currentId, orElse: () => dhikrs[0]);
    } else {
      // New day, reset count and session
      count = 0;
      sessionTotal = 0;
      currentDhikr = dhikrs.isNotEmpty ? dhikrs[0] : currentDhikr;
      _saveState();
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('tasbih_date', todayStr);
    await prefs.setInt('tasbih_count', count);
    await prefs.setInt('tasbih_session', sessionTotal);
    await prefs.setInt('tasbih_current_id', currentDhikr.id);
  }

  Future<void> _saveDhikrs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(dhikrs.map((d) => d.toJson()).toList());
    await prefs.setString('dhikrs', encoded);
  }

  void increment() {
    setState(() {
      count++;
      sessionTotal++;
    });
    _saveState();
    _pulseController.forward().then((_) => _pulseController.reverse());
    _bounceController.forward().then((_) => _bounceController.reverse());
    HapticFeedback.lightImpact();
  }

  void decrement() {
    if (count > 0) {
      setState(() {
        count--;
        sessionTotal--;
      });
      _saveState();
    }
  }

  void resetCounter() {
    setState(() {
      count = 0;
    });
    _saveState();
  }

  void selectDhikr(Dhikr dhikr) {
    setState(() {
      currentDhikr = dhikr;
      count = 0;
    });
    _saveState();
  }

  void addCustomDhikr(String text, int target, String icon) {
    if (text.trim().isEmpty) return;
    setState(() {
      dhikrs.add(Dhikr(
        id: nextId++,
        text: text.trim(),
        target: target,
        icon: icon,
        category: 'custom',
      ));
    });
    _saveDhikrs();
  }

  void deleteDhikr(int id) {
    if (dhikrs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, 'error_last'))),
      );
      return;
    }
    setState(() {
      dhikrs.removeWhere((d) => d.id == id);
      if (currentDhikr.id == id) {
        currentDhikr = dhikrs[0];
        count = 0;
        _saveState();
      }
    });
    _saveDhikrs();
  }

  void editDhikr(int id, String newText, int newTarget) {
    setState(() {
      final index = dhikrs.indexWhere((d) => d.id == id);
      if (index != -1) {
        dhikrs[index].text = newText;
        dhikrs[index].target = newTarget;
        if (currentDhikr.id == id) {
          currentDhikr = dhikrs[index];
          // Recalculate progress, prevent NaN
          if (count > currentDhikr.target && currentDhikr.target > 0) {
            count = currentDhikr.target;
          }
        }
      }
    });
    _saveDhikrs();
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final progress = currentDhikr.target > 0 ? (count / currentDhikr.target) : 0.0;
    final isComplete = currentDhikr.target > 0 ? (count >= currentDhikr.target) : true;

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        
        final bgColor = isDark ? const Color(0xFF0D1F17) : const Color(0xFFF5F7F4);
        final cardBgColor = isDark ? const Color(0xFF142912) : Colors.white;
        final textColor = isDark ? const Color(0xFFE8DCC8) : const Color(0xFF0D3D2E);
        final secondaryTextColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
        final borderColor = isDark ? const Color(0xFF2D8A6E).withValues(alpha: 0.3) : const Color(0xFFE0E6DC);
        final activeCardColor = isDark ? const Color(0xFF1A5F4A).withValues(alpha: 0.3) : const Color(0xFFF0F7F4);
        final inputBgColor = isDark ? const Color(0xFF06100A) : const Color(0xFFF5F7F4);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            title: Text(
              _t(context, 'title'),
              style: TextStyle(color: AppTheme.getAppBarTextColor(theme)),
            ),
            iconTheme: IconThemeData(color: AppTheme.getAppBarTextColor(theme)),
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(textColor),
                    const SizedBox(height: 24),
                    _buildCounterCard(progress, isComplete, cardBgColor, textColor, secondaryTextColor, borderColor),
                    const SizedBox(height: 24),
                    _buildDhikrGrid(cardBgColor, textColor, secondaryTextColor, borderColor, activeCardColor),
                    const SizedBox(height: 24),
                    _buildAddSection(cardBgColor, textColor, secondaryTextColor, borderColor, inputBgColor),
                    // Manage List
                    if (dhikrs.any((d) => d.category != 'default')) ...[
                      _buildManageList(cardBgColor, textColor, secondaryTextColor, borderColor, inputBgColor),
                      const SizedBox(height: 24),
                    ],
                    _buildStats(cardBgColor, textColor, secondaryTextColor, borderColor),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      children: [
        const Text('🕌', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Text(
          _t(context, 'title'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(context, 'sub'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D8A6E),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterCard(double progress, bool isComplete, Color cardBg, Color textColor, Color secColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F4A).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A5F4A), Color(0xFFD4A843)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A5F4A), Color(0xFF2D8A6E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_t(context, 'goal')} ${currentDhikr.target}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(150, 150),
                        painter: ProgressRingPainter(
                          progress: progress,
                          isComplete: isComplete,
                          bgStrokeColor: borderColor,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isComplete
                                    ? const Color(0xFFD4A843)
                                    : textColor,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                            child: Text(
                              currentDhikr.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: secColor,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ScaleTransition(
                            scale: _bounceAnimation,
                            child: Text(
                              currentDhikr.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconButton('↺', resetCounter, cardBg, secColor, borderColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: increment,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isComplete
                                  ? [const Color(0xFFD4A843), const Color(0xFFF0D78C)]
                                  : [const Color(0xFF1A5F4A), const Color(0xFF2D8A6E)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isComplete
                                        ? const Color(0xFFD4A843)
                                        : const Color(0xFF1A5F4A))
                                    .withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _t(context, 'tasbih_btn'),
                              style: TextStyle(
                                color: isComplete ? const Color(0xFF0D3D2E) : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildIconButton('−', decrement, cardBg, secColor, borderColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(String icon, VoidCallback onTap, Color cardBg, Color secColor, Color borderColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
          color: cardBg,
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(fontSize: 18, color: secColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDhikrGrid(Color cardBg, Color textColor, Color secColor, Color borderColor, Color activeBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _t(context, 'dhikrs'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: dhikrs.length,
          itemBuilder: (context, index) {
            final dhikr = dhikrs[index];
            final isActive = dhikr.id == currentDhikr.id;
            return GestureDetector(
              onTap: () => selectDhikr(dhikr),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? activeBg : cardBg,
                  border: Border.all(
                    color: isActive ? const Color(0xFF1A5F4A) : borderColor,
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1A5F4A).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    if (isActive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A5F4A),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '✓',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dhikr.icon, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            dhikr.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: borderColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${dhikr.target} ${_t(context, 'times')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: secColor,
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
          },
        ),
      ],
    );
  }

  Widget _buildAddSection(Color cardBg, Color textColor, Color secColor, Color borderColor, Color inputBgColor) {
    final textController = TextEditingController();
    final targetController = TextEditingController(text: '33');
    String selectedIcon = '📿';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A5F4A).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚙️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    _t(context, 'manage'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                textAlign: TextAlign.right,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: _t(context, 'type_new'),
                  hintStyle: TextStyle(color: secColor),
                  filled: true,
                  fillColor: inputBgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2D8A6E)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: _t(context, 'goal_hint'),
                        hintStyle: TextStyle(color: secColor),
                        filled: true,
                        fillColor: inputBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2D8A6E)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedIcon,
                        dropdownColor: cardBg,
                        items: ['📿', '🤲', '⭐', '🌙', '☪️', '💎', '🔮', '🕊️']
                            .map((icon) => DropdownMenuItem(
                                  value: icon,
                                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setLocalState(() => selectedIcon = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  addCustomDhikr(
                    textController.text,
                    int.tryParse(targetController.text) ?? 33,
                    selectedIcon,
                  );
                  textController.clear();
                  targetController.text = '33';
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A843), Color(0xFFF0D78C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A843).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D3D2E))),
                        const SizedBox(width: 8),
                        Text(
                          _t(context, 'add_new'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D3D2E),
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
    );
  }

  Widget _buildManageList(Color cardBg, Color textColor, Color secColor, Color borderColor, Color inputBgColor) {
    final customDhikrs = dhikrs.where((d) => d.category != 'default').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F4A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _t(context, 'edit_delete'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customDhikrs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final dhikr = customDhikrs[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(dhikr.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dhikr.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${_t(context, 'goal')} ${dhikr.target}',
                            style: TextStyle(
                              fontSize: 12,
                              color: secColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final editText = TextEditingController(text: dhikr.text);
                                final editTarget = TextEditingController(text: '${dhikr.target}');
                                return AlertDialog(
                                  backgroundColor: cardBg,
                                  title: Text(_t(context, 'edit'), style: TextStyle(color: textColor)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: editText,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: _t(context, 'text'), 
                                          labelStyle: TextStyle(color: secColor)
                                        ),
                                      ),
                                      TextField(
                                        controller: editTarget,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: _t(context, 'goal'),
                                          labelStyle: TextStyle(color: secColor)
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(_t(context, 'cancel'), style: TextStyle(color: secColor)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        editDhikr(
                                          dhikr.id,
                                          editText.text,
                                          int.tryParse(editTarget.text) ?? dhikr.target,
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: Text(_t(context, 'save'), style: const TextStyle(color: Color(0xFF1A5F4A))),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('✏️', style: TextStyle(fontSize: 16))),
                          ),
                        ),
                        if (dhikr.category != 'default')
                          GestureDetector(
                            onTap: () => deleteDhikr(dhikr.id),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: Text('🗑️', style: TextStyle(fontSize: 16))),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Color cardBg, Color textColor, Color secColor, Color borderColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('📿', '${dhikrs.length}', _t(context, 'active'), cardBg, textColor, secColor, borderColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('🔥', '$sessionTotal', _t(context, 'session'), cardBg, textColor, secColor, borderColor),
        ),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color cardBg, Color textColor, Color secColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A5F4A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D8A6E),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: secColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================
// راسم الحلقة الدائرية
// ============================================
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isComplete;
  final Color bgStrokeColor;

  ProgressRingPainter({required this.progress, required this.isComplete, required this.bgStrokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 15;

    // Background circle
    final bgPaint = Paint()
      ..color = bgStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // Skip drawing progress if zero to avoid SweepGradient assertion crash
    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: isComplete
          ? [const Color(0xFFD4A843), const Color(0xFFF0D78C)]
          : [const Color(0xFF1A5F4A), const Color(0xFFD4A843)],
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
