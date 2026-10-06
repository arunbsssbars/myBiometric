import 'dart:math';
import '../domain/models/overtime_policy.dart';

/// Individual day overtime computation result
class DailyOvertimeResult {
  final DateTime date;
  final int totalWorkMinutes;
  final int regularMinutes;
  final int standardOvertimeMinutes; // 1.5x daily overtime
  final int doubleOvertimeMinutes; // 2.0x daily double overtime
  final int restDayMinutes;
  final int holidayMinutes;
  final bool isRestDay;
  final bool isHoliday;

  const DailyOvertimeResult({
    required this.date,
    required this.totalWorkMinutes,
    required this.regularMinutes,
    this.standardOvertimeMinutes = 0,
    this.doubleOvertimeMinutes = 0,
    this.restDayMinutes = 0,
    this.holidayMinutes = 0,
    this.isRestDay = false,
    this.isHoliday = false,
  });

  double get regularHours => regularMinutes / 60.0;
  double get standardOvertimeHours => standardOvertimeMinutes / 60.0;
  double get doubleOvertimeHours => doubleOvertimeMinutes / 60.0;
  double get restDayHours => restDayMinutes / 60.0;
  double get holidayHours => holidayMinutes / 60.0;
  double get totalHours => totalWorkMinutes / 60.0;

  /// Effective overtime hours combining all premium tiers
  double get totalOvertimeHours =>
      standardOvertimeHours + doubleOvertimeHours + restDayHours + holidayHours;

  /// Weighted equivalent payable hours applying tier multipliers
  double getWeightedPayableHours(OvertimePolicy policy) {
    if (!policy.isEnabled) return totalHours;
    return (regularMinutes / 60.0) * 1.0 +
        (standardOvertimeMinutes / 60.0) * policy.standardOvertimeMultiplier +
        (doubleOvertimeMinutes / 60.0) * policy.doubleOvertimeMultiplier +
        (restDayMinutes / 60.0) * policy.restDayMultiplier +
        (holidayMinutes / 60.0) * policy.holidayMultiplier;
  }
}

/// Period-level aggregated overtime breakdown (daily + weekly roll-up)
class OvertimeBreakdown {
  final List<DailyOvertimeResult> dailyResults;
  final int totalRegularMinutes;
  final int totalDailyOtMinutes;
  final int totalDailyDoubleOtMinutes;
  final int totalWeeklyOtMinutes; // Excess weekly regular hours converted to OT
  final int totalRestDayMinutes;
  final int totalHolidayMinutes;
  final double totalWeightedPayableHours;
  final OvertimePolicy policy;

  const OvertimeBreakdown({
    required this.dailyResults,
    required this.totalRegularMinutes,
    required this.totalDailyOtMinutes,
    required this.totalDailyDoubleOtMinutes,
    required this.totalWeeklyOtMinutes,
    required this.totalRestDayMinutes,
    required this.totalHolidayMinutes,
    required this.totalWeightedPayableHours,
    required this.policy,
  });

  double get regularHours => totalRegularMinutes / 60.0;
  double get dailyOtHours => totalDailyOtMinutes / 60.0;
  double get doubleOtHours => totalDailyDoubleOtMinutes / 60.0;
  double get weeklyOtHours => totalWeeklyOtMinutes / 60.0;
  double get restDayHours => totalRestDayMinutes / 60.0;
  double get holidayHours => totalHolidayMinutes / 60.0;
  
  /// Total premium overtime hours across daily, weekly, rest day, and holiday
  double get totalOvertimeHours =>
      dailyOtHours + doubleOtHours + weeklyOtHours + restDayHours + holidayHours;

  double get totalLoggedHours =>
      (totalRegularMinutes +
          totalDailyOtMinutes +
          totalDailyDoubleOtMinutes +
          totalWeeklyOtMinutes +
          totalRestDayMinutes +
          totalHolidayMinutes) /
      60.0;

  String get formattedRegularHours => '${regularHours.toStringAsFixed(1)} hrs';
  String get formattedOvertimeHours => '${totalOvertimeHours.toStringAsFixed(1)} hrs';
  String get formattedWeightedHours => '${totalWeightedPayableHours.toStringAsFixed(1)} hrs';
}

