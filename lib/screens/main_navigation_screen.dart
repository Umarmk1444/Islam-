import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import 'muslim_dashboard_tab.dart';
import 'minbar_tab.dart';
import 'settings_screen.dart';
import 'library_screen.dart';
import '../core/constants/app_colors.dart';

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
// Uses IndexedStack so each tab's scroll/state is preserved across switches.
// ─────────────────────────────────────────────────────────────────────────────

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<GlobalKey> _tabKeys = [
    GlobalKey(debugLabel: 'dashboard_tab'),
    GlobalKey(debugLabel: 'minbar_tab'),
    GlobalKey(debugLabel: 'library_tab'),
    GlobalKey(debugLabel: 'settings_tab'),
  ];

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
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
    if (index == _currentIndex) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: [
          MuslimDashboardTab(key: _tabKeys[0]),
          MinbarTab(key: _tabKeys[1]),
          LibraryScreen(key: _tabKeys[2]),
          SettingsScreen(key: _tabKeys[3]),
        ],
      ),
      bottomNavigationBar: _AppBottomNavBar(
        currentIndex: _currentIndex,
        navMeta: _navMeta,
        l10n: l10n,
        isDark: isDark,
        barBgColor: barBgColor,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        onTap: _onTabTapped,
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBottomNavBar — custom styled nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBottomNavBar extends StatelessWidget {
  const _AppBottomNavBar({
    required this.currentIndex,
    required this.navMeta,
    required this.l10n,
    required this.isDark,
    required this.barBgColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final int currentIndex;
  final List<_NavItem> navMeta;
  final AppLocalizations? l10n;
  final bool isDark;
  final Color barBgColor;
  final Color selectedColor;
  final Color unselectedColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: barBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.divider : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navMeta.length, (i) {
              final item   = navMeta[i];
              final active = i == currentIndex;
              return _NavBarButton(
                item: item,
                isActive: active,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                l10n: l10n,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBarButton — animated individual tab button
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.item,
    required this.isActive,
    required this.selectedColor,
    required this.unselectedColor,
    required this.l10n,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final Color selectedColor;
  final Color unselectedColor;
  final AppLocalizations? l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel(l10n);
    final isSettings = item.labelKey == 'navSettings';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSettings ? 12 : 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? selectedColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? selectedColor : unselectedColor,
                size: isSettings ? 20 : 22,
              ),
            ),
            if (!isSettings) ...[
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isActive ? 10.5 : 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? selectedColor : unselectedColor,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const SizedBox(height: 14), // Aligns icons vertically by matching text height
            ],
            const SizedBox(height: 3),
            // Subtle active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveLabel(AppLocalizations? l10n) {
    if (l10n == null) return item.fallback;
    try {
      switch (item.labelKey) {
        case 'navSettings':  return l10n.navSettings;
        case 'navDashboard': return l10n.navDashboard;
        case 'navMinbar':    return l10n.navMinbar;
        case 'navLibrary':   return l10n.navLibrary;
        default: return item.fallback;
      }
    } catch (_) {
      return item.fallback;
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
