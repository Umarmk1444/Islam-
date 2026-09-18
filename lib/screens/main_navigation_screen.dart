import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import 'muslim_dashboard_tab.dart';
import 'minbar_tab.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import '../core/constants/app_colors.dart';
import '../main.dart';
import 'quran_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../services/app_update_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainNavigationScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// 4-tab bottom navigator:
//   Tab 0 → MuslimDashboardTab  ("Home" / "الرئيسية")
//   Tab 1 → LibraryScreen       ("Library" / "المكتبة")
//   Tab 2 → MinbarTab           ("Minbar" / "المنبر")
//   Tab 3 → SettingsScreen      ("Settings" / "الإعدادات")
//
// Uses PageView + AutomaticKeepAliveClientMixin so swiping works left/right
// and each tab's scroll/state is preserved across switches.
// ─────────────────────────────────────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<GlobalKey> _tabKeys = [
    GlobalKey(debugLabel: 'dashboard_tab'),
    GlobalKey(debugLabel: 'library_tab'),
    GlobalKey(debugLabel: 'minbar_tab'),
    GlobalKey(debugLabel: 'settings_tab'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pageController.addListener(_onPageScroll);
    
    // Mark global navigation as ready
    kMainNavigationReady = true;

    // Check if there was a pending deep link from the Android Widget
    if (kPendingQuranWidgetClick) {
      kPendingQuranWidgetClick = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuranScreen()),
        );
      });
    }

    // Launch staged permissions sequence and check daily updates after screen is settled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAppPermissionsSequence();
      AppUpdateService.instance.checkDailyUpdate(context);
    });
  }

  Future<void> _initAppPermissionsSequence() async {
    final prayerCtrl = PrayerController();

    // Respect offline manual choice: if already set manually, never trigger GPS or ask on launch!
    if (prayerCtrl.config.isManualLocation) {
      // Still allow notifications to be requested if appropriate
      await _requestNotificationPermission();
      if (!kIsWeb && Platform.isAndroid) {
        await _checkAndPromptAutoSilent();
      }
      return;
    }

    // Stage 1: Location Permission & Auto-Sync (FIRST)
    // Completely awaited so user can take their time without dialog collisions
    await _requestLocationPermission();

    // Stage 2: Notifications Permission (SECOND)
    // Only prompted after location decision has completed
    await _requestNotificationPermission();

    // Stage 3: Auto-Silent Mode (DND) Prompt (Android Only)
    if (!kIsWeb && Platform.isAndroid) {
      await _checkAndPromptAutoSilent();
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

      final prefs = await SharedPreferences.getInstance();
      final lastDeniedTime = prefs.getInt('notif_denied_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // If user denied recently (less than 24h ago), snooze until tomorrow
      if (lastDeniedTime > 0 && (now - lastDeniedTime) < 86400000) {
        return;
      }

      final isGranted = await ph.Permission.notification.isGranted;
      if (!isGranted) {
        final status = await ph.Permission.notification.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          await prefs.setInt('notif_denied_timestamp', now);
        } else if (status.isGranted) {
          await prefs.remove('notif_denied_timestamp');
        }
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] Notification permission error: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final prayerCtrl = PrayerController();
      if (prayerCtrl.config.isManualLocation) return;

      final prefs = await SharedPreferences.getInstance();
      final lastDeniedTime = prefs.getInt('location_denied_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // If user denied recently (less than 24 hours ago), do not badger them on launch
      if (lastDeniedTime > 0 && (now - lastDeniedTime) < 86400000) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await prefs.setInt('location_denied_timestamp', now);
        }
      }
      
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await prefs.remove('location_denied_timestamp');
        if (mounted) {
          // Immediately sync location - now fast (<10ms with getLastKnownPosition)
          await prayerCtrl.syncLocation();
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final locPromptCount = prefs.getInt('location_prompt_count') ?? 0;
          if (locPromptCount < 2) {
            await prefs.setInt('location_prompt_count', locPromptCount + 1);
            if (!mounted) return;
            final locale =
                Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
            final String title = locale == 'ar'
                ? 'تحديد الموقع مطلوب'
                : (locale == 'am'
                    ? 'አካባቢ ያስፈልጋል'
                    : (locale == 'om'
                        ? 'Bakka Barbaachisaadha'
                        : 'Location Required'));
            final String content = locale == 'ar'
                ? 'تم رفض إذن الموقع بشكل دائم. يمكنك تفعيله من الإعدادات أو اختيار مدينتك يدوياً لعرض أوقات الصلاة والقبلة بدقة.'
                : (locale == 'am'
                    ? 'የአካባቢ ፈቃድ በቋሚነት ተከልክሏል። ትክክለኛውን የሶላት ወቅት ለማግኘት እባክዎ በቅንብሮች ውስጥ ያንቁት ወይም ከተማዎን በእጅ ይምረጡ።'
                    : (locale == 'om'
                        ? 'Hayyamni bakkaa guutummaatti dhorkameera. Yeroo salaataa sirrii argachuuf maaloo Qindaa\'ina keessatti banaa ykn magaalaa keessan filadhaa.'
                        : 'Location permission is permanently denied. You can enable it in Settings or select your city manually to calculate accurate prayer times and Qibla.'));
            final String openSettingsStr = locale == 'ar'
                ? 'فتح الإعدادات'
                : (locale == 'am'
                    ? 'ቅንብሮችን ክፈት'
                    : (locale == 'om'
                        ? 'Qindaa\'ina Bani'
                        : 'Open Settings'));
            final String cancelStr = locale == 'ar'
                ? 'إلغاء'
                : (locale == 'am'
                    ? 'ይቅር'
                    : (locale == 'om' ? 'Dhiisi' : 'Cancel'));

            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(cancelStr),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Geolocator.openAppSettings();
                    },
                    child: Text(openSettingsStr),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] Location permission error: $e');
    }
  }

  Future<void> _checkAndPromptAutoSilent() async {
    try {
      final isGranted = await ph.Permission.accessNotificationPolicy.isGranted;
      if (isGranted) return;

      final prefs = await SharedPreferences.getInstance();
      final dndPromptCount = prefs.getInt('dnd_prompt_count') ?? 0;
      final dndSnoozeTime = prefs.getInt('dnd_snooze_timestamp') ?? 0;

      bool shouldPrompt = true;
      if (dndSnoozeTime > 0) {
        final hoursSinceLastPrompt =
            (DateTime.now().millisecondsSinceEpoch - dndSnoozeTime) / (1000 * 3600);
        if (hoursSinceLastPrompt < 24) {
          shouldPrompt = false; // Snooze for 24h if dismissed
        } else if (dndPromptCount >= 3 && hoursSinceLastPrompt < 72) {
          shouldPrompt = false; // Max 3 strikes, snooze 3 days
        }
      }

      if (shouldPrompt && mounted) {
        final locale =
            Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
        final String title = locale == 'ar'
            ? 'وضع الصامت التلقائي في المسجد'
            : (locale == 'am'
                ? 'በመስጂድ ውስጥ ራስ-ሰር ድምፅ አልባ ሁነታ'
                : (locale == 'om'
                    ? 'Moosqii Keessatti Sagalee Dhabamsiisuu'
                    : 'Auto-Silent Mode in Mosque'));
        final String content = locale == 'ar'
            ? 'لكتم صوت هاتفك تلقائياً أثناء أوقات الصلاة في المسجد حتى لا تنزعج أو تزعج المصلين، يُرجى منح إذن "عدم الإزعاج" في الشاشة التالية.'
            : (locale == 'am'
                ? 'በመስጂድ ውስጥ በሶላት ወቅት ስልክዎን በራስ-ሰር ድምፅ አልባ ለማድረግ በሚቀጥለው ገጽ ላይ የ "አትረብሹ" (Do Not Disturb) ፈቃድ ይስጡ።'
                : (locale == 'om'
                    ? 'Yeroo salaataa masjiida keessatti bilbilli keessan ofumaan sagalee akka hin dhageessifneef, fuula itti aanu irratti heyyama "Do Not Disturb" kennaa.'
                    : 'To automatically silence your phone during prayers in the mosque so you are never disturbed, please grant Do Not Disturb access on the next screen.'));
        final String proceedStr = locale == 'ar'
            ? 'تفعيل'
            : (locale == 'am'
                ? 'አንቃ'
                : (locale == 'om' ? 'Bani' : 'Enable'));
        final String cancelStr = locale == 'ar'
            ? 'لاحقاً'
            : (locale == 'am'
                ? 'ቆይቶ'
                : (locale == 'om' ? 'Booda' : 'Later'));

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_rounded,
                    color: AppColors.emeraldMid, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final newCount = (prefs.getInt('dnd_prompt_count') ?? 0) + 1;
                  await prefs.setInt('dnd_prompt_count', newCount);
                  if (newCount >= 3) {
                    await prefs.setInt('dnd_snooze_timestamp',
                        DateTime.now().millisecondsSinceEpoch);
                  }
                },
                child: Text(cancelStr),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldMid,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final status =
                      await ph.Permission.accessNotificationPolicy.request();
                  if (status.isGranted) {
                    await PrayerController().toggleAutoSilent(true);
                  }
                },
                child: Text(proceedStr),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('[MainNavigationScreen] DND permission error: $e');
    }
  }

  void _onPageScroll() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  // Nav-bar items are built in [build] so they can access localised strings.
  static const List<_NavItem> _navMeta = [
    _NavItem(
      icon: Icons.mosque_outlined,
      activeIcon: Icons.mosque_rounded,
      labelKey: 'navDashboard',
      fallback: 'Home',
    ),
    _NavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      labelKey: 'navLibrary',
      fallback: 'Library',
    ),
    _NavItem(
      icon: Icons.graphic_eq_rounded,
      activeIcon: Icons.graphic_eq_rounded,
      labelKey: 'navMinbar',
      fallback: 'Minbar',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_suggest_rounded,
      labelKey: 'navSettings',
      fallback: 'Settings',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;
        final l10n = AppLocalizations.of(context);

        final Color bgColor = AppTheme.getScreenBgColor(theme);

        // One UI 8.5 Translucent Frosted Glass Palettes
        final Color barBgColor = isDark
            ? const Color(0xFF1B221E).withValues(alpha: 0.82)
            : (isCream
                ? const Color(0xFFF5EFE3).withValues(alpha: 0.84)
                : const Color(0xFFEEF3F0).withValues(alpha: 0.82));

        final Color borderColor = isDark
            ? Colors.white.withValues(alpha: 0.14)
            : (isCream
                ? const Color(0xFFC9A84C).withValues(alpha: 0.32)
                : const Color(0xFF0D5D44).withValues(alpha: 0.14));

        final Color selectedColor = isDark
            ? const Color(0xFF00E676)
            : (isCream ? const Color(0xFF1B4332) : const Color(0xFF0D5D44));

        final Color unselectedColor = isDark
            ? Colors.white.withValues(alpha: 0.45)
            : (isCream
                ? const Color(0xFF7A5C28).withValues(alpha: 0.65)
                : Colors.black.withValues(alpha: 0.42));

        final Color activeIndicatorColor = selectedColor.withValues(
            alpha: isDark ? 0.18 : (isCream ? 0.14 : 0.12));

        return Scaffold(
          extendBody: true,
          backgroundColor: bgColor,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (_currentIndex != index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                    physics: const BouncingScrollPhysics(),
                    children: [
                      MuslimDashboardTab(key: _tabKeys[0]),
                      LibraryScreen(key: _tabKeys[1]),
                      MinbarTab(key: _tabKeys[2]),
                      SettingsScreen(key: _tabKeys[3]),
                    ],
                  ),
                  // ── Samsung One UI 8.5 Bottom Soft Fade-out Scrim ───────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 115,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bgColor.withValues(alpha: 0.0),
                              bgColor.withValues(alpha: isDark ? 0.45 : 0.35),
                              bgColor.withValues(alpha: isDark ? 0.85 : 0.80),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: _AppBottomNavBar(
                currentIndex: _currentIndex,
                pageController: _pageController,
                navMeta: _navMeta,
                l10n: l10n,
                isDark: isDark,
                barBgColor: barBgColor,
                borderColor: borderColor,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                activeIndicatorColor: activeIndicatorColor,
                onTap: _onTabTapped,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBottomNavBar — Samsung One UI 8.5 Floating Glassmorphic Dock
// ─────────────────────────────────────────────────────────────────────────────

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.pageController,
    required this.navMeta,
    required this.l10n,
    required this.isDark,
    required this.barBgColor,
    required this.borderColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.activeIndicatorColor,
    required this.onTap,
  });

  final int currentIndex;
  final PageController pageController;
  final List<_NavItem> navMeta;
  final AppLocalizations? l10n;
  final bool isDark;
  final Color barBgColor;
  final Color borderColor;
  final Color selectedColor;
  final Color unselectedColor;
  final Color activeIndicatorColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final int count = navMeta.length;

        // Reduced dock width by 30% for an ultra-compact, centered Samsung One UI island
        final double dockWidth = (totalWidth * 0.70).clamp(250.0, 340.0);
        final double horizontalMargin = (totalWidth - dockWidth) / 2;
        final double availableWidth = dockWidth;

        // Account for container border width: 1.2px on each side = 2.4px total
        const double borderWidth = 1.2;
        final double innerContentWidth = availableWidth - (borderWidth * 2);
        final double itemWidth = innerContentWidth / count;

        final double currentPage = (pageController.hasClients &&
                pageController.position.haveDimensions)
            ? (pageController.page ?? currentIndex.toDouble())
            : currentIndex.toDouble();

        // Calculate visual page position supporting RTL (Arabic)
        final double visualPage = isRtl
            ? ((count - 1) - currentPage)
            : currentPage;

        const double barHeight = 54.0;
        const double pillHeight = 40.0;
        final double pillWidth = itemWidth - 2.0;
        final double pillLeft = (visualPage * itemWidth) + (itemWidth - pillWidth) / 2;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: barBgColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // ── One UI 8.5 Sliding Squircle / Capsule Indicator ──
                      Positioned(
                        left: pillLeft,
                        top: (barHeight - pillHeight) / 2,
                        width: pillWidth,
                        height: pillHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeIndicatorColor,
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: selectedColor.withValues(alpha: isDark ? 0.35 : 0.22),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedColor.withValues(alpha: isDark ? 0.20 : 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 4 Nav Bar Item Buttons (Expanded to guarantee 0 overflow) ──
                      Row(
                        children: List.generate(count, (i) {
                          final item = navMeta[i];
                          final double distance = (currentPage - i).abs();
                          final double activeWeight = (1.0 - distance).clamp(0.0, 1.0);

                          return Expanded(
                            child: SizedBox(
                              height: barHeight,
                              child: _NavBarButton(
                                item: item,
                                activeWeight: activeWeight,
                                selectedColor: selectedColor,
                                unselectedColor: unselectedColor,
                                l10n: l10n,
                                onTap: () => onTap(i),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBarButton — One UI 8.5 animated individual tab button
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarButton extends StatefulWidget {
  const _NavBarButton({
    required this.item,
    required this.activeWeight,
    required this.selectedColor,
    required this.unselectedColor,
    required this.l10n,
    required this.onTap,
  });

  final _NavItem item;
  final double activeWeight;
  final Color selectedColor;
  final Color unselectedColor;
  final AppLocalizations? l10n;
  final VoidCallback onTap;

  @override
  State<_NavBarButton> createState() => _NavBarButtonState();
}

class _NavBarButtonState extends State<_NavBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel(context, widget.l10n);
    final weight = widget.activeWeight;

    // Smooth color lerp
    final Color iconColor =
        Color.lerp(widget.unselectedColor, widget.selectedColor, weight)!;
    final bool isSelected = weight > 0.5;

    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey('${widget.item.labelKey}_$isSelected'),
                      color: iconColor,
                      size: isSelected ? 21 : 19.5,
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: weight,
                      child: Opacity(
                        opacity: weight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, right: 3),
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: widget.selectedColor,
                              letterSpacing: 0.1,
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
        ),
      ),
    );
  }

  String _resolveLabel(BuildContext context, AppLocalizations? l10n) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    switch (widget.item.labelKey) {
      case 'navDashboard':
        return lang == 'ar' ? 'الرئيسية' : 'Home';
      case 'navLibrary':
        return lang == 'ar' ? 'المكتبة' : 'Library';
      case 'navMinbar':
        return lang == 'ar' ? 'المنبر' : 'Minbar';
      case 'navSettings':
        return lang == 'ar' ? 'الإعدادات' : 'Settings';
      default:
        return widget.item.fallback;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — value holder
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.fallback,
  });

  final IconData icon;
  final IconData activeIcon;
  final String labelKey;   // key in AppLocalizations
  final String fallback;   // used when l10n is unavailable
}
