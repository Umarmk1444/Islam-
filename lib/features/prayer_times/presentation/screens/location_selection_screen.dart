import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/prayer_controller.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key, required this.controller});
  final PrayerController controller;

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  bool _isLoading = true;

  // Map: Country Name -> List of City Maps (with lat, lng, etc.)
  final Map<String, List<dynamic>> _countryMap = {};
  List<String> _countries = [];

  String? _selectedCountry;
  dynamic _selectedCity; // The actual JSON object for the selected city

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final byteData = await rootBundle.load('assets/cities.json.gz');
      final compressedBytes = byteData.buffer.asUint8List();
      final result = await compute(_parseCitiesFromBytes, compressedBytes);

      setState(() {
        _countryMap.addAll(result.map);
        _countries = result.countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSave() {
    if (_selectedCity == null) return;

    final cityStr = _selectedCity['city'] as String;
    final countryStr = _selectedCity['country'] as String;
    final lat = (_selectedCity['lat'] as num).toDouble();
    final lng = (_selectedCity['lng'] as num).toDouble();
    final label = '$cityStr, $countryStr';

    widget.controller.setManualLocation(lat, lng, label);
    Navigator.pop(context);
  }

  Future<void> _showSearchableSheet({
    required String title,
    required List<dynamic> items,
    required String Function(dynamic) labelBuilder,
    required void Function(dynamic) onSelected,
  }) async {
    final theme = AppTheme.notifier.value;
    final bg = AppTheme.getScreenBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);
    final primary = AppTheme.getPrimaryColor(theme);
    final isDark = theme == QuranTheme.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SearchableListSheet(
          title: title,
          items: items,
          labelBuilder: labelBuilder,
          bg: bg,
          textColor: textColor,
          primary: primary,
          isDark: isDark,
          onSelected: (val) {
            Navigator.pop(context);
            onSelected(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final l10n = AppLocalizations.of(context)!;
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primary = AppTheme.getPrimaryColor(theme);
        final isDark = theme == QuranTheme.dark;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.selectLocation,
              style: AppTextStyles.headlineMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: primary))
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.country,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SelectionField(
                        hint: 'Select a country',
                        value: _selectedCountry,
                        icon: Icons.public,
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                        onTap: () {
                          _showSearchableSheet(
                            title: 'Select Country',
                            items: _countries,
                            labelBuilder: (item) => item as String,
                            onSelected: (val) {
                              if (_selectedCountry != val) {
                                setState(() {
                                  _selectedCountry = val as String;
                                  _selectedCity =
                                      null; // reset city when country changes
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.cityRegion,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SelectionField(
                        hint: 'Select a city',
                        value: _selectedCity != null
                            ? '${_selectedCity['city']}, ${_selectedCity['state']}'
                            : null,
                        icon: Icons.location_city_rounded,
                        primary: primary,
                        textColor: textColor,
                        isDark: isDark,
                        isDisabled: _selectedCountry == null,
                        onTap: () {
                          if (_selectedCountry == null) return;
                          _showSearchableSheet(
                            title: 'Select City',
                            items: _countryMap[_selectedCountry] ?? [],
                            labelBuilder: (item) => '${item['city']}, ${item['state']}',
                            onSelected: (val) {
                              setState(() {
                                _selectedCity = val;
                              });
                            },
                          );
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _selectedCity != null ? _onSave : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          disabledForegroundColor:
                              isDark ? Colors.white38 : Colors.black38,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.saveLocation,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedCity != null
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.primary,
    required this.textColor,
    required this.isDark,
    required this.onTap,
    this.isDisabled = false,
  });

  final String hint;
  final String? value;
  final IconData icon;
  final Color primary;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03))
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isDisabled || isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled ? textColor.withValues(alpha: 0.3) : primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value ?? hint,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: value != null
                      ? textColor
                      : textColor.withValues(alpha: isDisabled ? 0.3 : 0.5),
                  fontWeight:
                      value != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textColor.withValues(alpha: isDisabled ? 0.2 : 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableListSheet extends StatefulWidget {
  const _SearchableListSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    required this.bg,
    required this.textColor,
    required this.primary,
    required this.isDark,
    required this.onSelected,
  });

  final String title;
  final List<dynamic> items;
  final String Function(dynamic) labelBuilder;
  final Color bg;
  final Color textColor;
  final Color primary;
  final bool isDark;
  final void Function(dynamic) onSelected;

  @override
  State<_SearchableListSheet> createState() => _SearchableListSheetState();
}

class _SearchableListSheetState extends State<_SearchableListSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtered = widget.items;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filtered = widget.items.where((item) {
        return widget.labelBuilder(item).toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: widget.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: AppTextStyles.bodyLarge.copyWith(color: widget.textColor),
              decoration: InputDecoration(
                hintText: l10n.search,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: widget.textColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.search, color: widget.primary),
                filled: true,
                fillColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: widget.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      final label = widget.labelBuilder(item);
                      return ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: widget.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: widget.textColor.withValues(alpha: 0.3)),
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ParseResult {
  final Map<String, List<dynamic>> map;
  final List<String> countries;
  _ParseResult(this.map, this.countries);
}

_ParseResult _parseCitiesFromBytes(Uint8List compressedBytes) {
  final uncompressedBytes = GZipCodec().decoder.convert(compressedBytes);
  final jsonString = utf8.decode(uncompressedBytes);
  final data = json.decode(jsonString) as List;
  final map = <String, List<dynamic>>{};
  for (final countryItem in data) {
    final countryName = countryItem['name'] as String;
    final states = countryItem['states'] as List? ?? [];
    final citiesList = <dynamic>[];

    for (final state in states) {
      final stateName = state['name'] as String;
      final cities = state['cities'] as List? ?? [];
      for (final city in cities) {
        final latRaw = city['latitude'];
        final lngRaw = city['longitude'];
        double lat = 0.0;
        double lng = 0.0;
        if (latRaw is String) {
          lat = double.tryParse(latRaw) ?? 0.0;
        } else if (latRaw is num) {
          lat = latRaw.toDouble();
        }
        
        if (lngRaw is String) {
          lng = double.tryParse(lngRaw) ?? 0.0;
        } else if (lngRaw is num) {
          lng = lngRaw.toDouble();
        }

        citiesList.add({
          'country': countryName,
          'state': stateName,
          'city': city['name'],
          'lat': lat,
          'lng': lng,
        });
      }
    }
    if (citiesList.isNotEmpty) {
      map[countryName] = citiesList;
    }
  }

  final sortedCountries = map.keys.toList()..sort();
  for (final list in map.values) {
    list.sort((a, b) => (a['city'] as String).compareTo(b['city'] as String));
  }
  return _ParseResult(map, sortedCountries);
}
