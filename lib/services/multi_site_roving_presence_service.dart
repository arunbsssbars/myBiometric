
class BranchPunchEvent {
  final String branchId;
  final String branchName;
  final DateTime timestamp;
  final String punchType; // PUNCH_IN or PUNCH_OUT

  const BranchPunchEvent({
    required this.branchId,
    required this.branchName,
    required this.timestamp,
    required this.punchType,
  });

  Map<String, dynamic> toJson() => {
    'branchId': branchId,
    'branchName': branchName,
    'timestamp': timestamp.toIso8601String(),
    'punchType': punchType,
  };

  factory BranchPunchEvent.fromJson(Map<String, dynamic> json) {
    return BranchPunchEvent(
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? 'Branch',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      punchType: json['punchType'] as String? ?? 'PUNCH_IN',
    );
  }
}

class InterBranchTransit {
  final String fromBranchId;
  final String toBranchId;
  final Duration transitDuration;
  final DateTime departedAt;
  final DateTime arrivedAt;

  const InterBranchTransit({
    required this.fromBranchId,
    required this.toBranchId,
    required this.transitDuration,
    required this.departedAt,
    required this.arrivedAt,
  });

  Map<String, dynamic> toJson() => {
    'fromBranchId': fromBranchId,
    'toBranchId': toBranchId,
    'transitMinutes': transitDuration.inMinutes,
    'departedAt': departedAt.toIso8601String(),
    'arrivedAt': arrivedAt.toIso8601String(),
  };
}

class EmployeeRovingDayRecord {
  final String userId;
  final String employeeName;
  final DateTime date;
  final List<BranchPunchEvent> punchHistory;
  final List<InterBranchTransit> transits;
  final Set<String> visitedBranchIds;

  const EmployeeRovingDayRecord({
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.punchHistory,
    required this.transits,
    required this.visitedBranchIds,
  });

  bool get isMultiSiteRoving => visitedBranchIds.length > 1;

  Duration get totalTransitDuration => transits.fold(
    Duration.zero,
    (acc, t) => acc + t.transitDuration,
  );
}

class MultiSiteRovingPresenceService {
  static final MultiSiteRovingPresenceService _instance = MultiSiteRovingPresenceService._internal();
  factory MultiSiteRovingPresenceService() => _instance;
  MultiSiteRovingPresenceService._internal();

  EmployeeRovingDayRecord evaluateDailyPresence({
    required String userId,
    required String employeeName,
    required DateTime date,
    required List<BranchPunchEvent> punches,
  }) {
    if (punches.isEmpty) {
      return EmployeeRovingDayRecord(
        userId: userId,
        employeeName: employeeName,
        date: date,
        punchHistory: const [],
        transits: const [],
        visitedBranchIds: const {},
      );
    }

    final sorted = List<BranchPunchEvent>.from(punches)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final visitedBranches = <String>{};
    final transits = <InterBranchTransit>[];

    BranchPunchEvent? lastPunchOut;

    for (final p in sorted) {
      visitedBranches.add(p.branchId);

      if (p.punchType == 'PUNCH_OUT') {
        lastPunchOut = p;
      } else if (p.punchType == 'PUNCH_IN' && lastPunchOut != null) {
        if (lastPunchOut.branchId != p.branchId && p.timestamp.isAfter(lastPunchOut.timestamp)) {
          final transitTime = p.timestamp.difference(lastPunchOut.timestamp);
          transits.add(
            InterBranchTransit(
              fromBranchId: lastPunchOut.branchId,
              toBranchId: p.branchId,
              transitDuration: transitTime,
              departedAt: lastPunchOut.timestamp,
              arrivedAt: p.timestamp,
            ),
          );
        }
      }
    }

    return EmployeeRovingDayRecord(
      userId: userId,
      employeeName: employeeName,
      date: date,
      punchHistory: sorted,
      transits: transits,
      visitedBranchIds: visitedBranches,
    );
  }
}
