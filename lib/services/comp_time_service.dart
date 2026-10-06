import '../domain/models/comp_time_record.dart';

/// Service for managing compensatory off (Comp-Time) accrual and redemption
class CompTimeService {
  /// Accrue comp-time credit from eligible overtime hours (e.g. 1.0x or 1.5x multiplier)
  static CompTimeRecord accrueCompTime({
    required String recordId,
    required String enterpriseId,
    required String userId,
    required String employeeName,
    required double overtimeHoursWorked,
    double accrualMultiplier = 1.0,
    Duration validityDuration = const Duration(days: 90),
    DateTime? earnedDate,
    String sourceAttendanceLogId = '',
  }) {
    final earned = earnedDate ?? DateTime.now();
    final expiry = earned.add(validityDuration);
    final totalCreditedHours = overtimeHoursWorked * accrualMultiplier;

    return CompTimeRecord(
      id: recordId,
      enterpriseId: enterpriseId,
      userId: userId,
      employeeName: employeeName,
      earnedHours: totalCreditedHours,
      usedHours: 0.0,
      earnedDate: earned,
      expiryDate: expiry,
      sourceAttendanceLogId: sourceAttendanceLogId,
    );
  }

  /// Calculates total active and usable comp-time balance across records
  static double getAvailableCompTimeBalance(
    List<CompTimeRecord> records, {
    DateTime? referenceDate,
  }) {
    final ref = referenceDate ?? DateTime.now();
    double total = 0.0;
    for (final r in records) {
      if (!r.isExpired(referenceDate: ref)) {
        total += r.remainingHours;
      }
    }
    return total;
  }
}
