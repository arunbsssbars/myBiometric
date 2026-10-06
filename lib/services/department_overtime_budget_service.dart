import '../domain/models/department_overtime_budget.dart';

/// Service for monitoring and evaluating departmental overtime budget utilization
class DepartmentOvertimeBudgetService {
  /// Evaluates departmental overtime consumption against configured caps
  static DepartmentBudgetStatus evaluateBudget({
    required DepartmentOvertimeBudget budget,
    required double consumedOvertimeHours,
  }) {
    final cap = budget.monthlyCapHours > 0 ? budget.monthlyCapHours : 1.0;
    final percent = (consumedOvertimeHours / cap) * 100.0;
    final isExceeded = consumedOvertimeHours >= budget.monthlyCapHours;
    final isNearLimit = !isExceeded && percent >= budget.alertThresholdPercent;
    final cost = consumedOvertimeHours * budget.costPerHour;

    return DepartmentBudgetStatus(
      departmentName: budget.departmentName,
      totalAllocatedCapHours: budget.monthlyCapHours,
      consumedOvertimeHours: consumedOvertimeHours,
      consumptionPercent: percent,
      estimatedCost: cost,
      isNearLimit: isNearLimit,
      isExceeded: isExceeded,
    );
  }
}
