import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_automation_rule.dart';
import 'terminal_attendance_injector_service.dart';

/// Result of evaluating and executing terminal automation rules.
class AutomationEvaluationResult {
  final int rulesEvaluated;
  final int punchesTriggered;
  final List<String> logs;

  const AutomationEvaluationResult({
    required this.rulesEvaluated,
    required this.punchesTriggered,
    required this.logs,
  });
}

/// Service managing scheduled automated terminal punch injection,
/// mimicking natural human arrival/departure variance at physical terminals.
class TerminalAutomationEngineService {
  final FirebaseFirestore? _firestore;
  final TerminalAttendanceInjectorService? _injectorService;

  TerminalAutomationEngineService({
    FirebaseFirestore? firestore,
    TerminalAttendanceInjectorService? injectorService,
  })  : _firestore = firestore,
        _injectorService = injectorService;

  FirebaseFirestore get _effectiveFirestore {
    return _firestore ?? FirebaseFirestore.instance;
  }

  TerminalAttendanceInjectorService get _effectiveInjector {
    return _injectorService ?? TerminalAttendanceInjectorService(firestore: _firestore);
  }

  /// Evaluates active automation rules and executes scheduled punches if the current time matches.
  Future<AutomationEvaluationResult> evaluateAndTriggerRules({
    required String enterpriseId,
    required List<TerminalAutomationRule> rules,
    required List<BiometricTerminalDevice> devices,
    DateTime? currentTime,
  }) async {
    final now = currentTime ?? DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    int triggeredCount = 0;
    final logs = <String>[];

    final deviceMap = {for (final d in devices) d.id: d};

    for (final rule in rules) {
      if (!rule.isActive) continue;
      if (!rule.activeWeekdays.contains(currentWeekday)) continue;

      final device = deviceMap[rule.preferredTerminalId] ?? (devices.isNotEmpty ? devices.first : null);
      if (device == null) {
        logs.add('Skipped ${rule.employeeName}: No matching terminal found.');
        continue;
      }

      // Check Punch In window
      if (rule.autoPunchIn) {
        final targetPunchIn = rule.computeRealisticPunchTime(now, rule.shiftStartTime, seed: now.day * 31 + rule.employeeId.hashCode);
        final diffMinutes = (now.difference(targetPunchIn).inSeconds / 60.0).abs();

        if (diffMinutes <= 15) {
          // Check if already triggered today for PUNCH_IN
          final alreadyTriggeredToday = rule.lastTriggeredAt != null &&
              rule.lastTriggeredAt!.year == now.year &&
              rule.lastTriggeredAt!.month == now.month &&
              rule.lastTriggeredAt!.day == now.day &&
              rule.lastTriggeredType == 'PUNCH_IN';

          if (!alreadyTriggeredToday) {
            final res = await _effectiveInjector.injectTerminalPunch(
              enterpriseId: enterpriseId,
              device: device,
              userId: rule.employeeId,
              employeeId: rule.employeeId,
              employeeName: rule.employeeName,
              punchType: 'PUNCH_IN',
              authMode: rule.preferredAuthMode,
              similarityScore: 99.1 + ((rule.employeeId.hashCode % 8) / 10.0),
              timestamp: targetPunchIn,
            );

            if (res.success) {
              triggeredCount++;
              logs.add('Successfully auto-injected PUNCH_IN for ${rule.employeeName} at ${targetPunchIn.hour}:${targetPunchIn.minute.toString().padLeft(2, '0')}.');
              await _updateRuleTrigger(enterpriseId, rule.id, 'PUNCH_IN', targetPunchIn);
            }
          }
        }
      }

      // Check Punch Out window
      if (rule.autoPunchOut) {
        final targetPunchOut = rule.computeRealisticPunchTime(now, rule.shiftEndTime, seed: now.day * 47 + rule.employeeId.hashCode);
        final diffMinutes = (now.difference(targetPunchOut).inSeconds / 60.0).abs();

        if (diffMinutes <= 15) {
          final alreadyTriggeredToday = rule.lastTriggeredAt != null &&
              rule.lastTriggeredAt!.year == now.year &&
              rule.lastTriggeredAt!.month == now.month &&
              rule.lastTriggeredAt!.day == now.day &&
              rule.lastTriggeredType == 'PUNCH_OUT';

          if (!alreadyTriggeredToday) {
            final res = await _effectiveInjector.injectTerminalPunch(
              enterpriseId: enterpriseId,
              device: device,
              userId: rule.employeeId,
              employeeId: rule.employeeId,
              employeeName: rule.employeeName,
              punchType: 'PUNCH_OUT',
              authMode: rule.preferredAuthMode,
              similarityScore: 99.2 + ((rule.employeeId.hashCode % 7) / 10.0),
              timestamp: targetPunchOut,
            );

            if (res.success) {
              triggeredCount++;
              logs.add('Successfully auto-injected PUNCH_OUT for ${rule.employeeName} at ${targetPunchOut.hour}:${targetPunchOut.minute.toString().padLeft(2, '0')}.');
              await _updateRuleTrigger(enterpriseId, rule.id, 'PUNCH_OUT', targetPunchOut);
            }
          }
        }
      }
    }

    return AutomationEvaluationResult(
      rulesEvaluated: rules.length,
      punchesTriggered: triggeredCount,
      logs: logs,
    );
  }

  Future<void> _updateRuleTrigger(
    String enterpriseId,
    String ruleId,
    String punchType,
    DateTime triggerTime,
  ) async {
    try {
      await _effectiveFirestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('terminal_automation_rules')
          .doc(ruleId)
          .update({
        'lastTriggeredAt': Timestamp.fromDate(triggerTime),
        'lastTriggeredType': punchType,
      });
    } catch (_) {}
  }
}
