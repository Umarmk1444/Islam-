import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../language_notifier.dart';
import 'main_navigation_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstRun;

  const LanguageSelectionScreen({
    super.key,
    this.isFirstRun = true,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  // Arabic is recommended by default
  String _selectedLang = 'Arabic';
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _languages = [
    {
      'key': 'Arabic',
      'nativeName': 'العربية',
      'englishName': 'Arabic',
      'desc': 'لغة القرآن الكريم • واجهة كاملة وتفاسير أصيلة',
      'subDesc': 'Full Arabic interface with authentic classical libraries',
      'isRecommended': true,
      'badge': 'الموصى بها • Recommended',
      'icon': Icons.stars_rounded,
      'accentColor': const Color(0xFFD4AF37),
    },
    {
      'key': 'English',
      'nativeName': 'English',
      'englishName': 'English',
      'desc': 'Complete English interface & translations',
      'subDesc': 'Hadiths, references & trans-literations',
      'isRecommended': false,
      'badge': null,
      'icon': Icons.language_rounded,
      'accentColor': const Color(0xFF1B8A6B),
    },
    {
      'key': 'Amharic',
      'nativeName': 'አማርኛ',
      'englishName': 'Amharic',
      'desc': 'የቁርኣን ትርጉም እና ሙሉ እስላማዊ ማጣቀሻዎች',
      'subDesc': 'Amharic translations & Islamic knowledge',
      'isRecommended': false,
      'badge': null,
      'icon': Icons.public_rounded,
      'accentColor': const Color(0xFF2B6CB0),
    },
    {
      'key': 'Oromo',
      'nativeName': 'Afaan Oromoo',
      'englishName': 'Oromo',
      'desc': "Hiika Qur'aanaa fi qajeelfama amantii Islaamaa",
      'subDesc': 'Oromo translations & references',
      'isRecommended': false,
      'badge': null,
      'icon': Icons.menu_book_rounded,
      'accentColor': const Color(0xFF9B2C2C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _confirmSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_chosen_initial_language', true);
    await AppLanguage.changeLanguage(_selectedLang);

    if (!mounted) return;

    if (widget.isFirstRun) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B0E), // Deep luxury midnight obsidian
      body: Stack(
        children: [
          // Ambient Atmospheric Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4AF37).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B8A6B).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar / Skip Row if not first run
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!widget.isFirstRun)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48),

                      // Ornamental Star Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFFD4AF37), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'لغة التطبيق • App Language',
                              style: TextStyle(
                                color: Color(0xFFE2BC6A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Header Title & Welcoming Callout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Text(
                        'اختر لغتك المفضلة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Choose Your Preferred Language',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9EABA6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12, width: 0.6),
                        ),
                        child: const Text(
                          'نوصي باختيار اللغة العربية لتجربة قرآنية وعلمية كاملة • يمكنك تغييرها لاحقاً في أي وقت من الإعدادات',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                            height: 1.4,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Language Cards List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: _languages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final item = _languages[idx];
                      final isSelected = _selectedLang == item['key'];
                      final isRecommended = item['isRecommended'] as bool;
                      final Color accent = item['accentColor'] as Color;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLang = item['key'] as String;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isRecommended
                                    ? const Color(0xFF1B2A22)
                                    : const Color(0xFF111E1D))
                                : const Color(0xFF0F161A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? (isRecommended ? const Color(0xFFD4AF37) : accent)
                                  : (isRecommended
                                      ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.08)),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: (isRecommended ? const Color(0xFFD4AF37) : accent)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Selection Radio Circle
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (isRecommended ? const Color(0xFFD4AF37) : accent)
                                        : Colors.white38,
                                    width: isSelected ? 6.5 : 1.5,
                                  ),
                                  color: isSelected ? Colors.white : Colors.transparent,
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Language Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item['nativeName'] as String,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: item['key'] == 'Arabic' ? 'Amiri' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${item['englishName']})',
                                          style: const TextStyle(
                                            color: Color(0xFF889A94),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isRecommended)
                                          ScaleTransition(
                                            scale: _pulseAnimation,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF8D6820), Color(0xFFD4AF37)],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Colors.black, size: 12),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    item['badge'] as String,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['desc'] as String,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFFE2E8F0) : const Color(0xFF7F928C),
                                        fontSize: 11.5,
                                        height: 1.3,
                                        fontFamily: item['key'] == 'Arabic' ? 'Amiri' : null,
                                      ),
                                    ),
                                    Text(
                                      item['subDesc'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFF5A6F68),
                                        fontSize: 10,
                                        height: 1.25,
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
                ),

                // Bottom Confirmation CTA Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B), Color(0xFF2ECC9A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _confirmSelection,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedLang == 'Arabic'
                                ? 'تأكيد ومتابعة التصفح'
                                : 'Confirm & Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
    );
  }
}
