import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/face_math_utils.dart';
import '../../services/shift_evaluation_service.dart';
import '../models/employee_profile.dart';
import '../models/face_match_result.dart';
import '../models/shift_schedule.dart';
import '../repositories/attendance_repository.dart';

/// Business logic for identifying a face from enterprise candidates and recording attendance
/// adhering to strict Clock In / Clock Out sequence state transitions.
class VerifyFacePunchInUseCase {
  final AttendanceRepository _attendanceRepository;
  final double defaultThreshold;

  AttendanceRepository get attendanceRepository => _attendanceRepository;

  VerifyFacePunchInUseCase({
    required AttendanceRepository attendanceRepository,
    this.defaultThreshold = 0.60,
  }) : _attendanceRepository = attendanceRepository;

  static final Map<String, List<double>> _normalizedCandidateCache = {};

  static List<double> _getNormalizedSignature(String uid, List<double> raw) {
    final cached = _normalizedCandidateCache[uid];
    if (cached != null && cached.length == raw.length) {
      return cached;
    }
    final normalized = FaceMathUtils.l2Normalize(raw);
    _normalizedCandidateCache[uid] = normalized;
    return normalized;
  }

  Future<FaceMatchResult> execute({
    required List<double> liveEmbedding,
    required List<EmployeeProfile> candidates,
    required String enterpriseId,
    String punchType = 'AUTO', // 'AUTO', 'PUNCH_IN', or 'PUNCH_OUT'
    String verifiedVia = 'FACE_ID',
    double? threshold,
    double? latitude,
    double? longitude,
    double? distanceFromOfficeMeters,
    bool? withinGeofence,
    ShiftSchedule? shiftSchedule,
    bool bypassRapidPunchOut = false,
    bool allowRapidPunchOutInCooldown = false,
    String? selectedBreakType,
  }) async {
    final effectiveThreshold = threshold ?? defaultThreshold;
    if (liveEmbedding.isEmpty || candidates.isEmpty) {
      return const FaceMatchResult.noMatch();
    }

    // Ensure live embedding is L2-normalized
    final normalizedLive = FaceMathUtils.l2Normalize(liveEmbedding);

    EmployeeProfile? bestMatch;
    double highestSimilarity = -1.0;

    // High-performance candidate matching leveraging cached normalized vectors
    for (final employee in candidates) {
      final sig = employee.facialSignature;
      if (sig == null || sig.isEmpty) continue;

      final candidateSig = _getNormalizedSignature(employee.uid, sig);
      final similarity = FaceMathUtils.cosineSimilarity(normalizedLive, candidateSig);

      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        bestMatch = employee;
      }
    }

