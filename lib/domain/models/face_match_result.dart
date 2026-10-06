import 'employee_profile.dart';

/// Represents the outcome of matching a live facial signature against database profiles.
class FaceMatchResult {
  final bool isMatch;
  final EmployeeProfile? matchedEmployee;
  final double similarity;
  final double confidenceScore;
  final String punchType;
  final bool isSequenceError;
  final String? sequenceErrorMessage;
  final bool isCooldownError;
  final int? cooldownMinutes;
  final bool isRapidPunchOutConfirmationRequired;
  final int? rapidElapsedMinutes;
  final int? rapidElapsedSeconds;
  final int? shiftDurationMinutes;
  final DateTime? lastPunchTime;
  final String? punchStatus;
  final int? lateMinutes;
  final int? earlyMinutes;
  final int? overtimeMinutes;
  final String? workStatus;
  final String? statusMessage;
  final String? breakType;

  const FaceMatchResult({
    required this.isMatch,
    this.matchedEmployee,
    required this.similarity,
    required this.confidenceScore,
    this.punchType = 'PUNCH_IN',
    this.isSequenceError = false,
    this.sequenceErrorMessage,
    this.isCooldownError = false,
    this.cooldownMinutes,
    this.isRapidPunchOutConfirmationRequired = false,
    this.rapidElapsedMinutes,
    this.rapidElapsedSeconds,
    this.shiftDurationMinutes,
    this.lastPunchTime,
    this.punchStatus,
    this.lateMinutes,
    this.earlyMinutes,
    this.overtimeMinutes,
    this.workStatus,
    this.statusMessage,
    this.breakType,
  });

  const FaceMatchResult.noMatch({this.similarity = 0.0})
      : isMatch = false,
        matchedEmployee = null,
        confidenceScore = 0.0,
        punchType = '',
        isSequenceError = false,
        sequenceErrorMessage = null,
        isCooldownError = false,
        cooldownMinutes = null,
        isRapidPunchOutConfirmationRequired = false,
        rapidElapsedMinutes = null,
        rapidElapsedSeconds = null,
        shiftDurationMinutes = null,
        lastPunchTime = null,
        punchStatus = null,
        lateMinutes = null,
        earlyMinutes = null,
        overtimeMinutes = null,
        workStatus = null,
        statusMessage = null,
        breakType = null;
}
