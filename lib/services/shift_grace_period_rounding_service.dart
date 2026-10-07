
enum RoundingInterval {
  none,
  fiveMinutes,
  sevenMinuteFLSA, // 7/8 minute rule for 15-min intervals
  fifteenMinutesStrict,
}

class ShiftGraceRulePolicy {
  final String policyId;
  final String enterpriseId;
  final RoundingInterval interval;
  final int gracePeriodArrivalMinutes; // e.g. 5 mins late allowed without penalty
  final int gracePeriodDepartureMinutes; // e.g. 5 mins early departure allowed
  final bool roundPunchIn;
  final bool roundPunchOut;

  const ShiftGraceRulePolicy({
    required this.policyId,
    required this.enterpriseId,
    this.interval = RoundingInterval.sevenMinuteFLSA,
    this.gracePeriodArrivalMinutes = 5,
    this.gracePeriodDepartureMinutes = 5,
    this.roundPunchIn = true,
    this.roundPunchOut = true,
  });

  Map<String, dynamic> toJson() => {
    'policyId': policyId,
    'enterpriseId': enterpriseId,
    'interval': interval.name,
    'gracePeriodArrivalMinutes': gracePeriodArrivalMinutes,
    'gracePeriodDepartureMinutes': gracePeriodDepartureMinutes,
    'roundPunchIn': roundPunchIn,
    'roundPunchOut': roundPunchOut,
  };

  factory ShiftGraceRulePolicy.fromJson(Map<String, dynamic> json) {
    return ShiftGraceRulePolicy(
      policyId: json['policyId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      interval: RoundingInterval.values.firstWhere(
        (e) => e.name == json['interval'],
        orElse: () => RoundingInterval.sevenMinuteFLSA,
      ),
      gracePeriodArrivalMinutes: (json['gracePeriodArrivalMinutes'] as num?)?.toInt() ?? 5,
      gracePeriodDepartureMinutes: (json['gracePeriodDepartureMinutes'] as num?)?.toInt() ?? 5,
      roundPunchIn: json['roundPunchIn'] as bool? ?? true,
      roundPunchOut: json['roundPunchOut'] as bool? ?? true,
    );
  }
}

class RoundedPunchResult {
  final DateTime rawTimestamp;
  final DateTime roundedTimestamp;
  final bool isGracePeriodApplied;
  final int differenceMinutes;

  const RoundedPunchResult({
    required this.rawTimestamp,
    required this.roundedTimestamp,
    required this.isGracePeriodApplied,
    required this.differenceMinutes,
  });
}

class ShiftGracePeriodRoundingService {
  static final ShiftGracePeriodRoundingService _instance = ShiftGracePeriodRoundingService._internal();
  factory ShiftGracePeriodRoundingService() => _instance;
  ShiftGracePeriodRoundingService._internal();

  RoundedPunchResult calculateRoundedPunch({
    required DateTime actualPunchTime,
    required DateTime scheduledShiftTime,
    required ShiftGraceRulePolicy policy,
    required bool isArrival,
  }) {
    // 1. Check Grace Period
    final deltaToSchedule = actualPunchTime.difference(scheduledShiftTime).inMinutes;

    if (isArrival) {
      if (deltaToSchedule > 0 && deltaToSchedule <= policy.gracePeriodArrivalMinutes) {
        // Arrived within 5 mins of schedule: forgiven to scheduled time
        return RoundedPunchResult(
          rawTimestamp: actualPunchTime,
          roundedTimestamp: scheduledShiftTime,
          isGracePeriodApplied: true,
          differenceMinutes: -deltaToSchedule,
        );
      }
    } else {
      if (deltaToSchedule < 0 && deltaToSchedule.abs() <= policy.gracePeriodDepartureMinutes) {
        // Left up to 5 mins before schedule: forgiven to scheduled time
        return RoundedPunchResult(
          rawTimestamp: actualPunchTime,
          roundedTimestamp: scheduledShiftTime,
          isGracePeriodApplied: true,
          differenceMinutes: deltaToSchedule.abs(),
        );
      }
    }

    // 2. Interval Rounding (FLSA 7/8 minute rule)
    if (policy.interval == RoundingInterval.none) {
      return RoundedPunchResult(
        rawTimestamp: actualPunchTime,
        roundedTimestamp: actualPunchTime,
        isGracePeriodApplied: false,
        differenceMinutes: 0,
      );
    }

    final rounded = _applyFlsaRounding(actualPunchTime, policy.interval);
    final diff = rounded.difference(actualPunchTime).inMinutes;

    return RoundedPunchResult(
      rawTimestamp: actualPunchTime,
      roundedTimestamp: rounded,
      isGracePeriodApplied: false,
      differenceMinutes: diff,
    );
  }

  DateTime _applyFlsaRounding(DateTime time, RoundingInterval interval) {
    if (interval == RoundingInterval.sevenMinuteFLSA) {
      // 15-minute block: 1-7 mins rounds down, 8-14 mins rounds up
      final min = time.minute;
      final remainder = min % 15;
      final base = min - remainder;

      int targetMin;
      int addHour = 0;

      if (remainder <= 7) {
        targetMin = base;
      } else {
        targetMin = base + 15;
        if (targetMin >= 60) {
          targetMin = 0;
          addHour = 1;
        }
      }

      return DateTime(
        time.year,
        time.month,
        time.day,
        time.hour + addHour,
        targetMin,
        0,
      );
    }

    return time;
  }
}