    if (bestMatch != null && highestSimilarity >= effectiveThreshold) {
      final isAdmin = bestMatch.role == 'enterprise_admin' ||
          bestMatch.role == 'admin' ||
          bestMatch.role == 'super_admin';
      final canUseKiosk = isAdmin || bestMatch.allowedVerificationMethods.contains('KIOSK_FACE');

      if (!canUseKiosk) {
        return FaceMatchResult(
          isMatch: false,
          matchedEmployee: bestMatch,
          similarity: highestSimilarity,
          confidenceScore: highestSimilarity,
          punchType: punchType,
          isSequenceError: true,
          sequenceErrorMessage: 'Kiosk facial attendance is not authorized for your account. Please contact your company admin.',
        );
      }

      final latestPunch = await _attendanceRepository.getLatestPunchToday(bestMatch.uid);
      final String? lastType = latestPunch?['type'] as String?;
      DateTime? lastTime;
      final rawTs = latestPunch?['timestamp'];
      if (rawTs is Timestamp) {
        lastTime = rawTs.toDate();
      } else if (rawTs is DateTime) {
        lastTime = rawTs;
      }

      // Determine effective punch action via Sequence State Machine
      String resolvedType = punchType;
      if (resolvedType == 'AUTO') {
        if (lastType == 'START_BREAK') {
          resolvedType = 'END_BREAK';
        } else if (lastType == 'PUNCH_IN' || lastType == 'END_BREAK') {
          resolvedType = 'PUNCH_OUT';
        } else {
          resolvedType = 'PUNCH_IN';
        }
      } else if (resolvedType == 'BREAK' || resolvedType == 'START_BREAK') {
        if (lastType == 'START_BREAK') {
          resolvedType = 'END_BREAK';
        } else if (lastType == 'PUNCH_IN' || lastType == 'END_BREAK') {
          resolvedType = 'START_BREAK';
        } else {
          return FaceMatchResult(
            isMatch: true,
            matchedEmployee: bestMatch,
            similarity: highestSimilarity,
            confidenceScore: highestSimilarity,
            punchType: 'START_BREAK',
            isSequenceError: true,
            sequenceErrorMessage: 'Please clock IN before taking a break.',
            lastPunchTime: lastTime,
          );
        }
      }

      final diffSecs = lastTime != null ? DateTime.now().difference(lastTime).inSeconds : 999999;
      final isSameTypeDuplicate = lastTime != null && resolvedType == lastType && diffSecs < 120;
      final isAutoCooldown = lastTime != null &&
          punchType == 'AUTO' &&
          lastType == 'PUNCH_IN' &&
          diffSecs < 120 &&
          !allowRapidPunchOutInCooldown;

      // Check double-punch suppression (2-minute cooldown for duplicate punch type or passive AUTO)
      if (isSameTypeDuplicate || isAutoCooldown) {
        final diffMins = (diffSecs / 60).ceil();
        final typeStr = lastType == 'PUNCH_IN' ? 'IN' : 'OUT';
        return FaceMatchResult(
          isMatch: true,
          matchedEmployee: bestMatch,
          similarity: highestSimilarity,
          confidenceScore: highestSimilarity,
          punchType: lastType ?? 'PUNCH_IN',
          isSequenceError: true,
          isCooldownError: true,
          cooldownMinutes: diffMins,
          sequenceErrorMessage: 'You already punched $typeStr $diffMins min ago. Accidental double-punch prevented.',
          lastPunchTime: lastTime,
        );
      }

      if (resolvedType == 'PUNCH_IN' && lastType == 'PUNCH_IN') {
        final timeStr = lastTime != null
            ? '${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}'
            : 'earlier';
        return FaceMatchResult(
          isMatch: true,
          matchedEmployee: bestMatch,
          similarity: highestSimilarity,
          confidenceScore: highestSimilarity,
          punchType: 'PUNCH_IN',
          isSequenceError: true,
          sequenceErrorMessage: 'Already Clocked In at $timeStr. Please punch OUT before punching IN again.',
          lastPunchTime: lastTime,
        );
      } else if (resolvedType == 'PUNCH_OUT' && (lastType == null || lastType == 'PUNCH_OUT')) {
        return FaceMatchResult(
          isMatch: true,
          matchedEmployee: bestMatch,
          similarity: highestSimilarity,
          confidenceScore: highestSimilarity,
          punchType: 'PUNCH_OUT',
          isSequenceError: true,
          sequenceErrorMessage: 'Already Clocked Out. Please punch IN before clocking out.',
          lastPunchTime: lastTime,
        );
      }

      // Rapid Punch-Out Warning Safeguard:
      // If employee clocked IN less than 15 minutes ago, prompt for confirmation dialog with timer undo operation
      if (!bypassRapidPunchOut && resolvedType == 'PUNCH_OUT' && lastType == 'PUNCH_IN' && lastTime != null) {
        final diff = DateTime.now().difference(lastTime).inMinutes;
        if (diff < 15) {
          return FaceMatchResult(
            isMatch: true,
            matchedEmployee: bestMatch,
            similarity: highestSimilarity,
            confidenceScore: highestSimilarity,
            punchType: 'PUNCH_OUT',
            isRapidPunchOutConfirmationRequired: true,
            rapidElapsedMinutes: diff,
            rapidElapsedSeconds: diffSecs,
            lastPunchTime: lastTime,
          );
        }
      }

      // Calculate shift duration on PUNCH_OUT
      int? shiftDurationMinutes;
      if (resolvedType == 'PUNCH_OUT' && lastTime != null && lastType == 'PUNCH_IN') {
        shiftDurationMinutes = DateTime.now().difference(lastTime).inMinutes;
      }

      // Evaluate punch against enterprise shift schedule (dynamic per employee assignment)
      final evalSchedule = shiftSchedule ?? ShiftSchedule.fromPreset(bestMatch.assignedShift);
      final evalResult = ShiftEvaluationService.evaluatePunch(
        punchTime: DateTime.now(),
        punchType: resolvedType,
        schedule: evalSchedule,
        shiftDurationMinutes: shiftDurationMinutes,
      );

      final targetEnterpriseId = enterpriseId.trim().isNotEmpty
          ? enterpriseId.trim()
          : bestMatch.enterpriseId.trim();

      await _attendanceRepository.logAttendance(
        userId: bestMatch.uid,
        enterpriseId: targetEnterpriseId,
        type: resolvedType,
        verifiedVia: verifiedVia,
        confidenceScore: verifiedVia == 'FACE_ID' ? highestSimilarity : 1.0,
        shiftDurationMinutes: shiftDurationMinutes,
        latitude: latitude,
        longitude: longitude,
        distanceFromOfficeMeters: distanceFromOfficeMeters,
        withinGeofence: withinGeofence,
        employeeName: bestMatch.fullName,
        employeeIdCode: bestMatch.employeeId,
        punchStatus: evalResult.punchStatus,
        lateMinutes: evalResult.lateMinutes,
        earlyMinutes: evalResult.earlyMinutes,
        overtimeMinutes: evalResult.overtimeMinutes,
        workStatus: evalResult.workStatus,
        breakType: (resolvedType == 'START_BREAK' || resolvedType == 'END_BREAK')
            ? (selectedBreakType ?? 'Lunch Break')
            : null,
      );

      return FaceMatchResult(
        isMatch: true,
        matchedEmployee: bestMatch,
        similarity: highestSimilarity,
        confidenceScore: highestSimilarity,
        punchType: resolvedType,
        shiftDurationMinutes: shiftDurationMinutes,
        lastPunchTime: lastTime,
        punchStatus: evalResult.punchStatus,
        lateMinutes: evalResult.lateMinutes,
        earlyMinutes: evalResult.earlyMinutes,
        overtimeMinutes: evalResult.overtimeMinutes,
        workStatus: evalResult.workStatus,
        statusMessage: evalResult.statusMessage,
        breakType: (resolvedType == 'START_BREAK' || resolvedType == 'END_BREAK')
            ? (selectedBreakType ?? 'Lunch Break')
            : null,
      );
    }

    return FaceMatchResult(
      isMatch: false,
      similarity: highestSimilarity > 0 ? highestSimilarity : 0.0,
      confidenceScore: 0.0,
    );
  }
}
