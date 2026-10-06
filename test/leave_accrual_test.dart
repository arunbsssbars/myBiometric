import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/leave_accrual_policy.dart';
import 'package:mybiometric/services/leave_accrual_service.dart';

void main() {
  group('LeaveAccrualService Tests', () {
    const policy = LeaveAccrualPolicy(
      id: 'pol_annual_paid',
      enterpriseId: 'ent_demo',
      leaveType: 'PAID',
      annualQuotaDays: 24.0, // 2.0 days / month
      maxCarryoverDays: 5.0,
      prorateForNewHires: true,
    );

    test('Calculates accruals accurately through mid-year evaluation', () {
      final projection = LeaveAccrualService.calculateProjection(
        policy: policy,
        joiningDate: DateTime(2025, 1, 1),
        evaluationDate: DateTime(2026, 6, 15), // Month 6
        initialCarryover: 3.0,
        usedDays: 4.0,
      );

      // Accrued to month 6: 6 * 2.0 = 12.0 days. Total earned: 3 + 12 = 15.0 days.
      // Available: 15 - 4 = 11.0 days.
      expect(projection.startingBalance, equals(3.0));
      expect(projection.accruedToDate, equals(12.0));
      expect(projection.availableBalance, equals(11.0));
      expect(projection.projectedYearEndBalance, equals(23.0)); // 3 + 24 - 4 = 23
    });

    test('Prorates accrual for new employee joined in July', () {
      final projection = LeaveAccrualService.calculateProjection(
        policy: policy,
        joiningDate: DateTime(2026, 7, 1),
        evaluationDate: DateTime(2026, 10, 1), // Month 10 (4 active months: Jul, Aug, Sep, Oct)
        initialCarryover: 0.0,
        usedDays: 1.0,
      );

      // 4 active months * 2.0 days = 8.0 accrued.
      expect(projection.accruedToDate, equals(8.0));
      expect(projection.availableBalance, equals(7.0));
    });
  });
}
