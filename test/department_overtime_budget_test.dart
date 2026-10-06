import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/department_overtime_budget.dart';
import 'package:mybiometric_app/services/department_overtime_budget_service.dart';

void main() {
  group('DepartmentOvertimeBudgetService Tests', () {
    const budget = DepartmentOvertimeBudget(
      id: 'bud_logistics',
      enterpriseId: 'ent_demo',
      departmentName: 'Logistics',
      monthlyCapHours: 100.0,
      alertThresholdPercent: 80.0,
      costPerHour: 30.0,
    );

    test('Evaluates normal budget consumption accurately', () {
      final status = DepartmentOvertimeBudgetService.evaluateBudget(
        budget: budget,
        consumedOvertimeHours: 50.0,
      );

      expect(status.consumptionPercent, equals(50.0));
      expect(status.isNearLimit, isFalse);
      expect(status.isExceeded, isFalse);
      expect(status.estimatedCost, equals(1500.0));
    });

    test('Detects warning state when approaching alert threshold', () {
      final status = DepartmentOvertimeBudgetService.evaluateBudget(
        budget: budget,
        consumedOvertimeHours: 85.0,
      );

      expect(status.consumptionPercent, equals(85.0));
      expect(status.isNearLimit, isTrue);
      expect(status.isExceeded, isFalse);
    });

    test('Detects hard limit breach when cap is exceeded', () {
      final status = DepartmentOvertimeBudgetService.evaluateBudget(
        budget: budget,
        consumedOvertimeHours: 105.0,
      );

      expect(status.consumptionPercent, equals(105.0));
      expect(status.isExceeded, isTrue);
    });
  });
}
