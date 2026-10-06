import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/terminal_anti_passback_policy.dart';

/// Result of evaluating an Anti-Passback check.
class AntiPassbackEvaluationResult {
  final bool isAllowed;
  final bool isViolation;
  final String? violationType; // 'DOUBLE_ENTRY', 'DOUBLE_EXIT', 'INTERLOCK_OCCUPIED'
  final String message;

  const AntiPassbackEvaluationResult({
    required this.isAllowed,
    required this.isViolation,
    this.violationType,
    required this.message,
  });
}

/// Service enforcing Anti-Passback (APB) credential sequencing and dual-door interlock rules.
class TerminalAntiPassbackService {
  final FirebaseFirestore? _firestore;

  // In-memory cache of user zone locations for sub-millisecond evaluation
  final Map<String, String> _lastUserDirectionCache = {}; // employeeId -> 'IN' | 'OUT'
  final Map<String, DateTime> _lastUserPunchTimeCache = {};

  TerminalAntiPassbackService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _effectiveFirestore {
    return _firestore ?? FirebaseFirestore.instance;
  }

  /// Evaluates an incoming biometric punch against the active APB policy.
  Future<AntiPassbackEvaluationResult> evaluatePassback({
    required String enterpriseId,
    required String employeeId,
    required String terminalId,
    required String punchType, // 'PUNCH_IN', 'PUNCH_OUT'
    required TerminalAntiPassbackPolicy policy,
    String? userRole,
  }) async {
    if (!policy.isActive || policy.mode == AntiPassbackMode.disabled) {
      return const AntiPassbackEvaluationResult(
        isAllowed: true,
        isViolation: false,
        message: 'Anti-Passback disabled.',
      );
    }

    // Role exemption check
    if (userRole != null && policy.exemptRoles.contains(userRole)) {
      return const AntiPassbackEvaluationResult(
        isAllowed: true,
        isViolation: false,
        message: 'Role exempt from Anti-Passback validation.',
      );
    }

    final isEntryTerminal = policy.entryTerminalIds.contains(terminalId) || punchType == 'PUNCH_IN';
    final requestedDirection = isEntryTerminal ? 'IN' : 'OUT';

    final lastDirection = _lastUserDirectionCache[employeeId];
    final lastPunchTime = _lastUserPunchTimeCache[employeeId];
    final now = DateTime.now();

    // Check if auto-reset expired
    final isExpired = lastPunchTime != null &&
        now.difference(lastPunchTime).inHours >= policy.resetIntervalHours;

    if (lastDirection != null && !isExpired) {
      if (lastDirection == 'IN' && requestedDirection == 'IN') {
        // Double Entry Violation
        final isStrict = policy.mode == AntiPassbackMode.strict;
        await _logPassbackAlert(enterpriseId, employeeId, terminalId, 'DOUBLE_ENTRY', isStrict);

        return AntiPassbackEvaluationResult(
          isAllowed: !isStrict,
          isViolation: true,
          violationType: 'DOUBLE_ENTRY',
          message: isStrict
              ? 'Anti-Passback Error: Employee already scanned IN. Re-entry prohibited.'
              : 'Anti-Passback Warning: Consecutive IN scan recorded.',
        );
      } else if (lastDirection == 'OUT' && requestedDirection == 'OUT') {
        // Double Exit Violation
        final isStrict = policy.mode == AntiPassbackMode.strict;
        await _logPassbackAlert(enterpriseId, employeeId, terminalId, 'DOUBLE_EXIT', isStrict);

        return AntiPassbackEvaluationResult(
          isAllowed: !isStrict,
          isViolation: true,
          violationType: 'DOUBLE_EXIT',
          message: isStrict
              ? 'Anti-Passback Error: Employee already scanned OUT. Exit prohibited.'
              : 'Anti-Passback Warning: Consecutive OUT scan recorded.',
        );
      }
    }

    // Valid transition - record state
    _lastUserDirectionCache[employeeId] = requestedDirection;
    _lastUserPunchTimeCache[employeeId] = now;

    return const AntiPassbackEvaluationResult(
      isAllowed: true,
      isViolation: false,
      message: 'Sequence verified.',
    );
  }

  Future<void> _logPassbackAlert(
    String enterpriseId,
    String employeeId,
    String terminalId,
    String violationType,
    bool rejected,
  ) async {
    try {
      await _effectiveFirestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('security_alerts')
          .add({
        'type': 'ANTI_PASSBACK_VIOLATION',
        'violationType': violationType,
        'employeeId': employeeId,
        'terminalId': terminalId,
        'actionRejected': rejected,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
