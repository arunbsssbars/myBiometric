import 'package:flutter/material.dart';
import '../domain/models/early_departure_policy.dart';

/// Service to evaluate punch-out times against scheduled shift ends
class EarlyDepartureService {
  /// Evaluates whether a punch out is premature and within grace thresholds
  static EarlyDepartureEvaluation evaluateDeparture({
    required DateTime punchOutTime,
    required TimeOfDay scheduledEndTime,
    EarlyDeparturePolicy policy = const EarlyDeparturePolicy(),
  }) {
    final scheduledDateTime = DateTime(
      punchOutTime.year,
      punchOutTime.month,
      punchOutTime.day,
      scheduledEndTime.hour,
      scheduledEndTime.minute,
    );

    if (!punchOutTime.isBefore(scheduledDateTime)) {
      return const EarlyDepartureEvaluation(
        isEarly: false,
        withinGracePeriod: false,
        earlyMinutes: 0,
        triggersHalfDay: false,
        statusLabel: 'ON_TIME',
      );
    }

    final diffMinutes = scheduledDateTime.difference(punchOutTime).inMinutes;

    if (diffMinutes <= policy.gracePeriodMinutes) {
      return EarlyDepartureEvaluation(
        isEarly: true,
        withinGracePeriod: true,
        earlyMinutes: diffMinutes,
        triggersHalfDay: false,
        statusLabel: 'GRACE_PERIOD',
      );
    }

    final triggersHalfDay = diffMinutes >= policy.halfDayThresholdMinutes;

    return EarlyDepartureEvaluation(
      isEarly: true,
      withinGracePeriod: false,
      earlyMinutes: diffMinutes,
      triggersHalfDay: triggersHalfDay,
      statusLabel: triggersHalfDay ? 'HALF_DAY_PENALTY' : 'EARLY_DEPARTURE',
    );
  }
}
