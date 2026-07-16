import 'package:appwrite_user_app/app/controllers/settings_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Central helper for handling times in the **store's** timezone.
///
/// The store runs on its own timezone (configured in business setup), not the
/// customer's device timezone. All order-placement and scheduled-delivery times
/// are computed and displayed in that zone. Absolute instants are always stored
/// and compared in **UTC**; this helper only converts between UTC and the
/// store's wall-clock for building slots and for display.
///
/// The offset is a fixed number of minutes east of UTC (no DST) — correct for a
/// single non-DST region such as the default `Asia/Dhaka` (+06:00).
class StoreTime {
  const StoreTime._();

  /// The store's UTC offset. Falls back to +06:00 when settings aren't loaded.
  static Duration get offset {
    if (Get.isRegistered<SettingsController>()) {
      final setup = Get.find<SettingsController>().businessSetup;
      if (setup != null) return setup.timezoneOffset;
    }
    return const Duration(minutes: 360);
  }

  /// "Now" as the store's wall-clock (its Y/M/D/H/M fields read as store-local
  /// time). Use for slot generation / lead-time checks instead of
  /// `DateTime.now()`.
  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// Converts a UTC [instant] to the store's wall-clock for display/formatting.
  static DateTime toStore(DateTime instant) => instant.toUtc().add(offset);

  /// Builds the absolute **UTC** instant for a store wall-clock [date] at
  /// [hour]:[minute]. Only the Y/M/D of [date] are used.
  static DateTime wallClockToUtc(DateTime date, {int hour = 0, int minute = 0}) {
    return DateTime.utc(date.year, date.month, date.day, hour, minute)
        .subtract(offset);
  }

  /// Formats a UTC [instant] in the store's timezone with [pattern].
  static String format(DateTime instant, String pattern) =>
      DateFormat(pattern).format(toStore(instant));

  /// Resolves a delivery slot — a store wall-clock [date] plus a label like
  /// "10:00 AM - 11:00 AM" — into an absolute UTC start/end range. Slot labels
  /// are always emitted in English, so parsing is language-independent. Returns
  /// null when the label can't be parsed.
  static ({DateTime start, DateTime end})? slotToUtcRange(
    DateTime date,
    String slotLabel,
  ) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(slotLabel.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final period = match.group(3)!;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return (
      start: wallClockToUtc(date, hour: hour),
      end: wallClockToUtc(date, hour: hour + 1),
    );
  }
}
