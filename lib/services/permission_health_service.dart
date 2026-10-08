import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized service that monitors critical app permissions
/// and exposes a reactive badge counter for the Settings tab and Health Card.
class PermissionHealthService {
  static final PermissionHealthService _instance = PermissionHealthService._internal();
  factory PermissionHealthService() => _instance;
  PermissionHealthService._internal();

  /// Reactive count of missing permissions requiring user attention.
  static final ValueNotifier<int> missingCountNotifier = ValueNotifier<int>(0);

  /// Reactive list of keys for missing permissions.
  static final ValueNotifier<List<String>> missingPermissionsNotifier =
      ValueNotifier<List<String>>([]);

  /// Checks the current state of critical permissions and updates notifiers.
  static Future<void> checkHealth() async {
    try {
      final List<String> missing = [];

      // 1. Notification Permission
      final bool notifGranted = await Permission.notification.isGranted;
      if (!notifGranted) {
        missing.add('notification');
      }

      if (!kIsWeb && Platform.isAndroid) {
        // 2. Battery Optimization Exemption (Crucial for background Athan)
        final bool batteryGranted =
            await Permission.ignoreBatteryOptimizations.isGranted;
        if (!batteryGranted) {
          missing.add('battery');
        }

        // 3. Exact Alarm Permission (Android 12+)
        final bool exactGranted =
            await Permission.scheduleExactAlarm.isGranted;
        if (!exactGranted) {
          missing.add('exact_alarm');
        }

        // 4. Do Not Disturb Access (Auto-silent during prayers)
        final bool dndGranted =
            await Permission.accessNotificationPolicy.isGranted;
        if (!dndGranted) {
          missing.add('dnd');
        }
      }

      // 5. Location Permission
      final LocationPermission loc = await Geolocator.checkPermission();
      final bool locGranted =
          (loc == LocationPermission.always || loc == LocationPermission.whileInUse);
      if (!locGranted) {
        missing.add('location');
      }

      missingPermissionsNotifier.value = missing;
      missingCountNotifier.value = missing.length;
    } catch (e) {
      debugPrint('[PermissionHealthService] checkHealth error: $e');
    }
  }
}
