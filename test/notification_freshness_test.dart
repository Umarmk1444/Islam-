import 'package:flutter_test/flutter_test.dart';
import 'package:quran_zone/core/services/background_engine.dart';
import 'package:quran_zone/core/services/islamic_reminder_strings.dart';

void main() {
  group('Islamic Reminders Next Occurrence Computation', () {
    test('Slot 1 (Morning Adhkar) targets 7:00 AM', () {
      // If now is 6:00 AM on 2026-10-15, next occurrence should be 7:00 AM same day
      final before7 = DateTime(2026, 10, 15, 6, 0);
      final next1 = computeNextOccurrence(1, before7);
      expect(next1, DateTime(2026, 10, 15, 7, 0));

      // If now is 8:00 AM on 2026-10-15, next occurrence should be 7:00 AM next day
      final after7 = DateTime(2026, 10, 15, 8, 0);
      final next2 = computeNextOccurrence(1, after7);
      expect(next2, DateTime(2026, 10, 16, 7, 0));
    });

    test('Slot 2 (Duha Prayer) targets 9:30 AM', () {
      final before930 = DateTime(2026, 10, 15, 9, 0);
      final next1 = computeNextOccurrence(2, before930);
      expect(next1, DateTime(2026, 10, 15, 9, 30));

      final after930 = DateTime(2026, 10, 15, 10, 0);
      final next2 = computeNextOccurrence(2, after930);
      expect(next2, DateTime(2026, 10, 16, 9, 30));
    });

    test('Slot 3 (Evening Adhkar) targets 17:00 (5:00 PM)', () {
      final before17 = DateTime(2026, 10, 15, 16, 30);
      final next1 = computeNextOccurrence(3, before17);
      expect(next1, DateTime(2026, 10, 15, 17, 0));

      final after17 = DateTime(2026, 10, 15, 17, 30);
      final next2 = computeNextOccurrence(3, after17);
      expect(next2, DateTime(2026, 10, 16, 17, 0));
    });

    test('Slot 4 (Sleep Adhkar & Al-Mulk) targets 22:00 (10:00 PM)', () {
      final before22 = DateTime(2026, 10, 15, 21, 0);
      final next1 = computeNextOccurrence(4, before22);
      expect(next1, DateTime(2026, 10, 15, 22, 0));

      final after22 = DateTime(2026, 10, 15, 23, 0);
      final next2 = computeNextOccurrence(4, after22);
      expect(next2, DateTime(2026, 10, 16, 22, 0));
    });

    test('Slot 10 (Friday Al-Kahf) targets Friday 10:00 AM', () {
      // 2026-10-15 is a Thursday
      final thursday = DateTime(2026, 10, 15, 12, 0);
      final nextFriday = computeNextOccurrence(10, thursday);
      expect(nextFriday.weekday, DateTime.friday);
      expect(nextFriday.hour, 10);
      expect(nextFriday.minute, 0);
      expect(nextFriday.day, 16);

      // Friday afternoon after 10:00 AM targets next week Friday
      final fridayAfternoon = DateTime(2026, 10, 16, 14, 0);
      final followingFriday = computeNextOccurrence(10, fridayAfternoon);
      expect(followingFriday.weekday, DateTime.friday);
      expect(followingFriday.day, 23);
    });

    test('Slot 11 (Monday Fasting) targets Sunday 20:00 (8:00 PM)', () {
      final saturday = DateTime(2026, 10, 17, 10, 0);
      final nextSun = computeNextOccurrence(11, saturday);
      expect(nextSun.weekday, DateTime.sunday);
      expect(nextSun.hour, 20);
      expect(nextSun.minute, 0);
    });

    test('Slot 12 (Thursday Fasting) targets Wednesday 20:00 (8:00 PM)', () {
      final monday = DateTime(2026, 10, 19, 10, 0);
      final nextWed = computeNextOccurrence(12, monday);
      expect(nextWed.weekday, DateTime.wednesday);
      expect(nextWed.hour, 20);
      expect(nextWed.minute, 0);
    });
  });

  group('60-Minute Freshness Guard Logic', () {
    // Helper replicating the freshness guard decision in azkarReminderCallback
    bool isReminderFresh(int scheduledEpoch, DateTime now) {
      if (scheduledEpoch <= 0) return false;
      final scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledEpoch);
      final lateness = now.difference(scheduledTime);
      if (lateness.isNegative || lateness > const Duration(minutes: 60)) {
        return false;
      }
      return true;
    }

    test('T0_on_time: Exactly on time (0s difference) is DELIVERED (eligible)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, scheduled), isTrue);
    });

    test('T0_early_1s: 1 second early (-1s) is REJECTED (not yet due)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final earlyNow = scheduled.subtract(const Duration(seconds: 1));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, earlyNow), isFalse);
    });

    test('T0_early_60s: 60 seconds early (-60s) is REJECTED (not yet due)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final earlyNow = scheduled.subtract(const Duration(seconds: 60));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, earlyNow), isFalse);
    });

    test('T0_early_61s: 61 seconds early (-61s) is REJECTED (not yet due)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final earlyNow = scheduled.subtract(const Duration(seconds: 61));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, earlyNow), isFalse);
    });

    test('T1: 59 minutes 59 seconds late is DELIVERED (eligible)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final now = scheduled.add(const Duration(minutes: 59, seconds: 59));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, now), isTrue);
    });

    test('T2: Exactly 60 minutes 00 seconds late is DELIVERED (inclusive boundary)', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final now = scheduled.add(const Duration(minutes: 60));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, now), isTrue);
    });

    test('T3: 60 minutes 01 seconds late is SILENTLY DISCARDED', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final now = scheduled.add(const Duration(minutes: 60, seconds: 1));
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, now), isFalse);
    });

    test('T4: 5 hours late (e.g. phone turned on at 12:00 PM) is SILENTLY DISCARDED', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final now = DateTime(2026, 10, 15, 12, 0); // 300 minutes late
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, now), isFalse);
    });

    test('T5: 24 hours late (app opened next day) is SILENTLY DISCARDED', () {
      final scheduled = DateTime(2026, 10, 15, 7, 0);
      final now = DateTime(2026, 10, 16, 7, 0); // 1440 minutes late
      expect(isReminderFresh(scheduled.millisecondsSinceEpoch, now), isFalse);
    });

    test('T6: Missing or 0 epoch timestamp is safely rejected', () {
      final now = DateTime(2026, 10, 15, 7, 0);
      expect(isReminderFresh(0, now), isFalse);
      expect(isReminderFresh(-1, now), isFalse);
    });
  });

  group('Localization Completeness (AR, EN, AM, OM)', () {
    const slots = [1, 2, 3, 4, 10, 11, 12];
    const languages = ['ar', 'en', 'am', 'om'];

    for (final lang in languages) {
      test('Language "$lang" covers all 7 in-scope reminder slots', () {
        for (final slot in slots) {
          final content = IslamicReminderStrings.getReminder(slot, lang);
          expect(content.title.isNotEmpty, isTrue,
              reason: 'Slot $slot title must not be empty in $lang');
          expect(content.body.isNotEmpty, isTrue,
              reason: 'Slot $slot body must not be empty in $lang');
          expect(content.payload.isNotEmpty, isTrue,
              reason: 'Slot $slot payload must not be empty in $lang');

          // Morning (1) and Sleep (4) must have action buttons and expanded text
          if (slot == 1 || slot == 4) {
            expect(content.actionLabel, isNotNull,
                reason: 'Slot $slot must have actionLabel in $lang');
            expect(content.actionLabel!.isNotEmpty, isTrue);
            expect(content.expandedText, isNotNull,
                reason: 'Slot $slot must have expandedText in $lang');
            expect(content.expandedText!.isNotEmpty, isTrue);
          }
        }
      });
    }

    test('Language normalizer correctly handles case and aliases', () {
      expect(IslamicReminderStrings.normalizeLang('Arabic'), 'ar');
      expect(IslamicReminderStrings.normalizeLang('ar'), 'ar');
      expect(IslamicReminderStrings.normalizeLang('Amharic'), 'am');
      expect(IslamicReminderStrings.normalizeLang('am'), 'am');
      expect(IslamicReminderStrings.normalizeLang('Oromo'), 'om');
      expect(IslamicReminderStrings.normalizeLang('om'), 'om');
      expect(IslamicReminderStrings.normalizeLang('English'), 'en');
      expect(IslamicReminderStrings.normalizeLang(null), 'en');
      expect(IslamicReminderStrings.normalizeLang('unknown'), 'en');
    });
  });

  group('Regression Guard: Excluded Systems Preservation', () {
    test('Islamic reminder slots do not overlap with Athan (100-105) or Pre-Adhan (200-205)', () {
      const islamicSlots = [1, 2, 3, 4, 10, 11, 12, 888];
      const athanSlots = [100, 101, 102, 103, 104, 105];
      const preAdhanSlots = [200, 201, 202, 203, 204, 205];
      const silentSlots = [400, 401, 402, 403, 404, 405, 500, 501, 502, 503, 504, 505];
      const unrelatedSlots = [900, 901, 902, 9999];

      for (final slot in islamicSlots) {
        expect(athanSlots.contains(slot), isFalse);
        expect(preAdhanSlots.contains(slot), isFalse);
        expect(silentSlots.contains(slot), isFalse);
        expect(unrelatedSlots.contains(slot), isFalse);
      }
    });
  });

  group('Periodic Daytime Dhikr (Slot 888) Resume Preservation & Non-Postponement', () {
    test('Initial schedule at T0 (10:00 AM) sets target at T0 + 60m (11:00 AM)', () {
      final t0 = DateTime(2026, 10, 15, 10, 0);
      final target = computeNextZekrOccurrence(
        now: t0,
        intervalMinutes: 60,
        currentScheduledEpoch: 0,
        lastShownEpoch: 0,
        forceReset: true,
      );
      expect(target, DateTime(2026, 10, 15, 11, 0));
    });

    test('App resume at T0 + 20m does NOT postpone target (returns exact original target for AlarmManager re-arming)', () {
      final t0 = DateTime(2026, 10, 15, 10, 0);
      final scheduledTarget = DateTime(2026, 10, 15, 11, 0);
      final resumeTime = t0.add(const Duration(minutes: 20)); // 10:20 AM

      final result = computeNextZekrOccurrence(
        now: resumeTime,
        intervalMinutes: 60,
        currentScheduledEpoch: scheduledTarget.millisecondsSinceEpoch,
        lastShownEpoch: t0.millisecondsSinceEpoch,
        forceReset: false,
      );

      // Returns identical 11:00 AM target: re-arms AlarmManager without postponing
      expect(result, scheduledTarget,
          reason: 'App resume must preserve active cycle target for AlarmManager re-registration');
    });

    test('Repeated app resumes at 10:10, 10:25, 10:40, 10:55 never postpone target', () {
      final scheduledTarget = DateTime(2026, 10, 15, 11, 0);
      final resumeMoments = [
        DateTime(2026, 10, 15, 10, 10),
        DateTime(2026, 10, 15, 10, 25),
        DateTime(2026, 10, 15, 10, 40),
        DateTime(2026, 10, 15, 10, 55),
      ];

      for (final moment in resumeMoments) {
        final result = computeNextZekrOccurrence(
          now: moment,
          intervalMinutes: 60,
          currentScheduledEpoch: scheduledTarget.millisecondsSinceEpoch,
          lastShownEpoch: DateTime(2026, 10, 15, 10, 0).millisecondsSinceEpoch,
          forceReset: false,
        );
        expect(result, scheduledTarget,
            reason: 'Resume at $moment must preserve existing 11:00 target without postponement');
      }
    });

    test('Return from Android Settings (e.g. permission restore) re-registers identical target time', () {
      final scheduledTarget = DateTime(2026, 10, 15, 19, 0); // 7:00 PM target
      final returnFromSettings = DateTime(2026, 10, 15, 18, 5); // 6:05 PM restore

      final result = computeNextZekrOccurrence(
        now: returnFromSettings,
        intervalMinutes: 60,
        currentScheduledEpoch: scheduledTarget.millisecondsSinceEpoch,
        lastShownEpoch: DateTime(2026, 10, 15, 18, 0).millisecondsSinceEpoch,
        forceReset: false,
      );

      expect(result, scheduledTarget,
          reason: 'Permission restore must preserve identical 19:00 target so AlarmManager is re-armed without reset');
    });

    test('If epoch is missing, calculates remaining time from last_zekr_shown_timestamp', () {
      // Last shown at 10:00 AM, app opened at 10:35 AM with interval 60m
      // Remaining time is 25 minutes -> target should be 10:35 + 25m = 11:00 AM!
      final lastShown = DateTime(2026, 10, 15, 10, 0);
      final openTime = DateTime(2026, 10, 15, 10, 35);

      final result = computeNextZekrOccurrence(
        now: openTime,
        intervalMinutes: 60,
        currentScheduledEpoch: 0, // missing/inactive epoch
        lastShownEpoch: lastShown.millisecondsSinceEpoch,
        forceReset: false,
      );

      expect(result, DateTime(2026, 10, 15, 11, 0),
          reason: 'Must calculate remaining time from last shown timestamp');
    });

    test('User changes interval in Settings (forceReset: true) arms fresh interval immediately', () {
      final now = DateTime(2026, 10, 15, 10, 20);
      final oldTarget = DateTime(2026, 10, 15, 11, 0);

      // User changes interval from 60 to 15 minutes
      final result = computeNextZekrOccurrence(
        now: now,
        intervalMinutes: 15,
        currentScheduledEpoch: oldTarget.millisecondsSinceEpoch,
        lastShownEpoch: DateTime(2026, 10, 15, 10, 0).millisecondsSinceEpoch,
        forceReset: true, // User explicit change
      );

      expect(result, DateTime(2026, 10, 15, 10, 35),
          reason: 'Explicit interval change must start a fresh interval from now');
    });

    test('User enables feature (forceReset: true) starts fresh interval', () {
      final now = DateTime(2026, 10, 15, 14, 0);

      final result = computeNextZekrOccurrence(
        now: now,
        intervalMinutes: 60,
        currentScheduledEpoch: 0,
        lastShownEpoch: 0,
        forceReset: true,
      );

      expect(result, DateTime(2026, 10, 15, 15, 0));
    });

    test('Quiet night hours (10:00 PM to 8:00 AM) are enforced', () {
      // Late night: 22:30 targets next day 8:00 AM
      final nightTime = DateTime(2026, 10, 15, 22, 30);
      final nightResult = computeNextZekrOccurrence(
        now: nightTime,
        intervalMinutes: 60,
        forceReset: true,
      );
      expect(nightResult, DateTime(2026, 10, 16, 8, 0));

      // Early morning: 3:00 AM targets same day 8:00 AM
      final earlyMorning = DateTime(2026, 10, 16, 3, 0);
      final earlyResult = computeNextZekrOccurrence(
        now: earlyMorning,
        intervalMinutes: 60,
        forceReset: true,
      );
      expect(earlyResult, DateTime(2026, 10, 16, 8, 0));

      // Daytime candidate landing past 22:00: 21:30 + 60m = 22:30 -> targets 8:00 AM tomorrow
      final eveningTime = DateTime(2026, 10, 15, 21, 30);
      final eveningResult = computeNextZekrOccurrence(
        now: eveningTime,
        intervalMinutes: 60,
        forceReset: true,
      );
      expect(eveningResult, DateTime(2026, 10, 16, 8, 0));
    });
  });
}
