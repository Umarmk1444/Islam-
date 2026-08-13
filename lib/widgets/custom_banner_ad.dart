import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Global notifier: set to `true` when the Holy Quran reading screen is visible.
/// The persistent banner listens to this and hides itself accordingly.
final ValueNotifier<bool> kQuranScreenActive = ValueNotifier<bool>(false);

/// Global notifier: set to `true` when the persistent ad is loaded and visible.
/// This is used by MaterialApp.builder to scale down the rest of the application layout.
final ValueNotifier<bool> kAdVisibleNotifier = ValueNotifier<bool>(false);

/// A persistent, non-overlapping AdMob Banner that lives at the TOP of the
/// app layout tree. It uses [AnimatedSize] so the height animates smoothly
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
  bool _isAdLoading = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  // Standard Ad Unit ID for Android Banners
  static const String _adUnitId = 'ca-app-pub-5557619519970400/5577116496';

  @override
  void initState() {
    super.initState();
    _loadAd();
    kQuranScreenActive.addListener(_onQuranScreenChanged);
  }

  void _updateAdVisibility() {
    final bool isVisible =
        _isAdLoaded && _bannerAd != null && !kQuranScreenActive.value;
    if (kAdVisibleNotifier.value != isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          kAdVisibleNotifier.value = isVisible;
        }
      });
    }
  }

  void _onQuranScreenChanged() {
    if (mounted) {
      // CRITICAL FIX: If we are LEAVING the Quran screen, we must discard the old ad instance
      // and load a fresh one, because Flutter's AdWidget destroys the native view
      // when it's removed from the tree.
      if (!kQuranScreenActive.value) {
        _isAdLoaded = false;
        _bannerAd?.dispose();
        _bannerAd = null;
        _loadAd();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
          _updateAdVisibility();
        }
      });
    }
  }

  void _loadAd() {
    // Prevent duplicate concurrent load calls or reloading if already loaded successfully.
    if (_isAdLoading) return;
    if (_isAdLoaded && _bannerAd != null) return;

    _retryTimer?.cancel();
    _retryTimer = null;

    // Dispose old instance if it exists before creating a new one
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
    _isAdLoading = true;

    final BannerAd banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdMob BannerAd successfully loaded.');
          if (!mounted) {
            ad.dispose();
            return;
          }
          _retryAttempt = 0; // Reset retry attempt counter on success
          setState(() {
            _isAdLoaded = true;
            _isAdLoading = false;
          });
          _updateAdVisibility();
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint(
              'AdMob BannerAd failed to load (code ${err.code}): ${err.message}');
          ad.dispose(); // CRITICAL: Clear corrupted instance immediately
          if (!mounted) return;

          _retryAttempt++;
          setState(() {
            _isAdLoaded = false;
            _isAdLoading = false;
            _bannerAd = null;
          });
          _updateAdVisibility();

          // Aggressive retry logic: constantly try every 10 seconds so it appears
          // almost immediately when the internet is turned back on.
          const int retryDelaySeconds = 10;

          debugPrint(
              'Scheduling AdMob retry attempt #$_retryAttempt in ${retryDelaySeconds}s');

          _retryTimer?.cancel();
          // ignore: prefer_const_constructors
          _retryTimer = Timer(Duration(seconds: retryDelaySeconds), () {
            if (mounted && _bannerAd == null && !_isAdLoading) {
              _loadAd();
            }
          });
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    kQuranScreenActive.removeListener(_onQuranScreenChanged);
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShow =
        _isAdLoaded && _bannerAd != null && !kQuranScreenActive.value;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: shouldShow
          ? Center(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
