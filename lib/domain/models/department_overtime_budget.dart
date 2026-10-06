/// Represents a monthly or weekly overtime budget cap for a department
class DepartmentOvertimeBudget {
  final String id;
  final String enterpriseId;
  final String departmentName;
  final double monthlyCapHours;
  final double alertThresholdPercent; // e.g. 80.0%
  final double costPerHour;

  const DepartmentOvertimeBudget({
    required this.id,
    required this.enterpriseId,
    required this.departmentName,
    required this.monthlyCapHours,
    this.alertThresholdPercent = 80.0,
    this.costPerHour = 25.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'departmentName': departmentName,
      'monthlyCapHours': monthlyCapHours,
      'alertThresholdPercent': alertThresholdPercent,
      'costPerHour': costPerHour,
    };
  }

  factory DepartmentOvertimeBudget.fromMap(Map<String, dynamic> map, {String? docId}) {
    return DepartmentOvertimeBudget(
      id: docId ?? map['id'] ?? '',
      enterpriseId: map['enterpriseId'] ?? '',
      departmentName: map['departmentName'] ?? '',
      monthlyCapHours: (map['monthlyCapHours'] as num?)?.toDouble() ?? 100.0,
      alertThresholdPercent: (map['alertThresholdPercent'] as num?)?.toDouble() ?? 80.0,
      costPerHour: (map['costPerHour'] as num?)?.toDouble() ?? 25.0,
    );
  }
}

/// Budget consumption evaluation
class DepartmentBudgetStatus {
  final String departmentName;
  final double totalAllocatedCapHours;
  final double consumedOvertimeHours;
  final double consumptionPercent;
  final double estimatedCost;
  final bool isNearLimit;
  final bool isExceeded;

  const DepartmentBudgetStatus({
    required this.departmentName,
    required this.totalAllocatedCapHours,
    required this.consumedOvertimeHours,
    required this.consumptionPercent,
    required this.estimatedCost,
    required this.isNearLimit,
    required this.isExceeded,
  });
}
