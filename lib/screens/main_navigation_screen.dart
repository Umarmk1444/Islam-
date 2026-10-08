import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import 'muslim_dashboard_tab.dart';
import 'minbar_tab.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import '../main.dart';
import 'quran_screen.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../features/prayer_times/presentation/screens/permissions_setup_screen.dart';
import '../services/app_update_service.dart';
import '../services/permission_health_service.dart';

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
// ── Theme Transition Constant (Identical to Holy Quran circular reveal: 850ms) ──
const Duration kQuranThemeDuration = Duration(milliseconds: 850);
const Curve kQuranThemeCurve = Curves.easeInOutCubic;

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isOnboardingDone =
          prefs.getBool('permissions_onboarding_completed') ?? false;

      if (!isOnboardingDone && mounted) {
        // First-run launch: Display the unified luxury permissions sheet
        await PermissionsSetupScreen.showAsModal(context);
        await prefs.setBool('permissions_onboarding_completed', true);
      }

      // Passive non-destructive background location analyzer:
      // Silently checks displacement delta (>30km) or timezone changes.
      // If GPS is turned off or permission denied, does nothing and keeps cached location intact!
      await PrayerController().analyzeLocationInBackground();

      // Refresh permission health count for reactive Settings badge
      await PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[MainNavigationScreen] _initAppPermissionsSequence error: $e');
    }
  }

  void _onPageScroll() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PermissionHealthService.checkHealth();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    if (index == _currentIndex) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
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
        final bool isRtl = Directionality.of(context) == TextDirection.rtl;

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
          backgroundColor: Colors.transparent,
          body: AnimatedContainer(
            duration: kQuranThemeDuration,
            curve: kQuranThemeCurve,
            color: bgColor,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Stack(
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
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
                          Directionality(
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: MuslimDashboardTab(key: _tabKeys[0]),
                          ),
                          Directionality(
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: LibraryScreen(key: _tabKeys[1]),
                          ),
                          Directionality(
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: MinbarTab(key: _tabKeys[2]),
                          ),
                          Directionality(
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: SettingsScreen(key: _tabKeys[3]),
                          ),
                        ],
                      ),
                    ),
                    // ── Samsung One UI 8.5 Bottom Soft Fade-out Scrim ───────────
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 115,
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: kQuranThemeDuration,
                          curve: kQuranThemeCurve,
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final int count = navMeta.length;

          // Perfectly proportioned 30% width reduction for Samsung One UI floating island
          final double dockWidth = (totalWidth * 0.74).clamp(268.0, 335.0);
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

          const double barHeight = 60.0;
          const double pillHeight = 48.0;
          final double pillWidth = itemWidth - 6.0;

          // Organic fluid stretch physics (Samsung One UI 8.5 fluid capsule)
          final double fractional = (currentPage - currentPage.round()).abs(); // 0.0 to 0.5
          final double stretch = (fractional * 2.0); // 0.0 at rest, 1.0 halfway
          final double dynamicPillWidth = pillWidth + (stretch * 6.0);
          final double dynamicPillHeight = pillHeight - (stretch * 2.0);
          final double dynamicPillLeft =
              (currentPage * itemWidth) + (itemWidth - dynamicPillWidth) / 2;
          final double dynamicPillTop = (barHeight - dynamicPillHeight) / 2;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: kQuranThemeDuration,
                  curve: kQuranThemeCurve,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: barBgColor,
                    borderRadius: BorderRadius.circular(30),
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
                      if (isDark)
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // ── One UI 8.5 Fluid Squircle Capsule Indicator ──────
                      Positioned(
                        left: dynamicPillLeft,
                        top: dynamicPillTop,
                        width: dynamicPillWidth,
                        height: dynamicPillHeight,
                        child: AnimatedContainer(
                          duration: kQuranThemeDuration,
                          curve: kQuranThemeCurve,
                          decoration: BoxDecoration(
                            color: activeIndicatorColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selectedColor.withValues(
                                  alpha: isDark ? 0.35 : 0.22),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedColor.withValues(
                                    alpha: isDark ? 0.22 : 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 4 Nav Bar Item Buttons (Vertical One UI 8.5 Stack) ──
                      Row(
                        children: List.generate(count, (i) {
                          final item = navMeta[i];
                          final double distance = (currentPage - i).abs();
                          final double activeWeight =
                              (1.0 - distance).clamp(0.0, 1.0);

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
      ),
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
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(
        parent: _tapCtrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.elasticOut,
      ),
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

    // Smooth color & opacity interpolation
    final Color iconColor =
        Color.lerp(widget.unselectedColor, widget.selectedColor, weight)!;
    final Color textColor =
        Color.lerp(widget.unselectedColor, widget.selectedColor, weight)!;
    final bool isSelected = weight > 0.5;

    return GestureDetector(
      onTapDown: (_) {
        _tapCtrl.forward();
        HapticFeedback.lightImpact();
      },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                () {
                  final Widget iconWidget = TweenAnimationBuilder<Color?>(
                    duration: kQuranThemeDuration,
                    curve: kQuranThemeCurve,
                    tween: ColorTween(end: iconColor),
                    builder: (context, animIconColor, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isSelected ? widget.item.activeIcon : widget.item.icon,
                          key: ValueKey('${widget.item.labelKey}_$isSelected'),
                          color: animIconColor,
                          size: isSelected ? 21.5 : 20.0,
                        ),
                      );
                    },
                  );

                  if (widget.item.labelKey == 'navSettings') {
                    return ValueListenableBuilder<int>(
                      valueListenable: PermissionHealthService.missingCountNotifier,
                      builder: (context, missingCount, child) {
                        if (missingCount <= 0) return child!;
                        return Badge(
                          label: Text(
                            '$missingCount',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFFE53935),
                          offset: const Offset(6, -4),
                          child: child,
                        );
                      },
                      child: iconWidget,
                    );
                  }

                  return iconWidget;
                }(),
                const SizedBox(height: 2.5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TweenAnimationBuilder<Color?>(
                    duration: kQuranThemeDuration,
                    curve: kQuranThemeCurve,
                    tween: ColorTween(end: textColor),
                    builder: (context, animTextColor, _) {
                      return Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: animTextColor,
                          letterSpacing: 0.1,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
