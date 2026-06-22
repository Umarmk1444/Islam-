import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for copy to clipboard action
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../language_notifier.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;

  final List<String> _languages = [
    'Amharic',
    'Oromo',
    'English',
    'Arabic',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setLanguage(String lang) async {
    await AppLanguage.changeLanguage(lang);
    setState(() {
      _selectedLanguage = lang;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (value) {
      await NotificationService().scheduleDailyNotification(9, 0);
    } else {
      await NotificationService().cancelNotifications();
    }
  }

  Future<void> _clearAudioCache(BuildContext context, Color primaryColor, AppLocalizations l10n) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noAudioFound),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      bool deletedSomething = false;
      final List<dynamic> files = directory.listSync(recursive: true);
      for (final dynamic file in files) {
        if (file.path != null && (file.path as String).endsWith('.mp3')) {
          (file as dynamic).deleteSync();
          deletedSomething = true;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deletedSomething ? l10n.audioCacheCleared : l10n.noAudioFound),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLanguageDialog(Color primaryColor, Color mainTextColor, Color cardColor, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.selectLanguage,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w500)),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: primaryColor,
                onChanged: (val) {
                  if (val != null) {
                    _setLanguage(val);
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final Color primaryColor = AppTheme.getPrimaryColor(theme);
        final Color mainTextColor = AppTheme.getMainTextColor(theme);
        final Color cardBgColor = AppTheme.getCardBgColor(theme);
        final Color borderColor = AppTheme.getBorderColor(theme);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
              // Premium Telegram Collaboration Card
              _buildTelegramSupportCard(primaryColor, mainTextColor, cardBgColor, borderColor, l10n),
              const SizedBox(height: 24),

              _buildSectionHeader(l10n.preferences, primaryColor),
              _buildCard(
                cardBgColor,
                Column(
                  children: [
                    _buildListTile(
                      icon: Icons.language,
                      title: l10n.appLanguage,
                      subtitle: _selectedLanguage,
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () => _showLanguageDialog(primaryColor, mainTextColor, cardBgColor, l10n),
                    ),
                    _buildDivider(borderColor),
                    _buildThemeSelector(theme, primaryColor, mainTextColor, borderColor, l10n),
                    _buildDivider(borderColor),
                    SwitchListTile(
                      title: Text(l10n.dailyNotifications, style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.dailyNotificationsDesc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      value: _notificationsEnabled,
                      activeColor: primaryColor,
                      secondary: Icon(Icons.notifications_active, color: primaryColor),
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(l10n.storageAndData, primaryColor),
              _buildCard(
                cardBgColor,
                Column(
                  children: [
                    _buildListTile(
                      icon: Icons.delete_outline,
                      title: l10n.clearDownloadedAudio,
                      subtitle: l10n.freeUpSpace,
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () => _clearAudioCache(context, primaryColor, l10n),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(l10n.supportAndAbout, primaryColor),
              _buildCard(
                cardBgColor,
                Column(
                  children: [
                    _buildListTile(
                      icon: Icons.share,
                      title: l10n.shareApp,
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () {
                        Share.share(l10n.shareApp);
                      },
                    ),
                    _buildDivider(borderColor),
                    _buildListTile(
                      icon: Icons.star_rate,
                      title: l10n.rateUs,
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () async {
                        final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.example.quran_dawah');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not launch \$url');
                        }
                      },
                    ),
                    _buildDivider(borderColor),
                    _buildListTile(
                      icon: Icons.mail_outline,
                      title: l10n.contactUs,
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'support@example.com',
                          query: 'subject=Quran & Dawah App Feedback',
                        );
                        if (!await launchUrl(emailLaunchUri)) {
                          debugPrint('Could not launch email');
                        }
                      },
                    ),
                    _buildDivider(borderColor),
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: l10n.aboutApp,
                      subtitle: 'Version 1.0.0',
                      textColor: mainTextColor,
                      iconColor: primaryColor,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              Center(
                child: Text(
                  l10n.madeWithLove,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelegramSupportCard(Color primaryColor, Color textColor, Color bgColor, Color borderColor, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.contactDeveloper,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    Text(
                      l10n.contactDeveloperDesc,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.contactDeveloperText,
            style: TextStyle(fontSize: 13, height: 1.4, color: textColor.withOpacity(0.9), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri url = Uri.parse('https://t.me/UMER_jr');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint('Could not launch Telegram profile link');
                  }
                },
                icon: const Icon(Icons.telegram, size: 18),
                label: Text(l10n.chatOnTelegram),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: '@UMER_jr')).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedToClipboard),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.copyUsername),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(Color bgColor, Widget child) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color.withOpacity(0.15), indent: 56);
  }

  Widget _buildThemeSelector(QuranTheme currentTheme, Color primaryColor, Color mainTextColor, Color borderColor, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: primaryColor),
              const SizedBox(width: 16),
              Text(
                l10n.appTheme,
                style: TextStyle(color: mainTextColor, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ThemeOption(
                label: l10n.themeCream,
                color: const Color(0xFFFDFBF0),
                isSelected: currentTheme == QuranTheme.cream,
                activeColor: primaryColor,
                onTap: () => AppTheme.changeTheme(QuranTheme.cream),
              ),
              _ThemeOption(
                label: l10n.themeDark,
                color: const Color(0xFF0D1F17),
                isSelected: currentTheme == QuranTheme.dark,
                activeColor: primaryColor,
                onTap: () => AppTheme.changeTheme(QuranTheme.dark),
              ),
              _ThemeOption(
                label: l10n.themeWhite,
                color: Colors.white,
                isSelected: currentTheme == QuranTheme.white,
                activeColor: primaryColor,
                onTap: () => AppTheme.changeTheme(QuranTheme.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: activeColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: isSelected 
                ? Icon(Icons.check, color: activeColor, size: 24) 
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}