/// Represents an employee's presence state during an emergency evacuation roll call
class EvacueeStatus {
  final String userId;
  final String employeeName;
  final String department;
  final String lastKnownLocation; // e.g. "Floor 3 - Engineering Wing"
  final DateTime lastPunchTime;
  final bool isAccountedFor; // checked off by fire marshal / floor warden

  const EvacueeStatus({
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.lastKnownLocation,
    required this.lastPunchTime,
    this.isAccountedFor = false,
  });

  EvacueeStatus copyWith({bool? isAccountedFor}) {
    return EvacueeStatus(
      userId: userId,
      employeeName: employeeName,
      department: department,
      lastKnownLocation: lastKnownLocation,
      lastPunchTime: lastPunchTime,
      isAccountedFor: isAccountedFor ?? this.isAccountedFor,
    );
  }
}

/// Headcount summary for building evacuation
class EvacuationSummary {
  final int totalOnSite;
  final int totalAccountedFor;
  final int totalMissing;
  final double accountedForPercent;

  const EvacuationSummary({
    required this.totalOnSite,
    required this.totalAccountedFor,
    required this.totalMissing,
    required this.accountedForPercent,
  });
}
