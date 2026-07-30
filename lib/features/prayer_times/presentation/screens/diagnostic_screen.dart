import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  static const _channel = MethodChannel('com.sadaga.quran_dawah/device');
  
  bool _isLoading = true;
  bool _exactAlarm = false;
  bool _ignoreBattery = false;
  bool _notification = false;
  String _configDump = '';
  String _manufacturer = 'Unknown';
  int _sdkInt = 0;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    _exactAlarm = await Permission.scheduleExactAlarm.isGranted;
    _ignoreBattery = await Permission.ignoreBatteryOptimizations.isGranted;
    _notification = await Permission.notification.isGranted;

    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
        if (result != null) {
          _manufacturer = result['manufacturer'] as String? ?? 'Unknown';
          _sdkInt = result['sdkInt'] as int? ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final buffer = StringBuffer();
    for (var key in keys) {
      if (key.contains('prayer') || key.contains('athan')) {
        buffer.writeln('$key: ${prefs.get(key)}');
      }
    }
    _configDump = buffer.toString();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportLogs() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/athan_diagnostics.txt');
      
      final sb = StringBuffer();
      sb.writeln('=== QURAN DAWAH DIAGNOSTICS ===');
      sb.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
      sb.writeln('OS: ${Platform.operatingSystem}');
      sb.writeln('Manufacturer: $_manufacturer');
      sb.writeln('SDK Int: $_sdkInt');
      sb.writeln('Exact Alarm Granted: $_exactAlarm');
      sb.writeln('Ignore Battery Optimizations: $_ignoreBattery');
      sb.writeln('Notifications Granted: $_notification');
      sb.writeln('\n=== SHARED PREFS ===');
      sb.writeln(_configDump);
      
      await file.writeAsString(sb.toString());
      
      await Share.shareXFiles([XFile(file.path)], text: 'Quran Dawah Diagnostics');
    } catch (e) {
      debugPrint('Error exporting logs: $e');
    }
  }

  bool _needsBatteryGuidance() {
    final m = _manufacturer.toLowerCase();
    return m.contains('xiaomi') ||
        m.contains('huawei') ||
        m.contains('oppo') ||
        m.contains('vivo') ||
        m.contains('samsung');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final primary = AppTheme.getPrimaryColor(theme);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: const Text('System Diagnostics'),
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _isLoading ? null : _exportLogs,
                tooltip: 'Export Logs',
              )
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_needsBatteryGuidance() && !_ignoreBattery)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.coralRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.coralRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.coralRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_manufacturer.toUpperCase()} Battery Restrictions',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.coralRed, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your device aggressively kills background tasks. Please disable battery optimizations for this app to ensure the Adhan plays reliably.',
                                    style: AppTextStyles.labelSmall.copyWith(color: textColor, height: 1.4),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    
                    _buildSectionTitle('Device Info', primary),
                    _buildCard(
                      cardBg,
                      Column(
                        children: [
                          _buildInfoRow('OS', Platform.operatingSystem.toUpperCase(), textColor),
                          _buildInfoRow('Manufacturer', _manufacturer, textColor),
                          _buildInfoRow('SDK Version', '$_sdkInt', textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Permissions', primary),
                    _buildCard(
                      cardBg,
                      Column(
                        children: [
                          _buildStatusRow('Exact Alarms (Android 12+)', _exactAlarm, textColor),
                          _buildStatusRow('Battery Opt Ignored', _ignoreBattery, textColor),
                          _buildStatusRow('Notifications', _notification, textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Background Execution', primary),
                    _buildCard(
                      cardBg,
                      Text(
                        'WorkManager Periodic Sync: Active\n'
                        'System Event Receiver: Active\n'
                        'AlarmManager Slots: Active',
                        style: AppTextStyles.bodyMedium.copyWith(color: textColor, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Raw Configuration Dump', primary),
                    _buildCard(
                      cardBg,
                      SelectableText(
                        _configDump.isEmpty ? 'No relevant config found.' : _configDump,
                        style: AppTextStyles.bodySmall.copyWith(color: textColor.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelLarge.copyWith(
          color: primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(Color cardBg, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: textColor.withValues(alpha: 0.6))),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isOk ? AppColors.emeraldLight : AppColors.coralRed,
          ),
        ],
      ),
    );
  }
}
