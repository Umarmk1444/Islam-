
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;
import '../core/database/database_helper.dart';
import '../features/prayer_times/data/models/prayer_config.dart';


enum ZekrContext {
  wakingUp,
  morning,
  duha,
  afterPrayer,
  evening,
  beforeSleep,
  general
}

class ContextualZekr {
  final int id;
  final String zekr;
  final ZekrContext context;
  final String title;

  ContextualZekr({
    required this.id,
    required this.zekr,
    required this.context,
    required this.title,
  });
}

class AzkarService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Retains the old behavior for overlay/general usage if needed, 
  /// but can be replaced by context-aware.
  Future<String?> getRandomShortZekr() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT zekr FROM azkar WHERE LENGTH(zekr) < 80 ORDER BY RANDOM() LIMIT 1',
    );
    
    if (rows.isNotEmpty) {
      return rows.first['zekr'] as String?;
    }
    return null;
  }

  /// The new intelligent context-aware engine.
  Future<ContextualZekr?> getSmartContextualZekr({bool shortOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final ZekrContext currentContext = _determineCurrentContext(prefs);
    return _fetchZekrForContext(currentContext, prefs, shortOnly: shortOnly);
  }

  ZekrContext _determineCurrentContext(SharedPreferences prefs) {
    final rawConfig = prefs.getString(PrayerConfig.prefKey);
    if (rawConfig == null) return ZekrContext.general;
    
    final config = PrayerConfig.fromJsonString(rawConfig);
    final coordinates = adhan.Coordinates(config.latitude, config.longitude);
    adhan.CalculationParameters params;
    
    switch (config.method) {
      case CalculationMethodEnum.ummAlQura:
        params = adhan.CalculationMethod.umm_al_qura.getParameters();
        break;
      case CalculationMethodEnum.egyptian:
        params = adhan.CalculationMethod.egyptian.getParameters();
        break;
      case CalculationMethodEnum.mwl:
        params = adhan.CalculationMethod.muslim_world_league.getParameters();
        break;
      case CalculationMethodEnum.isna:
        params = adhan.CalculationMethod.north_america.getParameters();
        break;
      case CalculationMethodEnum.karachi:
        params = adhan.CalculationMethod.karachi.getParameters();
        break;
    }
    params.madhab = config.madhab == MadhabEnum.hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    
    final now = DateTime.now();
    final todayTimes = adhan.PrayerTimes(coordinates, adhan.DateComponents.from(now), params);
    
    // Check After Prayer (within 30 mins)
    final prayers = [todayTimes.fajr, todayTimes.dhuhr, todayTimes.asr, todayTimes.maghrib, todayTimes.isha];
    for (var prayerTime in prayers) {
      if (now.isAfter(prayerTime) && now.isBefore(prayerTime.add(const Duration(minutes: 30)))) {
        return ZekrContext.afterPrayer;
      }
    }
    
    // Check Morning (Fajr to Sunrise)
    if (now.isAfter(todayTimes.fajr) && now.isBefore(todayTimes.sunrise)) {
      return ZekrContext.morning;
    }
    
    // Check Duha (Sunrise + 20 mins to Dhuhr - 15 mins)
    final duhaStart = todayTimes.sunrise.add(const Duration(minutes: 20));
    final duhaEnd = todayTimes.dhuhr.subtract(const Duration(minutes: 15));
    if (now.isAfter(duhaStart) && now.isBefore(duhaEnd)) {
      return ZekrContext.duha;
    }
    
    // Check Evening (Asr to Maghrib)
    if (now.isAfter(todayTimes.asr) && now.isBefore(todayTimes.maghrib)) {
      return ZekrContext.evening;
    }
    
    // Check Before Sleep (from 21:00 to 03:00)
    if (now.hour >= 21 || now.hour < 3) {
      return ZekrContext.beforeSleep;
    }
    
    // Check Waking Up (03:00 to Fajr)
    if (now.hour >= 3 && now.isBefore(todayTimes.fajr)) {
      return ZekrContext.wakingUp;
    }
    
    return ZekrContext.general;
  }

  Future<ContextualZekr?> _fetchZekrForContext(ZekrContext context, SharedPreferences prefs, {bool shortOnly = false}) async {
    final db = await _dbHelper.database;
    
    String? categoryFilter;
    String title = "✨ ذكر الله";
    
    switch (context) {
      case ZekrContext.morning:
        categoryFilter = "أذكار الصباح";
        title = "🌅 أذكار الصباح";
        break;
      case ZekrContext.evening:
        categoryFilter = "أذكار المساء";
        title = "🌇 أذكار المساء";
        break;
      case ZekrContext.wakingUp:
        categoryFilter = "أذكار الاستيقاظ";
        title = "🌤️ أذكار الاستيقاظ";
        break;
      case ZekrContext.beforeSleep:
        categoryFilter = "اذكار النوم";
        title = "🌙 أذكار النوم";
        break;
      case ZekrContext.afterPrayer:
        categoryFilter = "دعاء بعد الصلاة";
        title = "🕌 أذكار بعد الصلاة";
        break;
      case ZekrContext.duha:
        // Duha doesn't have a specific table category usually, so use general dhikr with a gentle reminder title.
        categoryFilter = null;
        title = "☀️ وقت الضحى";
        break;
      case ZekrContext.general:
        categoryFilter = null;
        title = "✨ ذكر الله";
        break;
    }
    
    String lengthFilter = shortOnly ? " AND LENGTH(zekr) < 80" : "";
    List<Map<String, dynamic>> rows = [];
    
    if (categoryFilter != null) {
      // For categories that exist in DB
      rows = await db.rawQuery(
        "SELECT id, zekr FROM azkar WHERE type = ? $lengthFilter",
        [categoryFilter]
      );
    } 
    
    if (rows.isEmpty) {
      // Fallback to random general adhkar (excluding specific ones if possible)
      // The DB has things like 'أدعية نبوية' or just other types. Let's get anything < 80 chars
      rows = await db.rawQuery(
        "SELECT id, zekr FROM azkar WHERE LENGTH(zekr) < 80 AND type NOT IN ('أذكار الصباح', 'أذكار المساء', 'أذكار الاستيقاظ', 'اذكار النوم', 'دعاء بعد الصلاة')"
      );
    }
    
    if (rows.isEmpty) {
      // Absolute fallback
      rows = await db.rawQuery("SELECT id, zekr FROM azkar WHERE LENGTH(zekr) < 80");
    }
    
    if (rows.isNotEmpty) {
      // Implement smart rotation by filtering out recently shown items
      final List<String> recentIds = prefs.getStringList('recent_azkar_ids') ?? [];
      
      List<Map<String, dynamic>> candidates = rows.where((row) => !recentIds.contains(row['id'].toString())).toList();
      
      if (candidates.isEmpty) {
        // If all have been shown recently, reset history for this pool
        candidates = rows;
        recentIds.clear();
      }
      
      // Pick random from candidates
      final selected = candidates[Random().nextInt(candidates.length)];
      final selectedIdStr = selected['id'].toString();
      
      // Update history (keep last 50)
      recentIds.add(selectedIdStr);
      if (recentIds.length > 50) {
        recentIds.removeAt(0);
      }
      await prefs.setStringList('recent_azkar_ids', recentIds);
      
      // For Duha, we can append a reminder for Salat al-Duha if it's general
      String text = selected['zekr'] as String;
      if (context == ZekrContext.duha && categoryFilter == null) {
        if (!shortOnly) {
           text = "$text\n\n(لا تنسَ صلاة الضحى، فهي صدقة عن كل مفصل من جسدك)";
        }
      }
      
      return ContextualZekr(
        id: selected['id'] as int,
        zekr: text,
        context: context,
        title: title,
      );
    }
    
    return null;
  }
}
