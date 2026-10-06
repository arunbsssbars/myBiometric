import '../domain/models/leave_accrual_policy.dart';

/// Service for calculating employee leave accruals and future balance projections
class LeaveAccrualService {
  /// Calculate accrued leave days up to a specified evaluation month
  static LeaveAccrualProjection calculateProjection({
    required LeaveAccrualPolicy policy,
    required DateTime joiningDate,
    required DateTime evaluationDate,
    double initialCarryover = 0.0,
    double usedDays = 0.0,
  }) {
    final cappedCarryover = initialCarryover > policy.maxCarryoverDays
        ? policy.maxCarryoverDays
        : initialCarryover;

    // Calculate active months in the current fiscal/calendar year
    final evalMonth = evaluationDate.month;
    int eligibleMonths = evalMonth;

    if (policy.prorateForNewHires && joiningDate.year == evaluationDate.year) {
      eligibleMonths = (evalMonth - joiningDate.month + 1);
      if (eligibleMonths < 0) eligibleMonths = 0;
    }

    final accruedToDate = eligibleMonths * policy.monthlyAccrualRate;
    final totalEarned = cappedCarryover + accruedToDate;
    final available = (totalEarned - usedDays) > 0 ? (totalEarned - usedDays) : 0.0;

    int totalYearMonths = 12;
    if (policy.prorateForNewHires && joiningDate.year == evaluationDate.year) {
      totalYearMonths = 12 - joiningDate.month + 1;
    }
    final fullYearAccrual = totalYearMonths * policy.monthlyAccrualRate;
    final projectedEnd = (cappedCarryover + fullYearAccrual - usedDays) > 0
        ? (cappedCarryover + fullYearAccrual - usedDays)
        : 0.0;

    return LeaveAccrualProjection(
      leaveType: policy.leaveType,
      startingBalance: cappedCarryover,
      accruedToDate: accruedToDate,
      usedToDate: usedDays,
      projectedYearEndBalance: projectedEnd,
      availableBalance: available,
    );
  }
}
