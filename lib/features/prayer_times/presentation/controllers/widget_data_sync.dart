import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../data/models/prayer_time_model.dart';

class WidgetDataSync {
  static const String appGroupId = 'com.umer.quranzone'; // Not strictly needed for Android, but good practice
  static const String androidWidgetName = 'PrayerWidgetProvider';

  static Future<void> updateWidget(PrayerTimeModel model) async {
    try {
      final hijriDate = model.hijriDate.formattedEn; // Using EN to ensure it displays nicely, or could save both and let native decide
      final gregorianDate = DateFormat('d MMM yyyy').format(model.date);
      final location = model.locationLabel;
      
      final nextPrayer = model.nextPrayer;
      final prayerName = nextPrayer.prayer.name;
      
      // Capitalize first letter
      final formattedName = prayerName.substring(0, 1).toUpperCase() + prayerName.substring(1);
      final prayerTime = DateFormat('h:mm a').format(nextPrayer.time);
      final prayerTimestamp = nextPrayer.time.millisecondsSinceEpoch;

      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDate);
      await HomeWidget.saveWidgetData<String>('gregorian_date', gregorianDate);
      await HomeWidget.saveWidgetData<String>('location_label', location);
      await HomeWidget.saveWidgetData<String>('next_prayer_name', formattedName);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', prayerTime);
      await HomeWidget.saveWidgetData<int>('next_prayer_timestamp', prayerTimestamp);
      await HomeWidget.saveWidgetData<String>('day_segment', model.daySegment.name);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
      );
    } catch (e) {
      // Fail silently for widget updates
    }
  }
}
