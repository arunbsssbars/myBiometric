/// Policy configuration for annual and monthly leave accrual calculations
class LeaveAccrualPolicy {
  final String id;
  final String enterpriseId;
  final String leaveType; // 'PAID', 'SICK', 'CASUAL'
  final double annualQuotaDays; // e.g. 18.0 days/year
  final double maxCarryoverDays; // e.g. 5.0 days into new fiscal year
  final bool prorateForNewHires;
  final double monthlyAccrualRate; // e.g. 1.5 days/month

  const LeaveAccrualPolicy({
    required this.id,
    required this.enterpriseId,
    required this.leaveType,
    required this.annualQuotaDays,
    this.maxCarryoverDays = 5.0,
    this.prorateForNewHires = true,
  }) : monthlyAccrualRate = annualQuotaDays / 12.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'leaveType': leaveType,
      'annualQuotaDays': annualQuotaDays,
      'maxCarryoverDays': maxCarryoverDays,
      'prorateForNewHires': prorateForNewHires,
      'monthlyAccrualRate': monthlyAccrualRate,
    };
  }

  factory LeaveAccrualPolicy.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LeaveAccrualPolicy(
      id: docId ?? map['id'] ?? '',
      enterpriseId: map['enterpriseId'] ?? '',
      leaveType: map['leaveType'] ?? 'PAID',
      annualQuotaDays: (map['annualQuotaDays'] as num?)?.toDouble() ?? 18.0,
      maxCarryoverDays: (map['maxCarryoverDays'] as num?)?.toDouble() ?? 5.0,
      prorateForNewHires: map['prorateForNewHires'] ?? true,
    );
  }
}

/// Simulated leave balance projection result
class LeaveAccrualProjection {
  final String leaveType;
  final double startingBalance;
  final double accruedToDate;
  final double usedToDate;
  final double projectedYearEndBalance;
  final double availableBalance;

  const LeaveAccrualProjection({
    required this.leaveType,
    required this.startingBalance,
    required this.accruedToDate,
    required this.usedToDate,
    required this.projectedYearEndBalance,
    required this.availableBalance,
  });
}
