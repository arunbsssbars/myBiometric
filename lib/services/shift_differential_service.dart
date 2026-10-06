import '../domain/models/shift_differential_policy.dart';

/// Service for calculating shift differentials (night shift, weekend premiums, etc.)
class ShiftDifferentialService {
  /// Calculate hours falling inside the night window (e.g. 22:00 to 06:00 next day)
  static double calculateNightShiftHours({
    required DateTime punchIn,
    required DateTime punchOut,
    int nightStartHour = 22,
    int nightEndHour = 6,
  }) {
    if (punchOut.isBefore(punchIn)) return 0.0;

    double nightMinutes = 0.0;
    DateTime cursor = punchIn;

    // Iterate minute-by-minute or in 15-min intervals for precision
    while (cursor.isBefore(punchOut)) {
      final hour = cursor.hour;
      final isNight = (nightStartHour > nightEndHour)
          ? (hour >= nightStartHour || hour < nightEndHour)
          : (hour >= nightStartHour && hour < nightEndHour);

      if (isNight) {
        nightMinutes += 1.0;
      }
      cursor = cursor.add(const Duration(minutes: 1));
    }

    return nightMinutes / 60.0;
  }

  /// Calculate shift differential earnings and split hours
  static ShiftDifferentialResult evaluateShiftDifferential({
    required DateTime punchIn,
    required DateTime punchOut,
    required double baseHourlyRate,
    List<ShiftDifferentialRule> rules = const [],
    List<DateTime> recognizedHolidays = const [],
  }) {
    final totalDuration = punchOut.difference(punchIn);
    final totalHours = totalDuration.inMinutes > 0 ? totalDuration.inMinutes / 60.0 : 0.0;

    final isWeekend = punchIn.weekday == DateTime.saturday || punchIn.weekday == DateTime.sunday;
    final isHoliday = recognizedHolidays.any((h) =>
        h.year == punchIn.year && h.month == punchIn.month && h.day == punchIn.day);

    double nightHours = 0.0;
    final nightRule = rules.where((r) => r.type == DifferentialType.nightShift).firstOrNull;
    if (nightRule != null) {
      final startH = nightRule.nightWindowStart?.hour ?? 22;
      final endH = nightRule.nightWindowEnd?.hour ?? 6;
      nightHours = calculateNightShiftHours(
        punchIn: punchIn,
        punchOut: punchOut,
        nightStartHour: startH,
        nightEndHour: endH,
      );
    }

    double weekendHours = isWeekend ? totalHours : 0.0;
    double holidayHours = isHoliday ? totalHours : 0.0;

    double premiumAmount = 0.0;

    for (final rule in rules) {
      if (rule.type == DifferentialType.nightShift && nightHours > 0) {
        premiumAmount += (nightHours * baseHourlyRate * (rule.rateMultiplier - 1.0)) +
            (nightHours * rule.flatBonusPerHour);
      } else if (rule.type == DifferentialType.weekend && isWeekend) {
        premiumAmount += (weekendHours * baseHourlyRate * (rule.rateMultiplier - 1.0)) +
            (weekendHours * rule.flatBonusPerHour);
      } else if (rule.type == DifferentialType.holiday && isHoliday) {
        premiumAmount += (holidayHours * baseHourlyRate * (rule.rateMultiplier - 1.0)) +
            (holidayHours * rule.flatBonusPerHour);
      }
    }

    final standardHours = (totalHours - nightHours) > 0 ? (totalHours - nightHours) : 0.0;

    return ShiftDifferentialResult(
      standardHours: standardHours,
      nightHours: nightHours,
      weekendHours: weekendHours,
      holidayHours: holidayHours,
      totalPremiumAmount: premiumAmount,
    );
  }
}
