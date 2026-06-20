import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../l10n/app_localizations.dart';

class DawahScreen extends StatelessWidget {
  const DawahScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> mockScholars = const [
    {
      "name": "Ustaz Yasin Nuru",
      "language": "Amharic",
      "languageCode": "am",
      "lectureCount": 5,
      "icon": Icons.record_voice_over,
      "lectures": [
        "Wajiba Keenya",
        "Yeroo Keyna",
        "Tawbah",
        "Guddina Islaamaa",
        "Aklaaq"
      ]
    },
    {
      "name": "Raayyaa Abbaa Maccaa",
      "language": "Oromo",
      "languageCode": "om",
      "lectureCount": 5,
      "icon": Icons.mic,
      "lectures": [
        "Nasheed 1",
        "Nasheed 2",
        "Nasheed 3",
        "Mootummaa Haalati",
        "Jirra Jirreanya"
      ]
    },
    {
      "name": "Ustaz Abubakar Ahmed",
      "language": "Amharic",
      "languageCode": "am",
      "lectureCount": 4,
      "icon": Icons.menu_book,
      "lectures": [
        "Sabrii",
        "Niyyah",
        "Du'aa Khayrii",
        "Haqqa Muslimaa"
      ]
    },
    {
      "name": "Sheikh Sa'id Ahmed Mustafa",
      "language": "Amharic / Oromo",
      "languageCode": "am_om",
      "lectureCount": 3,
      "icon": Icons.star,
      "lectures": [
        "Tafsiira Saalihiin",
        "Aadaa fi Islaama",
        "Zikr Khayr"
      ]
    },
    {
      "name": "Ustaz Kamil Shemsu",
      "language": "Amharic",
      "languageCode": "am",
      "lectureCount": 3,
      "icon": Icons.history_edu,
      "lectures": [
        "Fiqhi Al-Wajiz",
        "Seerah Nabaviyyah 1",
        "Seerah Nabaviyyah 2"
      ]
    },
  ];

  Color _langColor(String code) {
    switch (code) {
      case 'om':
        return const Color(0xFF2E7D32); // green for Oromo
      case 'am':
        return const Color(0xFF1565C0); // blue for Amharic
      case 'am_om':
        return const Color(0xFF6A1B9A); // purple for both
      default:
        return Colors.grey;
    }
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

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.dawahScholars),
          ),
          body: Column(
            children: [
              // Decorative header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  border: Border(
                    bottom: BorderSide(color: primaryColor.withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mosque, color: primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '${mockScholars.length} ${l10n.dawahScholars}',
                      style: TextStyle(
                        color: mainTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: mockScholars.length,
                  itemBuilder: (context, index) {
                    final scholar = mockScholars[index];
                    final langColor = _langColor(scholar["languageCode"]);

                    return Card(
                      elevation: 3,
                      color: cardBgColor,
                      margin: const EdgeInsets.only(bottom: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScholarLecturesScreen(
                                scholarName: scholar["name"],
                                lectures: List<String>.from(scholar["lectures"]),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar with unique icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                                ),
                                child: Icon(
                                  scholar["icon"] as IconData,
                                  color: primaryColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Scholar info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scholar["name"]!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: mainTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Language badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: langColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: langColor.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            scholar["language"]!,
                                            style: TextStyle(
                                              color: langColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Lecture count badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.headphones, size: 11, color: primaryColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${scholar["lectureCount"]} ${l10n.lectures}',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: primaryColor.withOpacity(0.5), size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Scholar Lectures Screen ---
class ScholarLecturesScreen extends StatefulWidget {
  final String scholarName;
  final List<String> lectures;

  const ScholarLecturesScreen({
    Key? key,
    required this.scholarName,
    required this.lectures
  }) : super(key: key);

  @override
  State<ScholarLecturesScreen> createState() => _ScholarLecturesScreenState();
}

class _ScholarLecturesScreenState extends State<ScholarLecturesScreen> {
  final Map<String, int> _downloadStates = {}; // 0: not downloaded, 1: downloading, 2: downloaded, 3: playing
  final Map<String, int> _progressStates = {}; // progress percentage 0-100

  @override
  void initState() {
    super.initState();
    for (var lecture in widget.lectures) {
      _downloadStates[lecture] = 0;
      _progressStates[lecture] = 0;
    }
  }

  Future<void> _downloadSingleLecture(String lectureName) async {
    if (_downloadStates[lectureName] == 1 || _downloadStates[lectureName]! >= 2) return;

    setState(() {
      _downloadStates[lectureName] = 1;
      _progressStates[lectureName] = 0;
    });

    for (int i = 1; i <= 100; i += 20) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        _progressStates[lectureName] = i;
      });
    }

    setState(() {
      _downloadStates[lectureName] = 2;
    });
  }

  void _downloadAllLectures() {
    for (var lecture in widget.lectures) {
      if (_downloadStates[lecture] == 0) {
        _downloadSingleLecture(lecture);
      }
    }
  }

  void _togglePlayPause(String lectureName) {
    setState(() {
      _downloadStates[lectureName] = _downloadStates[lectureName] == 2 ? 3 : 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final Color primaryColor = AppTheme.getPrimaryColor(theme);
        final Color mainTextColor = AppTheme.getMainTextColor(theme);
        final Color borderColor = AppTheme.getBorderColor(theme);
        final Color cardBgColor = AppTheme.getCardBgColor(theme);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.scholarName),
          ),
          body: Column(
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: primaryColor.withOpacity(0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.headphones, color: primaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.availableItems(widget.lectures.length),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: mainTextColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _downloadAllLectures,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: borderColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.download_for_offline, size: 18),
                      label: Text(l10n.downloadAll),
                    ),
                  ],
                ),
              ),
              // Lectures list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: widget.lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = widget.lectures[index];
                    final state = _downloadStates[lecture] ?? 0;
                    final progress = _progressStates[lecture] ?? 0;

                    return Card(
                      color: cardBgColor,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Number badge
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    lecture,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: mainTextColor,
                                    ),
                                  ),
                                ),
                                _buildActionWidget(lecture, state, primaryColor),
                              ],
                            ),
                            // Progress bar
                            if (state == 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          minHeight: 6,
                                          backgroundColor: theme == QuranTheme.dark ? Colors.grey[800] : Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "$progress%",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionWidget(String lecture, int state, Color primaryColor) {
    if (state == 0) {
      return IconButton(
        icon: Icon(Icons.download_rounded, color: primaryColor),
        onPressed: () => _downloadSingleLecture(lecture),
      );
    } else if (state == 1) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(
          state == 3 ? Icons.pause_circle_filled : Icons.play_circle_fill,
          size: 32,
          color: primaryColor,
        ),
        onPressed: () => _togglePlayPause(lecture),
      );
    }
  }
}