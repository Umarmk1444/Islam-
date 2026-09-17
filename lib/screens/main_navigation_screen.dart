import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
//   Tab 0 → MuslimDashboardTab  ("لوحة المسلم" / "Dashboard")
//   Tab 1 → LibraryScreen       ("المكتبة" / "Library")
//   Tab 2 → MinbarTab           ("المنبر" / "Minbar")
//   Tab 3 → SettingsScreen      ("الإعدادات" / "Settings")
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
    GlobalKey(debugLabel: 'minbar_tab'),
    GlobalKey(debugLabel: 'library_tab'),
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
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      labelKey: 'navDashboard',
      fallback: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.podcasts_outlined,
      activeIcon: Icons.podcasts_rounded,
      labelKey: 'navMinbar',
      fallback: 'المنبر',
    ),
    _NavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      labelKey: 'navLibrary',
      fallback: 'المكتبة',
    ),
    _NavItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      labelKey: 'navSettings',
      fallback: 'Settings',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme    = AppTheme.notifier.value;
    final isDark   = theme == QuranTheme.dark;
    final l10n     = AppLocalizations.of(context);

    final Color bgColor      = isDark ? AppColors.surfaceDark    : AppColors.surfaceLight;
    final Color barBgColor   = isDark ? AppColors.surfaceCard    : Colors.white;
    const Color selectedColor = AppColors.emeraldLight;
    final Color unselectedColor = isDark ? AppColors.textMuted : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: PageView(
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
              MinbarTab(key: _tabKeys[1]),
              LibraryScreen(key: _tabKeys[2]),
              SettingsScreen(key: _tabKeys[3]),
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
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBottomNavBar — ultra compact styled nav bar with scroll tracking & RTL
// ─────────────────────────────────────────────────────────────────────────────

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.pageController,
    required this.navMeta,
    required this.l10n,
    required this.isDark,
    required this.barBgColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final int currentIndex;
  final PageController pageController;
  final List<_NavItem> navMeta;
  final AppLocalizations? l10n;
  final bool isDark;
  final Color barBgColor;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final int count = navMeta.length;
        final double itemWidth = totalWidth / count;

        final double currentPage = (pageController.hasClients &&
                pageController.position.haveDimensions)
            ? (pageController.page ?? currentIndex.toDouble())
            : currentIndex.toDouble();

        // Calculate visual page position supporting RTL (Arabic)
        final double visualPage = isRtl
            ? ((count - 1) - currentPage)
            : currentPage;

        // Sliding pill parameters
        final double pillWidth = itemWidth - 4;
        const double pillHeight = 36;
        final double pillLeft = (visualPage * itemWidth) + (itemWidth - pillWidth) / 2;

        return Container(
          decoration: BoxDecoration(
            color: barBgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.divider : Colors.grey.shade200,
                width: 0.4,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // ── Floating Sliding Pill Indicator ────────────────────────
                  Positioned(
                    left: pillLeft,
                    top: (52 - pillHeight) / 2,
                    width: pillWidth,
                    height: pillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedColor.withValues(alpha: isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 4 Nav Bar Item Buttons ──────────────────────────────────
                  Row(
                    children: List.generate(count, (i) {
                      final item = navMeta[i];
                      final double distance = (currentPage - i).abs();
                      final double activeWeight = (1.0 - distance).clamp(0.0, 1.0);

                      return SizedBox(
                        width: itemWidth,
                        height: 52,
                        child: _NavBarButton(
                          item: item,
                          activeWeight: activeWeight,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          l10n: l10n,
                          onTap: () => onTap(i),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBarButton — animated individual tab button
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
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
    final label = _resolveLabel(widget.l10n);
    final weight = widget.activeWeight;

    // Smooth color lerp
    final Color iconColor = Color.lerp(widget.unselectedColor, widget.selectedColor, weight)!;
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isSelected ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey('${widget.item.labelKey}_$isSelected'),
                      color: iconColor,
                      size: 19,
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: weight,
                      child: Opacity(
                        opacity: weight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, right: 2),
                          child: Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
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

  String _resolveLabel(AppLocalizations? l10n) {
    if (l10n == null) return widget.item.fallback;
    try {
      switch (widget.item.labelKey) {
        case 'navSettings':  return l10n.navSettings;
        case 'navDashboard': return l10n.navDashboard;
        case 'navMinbar':    return l10n.navMinbar;
        case 'navLibrary':   return l10n.navLibrary;
        default: return widget.item.fallback;
      }
    } catch (_) {
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
