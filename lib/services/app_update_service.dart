import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _kLastCheckKey = 'last_update_check_epoch';
  static const int _kCheckIntervalMs = 24 * 60 * 60 * 1000; // 24 hours
  static const String _kPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.umer.quranzone';

  bool _isChecking = false;

  /// Runs periodic daily check when internet is active.
  Future<void> checkDailyUpdate(BuildContext context) async {
    if (_isChecking) return;
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_kLastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastCheck < _kCheckIntervalMs) {
        return; // Already checked within the last 24 hours
      }

      await prefs.setInt(_kLastCheckKey, now);
      if (context.mounted) {
        await checkForUpdate(context, isManual: false);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Daily update check failed: $e');
    }
  }

  /// Checks for updates using Google Play In-App Update,
  /// with a robust fallback for sideloaded/transferred installations.
  Future<void> checkForUpdate(BuildContext context, {bool isManual = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      if (kIsWeb || !Platform.isAndroid) {
        if (isManual && context.mounted) {
          _showUpToDateSnack(context);
        }
        _isChecking = false;
        return;
      }

      // 1. Try Google Play In-App Update API first
      try {
        final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
            _isChecking = false;
            return;
          } else if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
            _isChecking = false;
            return;
          }
        } else if (info.updateAvailability == UpdateAvailability.updateNotAvailable) {
          if (isManual && context.mounted) {
            _showUpToDateSnack(context);
          }
          _isChecking = false;
          return;
        }
      } catch (playError) {
        debugPrint('[AppUpdateService] Play In-App Update unavailable: $playError');
        // If sideloaded or transferred, proceed to Fallback check below
      }

      // 2. Fallback Check: Query Play Store / remote API version
      final updateAvailable = await _checkRemoteVersion();
      if (updateAvailable != null && updateAvailable['hasUpdate'] == true) {
        if (context.mounted) {
          _showUpdateAvailableDialog(
            context,
            latestVersion: updateAvailable['version'] ?? '',
            releaseNotes: updateAvailable['notes'] ?? '',
          );
        }
      } else if (isManual && context.mounted) {
        _showUpToDateSnack(context);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Update check error: $e');
      if (isManual && context.mounted) {
        _showUpToDateSnack(context);
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Checks if a higher version is published on Google Play
  Future<Map<String, dynamic>?> _checkRemoteVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Query Play Store public listing metadata
      final url = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.umer.quranzone&hl=en');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        // Look for version pattern in Play Store response
        final match = RegExp(r'\[\[\["([0-9]+\.[0-9]+\.[0-9]+)"\]\]').firstMatch(res.body);
        if (match != null && match.groupCount >= 1) {
          final storeVersion = match.group(1)!;
          if (_isVersionHigher(storeVersion, currentVersion)) {
            return {
              'hasUpdate': true,
              'version': storeVersion,
              'notes': 'A new version with latest improvements is available on Google Play.',
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isVersionHigher(String remote, String current) {
    try {
      final rParts = remote.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
    } catch (_) {}
    return false;
  }

  void _showUpdateAvailableDialog(
    BuildContext context, {
    required String latestVersion,
    required String releaseNotes,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            Text(
              isArabic ? 'تحديث جديد متوفر!' : 'New Update Available!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'يتوفر إصدار جديد من تطبيق Quran Zone ($latestVersion). يرجى التحديث للحصول على أحدث المزايا والتحسينات.'
                  : 'A new version of Quran Zone ($latestVersion) is available with the latest features and optimizations.',
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isArabic ? 'لاحقاً' : 'Later',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final Uri url = Uri.parse(_kPlayStoreUrl);
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                debugPrint('Could not launch play store');
              }
            },
            child: Text(
              isArabic ? 'تحديث الآن' : 'Update Now',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpToDateSnack(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تطبيق Quran Zone محدث إلى أحدث إصدار.'
              : 'Quran Zone is already up to date.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
