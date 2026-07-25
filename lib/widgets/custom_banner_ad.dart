import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Global notifier: set to `true` when the Holy Quran reading screen is visible.
/// The persistent banner listens to this and hides itself accordingly.
final ValueNotifier<bool> kQuranScreenActive = ValueNotifier<bool>(false);

/// Global notifier: set to `true` when the persistent ad is loaded and visible.
/// This is used by MaterialApp.builder to scale down the rest of the application layout.
final ValueNotifier<bool> kAdVisibleNotifier = ValueNotifier<bool>(false);

/// A persistent, non-overlapping AdMob Banner that lives at the TOP of the
/// app layout tree. It uses [AnimatedContainer] so the height animates smoothly
/// between its loaded size and zero, allowing the rest of the UI to resize
/// without any overflow errors.
///
/// Key behaviors:
///   • Smoothly collapses to height 0 when the ad fails to load, hasn't loaded
///     yet, or the Holy Quran screen is active.
///   • Pushes content down (never overlaps) because it sits inside a [Column]
///     above the main [Expanded] content area.
class PersistentBannerAd extends StatefulWidget {
  const PersistentBannerAd({super.key});

  @override
  State<PersistentBannerAd> createState() => _PersistentBannerAdState();
}

class _PersistentBannerAdState extends State<PersistentBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Standard Test Ad Unit ID for Android Banners
  static const String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadAd();
    kQuranScreenActive.addListener(_onQuranScreenChanged);
  }

  void _updateAdVisibility() {
    final bool isVisible = _isAdLoaded && _bannerAd != null && !kQuranScreenActive.value;
    if (kAdVisibleNotifier.value != isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        kAdVisibleNotifier.value = isVisible;
      });
    }
  }

  void _onQuranScreenChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
          _updateAdVisibility();
        }
      });
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isAdLoaded = true);
                _updateAdVisibility();
              }
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('AdMob BannerAd failed to load: $err');
          ad.dispose();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isAdLoaded = false;
                  _bannerAd = null;
                });
                _updateAdVisibility();
              }
            });
          }
          // Retry after 60 seconds
          Future.delayed(const Duration(seconds: 60), () {
            if (mounted && _bannerAd == null) _loadAd();
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    kQuranScreenActive.removeListener(_onQuranScreenChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShow = _isAdLoaded
        && _bannerAd != null
        && !kQuranScreenActive.value;

    final double targetHeight = shouldShow
        ? _bannerAd!.size.height.toDouble()
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: targetHeight,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(), // required for clipBehavior
      child: shouldShow
          ? SizedBox(
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }
}