/// Service providing enterprise-grade multi-tier overtime calculations (Jibble-compliant)
class OvertimeCalculationService {
  /// Calculate daily tier breakdown for a given day's worked minutes
  static DailyOvertimeResult calculateDaily({
    required DateTime date,
    required int totalWorkMinutes,
    bool isRestDay = false,
    bool isHoliday = false,
    OvertimePolicy policy = const OvertimePolicy(),
  }) {
    if (totalWorkMinutes <= 0) {
      return DailyOvertimeResult(
        date: date,
        totalWorkMinutes: 0,
        regularMinutes: 0,
        isRestDay: isRestDay,
        isHoliday: isHoliday,
      );
    }

    if (!policy.isEnabled) {
      return DailyOvertimeResult(
        date: date,
        totalWorkMinutes: totalWorkMinutes,
        regularMinutes: totalWorkMinutes,
        isRestDay: isRestDay,
        isHoliday: isHoliday,
      );
    }

    // 1. Holiday Override: All hours treated as holiday premium
    if (isHoliday) {
      return DailyOvertimeResult(
        date: date,
        totalWorkMinutes: totalWorkMinutes,
        regularMinutes: 0,
        holidayMinutes: totalWorkMinutes,
        isHoliday: true,
      );
    }

    // 2. Rest Day Override: All hours treated as rest day premium
    if (isRestDay) {
      return DailyOvertimeResult(
        date: date,
        totalWorkMinutes: totalWorkMinutes,
        regularMinutes: 0,
        restDayMinutes: totalWorkMinutes,
        isRestDay: true,
      );
    }

    // 3. Standard Daily Work Tiers
    final regular = min(totalWorkMinutes, policy.dailyStandardThresholdMinutes);
    final remainingAfterRegular = max(0, totalWorkMinutes - policy.dailyStandardThresholdMinutes);
    final otCap = policy.dailyDoubleThresholdMinutes - policy.dailyStandardThresholdMinutes;

    final standardOt = min(remainingAfterRegular, otCap);
    final doubleOt = max(0, totalWorkMinutes - policy.dailyDoubleThresholdMinutes);

    return DailyOvertimeResult(
      date: date,
      totalWorkMinutes: totalWorkMinutes,
      regularMinutes: regular,
      standardOvertimeMinutes: standardOt,
      doubleOvertimeMinutes: doubleOt,
    );
  }

  /// Aggregate a collection of daily records across a pay period, applying weekly thresholds
  static OvertimeBreakdown calculatePeriodBreakdown({
    required List<Map<String, dynamic>> dailyLogs,
    OvertimePolicy policy = const OvertimePolicy(),
  }) {
    final List<DailyOvertimeResult> dailyResults = [];
    int cumRegularMinutes = 0;
    int cumDailyOtMinutes = 0;
    int cumDailyDoubleOtMinutes = 0;
    int cumRestDayMinutes = 0;
    int cumHolidayMinutes = 0;

    for (final log in dailyLogs) {
      final date = log['date'] is DateTime
          ? log['date'] as DateTime
          : (DateTime.tryParse(log['date']?.toString() ?? '') ?? DateTime.now());
      final minutes = (log['minutes'] as num?)?.toInt() ?? 0;
      final isRestDay = log['isRestDay'] as bool? ?? false;
      final isHoliday = log['isHoliday'] as bool? ?? false;

      final res = calculateDaily(
        date: date,
        totalWorkMinutes: minutes,
        isRestDay: isRestDay,
        isHoliday: isHoliday,
        policy: policy,
      );

      dailyResults.add(res);
      cumRegularMinutes += res.regularMinutes;
      cumDailyOtMinutes += res.standardOvertimeMinutes;
      cumDailyDoubleOtMinutes += res.doubleOvertimeMinutes;
      cumRestDayMinutes += res.restDayMinutes;
      cumHolidayMinutes += res.holidayMinutes;
    }

    // Weekly Threshold Adjustment:
    // If cumulative regular hours exceed weekly threshold (e.g. 40h / 2400m), promote excess regular to weekly OT
    int weeklyOtMinutes = 0;
    int adjustedRegularMinutes = cumRegularMinutes;

    if (policy.isEnabled && cumRegularMinutes > policy.weeklyThresholdMinutes) {
      weeklyOtMinutes = cumRegularMinutes - policy.weeklyThresholdMinutes;
      adjustedRegularMinutes = policy.weeklyThresholdMinutes;
    }

    // Calculate total weighted payable hours
    double weightedHours = 0.0;
    if (policy.isEnabled) {
      weightedHours = (adjustedRegularMinutes / 60.0) * 1.0 +
          (cumDailyOtMinutes / 60.0) * policy.standardOvertimeMultiplier +
          (cumDailyDoubleOtMinutes / 60.0) * policy.doubleOvertimeMultiplier +
          (weeklyOtMinutes / 60.0) * policy.weeklyOvertimeRate +
          (cumRestDayMinutes / 60.0) * policy.restDayMultiplier +
          (cumHolidayMinutes / 60.0) * policy.holidayMultiplier;
    } else {
      weightedHours = (cumRegularMinutes +
              cumDailyOtMinutes +
              cumDailyDoubleOtMinutes +
              cumRestDayMinutes +
              cumHolidayMinutes) /
          60.0;
    }

    return OvertimeBreakdown(
      dailyResults: dailyResults,
      totalRegularMinutes: adjustedRegularMinutes,
      totalDailyOtMinutes: cumDailyOtMinutes,
      totalDailyDoubleOtMinutes: cumDailyDoubleOtMinutes,
      totalWeeklyOtMinutes: weeklyOtMinutes,
      totalRestDayMinutes: cumRestDayMinutes,
      totalHolidayMinutes: cumHolidayMinutes,
      totalWeightedPayableHours: weightedHours,
      policy: policy,
    );
  }
}

extension on OvertimePolicy {
  double get weeklyOvertimeRate => standardOvertimeMultiplier;
}
